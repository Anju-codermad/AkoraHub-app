import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/navigation/product_detail_route.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'product_detail_client.dart';
import 'usual_cart_provider.dart';

/// "Mon panier habituel" (06/08) — liste de produits + quantités que le
/// client compose une fois (icône sur la fiche produit) et recharge en
/// un clic, sans repasser par tout le catalogue. Distinct des favoris
/// (pas de quantité) et des commandes récurrentes (rien d'automatique
/// ici, juste un raccourci manuel).
class UsualCartScreen extends ConsumerStatefulWidget {
  const UsualCartScreen({super.key});

  @override
  ConsumerState<UsualCartScreen> createState() => _UsualCartScreenState();
}

class _UsualCartScreenState extends ConsumerState<UsualCartScreen> {
  List<Map<String, dynamic>> _products = [];
  final Map<String, int> _quantities = {};
  bool _isLoading = true;
  String? _error;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  String? get _myId => SupabaseConfig.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = _myId;
    if (!SupabaseConfig.isConfigured || userId == null) {
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
      final items = await SupabaseConfig.client
          .from('usual_cart_items')
          .select('product_id, quantity')
          .eq('customer_id', userId);
      final rows = List<Map<String, dynamic>>.from(items);
      final ids = rows.map((r) => r['product_id'] as String).toList();
      if (ids.isEmpty) {
        setState(() {
          _products = [];
          _isLoading = false;
        });
        return;
      }
      final products = await SupabaseConfig.client
          .from('products')
          .select()
          .inFilter('id', ids);
      final quantityById = {
        for (final r in rows) r['product_id'] as String: r['quantity'] as int,
      };
      setState(() {
        _products = List<Map<String, dynamic>>.from(products);
        _quantities
          ..clear()
          ..addAll(quantityById);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger votre panier habituel.';
      });
    }
  }

  Future<void> _setQuantity(String productId, int quantity) async {
    if (quantity < 1) return;
    setState(() => _quantities[productId] = quantity);
    final userId = _myId;
    if (userId == null) return;
    try {
      await SupabaseConfig.client
          .from('usual_cart_items')
          .update({'quantity': quantity})
          .eq('customer_id', userId)
          .eq('product_id', productId);
    } catch (_) {
      // Pas grave : la quantité affichée reste localement à jour pour
      // cette session, se resynchronisera au prochain chargement.
    }
  }

  Future<void> _remove(String productId) async {
    await ref.read(usualCartProvider.notifier).toggle(productId);
    if (!mounted) return;
    setState(() {
      _products.removeWhere((p) => p['id'] == productId);
      _quantities.remove(productId);
    });
  }

  void _addAllToCart() {
    for (final p in _products) {
      final quantity = _quantities[p['id']] ?? 1;
      ref.read(cartProvider.notifier).addItem(
            CartItem(
              productId: p['id'],
              name: p['name'] ?? '',
              priceDetail: (p['price_detail'] ?? 0).toDouble(),
              priceGros: (p['price_gros'] ?? 0).toDouble(),
              grosThresholdQty: (p['gros_threshold_qty'] ?? 10) as int,
              quantity: quantity,
            ),
          );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Panier habituel ajouté au panier.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier habituel'),
        actions: [
          if (_products.isNotEmpty)
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
              : _products.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          'Aucun produit pour l\'instant. Sur une fiche '
                          'produit, touchez l\'icône panier habituel pour '
                          'l\'ajouter ici.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _products.length,
                        separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                        itemBuilder: (context, index) {
                          final p = _products[index];
                          final productId = p['id'] as String;
                          final quantity = _quantities[productId] ?? 1;
                          final imageUrl = (p['image_url'] as String?) ?? '';
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(
                                  8, 4, 12, 4),
                              onTap: () => Navigator.push(
                                context,
                                productDetailRoute(
                                    ProductDetailClient(product: p)),
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: imageUrl.isEmpty
                                      ? Container(
                                          color: theme.colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                              Icons.inventory_2_outlined,
                                              color:
                                                  theme.colorScheme.outline),
                                        )
                                      : Image.network(imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            color: theme.colorScheme
                                                .surfaceContainerHighest,
                                            child: Icon(
                                                Icons.inventory_2_outlined,
                                                color: theme
                                                    .colorScheme.outline),
                                          )),
                                ),
                              ),
                              title: Text(
                                p['name'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                  _currency.format(p['price_detail'] ?? 0)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 20),
                                    onPressed: () => _setQuantity(
                                        productId, quantity - 1),
                                  ),
                                  Text('$quantity'),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        size: 20),
                                    onPressed: () => _setQuantity(
                                        productId, quantity + 1),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size: 20,
                                        color: theme.colorScheme.error),
                                    onPressed: () => _remove(productId),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
