import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'chat_attachment_service.dart';

/// Affiche la pièce jointe d'un message (photo/vidéo/note vocale/fichier)
/// dans la bulle de chat — utilisé à la fois côté client
/// (`chat_screen.dart`) et côté staff (`messaging_center_real.dart`).
class ChatAttachmentBubble extends StatefulWidget {
  final String path;
  final String type;
  final String? name;
  final int? durationMs;
  final Color foregroundColor;

  const ChatAttachmentBubble({
    super.key,
    required this.path,
    required this.type,
    required this.foregroundColor,
    this.name,
    this.durationMs,
  });

  @override
  State<ChatAttachmentBubble> createState() => _ChatAttachmentBubbleState();
}

class _ChatAttachmentBubbleState extends State<ChatAttachmentBubble> {
  late final Future<String> _urlFuture;
  VideoPlayerController? _videoController;
  final _audioPlayer = AudioPlayer();
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _urlFuture = ChatAttachmentService.signedUrl(widget.path);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _openImageViewer(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(child: Center(child: Image.network(url))),
            Positioned(
              top: 32,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAudio(String url) async {
    if (_isAudioPlaying) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _isAudioPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(url));
      if (mounted) setState(() => _isAudioPlaying = true);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isAudioPlaying = false);
      });
    }
  }

  String _formatDuration(int? ms) {
    if (ms == null) return '';
    final seconds = (ms / 1000).round();
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final url = snapshot.data!;

        switch (widget.type) {
          case 'image':
            return GestureDetector(
              onTap: () => _openImageViewer(url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  width: 55.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            );

          case 'video':
            _videoController ??= VideoPlayerController.networkUrl(
              Uri.parse(url),
            )..initialize().then((_) {
                if (mounted) setState(() {});
              });
            final controller = _videoController!;
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 55.w,
                child: controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(controller),
                            GestureDetector(
                              onTap: () => setState(() {
                                controller.value.isPlaying
                                    ? controller.pause()
                                    : controller.play();
                              }),
                              child: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
              ),
            );

          case 'audio':
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isAudioPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: widget.foregroundColor,
                    size: 32,
                  ),
                  onPressed: () => _toggleAudio(url),
                ),
                Text(
                  _formatDuration(widget.durationMs),
                  style: TextStyle(color: widget.foregroundColor),
                ),
              ],
            );

          case 'file':
          default:
            return InkWell(
              onTap: () => launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file_outlined,
                      color: widget.foregroundColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.name ?? 'Fichier',
                      style: TextStyle(
                        color: widget.foregroundColor,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}
