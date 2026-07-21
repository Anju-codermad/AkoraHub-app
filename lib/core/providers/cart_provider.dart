import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un article du panier client.
class CartItem {
  final String productId;
  final String name;
  final double priceDetail;
  final double priceGros;
  final int grosThresholdQty;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.productId,
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
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem newItem) {
    final index = state.indexWhere((i) => i.productId == newItem.productId);
    if (index >= 0) {
      final updated = [...state];
      updated[index].quantity += newItem.quantity;
      state = updated;
    } else {
      state = [...state, newItem];
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.productId == productId)
          (CartItem(
            productId: item.productId,
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

  void removeItem(String productId) {
    state = state.where((i) => i.productId != productId).toList();
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
