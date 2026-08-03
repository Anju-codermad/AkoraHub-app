import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/chat/unread_support_messages.dart';
import '../../core/loyalty/loyalty_tiers.dart';
import '../../core/providers/profile_accent_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'chat_screen.dart';
import 'community/public_profile_screen.dart';
import 'community/realisations_gallery_screen.dart';
import 'delivery_addresses/delivery_addresses_screen.dart';
import 'favorites_provider.dart';
import 'favorites_screen.dart';
import 'formation/my_formation_groups_screen.dart';
import 'loyalty/loyalty_screen.dart';
import 'my_contact_qr_screen.dart';
import 'my_reviews_screen.dart';
import 'orders_tab.dart';
import 'recurring_orders/recurring_orders_screen.dart';
import 'referral_screen.dart';
import 'settings/settings_screen.dart';
import 'wall/wall_tab.dart';

/// Profil client — mise en page centrée façon Facebook mobile (photo de
/// couverture, avatar chevauchant, identité centrée, onglets centrés),
/// mais dont le contenu est entièrement adapté à ce qui existe vraiment
/// dans `profiles` : pas de système d'amis, pas de stories "à la une",
/// pas de centres d'intérêt/loisirs (aucune table pour ça) — ces
/// sections Facebook ont été remplacées par des équivalents réels
/// (nombre de publications, catégories favorites déduites des favoris,
/// partage des coordonnées). Voir PROJECT_CONTEXT.md Phase 20.
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
  int _reviewsCount = 0;
  int _reactionsReceived = 0;
  int _commentsReceived = 0;
  List<Map<String, dynamic>> _recentPosts = [];
  List<Map<String, dynamic>> _realisationsPreview = [];
  List<String> _favoriteCategories = [];
  List<Map<String, dynamic>> _favoritePreview = [];
  int _unreadSupportCount = 0;

  /// 0 = Tout, 1 = Publications, 2 = Favoris
  int _selectedTab = 0;

  bool _isUploadingAvatar = false;
  bool _isUploadingCover = false;

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
    _loadUnreadSupportCount();
  }

  /// Badge sur le raccourci Assistance (03/08) — même source que la
  /// bulle de chat flottante, pas de requête dupliquée.
  Future<void> _loadUnreadSupportCount() async {
    final count = await fetchUnreadSupportMessagesCount();
    if (!mounted) return;
    setState(() => _unreadSupportCount = count);
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
      // dessous sert juste aux aperçus/à l'engagement, pas au total —
      // corrige au passage un compteur qui plafonnait silencieusement à
      // 30 avant le Lot 3 du Profil).
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
      final postIds = list.map((p) => p['id'] as String).toList();

      // Engagement reçu (Lot 3 du Profil, 03/08) — calculé sur les 30
      // dernières publications, pas l'historique complet : suffisant
      // pour un résumé d'activité récente.
      Future<int> loadReactionsReceived() async {
        if (postIds.isEmpty) return 0;
        try {
          final r = await SupabaseConfig.client
              .from('post_likes')
              .select('id')
              .inFilter('post_id', postIds)
              .count();
          return r.count;
        } catch (_) {
          return 0;
        }
      }

      Future<int> loadCommentsReceived() async {
        if (postIds.isEmpty) return 0;
        try {
          final r = await SupabaseConfig.client
              .from('post_comments')
              .select('id')
              .inFilter('post_id', postIds)
              .count();
          return r.count;
        } catch (_) {
          return 0;
        }
      }

      final engagement = await Future.wait<int>(
          [loadReactionsReceived(), loadCommentsReceived()]);

      if (mounted) {
        setState(() {
          _postsCount = results[0].count;
          _recentPosts = list.take(3).toList();
          _realisationsPreview = list
              .where((p) =>
                  p['image_url'] != null && p['mentioned_product_id'] != null)
              .take(6)
              .toList();
          _reactionsReceived = engagement[0];
          _commentsReceived = engagement[1];
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

    try {
      final result = await SupabaseConfig.client
          .from('product_reviews')
          .select('id')
          .eq('author_id', userId)
          .count();
      if (mounted) setState(() => _reviewsCount = result.count);
    } catch (_) {}

    try {
      final favoriteIds = ref.read(favoritesProvider);
      if (favoriteIds.isNotEmpty) {
        final products = await SupabaseConfig.client
            .from('products')
            .select()
            .inFilter('id', favoriteIds.toList());
        final list = List<Map<String, dynamic>>.from(products);
        final categories = list
            .map((p) => (p['category'] ?? '').toString())
            .where((c) => c.isNotEmpty)
            .toSet()
            .take(8)
            .toList();
        if (mounted) {
          setState(() {
            _favoriteCategories = categories;
            _favoritePreview = list.take(4).toList();
          });
        }
      }
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

  Future<void> _pickAndUploadCover() async {
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
      await SupabaseConfig.client
          .from('profiles')
          .update({'cover_url': url}).eq('id', userId);
      if (!mounted) return;
      setState(() {
        _profile = {...?_profile, 'cover_url': url};
        _isUploadingCover = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingCover = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Impossible de changer la couverture (migration phase20 exécutée ?).')),
      );
    }
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
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final user = SupabaseConfig.client.auth.currentUser;
    final profile = _profile ?? {};
    final fullName = profile['full_name'] as String?;
    final companyName = profile['company_name'] as String?;
    final location = profile['location'] as String?;
    final avatarUrl = profile['avatar_url'] as String?;
    final coverUrl = profile['cover_url'] as String?;
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
      coverUrl != null && coverUrl.isNotEmpty,
      bio != null && bio.isNotEmpty,
      (profile['phone'] as String?)?.trim().isNotEmpty == true,
      location != null && location.trim().isNotEmpty,
      companyName != null && companyName.trim().isNotEmpty,
      profile['client_type'] != null,
    ];
    final completionRatio =
        completionFields.where((f) => f).length / completionFields.length;

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (_error != null)
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          _buildCoverAndAvatar(theme, coverUrl, avatarUrl),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                SizedBox(height: 1.5.h),
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
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                    _StatItem(
                      value: '$_ordersCount',
                      label: 'Commandes',
                      color: accentColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar:
                                AppBar(title: const Text('Mes commandes')),
                            body: const OrdersTab(),
                          ),
                        ),
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
                SizedBox(height: 2.h),
                _buildShortcutsBar(theme),
                if (completionRatio < 1) ...[
                  SizedBox(height: 2.h),
                  _buildCompletionBar(theme, completionRatio, accentColor),
                ],
                SizedBox(height: 2.5.h),
                _buildTabSelector(theme),
                SizedBox(height: 2.h),
                if (_selectedTab == 0)
                  _buildAllTabContent(theme)
                else if (_selectedTab == 1)
                  _buildPublicationsPreview(theme)
                else
                  _buildFavoritesPreview(theme),
                SizedBox(height: 3.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverAndAvatar(
      ThemeData theme, String? coverUrl, String? avatarUrl) {
    return SizedBox(
      height: 24.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 18.h,
            child: GestureDetector(
              onTap: _isUploadingCover ? null : _pickAndUploadCover,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      image: coverUrl != null
                          ? DecorationImage(
                              image: NetworkImage(coverUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: coverUrl == null
                        ? Icon(Icons.image_outlined,
                            size: 40,
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.4))
                        : null,
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
          Positioned(
            top: 18.h - 9.h,
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
      ),
    );
  }

  /// Barre de raccourcis (03/08, inspirée de la barre d'icônes Facebook
  /// avec badges) — 4 actions "utilitaires" transverses (pas du contenu à
  /// parcourir, contrairement aux cartes plus bas) : Paramètres,
  /// Parrainage, Assistance, Scanner un produit. Volontairement limitée à
  /// 4 icônes pour rester lisible d'un coup d'œil ; Scanner et Assistance
  /// ont donc été retirés des cartes "Mes achats"/"Assistance" plus bas
  /// pour ne pas les dupliquer. Un seul badge (Assistance, messages
  /// support non lus) — les autres icônes sont des actions ponctuelles
  /// sans vraie "file d'attente", pas de badge à leur mettre.
  Widget _buildShortcutsBar(ThemeData theme) {
    final shortcuts = [
      (Icons.settings_outlined, 'Paramètres', 0, () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()))),
      (Icons.card_giftcard_outlined, 'Parrainage', 0, () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReferralScreen()))),
      // Badge = messages support non lus (même compteur que la bulle de
      // chat flottante) — seule icône avec une vraie "file d'attente",
      // rafraîchi au retour du chat (même logique que catalog_tab.dart).
      (Icons.chat_bubble_outline, 'Assistance', _unreadSupportCount,
          () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()))
              .then((_) => _loadUnreadSupportCount())),
      (Icons.qr_code_scanner, 'Scanner', 0,
          () => Navigator.pushNamed(context, '/product-scanner')),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final (icon, label, badgeCount, onTap) in shortcuts)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        child: Icon(icon,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: theme.scaffoldBackgroundColor,
                                  width: 1.5),
                            ),
                            child: Text(
                              badgeCount > 9 ? '9+' : '$badgeCount',
                              style: TextStyle(
                                color: theme.colorScheme.onError,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 0.6.h),
                  Text(label, style: theme.textTheme.labelSmall),
                ],
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

  Widget _buildTabSelector(ThemeData theme) {
    final tabs = ['Tout', 'Publications', 'Favoris'];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        for (var i = 0; i < tabs.length; i++)
          ChoiceChip(
            label: Text(tabs[i]),
            selected: _selectedTab == i,
            onSelected: (_) => setState(() => _selectedTab = i),
          ),
      ],
    );
  }

  /// Lot 1 (03/08) de la refonte du Profil — nettoyage structurel :
  /// "Informations personnelles" (Email/Société/Téléphone/Localisation)
  /// retiré de cette vue, déjà consultable/modifiable via "Modifier le
  /// profil" (société également affichée dans l'en-tête) et Email
  /// affiché dans Paramètres → Compte. Déconnexion retirée d'ici,
  /// désormais uniquement dans Paramètres. Scanner un produit, Assistance
  /// et Paramètres sont sortis d'ici (03/08, barre de raccourcis
  /// `_buildShortcutsBar`) pour ne pas les dupliquer.
  Widget _buildAllTabContent(ThemeData theme) {
    return Column(
      children: [
        if (_realisationsPreview.isNotEmpty) ...[
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
        Align(
          alignment: Alignment.centerLeft,
          child:
              Text('Mes achats', style: theme.textTheme.labelLarge),
        ),
        SizedBox(height: 1.h),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.autorenew),
                title: const Text('Commandes récurrentes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RecurringOrdersScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Fidélité'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoyaltyScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Adresses de livraison'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DeliveryAddressesScreen())),
              ),
            ],
          ),
        ),
        if (_favoriteCategories.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Catégories favorites',
                style: theme.textTheme.labelLarge),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in _favoriteCategories) Chip(label: Text(cat)),
            ],
          ),
        ],
        SizedBox(height: 2.h),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Communauté & Formation',
              style: theme.textTheme.labelLarge),
        ),
        SizedBox(height: 1.h),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Voir mon profil public'),
                subtitle: const Text('Ce que voient les autres clients'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final myId = SupabaseConfig.client.auth.currentUser?.id;
                  if (myId == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(userId: myId)),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.qr_code_2),
                title: const Text('Ma carte de contact'),
                subtitle: const Text('QR à faire scanner'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyContactQrScreen(
                      fullName: _profile?['full_name'] as String?,
                      companyName: _profile?['company_name'] as String?,
                      phone: _profile?['phone'] as String?,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Mes avis laissés'),
                subtitle: Text('$_reviewsCount avis'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyReviewsScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Mes groupes Formation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MyFormationGroupsScreen())),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Mon engagement'),
                subtitle: Text(
                    '$_reactionsReceived réaction${_reactionsReceived > 1 ? 's' : ''} · $_commentsReceived commentaire${_commentsReceived > 1 ? 's' : ''} reçus'),
              ),
            ],
          ),
        ),
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

  Widget _buildFavoritesPreview(ThemeData theme) {
    return Column(
      children: [
        if (_favoritePreview.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Text('Aucun favori pour l\'instant.',
                style: theme.textTheme.bodyMedium),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: _favoritePreview
                .map((p) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: (p['image_url'] as String?)
                                            ?.isNotEmpty ==
                                        true
                                    ? Image.network(p['image_url'],
                                        fit: BoxFit.cover,
                                        width: double.infinity)
                                    : Container(
                                        color: theme.colorScheme
                                            .surfaceContainerHighest,
                                        child: const Icon(
                                            Icons.inventory_2_outlined),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text((p['name'] ?? '').toString(),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        SizedBox(height: 1.h),
        OutlinedButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          child: const Text('Voir tous mes favoris'),
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
  late final TextEditingController _nameController;
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
    _nameController =
        TextEditingController(text: widget.profile['full_name'] ?? '');
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
    _nameController.dispose();
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
        'full_name': _nameController.text.trim(),
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
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
