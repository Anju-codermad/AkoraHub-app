import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/localization/app_translations.dart';
import '../../core/navigation/product_detail_route.dart';
import '../../core/notifications/category_subscription_repo.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/reference_data/reference_table_cache.dart';
import '../../core/supabase/supabase_config.dart';
import 'chat_screen.dart';
import 'community/public_profiles_repo.dart';
import 'favorites_provider.dart';
import 'flash_infos_screen.dart';
import 'product_detail_client.dart';
import 'wall/wall_tab.dart';

class CatalogTab extends ConsumerStatefulWidget {
  final VoidCallback onOpenCart;

  const CatalogTab({super.key, required this.onOpenCart});

  @override
  ConsumerState<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends ConsumerState<CatalogTab> {
  List<Map<String, dynamic>> _businessUnits = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedUnitId;
  String _selectedCategory = 'toutes';
  String _searchQuery = '';

  // Abonnement aux notifications pour la catégorie actuellement
  // sélectionnée (uniquement pertinent quand un pilier ET une catégorie
  // précis sont choisis — voir CategorySubscriptionRepo).
  bool _isSubscribedToCategory = false;
  bool _isTogglingSubscription = false;

  // Pagination : la grille produits n'avait pas de limite (catalogue
  // entier chargé d'un coup) — remplacé par un chargement par pages de
  // 20, filtré côté serveur (pilier/catégorie/recherche), la suite
  // arrivant en scrollant vers le bas. La recherche attend une courte
  // pause après la dernière frappe avant de relancer la requête (pas une
  // requête réseau par lettre tapée).
  //
  // `_allProductsForReference` reste un chargement complet séparé (en
  // arrière-plan, sans bloquer l'affichage) : les puces de catégorie et
  // le cache hors-ligne ont besoin de connaître TOUT le catalogue, pas
  // seulement la page actuellement affichée à l'écran.
  static const _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isLoadingProducts = false;
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _allProductsForReference = [];
  final _scrollController = ScrollController();
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  String? _clientName;
  String? _clientAvatarUrl;
  String? _clientLocation;
  int _unreadMessagesCount = 0;
  List<_ActivityItem> _activityFeed = [];
  List<Map<String, dynamic>> _reorderSuggestions = [];
  String? _flashInfo;

  final PageController _bannerController = PageController();
  int _bannerIndex = 0;

  // Repli par défaut : utilisé tant que l'Admin n'a créé aucune bannière
  // dans home_banners (voir supabase/phase6_patch_home_banners.sql et
  // l'écran Admin home_banners_management.dart).
  static const List<_PromoSlide> _defaultPromoSlides = [
    _PromoSlide(
      title: 'Vos produits,\nen un clic',
      subtitle: 'Rapide, fiable, adapté à votre activité',
      icon: Icons.local_shipping_outlined,
    ),
    _PromoSlide(
      title: 'Tarifs Gros\ndès la 1ère palette',
      subtitle: 'Remises automatiques à partir du seuil de quantité',
      icon: Icons.local_offer_outlined,
    ),
    _PromoSlide(
      title: 'Un compte,\ntrois activités',
      subtitle: 'Hygiène, peinture (ARCA) et formation, au même endroit',
      icon: Icons.grid_view_rounded,
    ),
  ];

  List<_PromoSlide> _promoSlides = _defaultPromoSlides;

  // Palette dérivée du vert de marque AkoraHub (voir app_theme.dart,
  // primaryLight #085041) plutôt que les couleurs Material par défaut
  // (vert/bleu/orange/violet/rouge/cyan saturés qui ne partagent aucune
  // tonalité commune) — tons apparentés (mêmes niveaux de saturation et
  // de luminosité), pour un ensemble qui se lit comme dessiné ensemble.
  final List<Color> _unitColors = const [
    Color(0xFF085041), // vert de marque
    Color(0xFF3E7C59), // sauge
    Color(0xFFB8863B), // ocre
    Color(0xFF8C5A3C), // terracotta
    Color(0xFF3D5A6C), // ardoise
    Color(0xFF6B4C6B), // prune
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreProducts();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProductsPage(int page) async {
    var query =
        SupabaseConfig.client.from('products').select().eq('visibility', true);
    if (_selectedUnitId != null) {
      query = query.eq('business_unit_id', _selectedUnitId!);
    }
    if (_selectedCategory != 'toutes') {
      query = query.eq('category', _selectedCategory);
    }
    if (_searchQuery.trim().isNotEmpty) {
      query = query.ilike('name', '%${_searchQuery.trim()}%');
    }
    final data = await query
        .order('name')
        .range(page * _pageSize, page * _pageSize + _pageSize - 1);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Relance la page 0 avec les filtres actuels (changement de pilier,
  /// catégorie ou recherche) — ne recharge que la grille produits, pas le
  /// reste de l'écran (bannières, fil d'activité...).
  Future<void> _reloadProductsPage() async {
    setState(() {
      _page = 0;
      _hasMore = true;
      _isLoadingProducts = true;
    });
    try {
      final rows = await _fetchProductsPage(0);
      if (!mounted) return;
      setState(() {
        _products = rows;
        _hasMore = rows.length == _pageSize;
        _isLoadingProducts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final rows = await _fetchProductsPage(nextPage);
      if (!mounted) return;
      setState(() {
        _products = [..._products, ...rows];
        _page = nextPage;
        _hasMore = rows.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 400), _reloadProductsPage);
  }

  /// Chargement complet du catalogue (arrière-plan, sans bloquer l'écran) —
  /// alimente les puces de catégorie (`_categories`) et le cache
  /// hors-ligne, qui ont besoin de connaître tout le catalogue, pas juste
  /// la page actuellement affichée.
  Future<void> _refreshFullCatalogReference() async {
    try {
      final data = await SupabaseConfig.client
          .from('products')
          .select()
          .eq('visibility', true)
          .order('name');
      if (!mounted) return;
      setState(() {
        _allProductsForReference = List<Map<String, dynamic>>.from(data);
      });
      _cacheCatalogOffline();
    } catch (_) {
      // Pas grave : les puces de catégorie et le cache hors-ligne restent
      // sur leur dernière valeur connue.
    }
  }

  Future<void> _loadData() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion au serveur indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 0;
      _hasMore = true;
    });
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client.from('business_units').select().eq('active', true),
        _fetchProductsPage(0),
        if (userId != null)
          SupabaseConfig.client
              .from('profiles')
              .select('full_name, avatar_url, location')
              .eq('id', userId)
              .single(),
      ]);
      final profile =
          userId != null ? results[2] as Map<String, dynamic> : null;

      // Les 5 blocs suivants sont indépendants les uns des autres (filtre
      // catégories, bannières, badge messages, fil d'activité, suggestions
      // de réapprovisionnement) — on les lance en parallèle plutôt qu'à la
      // suite, pour ne pas cumuler leurs temps de réseau. Chacun gère déjà
      // son propre repli silencieux en cas d'échec.
      Future<List<_PromoSlide>> loadBanners() async {
        try {
          final bannerRows = await SupabaseConfig.client
              .from('home_banners')
              .select()
              .eq('active', true)
              .order('sort_order');
          final rows = List<Map<String, dynamic>>.from(bannerRows);
          if (rows.isEmpty) return _defaultPromoSlides;
          return rows
              .map((b) => _PromoSlide(
                    title: (b['title'] ?? '').toString(),
                    subtitle: (b['subtitle'] ?? '').toString(),
                    imageUrl: b['image_url'] as String?,
                  ))
              .toList();
        } catch (_) {
          return _defaultPromoSlides;
        }
      }

      Future<String?> loadFlashInfo() async {
        try {
          final row = await SupabaseConfig.client
              .from('flash_infos')
              .select('message')
              .eq('active', true)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          return row?['message'] as String?;
        } catch (_) {
          return null;
        }
      }

      Future<int> loadUnreadCount() async {
        if (userId == null) return 0;
        try {
          final convo = await SupabaseConfig.client
              .from('conversations')
              .select('id')
              .eq('customer_id', userId)
              .maybeSingle();
          if (convo == null) return 0;
          final unread = await SupabaseConfig.client
              .from('messages')
              .select('id')
              .eq('conversation_id', convo['id'])
              .eq('sender_role', 'staff')
              .eq('read_by_client', false);
          return List.from(unread).length;
        } catch (_) {
          return 0;
        }
      }

      Future<List<_ActivityItem>> loadActivityFeed() async {
        try {
          final recentPosts = await SupabaseConfig.client
              .from('posts')
              .select()
              .eq('visibility', 'public')
              .order('created_at', ascending: false)
              .limit(5);
          final postList = List<Map<String, dynamic>>.from(recentPosts);
          final authorIds = postList
              .map((p) => p['author_id'] as String?)
              .whereType<String>()
              .toSet();
          final authorProfiles = await PublicProfilesRepo.fetchByIds(authorIds);

          final recentProducts = await SupabaseConfig.client
              .from('products')
              .select()
              .eq('visibility', true)
              .order('created_at', ascending: false)
              .limit(5);
          final productList = List<Map<String, dynamic>>.from(recentProducts);

          var feed = [
            ...postList.map((p) => _ActivityItem.post(
                  p,
                  authorProfiles[p['author_id']],
                  DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
                )),
            ...productList.map((p) => _ActivityItem.product(
                  p,
                  DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now(),
                )),
          ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (feed.length > 8) feed = feed.sublist(0, 8);
          return feed;
        } catch (_) {
          return <_ActivityItem>[];
        }
      }

      Future<List<Map<String, dynamic>>> loadReorderSuggestions() async {
        if (userId == null) return [];
        try {
          final orderItemRows = await SupabaseConfig.client
              .from('order_items')
              .select('product_id, order_id, orders!inner(customer_id)')
              .eq('orders.customer_id', userId);
          final itemList = List<Map<String, dynamic>>.from(orderItemRows);

          // Compte le nombre de commandes DISTINCTES contenant chaque
          // produit (pas le nombre de lignes, pour éviter qu'une grosse
          // quantité dans une seule commande fausse le classement).
          final ordersByProduct = <String, Set<String>>{};
          for (final item in itemList) {
            final productId = item['product_id'] as String?;
            final orderId = item['order_id'] as String?;
            if (productId == null || orderId == null) continue;
            ordersByProduct.putIfAbsent(productId, () => {}).add(orderId);
          }
          final frequentProductIds = ordersByProduct.entries
              .where((e) => e.value.length >= 2)
              .toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length));

          if (frequentProductIds.isEmpty) return [];
          final topIds =
              frequentProductIds.take(5).map((e) => e.key).toList();
          final productRows = await SupabaseConfig.client
              .from('products')
              .select()
              .inFilter('id', topIds)
              .eq('visibility', true);
          final productsById = {
            for (final p in List<Map<String, dynamic>>.from(productRows))
              p['id'] as String: p
          };
          // Conserve l'ordre de fréquence (le plus recommandé en premier).
          return topIds
              .map((id) => productsById[id])
              .whereType<Map<String, dynamic>>()
              .toList();
        } catch (_) {
          return [];
        }
      }

      final parallel = await Future.wait([
        loadBanners(),
        loadUnreadCount(),
        loadActivityFeed(),
        loadReorderSuggestions(),
        loadFlashInfo(),
      ]);
      final loadedSlides = parallel[0] as List<_PromoSlide>;
      final unreadMessages = parallel[1] as int;
      final activityFeed = parallel[2] as List<_ActivityItem>;
      final reorderSuggestions = parallel[3] as List<Map<String, dynamic>>;
      final flashInfo = parallel[4] as String?;

      final productsPage = List<Map<String, dynamic>>.from(results[1] as List);
      setState(() {
        _businessUnits = List<Map<String, dynamic>>.from(results[0] as List);
        _products = productsPage;
        _hasMore = productsPage.length == _pageSize;
        _clientName = profile?['full_name'] as String?;
        _clientAvatarUrl = profile?['avatar_url'] as String?;
        _clientLocation = profile?['location'] as String?;
        _promoSlides = loadedSlides;
        _unreadMessagesCount = unreadMessages;
        _activityFeed = activityFeed;
        _reorderSuggestions = reorderSuggestions;
        _flashInfo = flashInfo;
        _isLoading = false;
      });

      // Chargement complet du catalogue en arrière-plan (sans bloquer
      // l'affichage de cette première page) : alimente les puces de
      // catégorie et le cache hors-ligne, qui ont besoin de connaître
      // tout le catalogue — voir _refreshFullCatalogReference.
      _refreshFullCatalogReference();
    } catch (e) {
      final cached = await _loadCatalogFromCache();
      if (cached) {
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Impossible de charger le catalogue.';
        });
      }
    }
  }

  static const _offlineCacheKey = 'offline_catalog_cache';

  Future<void> _cacheCatalogOffline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _offlineCacheKey,
        jsonEncode({
          'businessUnits': _businessUnits,
          // Le catalogue COMPLET (pas juste la page affichée) — voir
          // _refreshFullCatalogReference, seule source fiable de "tout
          // le catalogue" depuis que _products est paginé.
          'products': _allProductsForReference,
          'cachedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {
      // Pas grave si le cache échoue (ex: stockage plein) — l'app reste
      // utilisable en ligne, juste pas de repli hors-ligne cette fois.
    }
  }

  /// Retourne `true` si un catalogue en cache a bien été chargé (hors-ligne).
  /// Hors-ligne, pas de pagination possible (pas de réseau pour charger la
  /// suite) : on affiche directement tout le catalogue mis en cache.
  Future<bool> _loadCatalogFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_offlineCacheKey);
      if (raw == null) return false;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(decoded['cachedAt'] ?? '');
      final cachedProducts =
          List<Map<String, dynamic>>.from(decoded['products'] ?? []);
      setState(() {
        _businessUnits =
            List<Map<String, dynamic>>.from(decoded['businessUnits'] ?? []);
        _products = cachedProducts;
        _allProductsForReference = cachedProducts;
        _hasMore = false;
      });
      if (mounted && cachedAt != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hors-ligne — catalogue affiché tel que vu le ${DateFormat('dd/MM à HH:mm').format(cachedAt)}.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return _products.isNotEmpty || _businessUnits.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _openNotifications() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Notifications',
                  style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 2.h),
              if (_unreadMessagesCount > 0)
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(_unreadMessagesCount == 1
                      ? 'Un nouveau message de notre équipe'
                      : '$_unreadMessagesCount nouveaux messages de notre équipe'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                )
              else
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  child: Center(
                    child: Text(
                      'Aucune nouvelle notification.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    // Au retour (que la messagerie ait été ouverte ou non), on rafraîchit
    // le compteur — read_by_client aura pu passer à true entre-temps.
    _loadData();
  }

  IconData _iconForUnit(Map<String, dynamic> unit) {
    final slug = (unit['slug'] ?? '').toString();
    // Peinture vérifié en premier : "matieres-premieres-peinture" contient
    // aussi "premieres" mais doit avoir l'icône pinceau, pas fiole.
    if (slug.contains('paint') || slug.contains('peinture')) {
      return Icons.format_paint;
    }
    if (slug.contains('formation')) return Icons.school;
    if (slug.contains('chimie') ||
        slug.contains('chimique') ||
        slug.contains('chemical')) {
      return Icons.science_outlined;
    }
    if (slug.contains('cosmet')) return Icons.spa_outlined;
    if (slug.contains('insecticide') ||
        slug.contains('insect') ||
        slug.contains('nuisible')) {
      return Icons.pest_control_outlined;
    }
    return Icons.cleaning_services;
  }

  /// Icône approximative par mot-clé du nom de catégorie (pas de slug
  /// dédié pour les catégories, contrairement aux piliers — voir
  /// `_iconForUnit` ci-dessus, même principe).
  IconData _iconForCategory(String category) {
    final name = category.toLowerCase();
    if (name.contains('peinture') || name.contains('paint')) {
      return Icons.format_paint;
    }
    if (name.contains('acide') || name.contains('base')) {
      return Icons.science_outlined;
    }
    if (name.contains('carrelage') || name.contains('sol')) {
      return Icons.grid_view_outlined;
    }
    if (name.contains('insecticide') ||
        name.contains('nuisible') ||
        name.contains('anti-')) {
      return Icons.pest_control_outlined;
    }
    if (name.contains('soin') || name.contains('cosmet')) {
      return Icons.spa_outlined;
    }
    if (name.contains('parfum') || name.contains('odeur')) {
      return Icons.local_florist_outlined;
    }
    if (name.contains('désinfect') || name.contains('desinfect')) {
      return Icons.sanitizer_outlined;
    }
    if (name.contains('emballage') || name.contains('contenant')) {
      return Icons.inventory_2_outlined;
    }
    return Icons.category_outlined;
  }

  List<String> get _categories {
    // Basé sur le catalogue complet (_allProductsForReference), pas sur
    // _products qui n'est plus qu'une page — sinon les puces
    // apparaîtraient/disparaîtraient au fil du scroll infini.
    final relevant = _selectedUnitId == null
        ? _allProductsForReference
        : _allProductsForReference
            .where((p) => p['business_unit_id'] == _selectedUnitId);
    // Catégories désactivées par l'Admin (voir category_management.dart) —
    // via le cache partagé plutôt qu'une requête dédiée à chaque ouverture
    // du catalogue (lib/core/reference_data/reference_table_cache.dart).
    final inactiveCategoryNames = ref
        .watch(categoriesCacheProvider)
        .where((c) => c['active'] == false)
        .map((c) => c['name'] as String)
        .toSet();
    final cats = relevant
        .map((p) => (p['category'] ?? '').toString())
        .where((c) => c.isNotEmpty && !inactiveCategoryNames.contains(c))
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  /// Recharge le statut d'abonnement pour le (pilier, catégorie)
  /// actuellement sélectionnés — pas pertinent si l'un des deux vaut
  /// "tous" (une catégorie choisie sans pilier précis pourrait exister
  /// dans plusieurs piliers, donc ambigu pour l'abonnement).
  Future<void> _refreshSubscriptionStatus() async {
    if (_selectedUnitId == null || _selectedCategory == 'toutes') {
      if (_isSubscribedToCategory) {
        setState(() => _isSubscribedToCategory = false);
      }
      return;
    }
    final subscribed = await CategorySubscriptionRepo.isSubscribed(
        _selectedUnitId!, _selectedCategory);
    if (!mounted) return;
    setState(() => _isSubscribedToCategory = subscribed);
  }

  Future<void> _toggleCategorySubscription() async {
    if (_selectedUnitId == null ||
        _selectedCategory == 'toutes' ||
        _isTogglingSubscription) {
      return;
    }
    setState(() => _isTogglingSubscription = true);
    try {
      if (_isSubscribedToCategory) {
        await CategorySubscriptionRepo.unsubscribe(
            _selectedUnitId!, _selectedCategory);
      } else {
        await CategorySubscriptionRepo.subscribe(
            _selectedUnitId!, _selectedCategory);
      }
      if (!mounted) return;
      setState(() => _isSubscribedToCategory = !_isSubscribedToCategory);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue. Réessayez.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTogglingSubscription = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((p) {
      final matchesUnit =
          _selectedUnitId == null || p['business_unit_id'] == _selectedUnitId;
      final matchesCategory = _selectedCategory == 'toutes' ||
          p['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          (p['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesUnit && matchesCategory && matchesSearch;
    }).toList();
  }

  void _quickAddToCart(Map<String, dynamic> product) {
    ref.read(cartProvider.notifier).addItem(
          CartItem(
            productId: product['id'],
            name: product['name'] ?? '',
            priceDetail: (product['price_detail'] ?? 0).toDouble(),
            priceGros: (product['price_gros'] ?? 0).toDouble(),
            grosThresholdQty: (product['gros_threshold_qty'] ?? 10) as int,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ajouté au panier'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartCount = ref.watch(cartProvider).length;
    final favorites = ref.watch(favoritesProvider);

    if (_isLoading) {
      return const _CatalogSkeleton();
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final hour = DateTime.now().hour;
    final greetingPrefix = hour < 5
        ? 'Bonsoir'
        : hour < 18
            ? 'Bonjour'
            : 'Bonsoir';
    final greetingName =
        (_clientName == null || _clientName!.trim().isEmpty)
            ? greetingPrefix
            : '$greetingPrefix, ${_clientName!.split(' ').first}';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // --- En-tête personnalisé : avatar, salutation, localisation, notifs ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: _clientAvatarUrl != null
                        ? NetworkImage(_clientAvatarUrl!)
                        : null,
                    child: _clientAvatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greetingName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_clientLocation != null &&
                            _clientLocation!.trim().isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  _clientLocation!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            shape: const CircleBorder(),
                            child: Badge(
                              label: Text('$cartCount'),
                              isLabelVisible: cartCount > 0,
                              child: IconButton(
                                icon: const Icon(Icons.shopping_cart_outlined),
                                tooltip: 'Panier',
                                onPressed: widget.onOpenCart,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Material(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            shape: const CircleBorder(),
                            child: Badge(
                              label: Text('$_unreadMessagesCount'),
                              isLabelVisible: _unreadMessagesCount > 0,
                              child: IconButton(
                                icon: const Icon(Icons.chat_bubble_outline),
                                tooltip: 'Messagerie',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ChatScreen()),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Material(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            shape: const CircleBorder(),
                            child: Badge(
                              label: Text('$_unreadMessagesCount'),
                              isLabelVisible: _unreadMessagesCount > 0,
                              child: IconButton(
                                icon: const Icon(
                                    Icons.notifications_none_rounded),
                                tooltip: 'Notifications',
                                onPressed: _openNotifications,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- Flash info (annonce courte de l'Admin, si présente) ---
          if (_flashInfo != null && _flashInfo!.trim().isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FlashInfosScreen()),
                  ),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.2.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            _flashInfo!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // --- Barre de recherche ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 1.h),
              child: TextField(
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: ref.tr('search_hint'),
                  hintStyle:
                      TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search,
                      color: theme.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),

          // --- Bannière en carrousel ---
          SliverToBoxAdapter(
            child: SizedBox(
              height: 16.h,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: _promoSlides.length,
                onPageChanged: (i) => setState(() => _bannerIndex = i),
                itemBuilder: (context, index) {
                  final slide = _promoSlides[index];
                  final hasImage =
                      slide.imageUrl != null && slide.imageUrl!.isNotEmpty;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: hasImage
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary
                                      .withValues(alpha: 0.75),
                                ],
                              ),
                        image: hasImage
                            ? DecorationImage(
                                image: NetworkImage(slide.imageUrl!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.45),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slide.title,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                    shadows: hasImage
                                        ? const [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 6,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  slide.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.85),
                                    shadows: hasImage
                                        ? const [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 6,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!hasImage && slide.icon != null)
                            Icon(
                              slide.icon,
                              size: 48,
                              color: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.85),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _promoSlides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _bannerIndex == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _bannerIndex == i
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Réapprovisionnement suggéré : produits commandés dans au
          // moins 2 commandes distinctes par ce client (voir _loadData).
          // Masqué si vide ou si le client n'a pas encore assez d'historique.
          if (_reorderSuggestions.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 1.h),
                child: Text('Vous recommandez souvent',
                    style: theme.textTheme.titleMedium),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 26.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _reorderSuggestions.length,
                  itemBuilder: (context, index) {
                    final p = _reorderSuggestions[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 3.w),
                      child: SizedBox(
                        width: 38.w,
                        // "Recommander" passé en badge interne à la carte
                        // (coin bas-gauche de la photo, seul coin libre :
                        // catégorie en haut-gauche, favori en haut-droite,
                        // ajout rapide en bas-droite) plutôt qu'empilé
                        // par-dessus dans un Stack séparé — évite la
                        // superposition avec l'étiquette de catégorie que ça
                        // provoquait auparavant (les deux au même repère
                        // top:8/left:8, dans deux Stack différents).
                        child: _ProductCard(
                          product: p,
                          currency: _currency,
                          isFavorite:
                              ref.watch(favoritesProvider).contains(p['id']),
                          enableHero: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              productDetailRoute(
                                  ProductDetailClient(product: p)),
                            );
                          },
                          onQuickAdd: () => _quickAddToCart(p),
                          onToggleFavorite: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(p['id']),
                          reorderBadge: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // --- "Pour vous" : fil d'activité mélangeant Communauté (ex-Mur)
          // + nouveaux produits (23/07). Masqué si vide (repli silencieux en cas
          // d'échec de chargement — voir _loadData). ---
          if (_activityFeed.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ref.tr('for_you'), style: theme.textTheme.titleMedium),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WallTab()),
                      ),
                      child: const Text('Voir la Communauté'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 16.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _activityFeed.length,
                  itemBuilder: (context, index) {
                    final item = _activityFeed[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 3.w),
                      child: SizedBox(
                        width: 55.w,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              if (item.isPost) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const WallTab()),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  productDetailRoute(ProductDetailClient(
                                      product: item.product!)),
                                );
                              }
                            },
                            child: Padding(
                              padding: EdgeInsets.all(2.5.w),
                              child: item.isPost
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.groups_outlined,
                                                size: 14,
                                                color: theme
                                                    .colorScheme.primary),
                                            SizedBox(width: 1.w),
                                            Expanded(
                                              child: Text(
                                                PublicProfilesRepo
                                                    .displayName(
                                                        item.authorProfile),
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 0.5.h),
                                        Expanded(
                                          child: Text(
                                            (item.post!['content'] ?? '')
                                                    .toString()
                                                    .isNotEmpty
                                                ? item.post!['content']
                                                : 'Nouvelle publication'
                                                    ' dans la Communauté',
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Container(
                                            width: 16.w,
                                            height: 16.w,
                                            color: theme.colorScheme
                                                .surfaceContainerHighest,
                                            child: ((item.product![
                                                            'image_url']
                                                        as String?) ??
                                                    '')
                                                .isEmpty
                                                ? Icon(
                                                    Icons
                                                        .inventory_2_outlined,
                                                    size: 20,
                                                    color: theme
                                                        .colorScheme.outline,
                                                  )
                                                : _productImage(
                                                    theme: theme,
                                                    imageUrl: item.product![
                                                        'image_url'],
                                                    enableHero: false,
                                                    tag:
                                                        'for-you-${item.product!['id']}',
                                                  ),
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .fiber_new_outlined,
                                                      size: 14,
                                                      color: theme.colorScheme
                                                          .primary),
                                                  SizedBox(width: 1.w),
                                                  Text('Nouveau produit',
                                                      style: theme.textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                ],
                                              ),
                                              SizedBox(height: 0.5.h),
                                              Text(
                                                item.product!['name'] ?? '',
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                              const Spacer(),
                                              Text(
                                                _currency.format((item
                                                            .product![
                                                        'price_detail'] as num?) ??
                                                    0),
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                        fontWeight:
                                                            FontWeight.w700),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // --- Nos activités : icônes rondes colorées ---
          if (_businessUnits.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ref.tr('our_activities'), style: theme.textTheme.titleMedium),
                    if (_selectedUnitId != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedUnitId = null;
                            _selectedCategory = 'toutes';
                          });
                          _reloadProductsPage();
                          _refreshSubscriptionStatus();
                        },
                        child: const Text('Voir tout'),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 12.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: _businessUnits.length,
                  itemBuilder: (context, index) {
                    final unit = _businessUnits[index];
                    final selected = _selectedUnitId == unit['id'];
                    final color = _unitColors[index % _unitColors.length];
                    return Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: () {
                          // Tous les piliers se comportent maintenant de la
                          // même façon (filtrent la grille produits) — la
                          // base Formation (matières premières) n'est plus
                          // accrochée à un pilier "Produits" détourné de son
                          // rôle (ex: "Akora Protect" doit pouvoir vendre de
                          // vrais insecticides finis un jour). Accès à
                          // Formation centralisé dans un seul point d'entrée
                          // (voir profile_tab.dart), voir PROJECT_CONTEXT.md.
                          setState(() {
                            _selectedUnitId = selected ? null : unit['id'];
                            _selectedCategory = 'toutes';
                          });
                          _reloadProductsPage();
                          _refreshSubscriptionStatus();
                        },
                        child: SizedBox(
                          width: 18.w,
                          child: Column(
                            children: [
                              Container(
                                width: 15.w,
                                height: 15.w,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: selected
                                        ? [
                                            color,
                                            color.withValues(alpha: 0.75),
                                          ]
                                        : [
                                            color.withValues(alpha: 0.24),
                                            color.withValues(alpha: 0.08),
                                          ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: selected
                                      ? Border.all(color: color, width: 2)
                                      : null,
                                ),
                                child: Icon(
                                  _iconForUnit(unit),
                                  color: selected ? Colors.white : color,
                                  size: 22,
                                ),
                              ),
                              SizedBox(height: 0.6.h),
                              Text(
                                unit['name'] ?? '',
                                // `labelSmall` du thème est prévu pour du
                                // texte désactivé/atténué (voir
                                // app_theme.dart) — pas adapté ici, le nom
                                // du pilier doit rester bien lisible.
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          if (_categories.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 5.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: const Icon(Icons.apps, size: 18),
                        label: Text(ref.tr('all_categories')),
                        selected: _selectedCategory == 'toutes',
                        onSelected: (_) {
                          setState(() => _selectedCategory = 'toutes');
                          _reloadProductsPage();
                          _refreshSubscriptionStatus();
                        },
                      ),
                    ),
                    ..._categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(_iconForCategory(c), size: 18),
                            label: Text(c),
                            selected: _selectedCategory == c,
                            onSelected: (_) {
                              setState(() => _selectedCategory = c);
                              _reloadProductsPage();
                              _refreshSubscriptionStatus();
                            },
                          ),
                        )),
                  ],
                ),
              ),
            ),

          if (_selectedUnitId != null && _selectedCategory != 'toutes')
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: Icon(
                      _isSubscribedToCategory
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      size: 18,
                      color: _isSubscribedToCategory
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    label: Text(
                      _isSubscribedToCategory
                          ? 'Abonné aux nouveautés'
                          : 'S\'abonner aux nouveautés',
                    ),
                    onPressed: _isTogglingSubscription
                        ? null
                        : _toggleCategorySubscription,
                  ),
                ),
              ),
            ),

          // --- Produits populaires / catalogue ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: Text(ref.tr('products'), style: theme.textTheme.titleMedium),
            ),
          ),
          _filteredProducts.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Center(
                      child: Text(
                        'Aucun produit trouvé.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  sliver: SliverGrid(
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 3.w,
                      mainAxisSpacing: 2.h,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final p = _filteredProducts[index];
                        return _ProductCard(
                          product: p,
                          currency: _currency,
                          isFavorite: favorites.contains(p['id']),
                          onTap: () {
                            Navigator.push(
                              context,
                              productDetailRoute(
                                  ProductDetailClient(product: p)),
                            );
                          },
                          onQuickAdd: () => _quickAddToCart(p),
                          onToggleFavorite: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(p['id']),
                        );
                      },
                      childCount: _filteredProducts.length,
                    ),
                  ),
                ),
          if (_hasMore || _isLoadingMore || _isLoadingProducts)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 4.h)),
        ],
      ),
    );
  }
}

class _PromoSlide {
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? imageUrl;

  const _PromoSlide(
      {required this.title,
      required this.subtitle,
      this.icon,
      this.imageUrl});
}

/// Un élément du fil d'activité "Pour vous" de l'Accueil (23/07) : soit une
/// publication publique de la Communauté, soit un produit récemment ajouté au
/// catalogue. Les deux sources sont mélangées et triées par date.
class _ActivityItem {
  final Map<String, dynamic>? post;
  final Map<String, dynamic>? authorProfile;
  final Map<String, dynamic>? product;
  final DateTime createdAt;

  _ActivityItem.post(this.post, this.authorProfile, this.createdAt)
      : product = null;
  _ActivityItem.product(this.product, this.createdAt)
      : post = null,
        authorProfile = null;

  bool get isPost => post != null;
}

/// Image produit avec loader/repli d'erreur, `Hero` optionnel (voir
/// `_ProductCard.enableHero`).
Widget _productImage({
  required ThemeData theme,
  required String imageUrl,
  required bool enableHero,
  required String tag,
}) {
  final image = Image.network(
    imageUrl,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stack) => Icon(
      Icons.inventory_2_outlined,
      size: 36,
      color: theme.colorScheme.outline,
    ),
    loadingBuilder: (context, child, progress) => progress == null
        ? child
        : Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
  );
  return enableHero ? Hero(tag: tag, child: image) : image;
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final NumberFormat currency;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;
  final VoidCallback onToggleFavorite;
  /// Un même produit peut apparaître à la fois dans la grille principale
  /// et dans "Vous recommandez souvent" (juste au-dessus) : deux `Hero`
  /// avec le même tag simultanément visibles sur le même écran cassent le
  /// vol (assertion Flutter ignorée en release — l'animation ne se
  /// déclenche simplement plus, sans erreur visible). Un seul des deux
  /// affichages doit donc porter le Hero ; la grille principale (entrée
  /// canonique) le garde, ce carrousel secondaire le désactive.
  final bool enableHero;

  /// Affiche un badge "Recommander" en bas à gauche de la photo — utilisé
  /// uniquement dans la section "Vous recommandez souvent" (catalog_tab).
  final bool reorderBadge;

  const _ProductCard({
    required this.product,
    required this.currency,
    required this.isFavorite,
    required this.onTap,
    required this.onQuickAdd,
    required this.onToggleFavorite,
    this.enableHero = true,
    this.reorderBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = (product['category'] ?? '').toString();
    final imageUrl = (product['image_url'] as String?) ?? '';

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: imageUrl.isEmpty
                            ? Icon(
                                Icons.inventory_2_outlined,
                                size: 36,
                                color: theme.colorScheme.outline,
                              )
                            : _productImage(
                                theme: theme,
                                imageUrl: imageUrl,
                                enableHero: enableHero,
                                tag: 'product-image-${product['id']}',
                              ),
                      ),
                    ),
                    if (category.isNotEmpty)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _Tag(label: category, theme: theme),
                      ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Material(
                        color:
                            theme.colorScheme.surface.withValues(alpha: 0.85),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onToggleFavorite,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              size: 18,
                              color: isFavorite
                                  ? Colors.amber
                                  : theme.colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _QuickAddButton(onTap: onQuickAdd),
                    ),
                    if (reorderBadge)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Material(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: onQuickAdd,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.replay,
                                      size: 12,
                                      color: theme.colorScheme.onPrimary),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Recommander',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                child: Text(
                  'Dès ${currency.format(product['price_detail'] ?? 0)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                child: Text(
                  product['name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton "+" d'ajout rapide au panier — petit effet de rebond au tap,
/// pour donner un retour visuel immédiat que l'ajout a bien eu lieu
/// (auparavant seul un SnackBar discret confirmait l'action).
class _QuickAddButton extends StatefulWidget {
  final VoidCallback onTap;

  const _QuickAddButton({required this.onTap});

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: theme.colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.add,
              size: 16,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final ThemeData theme;
  final bool accent;

  const _Tag({required this.label, required this.theme, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: accent
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Rectangle qui pulse doucement (dégradé animé) — remplace le spinner
/// plein écran pendant le tout premier chargement du catalogue, pour
/// donner une impression de rapidité plutôt qu'un écran vide. Fait main
/// plutôt qu'un package tiers (`shimmer`) pour ne pas ajouter de
/// dépendance non testable sans SDK Flutter local.
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const _ShimmerBox({
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.colorScheme.surface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// Aperçu de la mise en page de l'accueil pendant le premier chargement
/// (avant que `_loadData` n'ait de résultat) — reproduit approximativement
/// la forme de l'en-tête/bannière/grille de produits pour éviter un écran
/// vide ou un simple spinner central.
class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        children: [
          Row(
            children: [
              const _ShimmerBox(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.all(Radius.circular(22)),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 40.w, height: 16),
                    SizedBox(height: 1.h),
                    _ShimmerBox(width: 28.w, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _ShimmerBox(
            width: double.infinity,
            height: 20.h,
            borderRadius: BorderRadius.circular(16),
          ),
          SizedBox(height: 2.5.h),
          Row(
            children: List.generate(
              4,
              (i) => Padding(
                padding: EdgeInsets.only(right: 3.w),
                child: _ShimmerBox(
                  width: 15.w,
                  height: 15.w,
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
          SizedBox(height: 2.5.h),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 0.72,
            children: List.generate(
              4,
              (i) => _ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
