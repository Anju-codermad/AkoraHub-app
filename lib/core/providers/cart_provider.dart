import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un article du panier client.
class CartItem {
  /// Toujours l'ID du vrai produit (`products.id`) — jamais celui d'une
  /// variante, pour rester valide comme `order_items.product_id`
  /// (clé étrangère vers `products`, voir phase1/phase4).
  final String productId;

  /// ID de la variante choisie (`product_variants.id`), si le produit en
  /// a — nullable, va dans `order_items.variant_id` (phase4).
  final String? variantId;
  final String name;
  final double priceDetail;
  final double priceGros;
  final int grosThresholdQty;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.productId,
    this.variantId,
    required this.name,
    required this.priceDetail,
    required this.priceGros,
    required this.grosThresholdQty,
    this.imageUrl,
    this.quantity = 1,
  });

  /// Prix unitaire appliqué automatiquement selon le seuil de quantité
  /// (logique Gros/Détail définie en Phase 1).
  double get unitPrice => quantity >= grosThresholdQty ? priceGros : priceDetail;

  bool get isGrosPrice => quantity >= grosThresholdQty;

  double get total => unitPrice * quantity;

  /// Clé d'identité d'une ligne du panier — la variante si le produit en
  /// a une (deux variantes du même produit sont deux lignes distinctes),
  /// sinon le produit lui-même.
  String get cartKey => variantId ?? productId;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem newItem) {
    final index = state.indexWhere((i) => i.cartKey == newItem.cartKey);
    if (index >= 0) {
      final updated = [...state];
      updated[index].quantity += newItem.quantity;
      state = updated;
    } else {
      state = [...state, newItem];
    }
  }

  void updateQuantity(String cartKey, int quantity) {
    if (quantity <= 0) {
      removeItem(cartKey);
      return;
    }
    state = [
      for (final item in state)
        if (item.cartKey == cartKey)
          (CartItem(
            productId: item.productId,
            variantId: item.variantId,
            name: item.name,
            priceDetail: item.priceDetail,
            priceGros: item.priceGros,
            grosThresholdQty: item.grosThresholdQty,
            imageUrl: item.imageUrl,
            quantity: quantity,
          ))
        else
          item,
    ];
  }

  void removeItem(String cartKey) {
    state = state.where((i) => i.cartKey != cartKey).toList();
  }

  void clear() {
    state = [];
  }

  double get total => state.fold(0, (sum, item) => sum + item.total);
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
