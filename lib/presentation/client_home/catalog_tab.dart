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
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 5.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Tous les piliers'),
                      selected: _selectedUnitId == null,
                      onSelected: (_) => setState(() {
                        _selectedUnitId = null;
                        _selectedCategory = 'toutes';
                      }),
                    ),
                  ),
                  ..._businessUnits.map((u) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(u['name']),
                          selected: _selectedUnitId == u['id'],
                          onSelected: (_) => setState(() {
                            _selectedUnitId = u['id'];
                            _selectedCategory = 'toutes';
                          }),
                        ),
                      )),
                ],
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 5.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
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
          SliverToBoxAdapter(child: SizedBox(height: 1.h)),
          _filteredProducts.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Aucun produit trouvé.',
                      style: theme.textTheme.bodyMedium,
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dès ${currency.format(product['price_detail'] ?? 0)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

