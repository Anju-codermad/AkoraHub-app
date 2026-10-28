import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../core/device/device_id.dart';
import '../../../core/formation/course_purchases_repo.dart';
import '../../../core/supabase/private_storage_image.dart';
import '../../../core/supabase/supabase_config.dart';

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
///
/// Trois protections supplémentaires (28/10, demandes explicites) :
/// - **Vérification par selfie** avant le tout premier accès au contenu
///   d'une formation (une seule fois, couvre ensuite toutes les
///   formations du client — voir `profiles.selfie_verified_at`,
///   supabase/phase278_patch_formation_selfie_verification.sql).
///   Ponctuelle et visible, PAS une caméra qui tourne en continu : voir
///   la discussion du même jour sur les limites légales/techniques
///   d'une surveillance continue par caméra.
/// - **Un seul appareil actif** à la fois pour consulter les formations
///   (`profiles.formation_device_id`, supabase/phase279_patch_formation_single_device.sql)
///   — ouvrir ses formations sur un nouvel appareil "éjecte"
///   automatiquement l'ancien, dissuade le partage de compte.
/// - **Filigrane** (nom + téléphone du client) superposé sur la vidéo et
///   les photos pendant la lecture (`_WatermarkOverlay`) — rend toute
///   fuite traçable jusqu'au responsable, y compris en cas de
///   re-filmage de l'écran (la "faille analogique" reste indétectable,
///   mais le filigrane apparaît alors aussi dans ce qui est refilmé).
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
  bool _needsSelfieVerification = false;
  bool _isUploadingSelfie = false;
  bool _needsDeviceConfirmation = false;
  bool _isClaimingDevice = false;
  String? _watermarkText;

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
      _needsSelfieVerification = false;
      _needsDeviceConfirmation = false;
    });
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      Map<String, dynamic>? profile;
      if (userId != null) {
        profile = await SupabaseConfig.client
            .from('profiles')
            .select('full_name, phone, selfie_verified_at, formation_device_id')
            .eq('id', userId)
            .maybeSingle();
      }
      final watermarkParts = [profile?['full_name'], profile?['phone']]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty);
      final watermark = watermarkParts.join(' · ');

      if (profile != null && profile['selfie_verified_at'] == null) {
        setState(() {
          _isLoading = false;
          _needsSelfieVerification = true;
          _watermarkText = watermark.isEmpty ? null : watermark;
        });
        return;
      }

      if (profile != null) {
        final remoteDeviceId = profile['formation_device_id'] as String?;
        final localDeviceId = await DeviceId.get();
        if (remoteDeviceId == null) {
          // Premier accès aux formations sur cet appareil : on le
          // réclame directement, rien à confirmer.
          await SupabaseConfig.client
              .from('profiles')
              .update({'formation_device_id': localDeviceId}).eq('id', userId!);
        } else if (remoteDeviceId != localDeviceId) {
          setState(() {
            _isLoading = false;
            _needsDeviceConfirmation = true;
            _watermarkText = watermark.isEmpty ? null : watermark;
          });
          return;
        }
      }

      final modules =
          await CoursePurchasesRepo.fetchCourseModules(widget.courseId);
      setState(() {
        _modules = modules;
        _isLoading = false;
        _watermarkText = watermark.isEmpty ? null : watermark;
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

  /// "Éjecte" l'autre appareil en reprenant la main ici — voir le
  /// commentaire de classe. Friction volontaire : chaque transfert
  /// déconnecte l'appareil précédent, ce qui dissuade un partage de
  /// compte actif sans bloquer un vrai changement de téléphone.
  Future<void> _claimThisDevice() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _isClaimingDevice = true);
    try {
      final localDeviceId = await DeviceId.get();
      await SupabaseConfig.client
          .from('profiles')
          .update({'formation_device_id': localDeviceId}).eq('id', userId);
      if (!mounted) return;
      setState(() => _isClaimingDevice = false);
      _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isClaimingDevice = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Échec — réessayez.')));
    }
  }

  /// Vérification ponctuelle (pas de caméra en continu) — voir le
  /// commentaire de classe. Couvre tout le compte client une fois faite
  /// (`profiles.selfie_verified_at`), pas seulement ce cours.
  Future<void> _captureAndUploadSelfie() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _isUploadingSelfie = true);
    try {
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await SupabaseConfig.client.storage
          .from('identity-verification')
          .upload(path, File(picked.path));
      await SupabaseConfig.client.from('profiles').update({
        'selfie_url': path,
        'selfie_verified_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      if (!mounted) return;
      setState(() => _isUploadingSelfie = false);
      _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isUploadingSelfie = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Échec de l\'envoi — réessayez.')));
    }
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  Widget _buildSelfieGate() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined,
                size: 48, color: theme.colorScheme.primary),
            SizedBox(height: 2.h),
            Text('Vérification d\'identité',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            SizedBox(height: 1.h),
            Text(
              'Pour protéger nos formations payantes, nous devons confirmer '
              'que c\'est bien vous qui accédez au contenu. Prenez un selfie '
              '— une seule fois, pour tous vos cours. Votre photo reste '
              'privée et sert uniquement à cette vérification.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 3.h),
            _isUploadingSelfie
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: _captureAndUploadSelfie,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Prendre un selfie'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceGate() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phonelink_lock_outlined,
                size: 48, color: theme.colorScheme.primary),
            SizedBox(height: 2.h),
            Text('Un seul appareil à la fois',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            SizedBox(height: 1.h),
            Text(
              'Vos formations sont actuellement liées à un autre appareil. '
              'Pour des raisons de sécurité, un seul appareil peut y accéder '
              'à la fois. Si c\'est un changement de téléphone légitime, '
              'continuez ici — l\'autre appareil sera déconnecté.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 3.h),
            _isClaimingDevice
                ? const CircularProgressIndicator()
                : FilledButton.icon(
                    onPressed: _claimThisDevice,
                    icon: const Icon(Icons.phone_android_outlined),
                    label: const Text('Continuer sur cet appareil'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _needsSelfieVerification
              ? _buildSelfieGate()
              : _needsDeviceConfirmation
                  ? _buildDeviceGate()
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(6.w),
                            child:
                                Text(_error!, textAlign: TextAlign.center),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _modules.length,
                          separatorBuilder: (_, __) => SizedBox(height: 2.h),
                          itemBuilder: (context, index) => _ModuleCard(
                            module: _modules[index],
                            watermarkText: _watermarkText,
                          ),
                    ),
    );
  }
}

/// Filigrane discret (nom + téléphone du client) superposé sur la vidéo
/// et les photos pendant la lecture — voir le commentaire de classe de
/// `CourseContentScreen`.
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

class _ModuleCard extends StatefulWidget {
  final Map<String, dynamic> module;
  final String? watermarkText;

  const _ModuleCard({required this.module, this.watermarkText});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  VideoPlayerController? _videoController;
  bool _isVideoInitializing = false;
  File? _localVideoFile;
  bool _isDownloading = false;

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

  /// Bucket privé (phase275, protection maximale demandée explicitement)
  /// : `_videoUrl` est un CHEMIN, pas une URL — le téléchargement passe
  /// par le SDK Supabase authentifié, jamais par un lien direct. Aucun
  /// "lien" n'existe donc à intercepter ou à partager, à aucun moment,
  /// ni pendant la lecture ni après.
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

  /// La lecture nécessite toujours une copie locale (pas de streaming
  /// direct depuis un bucket privé) — télécharge d'abord si ce n'est pas
  /// déjà fait, comme "Télécharger (hors-ligne)", puis lit.
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
                      label: Text(_isDownloading
                          ? 'Téléchargement…'
                          : 'Lire la vidéo'),
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
                    else if (!_isDownloading)
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
                          width: 22.w,
                          height: 22.w,
                          fit: BoxFit.cover,
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
