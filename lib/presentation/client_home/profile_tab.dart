import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/loyalty/loyalty_tiers.dart';
import '../../core/providers/profile_accent_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'community/realisations_gallery_screen.dart';
import 'loyalty/loyalty_screen.dart';
import 'orders_tab.dart';
import 'profile_menu_drawer.dart';
import 'wall/wall_tab.dart';

/// Profil client — mise en page centrée façon Facebook mobile (photo de
/// couverture, avatar chevauchant, identité centrée), mais dont le
/// contenu est entièrement adapté à ce qui existe vraiment dans
/// `profiles`. Voir PROJECT_CONTEXT.md Phase 20.
///
/// Depuis le 04/08, toutes les fonctions transverses (Paramètres,
/// Parrainage, Assistance, Scanner, Mes achats, Communauté & Formation,
/// Favoris) sont regroupées dans le menu latéral `ProfileMenuDrawer`
/// (icône ☰ dans la barre du haut) plutôt que sur cette page — celle-ci
/// se concentre sur l'essentiel visuel : couverture/identité,
/// réalisations, publications. Les informations personnelles restent
/// exclusivement modifiables via "Modifier le profil".
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  int _postsCount = 0;
  int _ordersCount = 0;
  List<Map<String, dynamic>> _recentPosts = [];
  List<Map<String, dynamic>> _realisationsPreview = [];

  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;

  // Photos de couverture multiples (05/08, jusqu'à 5, optionnel) — quelle
  // photo est actuellement affichée dans le fondu automatique, voir
  // `_scheduleCoverAutoplay` et `_buildProfileHeader`.
  int _coverPhotoIndex = 0;
  Timer? _coverAutoplayTimer;

  // Chevauchement entre l'avatar et la carte blanche en dessous (style
  // "carte de profil" façon carte de visite, 05/08) — même valeur utilisée
  // dans _buildCoverAndAvatar (position de l'avatar) et dans build()
  // (décalage de la carte) pour que l'avatar reste centré exactement sur
  // la jonction entre le bandeau et la carte. Correspond au rayon de
  // l'avatar (44) + son liseré blanc (3).
  static const double _avatarOverlap = 47;

  final Map<String, String> _sectorLabels = const {
    'hotel': 'Hôtel',
    'hopital': 'Hôpital',
    'entreprise': 'Entreprise',
    'particulier': 'Particulier',
  };

  final Map<String, IconData> _sectorIcons = const {
    'hotel': Icons.hotel_outlined,
    'hopital': Icons.local_hospital_outlined,
    'entreprise': Icons.business_center_outlined,
    'particulier': Icons.person_outline,
  };

  final Map<String, Color> _sectorColors = const {
    'hotel': Color(0xFF3D5A99),
    'hopital': Color(0xFFB3261E),
    'entreprise': Color(0xFF6B4C6B),
    'particulier': Color(0xFF085041),
  };

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _coverAutoplayTimer?.cancel();
    super.dispose();
  }

  /// Fondu automatique entre les photos de couverture (05/08, jusqu'à 5)
  /// — pas de swipe manuel ici (le tap sur la couverture ouvre plutôt la
  /// gestion des photos), donc un simple `Timer.periodic` suffit, sans la
  /// logique de reprogrammation utilisée pour la bannière de l'accueil.
  void _scheduleCoverAutoplay(int photoCount) {
    _coverAutoplayTimer?.cancel();
    if (photoCount <= 1) return;
    _coverAutoplayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _coverPhotoIndex = (_coverPhotoIndex + 1) % photoCount);
    });
  }

  Future<void> _loadAll() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (!SupabaseConfig.isConfigured || userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Non connecté.';
      });
      return;
    }
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      if (!mounted) return;
      setState(() {
        _profile = data;
        _isLoading = false;
      });
      final coverUrls =
          (data['cover_urls'] as List?)?.cast<String>() ?? const <String>[];
      _scheduleCoverAutoplay(coverUrls.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger le profil.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Nombre réel de publications via count() (le fil limité à 30 en
      // dessous sert juste aux aperçus, pas au total — corrige au passage
      // un compteur qui plafonnait silencieusement à 30 avant le Lot 3 du
      // Profil).
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('posts')
            .select('id')
            .eq('author_id', userId)
            .count(),
        SupabaseConfig.client
            .from('posts')
            .select()
            .eq('author_id', userId)
            .order('created_at', ascending: false)
            .limit(30),
      ]);
      final list = List<Map<String, dynamic>>.from(results[1] as List);

      if (mounted) {
        setState(() {
          _postsCount = results[0].count;
          _recentPosts = list.take(3).toList();
          _realisationsPreview = list
              .where((p) =>
                  p['image_url'] != null && p['mentioned_product_id'] != null)
              .take(6)
              .toList();
        });
      }
    } catch (_) {}

    try {
      final result = await SupabaseConfig.client
          .from('orders')
          .select('id')
          .eq('customer_id', userId)
          .count();
      if (mounted) setState(() => _ordersCount = result.count);
    } catch (_) {}
  }

  Future<void> _pickAndUploadAvatar() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await SupabaseConfig.client.storage
          .from('avatars')
          .upload(fileName, File(picked.path));
      final url =
          SupabaseConfig.client.storage.from('avatars').getPublicUrl(fileName);
      await SupabaseConfig.client
          .from('profiles')
          .update({'avatar_url': url}).eq('id', userId);
      if (!mounted) return;
      setState(() {
        _profile = {...?_profile, 'avatar_url': url};
        _isUploadingAvatar = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de changer la photo de profil.')),
      );
    }
  }

  /// Ajoute UNE photo à `profiles.cover_urls` (jusqu'à 5, voir
  /// `_openCoverPhotosManager`) — remplace l'ancien `_pickAndUploadCover`
  /// qui écrivait une seule `cover_url` (05/08). Réservé aux clients
  /// ayant déjà passé une commande : le contrôle se fait en amont, dans
  /// `_openCoverPhotosManager`, pas ici.
  Future<void> _uploadCoverPhoto() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingCover = true);
    try {
      final fileName =
          '$userId/cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await SupabaseConfig.client.storage
          .from('avatars')
          .upload(fileName, File(picked.path));
      final url =
          SupabaseConfig.client.storage.from('avatars').getPublicUrl(fileName);
      final updated = <String>[
        ...?(_profile?['cover_urls'] as List?)?.cast<String>(),
        url,
      ];
      await SupabaseConfig.client
          .from('profiles')
          .update({'cover_urls': updated}).eq('id', userId);
      if (!mounted) return;
      setState(() {
        _profile = {...?_profile, 'cover_urls': updated};
        _isUploadingCover = false;
      });
      _scheduleCoverAutoplay(updated.length);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingCover = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Impossible d\'ajouter cette photo (migration phase74 exécutée ?).')),
      );
    }
  }

  /// Retire une photo de `profiles.cover_urls`.
  Future<void> _removeCoverPhoto(String url) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    final updated = <String>[
      ...?(_profile?['cover_urls'] as List?)?.cast<String>(),
    ]..remove(url);
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'cover_urls': updated}).eq('id', userId);
      if (!mounted) return;
      setState(() {
        _profile = {...?_profile, 'cover_urls': updated};
        _coverPhotoIndex = 0;
      });
      _scheduleCoverAutoplay(updated.length);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de retirer cette photo.')),
      );
    }
  }

  /// Ouvre la gestion des photos de couverture (ajouter/retirer, jusqu'à
  /// 5) — réservée aux clients ayant déjà passé au moins une commande
  /// (`_ordersCount`, déjà chargé pour la stat "Commandes" du profil),
  /// sur demande explicite du 05/08. Les autres utilisateurs voient
  /// toujours la ou les photos existantes normalement ; seule l'AJOUT/
  /// SUPPRESSION est restreinte.
  Future<void> _openCoverPhotosManager() async {
    if (_ordersCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Les photos de couverture multiples sont réservées aux clients ayant déjà passé une commande.'),
        ),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final urls = (_profile?['cover_urls'] as List?)?.cast<String>() ??
              const <String>[];
          return Padding(
            padding: EdgeInsets.only(
              left: 4.w,
              right: 4.w,
              top: 3.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 3.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photos de couverture',
                    style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 0.5.h),
                Text(
                  'Jusqu\'à 5 photos (optionnel), affichées en fondu automatique.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 2.h),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final url in urls)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(url,
                                width: 80, height: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () async {
                                await _removeCoverPhoto(url);
                                setSheetState(() {});
                              },
                              child: const CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (urls.length < 5)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _isUploadingCover
                            ? null
                            : () async {
                                await _uploadCoverPhoto();
                                setSheetState(() {});
                              },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: _isUploadingCover
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : const Icon(Icons.add_a_photo_outlined),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _shareContactCard() {
    final profile = _profile ?? {};
    final name = (profile['full_name'] as String?)?.trim();
    final company = (profile['company_name'] as String?)?.trim();
    final phone = (profile['phone'] as String?)?.trim();
    final buffer = StringBuffer();
    buffer.writeln(name?.isNotEmpty == true ? name : 'Contact AkoraHub');
    if (company?.isNotEmpty == true) buffer.writeln(company);
    if (phone?.isNotEmpty == true) buffer.writeln('Tél : $phone');
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  Future<void> _openEditSheet() async {
    if (_profile == null) return;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EditProfileSheet(profile: _profile!),
    );
    if (updated == true) {
      _loadAll();
    }
  }

  /// Couleur d'accent personnelle (Lot 4, 03/08) — locale à l'appareil,
  /// voir core/providers/profile_accent_provider.dart pour le pourquoi.
  Future<void> _openAccentPicker() async {
    final current = ref.read(profileAccentProvider);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personnaliser mon profil'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final color in kProfileAccentChoices)
              GestureDetector(
                onTap: () {
                  ref.read(profileAccentProvider.notifier).setAccent(color);
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: color,
                  child: current?.value == color.value
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(profileAccentProvider.notifier).setAccent(null);
              Navigator.pop(context);
            },
            child: const Text('Par défaut'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        drawer: const ProfileMenuDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final user = SupabaseConfig.client.auth.currentUser;
    final profile = _profile ?? {};
    final fullName = profile['full_name'] as String?;
    final companyName = profile['company_name'] as String?;
    final location = profile['location'] as String?;
    final avatarUrl = profile['avatar_url'] as String?;
    // Photos de couverture multiples (05/08, jusqu'à 5) — repli sur
    // l'ancienne cover_url (singulier) tant que la migration phase74
    // n'a pas tourné, ou pour un profil créé avant cette fonctionnalité.
    final legacyCoverUrl = profile['cover_url'] as String?;
    final storedCoverUrls =
        (profile['cover_urls'] as List?)?.cast<String>() ?? const <String>[];
    final coverUrls = storedCoverUrls.isNotEmpty
        ? storedCoverUrls
        : (legacyCoverUrl != null && legacyCoverUrl.isNotEmpty
            ? [legacyCoverUrl]
            : const <String>[]);
    final bio = (profile['bio'] as String?)?.trim();
    final sector = _sectorLabels[profile['client_type']];
    final displayName = (fullName == null || fullName.trim().isEmpty)
        ? (user?.email ?? '')
        : fullName;

    String? joinYear;
    final createdAt = profile['created_at'] as String?;
    if (createdAt != null) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) joinYear = parsed.year.toString();
    }

    final loyaltyPoints = (profile['loyalty_points'] as num?)?.toInt() ?? 0;
    final loyaltyTier = currentLoyaltyTier(loyaltyPoints);
    final accentColor = ref.watch(profileAccentProvider);

    // Complétion du profil (Lot 2, 03/08) — 7 champs qui font un profil
    // vraiment utile (à soi comme aux autres) : photo, couverture, bio,
    // téléphone, localisation, société, secteur.
    final completionFields = <bool>[
      avatarUrl != null && avatarUrl.isNotEmpty,
      coverUrls.isNotEmpty,
      bio != null && bio.isNotEmpty,
      (profile['phone'] as String?)?.trim().isNotEmpty == true,
      location != null && location.trim().isNotEmpty,
      companyName != null && companyName.trim().isNotEmpty,
      profile['client_type'] != null,
    ];
    final completionRatio =
        completionFields.where((f) => f).length / completionFields.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      drawer: const ProfileMenuDrawer(),
      body: RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (_error != null)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          _buildProfileHeader(
            theme: theme,
            coverUrls: coverUrls,
            avatarUrl: avatarUrl,
            content: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                children: [
                  SizedBox(height: _avatarOverlap + 1.5.h),
                Text(
                  displayName,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                if (companyName != null && companyName.trim().isNotEmpty)
                  Text(
                    companyName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                if (joinYear != null) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    'Client depuis $joinYear',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (sector != null || loyaltyPoints > 0) ...[
                  SizedBox(height: 0.8.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (sector != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (_sectorColors[profile['client_type']] ??
                                    theme.colorScheme.primary)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _sectorIcons[profile['client_type']] ??
                                    Icons.person_outline,
                                size: 15,
                                color:
                                    _sectorColors[profile['client_type']] ??
                                        theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                sector,
                                style: TextStyle(
                                  color:
                                      _sectorColors[profile['client_type']] ??
                                          theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Badge de palier fidélité (Lot 4, 03/08) — visible
                      // dès le 1er point, pas seulement au palier Argent.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: loyaltyTier.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emoji_events,
                                size: 15, color: loyaltyTier.color),
                            const SizedBox(width: 5),
                            Text(
                              'Palier ${loyaltyTier.name}',
                              style: TextStyle(
                                color: loyaltyTier.color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 1.8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(
                      value: '$_postsCount',
                      label: 'Publications',
                      color: accentColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const WallTab(initialOnlyMine: true)),
                      ),
                    ),
                    _StatItem(
                      value: '$_ordersCount',
                      label: 'Commandes',
                      color: accentColor,
                      // OrdersTab a déjà sa propre AppBar (voir
                      // orders_tab.dart) — pas besoin de la ré-envelopper.
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrdersTab()),
                      ),
                    ),
                    _StatItem(
                      value: '$loyaltyPoints',
                      label: 'Points fidélité',
                      color: accentColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoyaltyScreen()),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                if (bio != null && bio.isNotEmpty)
                  Text(
                    bio,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  )
                else
                  TextButton(
                    onPressed: _openEditSheet,
                    child: const Text('+ Ajouter une bio'),
                  ),
                if (location != null && location.trim().isNotEmpty) ...[
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(location, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ],
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _openEditSheet,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Modifier le profil'),
                    ),
                    SizedBox(width: 3.w),
                    OutlinedButton.icon(
                      onPressed: _shareContactCard,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Partager'),
                    ),
                    SizedBox(width: 1.w),
                    IconButton(
                      tooltip: 'Personnaliser (cet appareil)',
                      icon: const Icon(Icons.palette_outlined),
                      onPressed: _openAccentPicker,
                    ),
                  ],
                ),
                if (completionRatio < 1) ...[
                  SizedBox(height: 2.h),
                  _buildCompletionBar(theme, completionRatio, accentColor),
                ],
                SizedBox(height: 2.5.h),
                if (_realisationsPreview.isNotEmpty)
                  _buildRealisationsPreview(theme),
                Align(
                  alignment: Alignment.centerLeft,
                  child:
                      Text('Mes publications', style: theme.textTheme.labelLarge),
                ),
                SizedBox(height: 1.h),
                _buildPublicationsPreview(theme),
                    SizedBox(height: 3.h),
                  ],
                ),
              ),
          ),
        ],
      ),
      ),
    );
  }

  /// Bandeau + carte blanche + avatar dans UN SEUL Stack (05/08). Avant,
  /// c'était deux éléments séparés de la ListView (cover+avatar, puis la
  /// carte) : comme une ListView peint ses enfants dans l'ordre, la carte
  /// (venant après) était peinte PAR-DESSUS la moitié basse de l'avatar
  /// au lieu de l'inverse — l'avatar semblait "coupé" derrière la carte
  /// ("le photo de profil doit être au premier plan", signalé avec
  /// capture). Ici l'avatar est le DERNIER enfant du Stack, donc peint en
  /// dernier (au-dessus de tout), quel que soit le chevauchement visuel.
  /// La carte reste le seul enfant NON positionné du Stack (poussée vers
  /// le bas via un simple padding plutôt que `Positioned`) : c'est ce qui
  /// donne sa hauteur réelle au Stack dans la ListView (des enfants tous
  /// `Positioned` ne comptent pas dans la taille du Stack).
  Widget _buildProfileHeader({
    required ThemeData theme,
    required List<String> coverUrls,
    required String? avatarUrl,
    required Widget content,
  }) {
    final coverHeight = 15.h;
    final currentCoverUrl = coverUrls.isEmpty
        ? null
        : coverUrls[_coverPhotoIndex % coverUrls.length];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: coverHeight,
          child: GestureDetector(
            onTap: _isUploadingCover ? null : _openCoverPhotosManager,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fondu automatique entre les photos (05/08, jusqu'à 5) —
                // voir `_scheduleCoverAutoplay`. `AnimatedSwitcher` plutôt
                // qu'un PageView : le tap sur la couverture ouvre déjà la
                // gestion des photos, pas de swipe manuel à ménager ici.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    key: ValueKey(currentCoverUrl ?? 'empty'),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      image: currentCoverUrl != null
                          ? DecorationImage(
                              image: NetworkImage(currentCoverUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: currentCoverUrl == null
                        ? Icon(Icons.image_outlined,
                            size: 40,
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.4))
                        : null,
                  ),
                ),
                if (_isUploadingCover)
                  Container(
                    color: Colors.black38,
                    child: const Center(
                        child:
                            CircularProgressIndicator(color: Colors.white)),
                  ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: coverHeight),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: content,
          ),
        ),
        Positioned(
          top: coverHeight - _avatarOverlap,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.scaffoldBackgroundColor,
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundImage:
                          avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, size: 44)
                          : null,
                    ),
                  ),
                  if (_isUploadingAvatar)
                    const Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.camera_alt,
                          size: 13, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Barre "Profil complété à X%" (Lot 2, 03/08) — disparaît une fois le
  /// profil complet plutôt que de rester affichée indéfiniment.
  Widget _buildCompletionBar(ThemeData theme, double ratio, Color? accent) {
    final percent = (ratio * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profil complété à $percent%',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: _openEditSheet,
                  child: const Text('Compléter'),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lot 1 (03/08) de la refonte du Profil — nettoyage structurel :
  /// "Informations personnelles" (Email/Société/Téléphone/Localisation)
  /// retiré de cette vue, déjà consultable/modifiable via "Modifier le
  /// profil" (société également affichée dans l'en-tête) et Email
  /// affiché dans Paramètres → Compte. Déconnexion retirée d'ici,
  /// désormais uniquement dans Paramètres.
  ///
  /// Lot 6 (04/08) : Scanner, Assistance, Paramètres, Parrainage, "Mes
  /// achats" et "Communauté & Formation" sont sortis d'ici vers le menu
  /// latéral (`ProfileMenuDrawer`, icône ☰ dans la barre du haut) — la
  /// page Profil se concentre désormais sur l'essentiel visuel :
  /// couverture/identité, réalisations, publications.
  Widget _buildRealisationsPreview(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mes réalisations', style: theme.textTheme.labelLarge),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RealisationsGalleryScreen(
                      authorId: SupabaseConfig.client.auth.currentUser?.id),
                ),
              ),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: _realisationsPreview
              .map((p) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      p['image_url'],
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: 2.h),
      ],
    );
  }

  Widget _buildPublicationsPreview(ThemeData theme) {
    return Column(
      children: [
        if (_recentPosts.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Text('Aucune publication pour l\'instant.',
                style: theme.textTheme.bodyMedium),
          )
        else
          ..._recentPosts.map((post) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((post['content'] ?? '').toString(),
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      if (post['image_url'] != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(post['image_url'],
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
        SizedBox(height: 1.h),
        OutlinedButton(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const WallTab(initialOnlyMine: true))),
          child: const Text('Voir toutes mes publications'),
        ),
      ],
    );
  }
}

/// Bandeau de stats cliquables façon Instagram (Lot 2 du Profil, 03/08).
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _StatItem(
      {required this.value,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(value,
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> profile;

  const _EditProfileSheet({required this.profile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _companyController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _bioController;
  String? _clientType;
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  bool _isSaving = false;

  final Map<String, String> _sectorLabels = const {
    'hotel': 'Hôtel',
    'hopital': 'Hôpital',
    'entreprise': 'Entreprise',
    'particulier': 'Particulier',
  };

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.profile['first_name'] ?? '');
    _lastNameController =
        TextEditingController(text: widget.profile['last_name'] ?? '');
    _companyController =
        TextEditingController(text: widget.profile['company_name'] ?? '');
    _phoneController =
        TextEditingController(text: widget.profile['phone'] ?? '');
    _locationController =
        TextEditingController(text: widget.profile['location'] ?? '');
    _bioController = TextEditingController(text: widget.profile['bio'] ?? '');
    _latitude = (widget.profile['latitude'] as num?)?.toDouble();
    _longitude = (widget.profile['longitude'] as num?)?.toDouble();
    _clientType = widget.profile['client_type'] as String?;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Autorisation de localisation refusée. Active-la dans les paramètres du téléphone.')),
        );
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Active le GPS/la localisation de ton téléphone puis réessaie.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      String address =
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      try {
        final placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [p.subLocality, p.locality, p.administrativeArea]
              .where((s) => s != null && s.trim().isNotEmpty)
              .toList();
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _locationController.text = address;
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de récupérer ta position.')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _save() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      await SupabaseConfig.client.from('profiles').update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'company_name': _companyController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'client_type': _clientType,
        'bio': _bioController.text.trim(),
      }).eq('id', userId);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        top: 2.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Modifier mon profil',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _bioController,
              maxLines: 2,
              maxLength: 140,
              decoration: const InputDecoration(
                labelText: 'Bio (courte présentation)',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Société',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Localisation',
                border: const OutlineInputBorder(),
                suffixIcon: _isLocating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.my_location),
                        tooltip: 'Utiliser ma position actuelle',
                        onPressed: _useCurrentLocation,
                      ),
              ),
            ),
            SizedBox(height: 1.5.h),
            DropdownButtonFormField<String>(
              initialValue: _clientType,
              decoration: const InputDecoration(
                labelText: 'Secteur',
                border: OutlineInputBorder(),
              ),
              items: _sectorLabels.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _clientType = v),
            ),
            SizedBox(height: 2.5.h),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
