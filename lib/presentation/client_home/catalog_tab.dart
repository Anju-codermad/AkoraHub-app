import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'product_detail_client.dart';

class CatalogTab extends ConsumerStatefulWidget {
  const CatalogTab({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadData();
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
      final units = await SupabaseConfig.client
          .from('business_units')
          .select()
          .eq('active', true);
      final products = await SupabaseConfig.client
          .from('products')
          .select()
          .eq('visibility', true)
          .order('name');
      setState(() {
        _businessUnits = List<Map<String, dynamic>>.from(units);
        _products = List<Map<String, dynamic>>.from(products);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger le catalogue.';
      });
    }
  }

  String _iconForUnit(Map<String, dynamic> unit) {
    final slug = (unit['slug'] ?? '').toString();
    if (slug.contains('paint')) return 'format_paint';
    if (slug.contains('formation')) return 'school';
    return 'cleaning_services';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // --- Barre de recherche ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
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

          // --- Bannière d'accroche ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vos produits,\nen un clic',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Rapide, fiable, adapté à votre activité',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 48,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Grille des piliers ---
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.5.h, 4.w, 1.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nos activités', style: theme.textTheme.titleMedium),
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
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 1.5.h,
                childAspectRatio: 3.2,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final unit = _businessUnits[index];
                  final selected = _selectedUnitId == unit['id'];
                  return Material(
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() {
                        _selectedUnitId = selected ? null : unit['id'];
                        _selectedCategory = 'toutes';
                      }),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _iconForUnit(unit) == 'format_paint'
                                    ? Icons.format_paint
                                    : _iconForUnit(unit) == 'school'
                                        ? Icons.school
                                        : Icons.cleaning_services,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                unit['name'] ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _businessUnits.length,
              ),
            ),
          ),

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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailClient(product: p),
                              ),
                            );
                          },
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

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final NumberFormat currency;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = (product['category'] ?? '').toString();
    final description = (product['description'] ?? '').toString();

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
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 36,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow
                                  .withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.north_east,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                child: Text(
                  product['name'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (category.isNotEmpty)
                      _Tag(label: category, theme: theme),
                    _Tag(
                      label:
                          'Dès ${currency.format(product['price_detail'] ?? 0)}',
                      theme: theme,
                      accent: true,
                    ),
                  ],
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
            : theme.colorScheme.surfaceContainerHighest,
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
