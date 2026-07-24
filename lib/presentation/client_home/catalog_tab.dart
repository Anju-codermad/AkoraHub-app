import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'chat_screen.dart';
import 'favorites_provider.dart';
import 'product_detail_client.dart';

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
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  String? _clientName;
  String? _clientAvatarUrl;
  String? _clientLocation;

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

  final List<Color> _unitColors = const [
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFEF6C00),
    Color(0xFF6A1B9A),
    Color(0xFFC62828),
    Color(0xFF00838F),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
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
    });
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      final results = await Future.wait([
        SupabaseConfig.client.from('business_units').select().eq('active', true),
        SupabaseConfig.client
            .from('products')
            .select()
            .eq('visibility', true)
            .order('name'),
        if (userId != null)
          SupabaseConfig.client
              .from('profiles')
              .select('full_name, avatar_url, location')
              .eq('id', userId)
              .single(),
      ]);
      final profile =
          userId != null ? results[2] as Map<String, dynamic> : null;

      // Bannières hero gérées par l'Admin (table home_banners). Chargement
      // séparé et tolérant : si la migration Supabase n'a pas encore été
      // appliquée, ou si aucune bannière n'est active, on garde le
      // carrousel par défaut plutôt que de casser l'écran d'accueil.
      List<_PromoSlide> loadedSlides = _defaultPromoSlides;
      try {
        final bannerRows = await SupabaseConfig.client
            .from('home_banners')
            .select()
            .eq('active', true)
            .order('sort_order');
        final rows = List<Map<String, dynamic>>.from(bannerRows);
        if (rows.isNotEmpty) {
          loadedSlides = rows
              .map((b) => _PromoSlide(
                    title: (b['title'] ?? '').toString(),
                    subtitle: (b['subtitle'] ?? '').toString(),
                    imageUrl: b['image_url'] as String?,
                  ))
              .toList();
        }
      } catch (_) {
        // Repli silencieux sur _defaultPromoSlides.
      }

      setState(() {
        _businessUnits = List<Map<String, dynamic>>.from(results[0] as List);
        _products = List<Map<String, dynamic>>.from(results[1] as List);
        _clientName = profile?['full_name'] as String?;
        _clientAvatarUrl = profile?['avatar_url'] as String?;
        _clientLocation = profile?['location'] as String?;
        _promoSlides = loadedSlides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger le catalogue.';
      });
    }
  }

  IconData _iconForUnit(Map<String, dynamic> unit) {
    final slug = (unit['slug'] ?? '').toString();
    if (slug.contains('paint')) return Icons.format_paint;
    if (slug.contains('formation')) return Icons.school;
    if (slug.contains('chimie') || slug.contains('chemical')) {
      return Icons.science_outlined;
    }
    if (slug.contains('cosmet')) return Icons.spa_outlined;
    if (slug.contains('insecticide') || slug.contains('insect')) {
      return Icons.pest_control_outlined;
    }
    return Icons.cleaning_services;
  }

  List<String> get _categories {
    final relevant = _selectedUnitId == null
        ? _products
        : _products.where((p) => p['business_unit_id'] == _selectedUnitId);
    final cats = relevant
        .map((p) => (p['category'] ?? '').toString())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    cats.sort();
    return cats;
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    final greetingName =
        (_clientName == null || _clientName!.trim().isEmpty)
            ? 'Bonjour'
            : 'Bonjour, ${_clientName!.split(' ').first}';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
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
                      Padding(
                        padding: const EdgeInsets.only(right: 4, bottom: 4),
                        child: Text(
                          'AkoraHub',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
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
                          SizedBox(width: 2.w),
                          Material(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            shape: const CircleBorder(),
                            child: IconButton(
                              icon: const Icon(
                                  Icons.notifications_none_rounded),
                              tooltip: 'Notifications',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Notifications bientôt disponibles'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
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

          // --- Barre de recherche ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 1.h),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
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
                                  Colors.black.withValues(alpha: 0.25),
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
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  slide.subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.85),
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

          // --- Nos activités : icônes rondes colorées ---
          if (_businessUnits.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 1.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nos activités', style: theme.textTheme.titleMedium),
                    if (_selectedUnitId != null)
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedUnitId = null;
                          _selectedCategory = 'toutes';
                        }),
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
                        onTap: () => setState(() {
                          _selectedUnitId = selected ? null : unit['id'];
                          _selectedCategory = 'toutes';
                        }),
                        child: SizedBox(
                          width: 18.w,
                          child: Column(
                            children: [
                              Container(
                                width: 15.w,
                                height: 15.w,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? color
                                      : color.withValues(alpha: 0.14),
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
                                  fontWeight: FontWeight.w600,
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
                        label: const Text('Toutes catégories'),
                        selected: _selectedCategory == 'toutes',
                        onSelected: (_) =>
                            setState(() => _selectedCategory = 'toutes'),
                      ),
                    ),
                    ..._categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: _selectedCategory == c,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = c),
                          ),
                        )),
                  ],
                ),
              ),
            ),

          // --- Produits populaires / catalogue ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: Text('Produits', style: theme.textTheme.titleMedium),
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
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailClient(product: p),
                              ),
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

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final NumberFormat currency;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;
  final VoidCallback onToggleFavorite;

  const _ProductCard({
    required this.product,
    required this.currency,
    required this.isFavorite,
    required this.onTap,
    required this.onQuickAdd,
    required this.onToggleFavorite,
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
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
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
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => Icon(
                                  Icons.inventory_2_outlined,
                                  size: 36,
                                  color: theme.colorScheme.outline,
                                ),
                                loadingBuilder:
                                    (context, child, progress) =>
                                        progress == null
                                            ? child
                                            : Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: theme
                                                        .colorScheme.outline,
                                                  ),
                                                ),
                                              ),
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
                      child: Material(
                        color: theme.colorScheme.primary,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onQuickAdd,
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
