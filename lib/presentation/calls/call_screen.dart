import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/calls/agora_token_repo.dart';
import '../../core/calls/call_repo.dart';
import '../../core/supabase/supabase_config.dart';

/// Écran d'appel en cours (audio ou vidéo) — rejoint le canal Agora
/// correspondant à `channelName`. `invitationId` est fourni des DEUX
/// côtés en pratique (l'appelant le reçoit de `CallRepo.createInvitation`
/// avant de pousser cet écran, l'appelé de la notification push) — reste
/// nullable par simplicité d'appel, mais permet d'écouter en direct
/// `call_invitations.status` (05/10 : détecte un refus avant que l'autre
/// partie n'ait rejoint le canal Agora, cas où aucun événement Agora ne
/// se déclenche jamais côté appelant) et de couper l'appel après 45s si
/// personne ne répond du tout (évite de rester bloqué indéfiniment sur
/// "Appel en cours...").
class CallScreen extends StatefulWidget {
  final String channelName;
  final String callType; // 'audio' | 'video'
  final String peerName;
  final String? invitationId;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.callType,
    required this.peerName,
    this.invitationId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RtcEngine? _engine;
  // Tonalité de sonnerie côté appelant ("Appel en cours...") — jusque-là
  // absente, l'appel semblait "silencieux" alors qu'il fonctionnait
  // (05/08). Même asset que la sonnerie d'appel entrant, en boucle.
  final _ringbackPlayer = AudioPlayer();
  bool get _isVideo => widget.callType == 'video';

  bool _joined = false;
  bool _remoteJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _speakerOn = true;
  bool _cameraOff = false;
  String? _error;

  /// Timeout de secours (05/10) + écoute en direct de
  /// `call_invitations.status` — voir le commentaire de classe.
  Timer? _timeoutTimer;
  StreamSubscription<List<Map<String, dynamic>>>? _statusSub;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _setup();
    _watchInvitationStatus();
  }

  /// Détecte en direct un refus/appel manqué signalé par l'AUTRE partie
  /// (05/10) — sans ça, si l'appelé refuse avant d'avoir rejoint le
  /// canal Agora, aucun événement Agora ne prévient jamais l'appelant
  /// (personne n'a rejoint pour en partir) : il restait bloqué sur
  /// "Appel en cours..." indéfiniment. Nécessite Realtime activé sur
  /// `call_invitations` (voir phase256_patch_call_invitations_realtime.sql).
  void _watchInvitationStatus() {
    if (widget.invitationId == null) return;
    _statusSub = SupabaseConfig.client
        .from('call_invitations')
        .stream(primaryKey: ['id'])
        .eq('id', widget.invitationId!)
        .listen((rows) {
      if (!mounted || rows.isEmpty || _remoteJoined) return;
      final status = rows.first['status'] as String?;
      if (status == 'declined') {
        _endCall(reasonMessage: 'Appel refusé.', skipStatusUpdate: true);
      } else if (status == 'missed') {
        _endCall(
            reasonMessage: 'Personne n\'a répondu.', skipStatusUpdate: true);
      }
    });
  }

  /// Coupe l'appel après 45s si personne n'a rejoint (05/10) — filet de
  /// sécurité indépendant du statut de l'invitation : couvre aussi le
  /// cas où l'autre partie n'a jamais même reçu la notification d'appel
  /// (push en échec), donc n'a jamais pu répondre "refusé"/"manqué".
  void _startCallerTimeout() {
    if (widget.invitationId == null || _timeoutTimer != null) return;
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!mounted || _remoteJoined || _ending) return;
      CallRepo.updateStatus(widget.invitationId!, 'missed').catchError((_) {});
      _endCall(reasonMessage: 'Personne n\'a répondu.', skipStatusUpdate: true);
    });
  }

  Future<void> _setup() async {
    try {
      final statuses = await [
        Permission.microphone,
        if (_isVideo) Permission.camera,
      ].request();
      if (statuses.values.any((s) => !s.isGranted)) {
        if (mounted) {
          setState(() => _error =
              'Autorisez le micro${_isVideo ? ' et la caméra' : ''} dans les paramètres pour passer l\'appel.');
        }
        return;
      }

      final token = await AgoraTokenRepo.fetchToken(widget.channelName);

      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(appId: token.appId));

      if (_isVideo) {
        await engine.enableVideo();
      } else {
        await engine.disableVideo();
        await engine.enableAudio();
      }
      await engine.setDefaultAudioRouteToSpeakerphone(true);

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (mounted) setState(() => _joined = true);
            _startRingback();
            _startCallerTimeout();
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            _stopRingback();
            _timeoutTimer?.cancel();
            if (mounted) {
              setState(() {
                _remoteJoined = true;
                _remoteUid = remoteUid;
              });
            }
          },
          onUserOffline: (connection, remoteUid, reason) {
            // L'autre partie a quitté — l'appel est terminé de son côté.
            if (mounted) _endCall();
          },
          onError: (err, msg) {
            if (mounted) setState(() => _error = msg);
          },
        ),
      );

      await engine.joinChannel(
        token: token.token,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      if (mounted) setState(() => _engine = engine);
    } catch (e) {
      debugPrint('CallScreen._setup error: $e');
      // Le message générique précédent ("Impossible de démarrer l'appel.")
      // masquait la cause réelle (token indisponible, App ID Agora
      // invalide, etc.) — affichée ici pour un diagnostic direct sans
      // avoir besoin des logs Supabase à chaque échec.
      if (mounted) {
        setState(() => _error = 'Impossible de démarrer l\'appel : $e');
      }
    }
  }

  Future<void> _startRingback() async {
    try {
      await _ringbackPlayer.setReleaseMode(ReleaseMode.loop);
      await _ringbackPlayer.play(AssetSource('notif_radar.wav'));
    } catch (_) {
      // Pas de sonnerie si l'asset est indisponible — pas bloquant.
    }
  }

  Future<void> _stopRingback() async {
    try {
      await _ringbackPlayer.stop();
    } catch (_) {}
  }

  Future<void> _endCall(
      {String? reasonMessage, bool skipStatusUpdate = false}) async {
    if (_ending) return;
    _ending = true;
    _timeoutTimer?.cancel();
    _statusSub?.cancel();
    await _stopRingback();
    if (reasonMessage != null && mounted) {
      // Laisse le motif s'afficher un court instant avant de fermer
      // l'écran — sinon l'appelant ne verrait jamais "Appel refusé"/
      // "Personne n'a répondu", juste un retour immédiat en arrière.
      setState(() => _error = reasonMessage);
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    if (!skipStatusUpdate && widget.invitationId != null) {
      try {
        await CallRepo.updateStatus(widget.invitationId!, 'ended');
      } catch (_) {}
    }
    await _engine?.leaveChannel();
    await _engine?.release();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _statusSub?.cancel();
    _ringbackPlayer.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              if (_isVideo && _remoteJoined && _engine != null)
                Positioned.fill(
                  child: AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection:
                          RtcConnection(channelId: widget.channelName),
                    ),
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          widget.peerName.isNotEmpty
                              ? widget.peerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 36, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        widget.peerName,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: Colors.white),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _error != null
                            ? _error!
                            : !_joined
                                ? 'Connexion en cours...'
                                : _remoteJoined
                                    ? 'En communication'
                                    : 'Appel en cours...',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              if (_isVideo && !_cameraOff && _engine != null)
                Positioned(
                  right: 4.w,
                  top: 4.w,
                  width: 28.w,
                  height: 40.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 4.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallControlButton(
                      icon: _muted ? Icons.mic_off : Icons.mic,
                      onTap: () {
                        setState(() => _muted = !_muted);
                        _engine?.muteLocalAudioStream(_muted);
                      },
                    ),
                    if (_isVideo)
                      _CallControlButton(
                        icon: _cameraOff
                            ? Icons.videocam_off
                            : Icons.videocam,
                        onTap: () {
                          setState(() => _cameraOff = !_cameraOff);
                          _engine?.muteLocalVideoStream(_cameraOff);
                        },
                      ),
                    if (!_isVideo)
                      _CallControlButton(
                        icon: _speakerOn
                            ? Icons.volume_up
                            : Icons.hearing,
                        onTap: () {
                          setState(() => _speakerOn = !_speakerOn);
                          _engine?.setEnableSpeakerphone(_speakerOn);
                        },
                      ),
                    if (_isVideo)
                      _CallControlButton(
                        icon: Icons.cameraswitch,
                        onTap: () => _engine?.switchCamera(),
                      ),
                    _CallControlButton(
                      icon: Icons.call_end,
                      color: Colors.red,
                      onTap: _endCall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CallControlButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white24,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
