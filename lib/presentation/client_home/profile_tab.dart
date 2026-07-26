import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../core/localization/app_translations.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'chat_screen.dart';
import 'favorites_provider.dart';
import 'favorites_screen.dart';
import 'loyalty/loyalty_screen.dart';
import 'recurring_orders/recurring_orders_screen.dart';
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
  final VoidCallback onLogout;

  const ProfileTab({super.key, required this.onLogout});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  int _postsCount = 0;
  List<Map<String, dynamic>> _recentPosts = [];
  List<String> _favoriteCategories = [];
  List<Map<String, dynamic>> _favoritePreview = [];

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

  @override
  void initState() {
    super.initState();
    _loadAll();
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
      final posts = await SupabaseConfig.client
          .from('posts')
          .select()
          .eq('author_id', userId)
          .order('created_at', ascending: false)
          .limit(30);
      final list = List<Map<String, dynamic>>.from(posts);
      if (mounted) {
        setState(() {
          _postsCount = list.length;
          _recentPosts = list.take(3).toList();
        });
      }
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
    final phone = profile['phone'] as String?;
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
                SizedBox(height: 0.5.h),
                Text(
                  joinYear != null
                      ? '$_postsCount publication${_postsCount > 1 ? 's' : ''} · Client depuis $joinYear'
                      : '$_postsCount publication${_postsCount > 1 ? 's' : ''}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
                if (sector != null) ...[
                  SizedBox(height: 0.5.h),
                  Chip(label: Text(sector)),
                ],
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
                  ],
                ),
                SizedBox(height: 2.5.h),
                _buildTabSelector(theme),
                SizedBox(height: 2.h),
                if (_selectedTab == 0)
                  _buildAllTabContent(
                      theme, user, companyName, phone, location, sector)
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

  Widget _buildAllTabContent(
    ThemeData theme,
    User? user,
    String? companyName,
    String? phone,
    String? location,
    String? sector,
  ) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Informations personnelles',
              style: theme.textTheme.labelLarge),
        ),
        SizedBox(height: 1.h),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user?.email ?? '—'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.business_outlined),
                title: const Text('Société'),
                subtitle: Text(
                  (companyName == null || companyName.trim().isEmpty)
                      ? '—'
                      : companyName,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Téléphone'),
                subtitle: Text(
                  (phone == null || phone.trim().isEmpty) ? '—' : phone,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Localisation'),
                subtitle: Text(
                  (location == null || location.trim().isEmpty)
                      ? '—'
                      : location,
                ),
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
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Messagerie'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatScreen())),
              ),
              const Divider(height: 1),
              Consumer(
                builder: (context, ref, _) {
                  final locale = ref.watch(localeProvider);
                  return ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('Langue / Fiteny'),
                    trailing: Text(
                      locale == 'fr' ? 'Français' : 'Malagasy',
                      style: theme.textTheme.bodyMedium,
                    ),
                    onTap: () async {
                      final selected = await showDialog<String>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: const Text('Choisir la langue'),
                          children: [
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, 'fr'),
                              child: const Row(
                                  children: [Text('🇫🇷 '), Text('Français')]),
                            ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, 'mg'),
                              child: const Row(
                                  children: [Text('🇲🇬 '), Text('Malagasy')]),
                            ),
                          ],
                        ),
                      );
                      if (selected != null) {
                        ref.read(localeProvider.notifier).setLocale(selected);
                      }
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scanner un produit'),
                subtitle: const Text('Vérifier la traçabilité d\'un lot'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/product-scanner'),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Consumer(
          builder: (context, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            return Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Mode sombre'),
                value: themeMode == ThemeMode.dark,
                onChanged: (value) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            );
          },
        ),
        SizedBox(height: 1.h),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title:
              const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          onTap: widget.onLogout,
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
