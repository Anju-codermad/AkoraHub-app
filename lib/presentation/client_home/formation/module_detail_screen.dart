import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/richtext/rich_text_viewer.dart';
import '../../../core/supabase/private_storage_image.dart';
import '../../../core/supabase/supabase_config.dart';

/// Écran dédié au contenu d'UN module (vidéo/texte/photos) — ouvert
/// depuis la rangée de vignettes de `CourseContentScreen` (29/10,
/// demande explicite : organisation façon vignettes qui défilent,
/// chaque vignette ouvre ce détail au lieu d'empiler tout le contenu
/// dans une longue liste verticale).
///
/// Toutes les protections déjà construites restent inchangées ici,
/// juste déplacées depuis l'ancien `_ModuleCard` : téléchargement
/// vidéo privé dans l'app (jamais dans la Galerie/Téléchargements),
/// lecture uniquement depuis une copie locale (pas de streaming
/// public), filigrane superposé sur la vidéo/les photos.
class ModuleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> module;
  final String? watermarkText;
  final bool showMalagasy;

  const ModuleDetailScreen({
    super.key,
    required this.module,
    this.watermarkText,
    this.showMalagasy = false,
  });

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;
  File? _localVideoFile;
  bool _isDownloading = false;

  String? get _videoUrl => widget.module['video_url'] as String?;
  String? get _documentUrl => widget.module['document_url'] as String?;

  String get _title {
    final mg = widget.module['title_mg'] as String?;
    if (widget.showMalagasy && mg != null && mg.isNotEmpty) return mg;
    return (widget.module['title'] as String?) ?? '';
  }

  String? get _contentText {
    final mg = widget.module['content_text_mg'] as String?;
    if (widget.showMalagasy && mg != null && mg.isNotEmpty) return mg;
    return widget.module['content_text'] as String?;
  }

  String? get _contentDeltaJson {
    if (widget.showMalagasy) {
      final deltaMg = widget.module['content_delta_mg'];
      if (deltaMg == null) return null;
      return jsonEncode(deltaMg);
    }
    final delta = widget.module['content_delta'];
    if (delta == null) return null;
    return jsonEncode(delta);
  }

  String? get _dureeLabel {
    final minutes = widget.module['duree_minutes'] as int?;
    if (minutes == null || minutes <= 0) return null;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  String get _moduleId => widget.module['id'].toString();

  List<String> get _photoUrls => List<String>.from(
      ((widget.module['photo_urls'] as List?) ?? []).map((e) => e.toString()));

  @override
  void initState() {
    super.initState();
    _checkLocalFile();
  }

  Future<File> _localVideoPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/formation_videos');
    if (!await folder.exists()) await folder.create(recursive: true);
    return File('${folder.path}/$_moduleId.mp4');
  }

  Future<void> _checkLocalFile() async {
    final file = await _localVideoPath();
    if (await file.exists() && await file.length() > 0) {
      if (!mounted) return;
      setState(() => _localVideoFile = file);
    }
  }

  Future<void> _downloadVideo() async {
    if (_videoUrl == null) return;
    setState(() => _isDownloading = true);
    final file = await _localVideoPath();
    try {
      final bytes = await SupabaseConfig.client.storage
          .from('formation-videos')
          .download(_videoUrl!);
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      setState(() {
        _localVideoFile = file;
        _isDownloading = false;
      });
    } catch (_) {
      if (await file.exists()) await file.delete();
      if (!mounted) return;
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Échec du téléchargement — réessayez.')));
    }
  }

  Future<void> _removeDownload() async {
    final file = await _localVideoPath();
    if (await file.exists()) await file.delete();
    if (!mounted) return;
    setState(() => _localVideoFile = null);
  }

  Future<void> _initVideo() async {
    if (_videoUrl == null || _videoController != null) return;
    if (_localVideoFile == null) {
      await _downloadVideo();
      if (_localVideoFile == null) return;
    }
    setState(() => _isVideoInitializing = true);
    final controller = VideoPlayerController.file(_localVideoFile!);
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _videoController = controller;
        _isVideoInitializing = false;
      });
      controller.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isVideoInitializing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de lire cette vidéo pour le moment.')));
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_dureeLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 14, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(_dureeLabel!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            if (_videoUrl != null) ...[
              if (_videoController != null &&
                  _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoPlayer(_videoController!),
                      _WatermarkOverlay(text: widget.watermarkText),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: (_isVideoInitializing || _isDownloading)
                          ? null
                          : _initVideo,
                      icon: (_isVideoInitializing || _isDownloading)
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_circle_outline),
                      label: Text(
                          _isDownloading ? 'Téléchargement…' : 'Lire la vidéo'),
                    ),
                    if (_localVideoFile != null)
                      Chip(
                        avatar:
                            const Icon(Icons.offline_pin_outlined, size: 16),
                        label: const Text('Disponible hors-ligne'),
                        visualDensity: VisualDensity.compact,
                        deleteIcon: const Icon(Icons.delete_outline, size: 16),
                        onDeleted: _removeDownload,
                      )
                    else if (!_isDownloading)
                      OutlinedButton.icon(
                        onPressed: _downloadVideo,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Télécharger (hors-ligne)'),
                      ),
                  ],
                ),
              SizedBox(height: 2.h),
            ],
            if ((_contentDeltaJson != null) ||
                (_contentText != null && _contentText!.isNotEmpty))
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: RichTextViewer(
                  deltaJson: _contentDeltaJson,
                  plainText: _contentText,
                ),
              ),
            if (_documentUrl != null)
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(_documentUrl!),
                      mode: LaunchMode.inAppWebView),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Ouvrir le document'),
                ),
              ),
            if (_photoUrls.isNotEmpty)
              SizedBox(
                height: 28.w,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  separatorBuilder: (_, __) => SizedBox(width: 2.w),
                  itemBuilder: (context, i) {
                    final url = _photoUrls[i];
                    return GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: EdgeInsets.all(4.w),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              InteractiveViewer(
                                child: PrivateStorageImage(
                                  bucket: 'formation-videos',
                                  path: url,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              _WatermarkOverlay(text: widget.watermarkText),
                            ],
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: PrivateStorageImage(
                          bucket: 'formation-videos',
                          path: url,
                          width: 28.w,
                          height: 28.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Filigrane discret (nom + téléphone du client) superposé sur la
/// vidéo et les photos pendant la lecture.
class _WatermarkOverlay extends StatelessWidget {
  final String? text;

  const _WatermarkOverlay({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = text;
    if (t == null || t.isEmpty) return const SizedBox.shrink();
    final style = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 11,
      shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
    );
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRect(
          child: Opacity(
            opacity: 0.45,
            child: Transform.rotate(
              angle: -0.35,
              child: Column(
                children: [
                  Expanded(child: Center(child: Text(t, style: style))),
                  Expanded(child: Center(child: Text(t, style: style))),
                  Expanded(child: Center(child: Text(t, style: style))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
