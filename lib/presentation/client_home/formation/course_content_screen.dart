import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/formation/course_purchases_repo.dart';

/// Contenu réel d'un cours AkoraFormation acheté (vidéo/document/texte par
/// module, voir supabase/phase50_patch_course_purchases_and_content.sql).
///
/// Protection appliquée pendant que cet écran est affiché : `FLAG_SECURE`
/// (Android, via screen_protector) bloque la capture d'écran et
/// l'enregistrement d'écran natifs, et masque l'aperçu de l'écran dans le
/// multitâche. Limite assumée et non contournable par personne : rien
/// n'empêche de filmer l'écran avec un second appareil physique (la
/// "faille analogique") — aucune plateforme au monde ne peut s'en
/// protéger techniquement.
///
/// Téléchargement hors-ligne (28/10, demande explicite "télécharger mais
/// la vidéo reste dans l'app") : `_ModuleCardState._downloadVideo()`
/// enregistre la vidéo dans le dossier privé de l'application
/// (`getApplicationDocumentsDirectory()`), jamais dans la Galerie ni un
/// dossier Téléchargements partagé — invisible et inaccessible aux autres
/// apps, donc consultable hors-ligne sans jamais pouvoir être partagée
/// comme un fichier normal.
class CourseContentScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const CourseContentScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen> {
  List<Map<String, dynamic>> _modules = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _enableProtection();
    _load();
  }

  Future<void> _enableProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (_) {
      // Best-effort : certaines plateformes/versions peuvent ne pas
      // supporter l'appel — le contenu reste affichable, juste sans
      // cette protection supplémentaire plutôt que de planter l'écran.
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final modules =
          await CoursePurchasesRepo.fetchCourseModules(widget.courseId);
      setState(() {
        _modules = modules;
        _isLoading = false;
        if (modules.isEmpty) {
          _error =
              'Le contenu de ce cours n\'est pas encore disponible — revenez bientôt.';
        }
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger le contenu pour le moment.';
      });
    }
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _modules.length,
                  separatorBuilder: (_, __) => SizedBox(height: 2.h),
                  itemBuilder: (context, index) =>
                      _ModuleCard(module: _modules[index]),
                ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final Map<String, dynamic> module;

  const _ModuleCard({required this.module});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;
  File? _localVideoFile;
  bool _isDownloading = false;
  double _downloadProgress = 0;

  String? get _videoUrl => widget.module['video_url'] as String?;
  String? get _documentUrl => widget.module['document_url'] as String?;
  String? get _contentText => widget.module['content_text'] as String?;
  String get _moduleId => widget.module['id'].toString();
  List<String> get _photoUrls => List<String>.from(
      ((widget.module['photo_urls'] as List?) ?? []).map((e) => e.toString()));

  @override
  void initState() {
    super.initState();
    _checkLocalFile();
  }

  /// Téléchargement hors-ligne (28/10, demande explicite) : la vidéo est
  /// enregistrée dans le dossier privé de l'app (jamais dans la Galerie
  /// ni un dossier Téléchargements partagé — invisible et inaccessible
  /// aux autres apps), donc "téléchargeable" sans jamais quitter l'app ni
  /// pouvoir être partagée comme un fichier normal.
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
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });
    final file = await _localVideoPath();
    try {
      await Dio().download(
        _videoUrl!,
        file.path,
        onReceiveProgress: (received, total) {
          if (total > 0 && mounted) {
            setState(() => _downloadProgress = received / total);
          }
        },
      );
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
    setState(() => _isVideoInitializing = true);
    final controller = _localVideoFile != null
        ? VideoPlayerController.file(_localVideoFile!)
        : VideoPlayerController.networkUrl(Uri.parse(_videoUrl!));
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.module['title'] ?? '',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (_contentText != null && _contentText!.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(_contentText!),
            ],
            if (_videoUrl != null) ...[
              SizedBox(height: 1.5.h),
              if (_videoController != null &&
                  _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isVideoInitializing ? null : _initVideo,
                      icon: _isVideoInitializing
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_circle_outline),
                      label: const Text('Lire la vidéo'),
                    ),
                    if (_localVideoFile != null)
                      Chip(
                        avatar: const Icon(Icons.offline_pin_outlined,
                            size: 16),
                        label: const Text('Disponible hors-ligne'),
                        visualDensity: VisualDensity.compact,
                        deleteIcon: const Icon(Icons.delete_outline, size: 16),
                        onDeleted: _removeDownload,
                      )
                    else if (_isDownloading)
                      SizedBox(
                        width: 36.w,
                        child: LinearProgressIndicator(
                          value:
                              _downloadProgress > 0 ? _downloadProgress : null,
                          minHeight: 6,
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _downloadVideo,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Télécharger (hors-ligne)'),
                      ),
                  ],
                ),
            ],
            if (_documentUrl != null) ...[
              SizedBox(height: 1.5.h),
              OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(_documentUrl!),
                    mode: LaunchMode.inAppWebView),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Ouvrir le document'),
              ),
            ],
            if (_photoUrls.isNotEmpty) ...[
              SizedBox(height: 1.5.h),
              SizedBox(
                height: 22.w,
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
                          child: InteractiveViewer(
                            child: Image.network(url, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          url,
                          width: 22.w,
                          height: 22.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 22.w,
                            height: 22.w,
                            color: Colors.black12,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
