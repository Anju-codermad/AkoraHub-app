import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/calls/agora_token_repo.dart';
import '../../core/calls/call_repo.dart';

/// Écran d'appel en cours (audio ou vidéo) — rejoint le canal Agora
/// correspondant à `channelName`. `invitationId` est optionnel : présent
/// côté appelé (pour marquer l'invitation "ended" en quittant), absent
/// côté appelant si l'appel est lancé avant que l'invitation existe
/// encore (ce n'est pas le cas ici, l'appelant crée toujours l'invitation
/// avant de pousser cet écran, mais le paramètre reste nullable par
/// simplicité d'appel).
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
  bool get _isVideo => widget.callType == 'video';

  bool _joined = false;
  bool _remoteJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _speakerOn = true;
  bool _cameraOff = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setup();
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
          },
          onUserJoined: (connection, remoteUid, elapsed) {
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

  Future<void> _endCall() async {
    if (widget.invitationId != null) {
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
