import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_config.dart';

/// Ensemble des IDs produits mis en favoris par le client connecté.
/// Persisté dans la table `favorites` (voir
/// `supabase/phase7_patch_favorites.sql`).
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (!SupabaseConfig.isConfigured || userId == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('favorites')
          .select('product_id')
          .eq('customer_id', userId);
      state = {for (final r in rows) r['product_id'] as String};
    } catch (_) {
      // Table pas encore créée côté Supabase, ou hors ligne — on reste
      // silencieusement avec une liste vide plutôt que de faire planter
      // l'écran.
    }
  }

  bool isFavorite(String productId) => state.contains(productId);

  /// Bascule l'état favori d'un produit, avec mise à jour optimiste
  /// (annulée si l'appel Supabase échoue).
  Future<void> toggle(String productId) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    final wasFavorite = state.contains(productId);

    state = wasFavorite
        ? (state.where((id) => id != productId).toSet())
        : ({...state, productId});

    try {
      if (wasFavorite) {
        await SupabaseConfig.client
            .from('favorites')
            .delete()
            .eq('customer_id', userId)
            .eq('product_id', productId);
      } else {
        await SupabaseConfig.client.from('favorites').insert({
          'customer_id': userId,
          'product_id': productId,
        });
      }
    } catch (_) {
      // Repli : on annule la mise à jour optimiste.
      state = wasFavorite
          ? ({...state, productId})
          : (state.where((id) => id != productId).toSet());
    }
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});
