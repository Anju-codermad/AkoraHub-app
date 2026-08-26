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
import 'catalog_tab.dart' show ProductCard;
import 'favorites_provider.dart';
import 'product_detail_client.dart';

/// Onglet dédié "Catalogue" (04/08) : parcours complet du catalogue
/// produits (recherche, filtre par activité/catégorie, grille avec
/// défilement infini) — extrait de l'Accueil (`catalog_tab.dart`), qui se
/// concentre désormais sur les raccourcis (bannières, "Pour vous",
/// réapprovisionnement) plutôt que la navigation exhaustive du
/// catalogue. Réutilise `ProductCard` (rendu public dans catalog_tab.dart
/// pour cet usage partagé) pour ne pas dupliquer la fiche produit.
/// Commandes a quitté la barre du bas pour une icône dans l'en-tête
/// d'Accueil (voir client_home.dart) afin de libérer cette place.
class ProductCatalogTab extends ConsumerStatefulWidget {
  const ProductCatalogTab({super.key});

  @override
  ConsumerState<ProductCatalogTab> createState() =>
      _ProductCatalogTabState();
}

class _ProductCatalogTabState extends ConsumerState<ProductCatalogTab> {
  List<Map<String, dynamic>> _businessUnits = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedUnitId;
  String _selectedCategory = 'toutes';
  // Filtre par usage (06/08, demande "praticable") — sur la colonne
  // `use_cases` (text[]) déjà utilisée pour les badges usages côté fiche
  // produit et le formulaire admin (phase73/kProductUsageSuggestionsByCategory).
  String _selectedUsage = 'toutes';
  String _searchQuery = '';

  // Catégories que CE client achète le plus souvent, dans l'ordre
  // (06/08) — utilisé pour réordonner les puces `_categories` ci-dessous
  // (les plus achetées en premier, plutôt que l'ordre alphabétique fixe).
  // Voir `client_top_categories` (supabase/phase75).
  List<String> _topCategoriesOrder = [];

  // Abonnement aux notifications pour la catégorie actuellement
  // sélectionnée (uniquement pertinent quand un pilier ET une catégorie
  // précis sont choisis — voir CategorySubscriptionRepo).
  bool _isSubscribedToCategory = false;
  bool _isTogglingSubscription = false;

  // Pagination par pages de 20, filtrée côté serveur (pilier/catégorie/
  // recherche), la suite arrivant en scrollant vers le bas.
  // `_allProductsForReference` reste un chargement complet séparé (en
  // arrière-plan) : les puces de catégorie et le cache hors-ligne ont
  // besoin de connaître TOUT le catalogue, pas seulement la page affichée.
  static const _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isLoadingProducts = false;
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _allProductsForReference = [];
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  /// Historique de recherche (local, `SharedPreferences`) + suggestions
  /// tapées dans le nom des produits déjà chargés — affichés sous la
  /// barre de recherche tant qu'elle a le focus.
  static const _recentSearchesPrefsKey = 'recent_product_searches';
  static const _maxRecentSearches = 6;
  List<String> _recentSearches = [];
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

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
    _searchFocusNode.addListener(() => setState(() {}));
    _loadRecentSearches();
    _loadTopCategories();
  }

  Future<void> _loadTopCategories() async {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null || !SupabaseConfig.isConfigured) return;
    try {
      final rows = await SupabaseConfig.client
          .rpc('client_top_categories', params: {'uid': uid});
      if (!mounted) return;
      setState(() {
        _topCategoriesOrder = List<Map<String, dynamic>>.from(rows)
            .map((r) => r['category'] as String)
            .toList();
      });
    } catch (_) {
      // Repli silencieux : migration phase75 pas encore exécutée, ou
      // aucune commande passée — l'ordre alphabétique reste utilisé.
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _recentSearches = prefs.getStringList(_recentSearchesPrefsKey) ?? [];
      });
    } catch (_) {
      // Pas grave : l'historique reste simplement vide.
    }
  }

  Future<void> _saveRecentSearch(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    final updated = [
      trimmed,
      ..._recentSearches.where((s) => s.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxRecentSearches).toList();
    setState(() => _recentSearches = updated);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesPrefsKey, updated);
    } catch (_) {
      // Pas grave : la session courante garde quand même l'historique.
    }
  }

  Future<void> _clearRecentSearches() async {
    setState(() => _recentSearches = []);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesPrefsKey);
    } catch (_) {}
  }

  void _applySearch(String term) {
    _searchController.text = term;
    _searchFocusNode.unfocus();
    _onSearchChanged(term);
    _saveRecentSearch(term);
  }

  /// Suggestions de noms de produits correspondant à la saisie en cours,
  /// dérivées du catalogue déjà chargé en mémoire — pas de requête réseau
  /// dédiée, juste un filtre local sur `_allProductsForReference`.
  List<String> get _searchSuggestions {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return [];
    final names = _allProductsForReference
        .map((p) => (p['name'] as String?) ?? '')
        .where((name) => name.toLowerCase().contains(query))
        .toSet()
        .toList();
    names.sort();
    return names.take(5).toList();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreProducts();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProductsPage(int page) async {
    // `product_variants(price_detail, formats(name))` embarqué (26/08) :
    // permet à ProductCard d'afficher l'unité (kg/L) à côté du prix pour
    // les produits à variantes, sans requête séparée par carte.
    var query = SupabaseConfig.client
        .from('products')
        .select('*, product_variants(price_detail, formats(name))')
        .eq('visibility', true);
    if (_selectedUnitId != null) {
      query = query.eq('business_unit_id', _selectedUnitId!);
    }
    if (_selectedCategory != 'toutes') {
      query = query.eq('category', _selectedCategory);
    }
    if (_selectedUsage != 'toutes') {
      query = query.contains('use_cases', [_selectedUsage]);
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
  /// catégorie ou recherche).
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
  /// hors-ligne, qui ont besoin de connaître tout le catalogue.
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
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client.from('business_units').select().eq('active', true),
        _fetchProductsPage(0),
      ]);
      final productsPage = List<Map<String, dynamic>>.from(results[1] as List);
      setState(() {
        _businessUnits = List<Map<String, dynamic>>.from(results[0] as List);
        _products = productsPage;
        _hasMore = productsPage.length == _pageSize;
        _isLoading = false;
      });

      // Chargement complet du catalogue en arrière-plan (sans bloquer
      // l'affichage de cette première page) — voir _refreshFullCatalogReference.
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
      // Pas grave si le cache échoue — l'app reste utilisable en ligne,
      // juste pas de repli hors-ligne cette fois.
    }
  }

  /// Retourne `true` si un catalogue en cache a bien été chargé (hors-ligne).
  /// Hors-ligne, pas de pagination possible : on affiche directement tout
  /// le catalogue mis en cache.
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
  /// dédié pour les catégories, contrairement aux piliers).
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
    // Catégories désactivées par l'Admin — via le cache partagé plutôt
    // qu'une requête dédiée à chaque ouverture du catalogue.
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
    // Catégories les plus achetées par ce client en premier (06/08),
    // ordre alphabétique pour le reste (et repli complet si le client n'a
    // pas encore d'historique, _topCategoriesOrder restant vide).
    cats.sort((a, b) {
      final rankA = _topCategoriesOrder.indexOf(a);
      final rankB = _topCategoriesOrder.indexOf(b);
      if (rankA == -1 && rankB == -1) return a.compareTo(b);
      if (rankA == -1) return 1;
      if (rankB == -1) return -1;
      return rankA.compareTo(rankB);
    });
    return cats;
  }

  /// Usages disponibles pour filtrer (06/08) — dérivés du catalogue
  /// complet comme `_categories`, scopés au pilier sélectionné mais PAS
  /// à la catégorie (un usage reste utile pour comparer plusieurs
  /// catégories d'un même pilier, ex. "Nettoyage" peut concerner
  /// Carrelage & Sols ET Cuisine & Vaisselle).
  List<String> get _usages {
    final relevant = _selectedUnitId == null
        ? _allProductsForReference
        : _allProductsForReference
            .where((p) => p['business_unit_id'] == _selectedUnitId);
    final usages = <String>{
      for (final p in relevant)
        ...List<String>.from(p['use_cases'] ?? const []),
    }.toList();
    usages.sort();
    return usages;
  }

  /// Recharge le statut d'abonnement pour le (pilier, catégorie)
  /// actuellement sélectionnés.
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
      final matchesUsage = _selectedUsage == 'toutes' ||
          List<String>.from(p['use_cases'] ?? const [])
              .contains(_selectedUsage);
      final matchesSearch = _searchQuery.isEmpty ||
          (p['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchesUnit && matchesCategory && matchesUsage && matchesSearch;
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
    final favorites = ref.watch(favoritesProvider);

    if (_isLoading) {
      return const _ProductCatalogSkeleton();
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // --- Barre de recherche ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: ref.tr('search_hint'),
                  hintStyle:
                      TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search,
                      color: theme.colorScheme.onSurfaceVariant),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant),
                          onPressed: () => _applySearch(''),
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  _onSearchChanged(value);
                  setState(() {});
                },
                onSubmitted: _applySearch,
              ),
            ),
          ),

          // --- Suggestions / historique de recherche ---
          if (_searchFocusNode.hasFocus &&
              (_searchController.text.trim().isEmpty
                  ? _recentSearches.isNotEmpty
                  : _searchSuggestions.isNotEmpty))
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 3.w, vertical: 1.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _searchController.text.trim().isEmpty
                          ? [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Recherches récentes',
                                      style: theme.textTheme.labelMedium),
                                  TextButton(
                                    onPressed: _clearRecentSearches,
                                    child: const Text('Effacer'),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  for (final term in _recentSearches)
                                    ActionChip(
                                      avatar: const Icon(Icons.history,
                                          size: 16),
                                      label: Text(term),
                                      onPressed: () => _applySearch(term),
                                    ),
                                ],
                              ),
                            ]
                          : [
                              for (final name in _searchSuggestions)
                                ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.search, size: 18),
                                  title: Text(name),
                                  onTap: () => _applySearch(name),
                                ),
                            ],
                    ),
                  ),
                ),
              ),
            ),

          // --- Nos activités : icônes rondes colorées ---
          if (_businessUnits.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(ref.tr('our_activities'),
                        style: theme.textTheme.titleMedium),
                    if (_selectedUnitId != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedUnitId = null;
                            _selectedCategory = 'toutes';
                            _selectedUsage = 'toutes';
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
                          setState(() {
                            _selectedUnitId = selected ? null : unit['id'];
                            _selectedCategory = 'toutes';
                            _selectedUsage = 'toutes';
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

          if (_usages.isNotEmpty)
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
                        avatar: const Icon(Icons.checklist_rtl, size: 18),
                        label: const Text('Tous les usages'),
                        selected: _selectedUsage == 'toutes',
                        onSelected: (_) {
                          setState(() => _selectedUsage = 'toutes');
                          _reloadProductsPage();
                        },
                      ),
                    ),
                    ..._usages.map((u) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(u),
                            selected: _selectedUsage == u,
                            onSelected: (_) {
                              setState(() => _selectedUsage = u);
                              _reloadProductsPage();
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

          // --- Grille de produits ---
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
                        return ProductCard(
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

/// Aperçu de la mise en page du catalogue pendant le premier chargement.
class _ProductCatalogSkeleton extends StatelessWidget {
  const _ProductCatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          SizedBox(height: 2.5.h),
          Row(
            children: List.generate(
              4,
              (i) => Padding(
                padding: EdgeInsets.only(right: 3.w),
                child: Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(color: base, shape: BoxShape.circle),
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
              (i) => Container(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
