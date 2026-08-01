import 'package:flutter/material.dart';
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

  String? get _videoUrl => widget.module['video_url'] as String?;
  String? get _documentUrl => widget.module['document_url'] as String?;
  String? get _contentText => widget.module['content_text'] as String?;

  Future<void> _initVideo() async {
    if (_videoUrl == null || _videoController != null) return;
    setState(() => _isVideoInitializing = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(_videoUrl!));
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
          ],
        ),
      ),
    );
  }
}
