import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'favorites_provider.dart';
import 'product_detail_client.dart';

/// Écran "Mes favoris" — liste les produits marqués en favoris par le
/// client (étoile sur les cartes produit et la fiche produit).
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String? _error;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadFavoriteProducts();
  }

  Future<void> _loadFavoriteProducts() async {
    final favoriteIds = ref.read(favoritesProvider).toList();
    if (!SupabaseConfig.isConfigured || favoriteIds.isEmpty) {
      setState(() {
        _isLoading = false;
        _products = [];
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await SupabaseConfig.client
          .from('products')
          .select()
          .inFilter('id', favoriteIds);
      setState(() {
        _products = List<Map<String, dynamic>>.from(products);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger vos favoris.';
      });
    }
  }

  void _addAllToCart() {
    for (final p in _products) {
      ref.read(cartProvider.notifier).addItem(
            CartItem(
              productId: p['id'],
              name: p['name'] ?? '',
              priceDetail: (p['price_detail'] ?? 0).toDouble(),
              priceGros: (p['price_gros'] ?? 0).toDouble(),
              grosThresholdQty: (p['gros_threshold_qty'] ?? 10) as int,
            ),
          );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favoris ajoutés au panier.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Se re-synchronise avec le provider si un favori est retiré depuis
    // cet écran ou ailleurs pendant la session.
    final favoriteIds = ref.watch(favoritesProvider);
    final visibleProducts =
        _products.where((p) => favoriteIds.contains(p['id'])).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes favoris'),
        actions: [
          if (visibleProducts.isNotEmpty)
            TextButton(
              onPressed: _addAllToCart,
              child: const Text('Tout ajouter'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : visibleProducts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          'Aucun favori pour le moment. Touchez l\'étoile '
                          'sur un produit pour l\'ajouter ici.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFavoriteProducts,
                      child: GridView.builder(
                        padding: EdgeInsets.all(4.w),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 3.w,
                          mainAxisSpacing: 2.h,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: visibleProducts.length,
                        itemBuilder: (context, index) {
                          final p = visibleProducts[index];
                          return _FavoriteCard(
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
                            onRemove: () => ref
                                .read(favoritesProvider.notifier)
                                .toggle(p['id']),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.product,
    required this.currency,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                              ),
                      ),
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
                          onTap: onRemove,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child:
                                Icon(Icons.star, size: 18, color: Colors.amber),
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
