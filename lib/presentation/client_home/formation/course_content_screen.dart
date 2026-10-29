import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:sizer/sizer.dart';

import '../../../core/device/device_id.dart';
import '../../../core/formation/course_purchases_repo.dart';
import '../../../core/formation/module_visual_style.dart';
import '../../../core/supabase/private_storage_image.dart';
import '../../../core/supabase/supabase_config.dart';
import 'module_detail_screen.dart';

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
/// la vidéo reste dans l'app") : `_ModuleDetailScreenState._downloadVideo()`
/// (voir `module_detail_screen.dart`) enregistre la vidéo dans le dossier
/// privé de l'application (`getApplicationDocumentsDirectory()`), jamais
/// dans la Galerie ni un dossier Téléchargements partagé — invisible et
/// inaccessible aux autres apps, donc consultable hors-ligne sans jamais
/// pouvoir être partagée comme un fichier normal.
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
///   les photos pendant la lecture (voir `_WatermarkOverlay` dans
///   `module_detail_screen.dart`) — rend toute fuite traçable jusqu'au
///   responsable, y compris en cas de re-filmage de l'écran (la "faille
///   analogique" reste indétectable, mais le filigrane apparaît alors
///   aussi dans ce qui est refilmé).
///
/// Organisation en vignettes (29/10, demande explicite, inspirée d'une
/// maquette façon JW/"formation af") : chaque module est une vignette
/// dans une rangée horizontale qui défile (`_ModuleThumbnail`), plutôt
/// qu'une longue liste verticale — toucher une vignette ouvre
/// `ModuleDetailScreen` où vit le contenu réel du module.
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
  // Bouton FR/MG (29/10, demande explicite) : une formation peut avoir du
  // contenu bilingue par module (title_mg/content_text_mg, voir
  // supabase/phase286_patch_formation_liquide_vaisselle_bilingue.sql) — le
  // client choisit la langue affichée ici, la vignette et l'écran détail
  // retombent sur le texte français si la traduction malgache d'un
  // module est absente.
  bool _showMalagasy = false;

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

  bool get _hasMalagasyContent => _modules.any((m) =>
      (m['title_mg'] as String?)?.isNotEmpty == true ||
      (m['content_text_mg'] as String?)?.isNotEmpty == true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseTitle),
        actions: [
          if (_hasMalagasyContent)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('FR')),
                    ButtonSegment(value: true, label: Text('MG')),
                  ],
                  selected: {_showMalagasy},
                  onSelectionChanged: (s) =>
                      setState(() => _showMalagasy = s.first),
                ),
              ),
            ),
        ],
      ),
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
                      : SizedBox(
                          height: 30.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.all(4.w),
                            itemCount: _modules.length,
                            separatorBuilder: (_, __) => SizedBox(width: 3.w),
                            itemBuilder: (context, index) => _ModuleThumbnail(
                              module: _modules[index],
                              index: index,
                              showMalagasy: _showMalagasy,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ModuleDetailScreen(
                                    module: _modules[index],
                                    watermarkText: _watermarkText,
                                    showMalagasy: _showMalagasy,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
    );
  }
}

/// Vignette d'un module dans la rangée horizontale qui défile — voir
/// le commentaire de classe de `CourseContentScreen` (29/10, demande
/// explicite inspirée d'une maquette façon JW/"formation af").
/// Affiche la première photo du module si disponible, sinon un fond
/// coloré + icône cycliques (voir `core/formation/module_visual_style.dart`).
class _ModuleThumbnail extends StatelessWidget {
  final Map<String, dynamic> module;
  final int index;
  final bool showMalagasy;
  final VoidCallback onTap;

  const _ModuleThumbnail({
    required this.module,
    required this.index,
    required this.showMalagasy,
    required this.onTap,
  });

  String get _title {
    final mg = module['title_mg'] as String?;
    if (showMalagasy && mg != null && mg.isNotEmpty) return mg;
    return (module['title'] as String?) ?? '';
  }

  String? get _dureeLabel {
    final minutes = module['duree_minutes'] as int?;
    if (minutes == null || minutes <= 0) return null;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  String? get _firstPhotoUrl {
    final urls = module['photo_urls'] as List?;
    if (urls == null || urls.isEmpty) return null;
    return urls.first.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = moduleColor(index);
    final photo = _firstPhotoUrl;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 42.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photo != null)
                      PrivateStorageImage(
                        bucket: 'formation-videos',
                        path: photo,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, color.withValues(alpha: 0.7)],
                          ),
                        ),
                        child: Center(
                          child: Icon(moduleIcon(index),
                              size: 36, color: Colors.white),
                        ),
                      ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Module ${index + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (module['video_url'] != null)
                      const Center(
                        child: Icon(Icons.play_circle_fill,
                            size: 40, color: Colors.white70),
                      ),
                    if (_dureeLabel != null)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_dureeLabel!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
