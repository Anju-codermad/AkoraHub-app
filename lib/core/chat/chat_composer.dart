import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sizer/sizer.dart';

/// Taille max d'une pièce jointe (29/09) — au-delà, l'envoi est refusé
/// avec un message clair plutôt que de laisser l'upload planter/traîner
/// indéfiniment sur un très gros fichier.
const int kMaxAttachmentSizeBytes = 25 * 1024 * 1024;

/// Barre de saisie de messagerie complète : texte, pièce jointe
/// (photo/vidéo/fichier via le bouton "+", prise de photo directe,
/// sélection multiple), message vocal (maintenir le bouton micro pour
/// enregistrer, relâcher pour envoyer — style WhatsApp, avec forme
/// d'onde capturée pendant l'enregistrement). Partagée entre
/// `chat_screen.dart` (client) et `messaging_center_real.dart` (staff)
/// pour que les deux côtés aient les mêmes capacités.
class ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSendText;
  final Future<void> Function(File file, String type,
      {String? name, int? durationMs, List<int>? waveform}) onSendAttachment;
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

  /// Forme d'onde (29/09) — un échantillon d'amplitude toutes les 150ms
  /// pendant l'enregistrement, ramené à ~28 barres avant l'envoi. Voir
  /// `audio_waveform_player.dart` côté lecture.
  StreamSubscription<Amplitude>? _amplitudeSub;
  final List<double> _amplitudeSamples = [];

  /// Barre de progression pendant l'envoi (29/09) — indéterminée plutôt
  /// qu'un pourcentage exact : le SDK de stockage Supabase utilisé ici
  /// n'expose pas de callback de progression réseau. Corrige quand même
  /// le vrai problème signalé ("l'app se bloque sans retour visuel") en
  /// désactivant les boutons d'envoi et en affichant un indicateur actif
  /// pendant l'upload.
  int _pendingUploads = 0;
  bool get _isUploading => _pendingUploads > 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _recordingTimer?.cancel();
    _amplitudeSub?.cancel();
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
    _amplitudeSamples.clear();
    _amplitudeSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 150))
        .listen((amp) {
      // dBFS (silence ~-45, max 0) ramené à une échelle 0-100 pour la
      // forme d'onde affichée à la lecture.
      final normalized = ((amp.current + 45) / 45 * 100).clamp(0, 100).toDouble();
      _amplitudeSamples.add(normalized);
    });
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() {
        _recordingElapsed = DateTime.now().difference(_recordingStartedAt!);
      });
    });
  }

  /// Ramène la liste d'échantillons bruts (un toutes les 150ms, donc
  /// potentiellement des centaines pour un long message) à un nombre
  /// fixe de barres pour l'affichage — moyenne de chaque tranche plutôt
  /// que d'envoyer des centaines de valeurs inutiles en base.
  List<int> _downsampleWaveform(List<double> samples, int targetCount) {
    if (samples.isEmpty) return List.filled(targetCount, 10);
    if (samples.length <= targetCount) {
      return samples.map((e) => e.round()).toList();
    }
    final chunk = samples.length / targetCount;
    return List.generate(targetCount, (i) {
      final start = (i * chunk).floor();
      final end =
          ((i + 1) * chunk).floor().clamp(start + 1, samples.length).toInt();
      final slice = samples.sublist(start, end);
      return (slice.reduce((a, b) => a + b) / slice.length).round();
    });
  }

  Future<void> _stopRecording({required bool send}) async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    _amplitudeSub?.cancel();
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
    final waveform = _downsampleWaveform(_amplitudeSamples, 28);
    await _sendFile(File(path), 'audio',
        durationMs: duration.inMilliseconds, waveform: waveform);
  }

  /// Vérifie la taille avant d'envoyer (29/09) — au-delà de
  /// `kMaxAttachmentSizeBytes`, message clair plutôt qu'un envoi qui
  /// traîne ou plante sur un très gros fichier. Compte les envois en
  /// cours (`_pendingUploads`) pour piloter la barre de progression,
  /// utilisable en parallèle pour plusieurs fichiers d'une sélection
  /// multiple.
  Future<void> _sendFile(File file, String type,
      {String? name, int? durationMs, List<int>? waveform}) async {
    final sizeBytes = await file.length();
    if (sizeBytes > kMaxAttachmentSizeBytes) {
      if (!mounted) return;
      final mb = (kMaxAttachmentSizeBytes / (1024 * 1024)).round();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fichier trop volumineux (max $mb Mo).')),
      );
      return;
    }
    if (mounted) setState(() => _pendingUploads++);
    try {
      await widget.onSendAttachment(file, type,
          name: name, durationMs: durationMs, waveform: waveform);
    } finally {
      if (mounted) setState(() => _pendingUploads--);
    }
  }

  Future<void> _pickAttachment() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
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

    if (choice == 'camera') {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked != null) {
        await _sendFile(File(picked.path), 'image');
      }
    } else if (choice == 'image') {
      // Sélection multiple (29/09) : envoyée comme plusieurs messages
      // distincts, un par photo — le schéma `messages` n'a qu'une pièce
      // jointe par ligne.
      final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
      for (final file in picked) {
        await _sendFile(File(file.path), 'image');
      }
    } else if (choice == 'video') {
      final picked =
          await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        await _sendFile(File(picked.path), 'video', name: picked.name);
      }
    } else if (choice == 'file') {
      final result =
          await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null) return;
      for (final f in result.files) {
        if (f.path != null) {
          await _sendFile(File(f.path!), 'file', name: f.name);
        }
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
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _isUploading ? null : _pickAttachment,
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
                      onLongPressStart:
                          _isUploading ? null : (_) => _startRecording(),
                      onLongPressEnd:
                          _isUploading ? null : (_) => _stopRecording(send: true),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.mic,
                            color: theme.colorScheme.onPrimary
                                .withValues(alpha: _isUploading ? 0.4 : 1)),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
