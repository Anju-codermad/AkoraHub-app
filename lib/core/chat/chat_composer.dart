import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';

/// Barre de saisie de messagerie complète : texte, pièce jointe
/// (photo/vidéo/fichier via le bouton "+"), message vocal (maintenir le
/// bouton micro pour enregistrer, relâcher pour envoyer — style
/// WhatsApp). Partagée entre `chat_screen.dart` (client) et
/// `messaging_center_real.dart` (staff) pour que les deux côtés aient les
/// mêmes capacités.
class ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSendText;
  final Future<void> Function(File file, String type,
      {String? name, int? durationMs}) onSendAttachment;
  final Widget? topBar;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSendText,
    required this.onSendAttachment,
    this.hintText = 'Écrire un message...',
    this.topBar,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _recordingStartedAt;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _recordingTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autorisation micro refusée.')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _recordingStartedAt = DateTime.now();
      _recordingElapsed = Duration.zero;
    });
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        _recordingElapsed = DateTime.now().difference(_recordingStartedAt!);
      });
    });
  }

  Future<void> _stopRecording({required bool send}) async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    final duration = _recordingElapsed;
    if (mounted) setState(() => _isRecording = false);
    if (!send || path == null) return;
    if (duration.inMilliseconds < 800) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message vocal trop court.')),
        );
      }
      return;
    }
    await widget.onSendAttachment(File(path), 'audio',
        durationMs: duration.inMilliseconds);
  }

  Future<void> _pickAttachment() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Photo'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Vidéo'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text('Fichier'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    if (choice == 'image') {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        await widget.onSendAttachment(File(picked.path), 'image');
      }
    } else if (choice == 'video') {
      final picked =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        await widget.onSendAttachment(File(picked.path), 'video',
            name: picked.name);
      }
    } else if (choice == 'file') {
      final result = await FilePicker.platform.pickFiles();
      final path = result?.files.single.path;
      if (path != null) {
        await widget.onSendAttachment(
          File(path),
          'file',
          name: result!.files.single.name,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = widget.controller.text.trim().isNotEmpty;

    if (_isRecording) {
      final seconds = _recordingElapsed.inSeconds;
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return Row(
        children: [
          Icon(Icons.mic, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enregistrement... $m:${s.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => _stopRecording(send: false),
            child: const Text('Annuler'),
          ),
          Material(
            color: theme.colorScheme.primary,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: theme.colorScheme.onPrimary,
              onPressed: () => _stopRecording(send: true),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.topBar != null) widget.topBar!,
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _pickAttachment,
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: hasText
                  ? IconButton(
                      icon: const Icon(Icons.send),
                      color: theme.colorScheme.onPrimary,
                      onPressed: widget.onSendText,
                    )
                  : GestureDetector(
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopRecording(send: true),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.mic,
                            color: theme.colorScheme.onPrimary),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
