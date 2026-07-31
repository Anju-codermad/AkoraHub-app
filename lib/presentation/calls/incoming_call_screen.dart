import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/calls/call_repo.dart';
import '../../core/supabase/supabase_config.dart';
import 'call_screen.dart';

/// Écran "appel entrant" — sonne (boucle) jusqu'à ce que l'appel soit
/// accepté/refusé ou expire (45s sans réponse -> "missed"). Affiché soit
/// depuis le flux temps réel (app ouverte, voir CallRepo.watchIncomingCalls
/// dans push_notification_service.dart) soit au tap sur la notification
/// push (app fermée/arrière-plan).
class IncomingCallScreen extends StatefulWidget {
  final String invitationId;
  final String channelName;
  final String callType;
  final String callerId;
  final String? callerName;

  const IncomingCallScreen({
    super.key,
    required this.invitationId,
    required this.channelName,
    required this.callType,
    required this.callerId,
    this.callerName,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final _player = AudioPlayer();
  Timer? _timeoutTimer;
  String? _callerName;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _callerName = widget.callerName;
    _startRinging();
    if (_callerName == null) _loadCallerName();
    // Appel non répondu au bout de 45s -> marqué manqué, cet écran se
    // ferme tout seul (l'appelant verra le canal jamais rejoint).
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!_resolved) _decline(status: 'missed');
    });
  }

  Future<void> _loadCallerName() async {
    try {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select('full_name, company_name')
          .eq('id', widget.callerId)
          .maybeSingle();
      if (!mounted || row == null) return;
      setState(() {
        _callerName =
            (row['company_name'] as String?) ?? (row['full_name'] as String?);
      });
    } catch (_) {
      // Pas grave : "Quelqu'un" reste affiché en repli.
    }
  }

  Future<void> _startRinging() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('notif_radar.wav'));
    } catch (_) {
      // Pas de sonnerie si l'asset est indisponible — pas bloquant.
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    _resolved = true;
    _timeoutTimer?.cancel();
    await _player.stop();
    try {
      await CallRepo.updateStatus(widget.invitationId, 'accepted');
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelName: widget.channelName,
          callType: widget.callType,
          peerName: _callerName ?? 'Appel',
          invitationId: widget.invitationId,
        ),
      ),
    );
  }

  Future<void> _decline({String status = 'declined'}) async {
    _resolved = true;
    _timeoutTimer?.cancel();
    await _player.stop();
    try {
      await CallRepo.updateStatus(widget.invitationId, status);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVideo = widget.callType == 'video';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 8.h),
              Text(
                isVideo ? 'Appel vidéo entrant' : 'Appel entrant',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: Colors.white70),
              ),
              SizedBox(height: 3.h),
              CircleAvatar(
                radius: 56,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  (_callerName?.isNotEmpty ?? false)
                      ? _callerName![0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 42, color: Colors.white),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                _callerName ?? 'Quelqu\'un',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: Colors.white),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Material(
                          color: Colors.red,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _decline(),
                            child: const Padding(
                              padding: EdgeInsets.all(18),
                              child: Icon(Icons.call_end,
                                  color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        const Text('Refuser',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    Column(
                      children: [
                        Material(
                          color: Colors.green,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _accept,
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Icon(
                                  isVideo ? Icons.videocam : Icons.call,
                                  color: Colors.white,
                                  size: 30),
                            ),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        const Text('Accepter',
                            style: TextStyle(color: Colors.white70)),
                      ],
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
