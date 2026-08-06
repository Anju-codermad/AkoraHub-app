import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_config.dart';

/// Ensemble des IDs produits dans "Mon panier habituel" du client
/// connecté — juste pour savoir quels produits afficher comme "déjà
/// ajoutés" (icône sur la fiche produit). La quantité de chacun (par
/// défaut 1, modifiable) vit uniquement dans `usual_cart_items`
/// (voir supabase/phase80_patch_usual_cart.sql), lue directement par
/// `UsualCartScreen` — ce notifier ne s'occupe que de la présence/
/// absence, comme `FavoritesNotifier`.
class UsualCartNotifier extends StateNotifier<Set<String>> {
  UsualCartNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (!SupabaseConfig.isConfigured || userId == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('usual_cart_items')
          .select('product_id')
          .eq('customer_id', userId);
      state = {for (final r in rows) r['product_id'] as String};
    } catch (_) {
      // Table pas encore créée côté Supabase, ou hors ligne — liste vide
      // plutôt que de faire planter l'écran.
    }
  }

  bool contains(String productId) => state.contains(productId);

  /// Bascule la présence d'un produit dans le panier habituel, avec mise
  /// à jour optimiste (annulée si l'appel Supabase échoue). Un nouvel
  /// ajout démarre à quantité 1 — modifiable ensuite depuis
  /// `UsualCartScreen`.
  Future<void> toggle(String productId) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    final wasIn = state.contains(productId);

    state = wasIn
        ? (state.where((id) => id != productId).toSet())
        : ({...state, productId});

    try {
      if (wasIn) {
        await SupabaseConfig.client
            .from('usual_cart_items')
            .delete()
            .eq('customer_id', userId)
            .eq('product_id', productId);
      } else {
        await SupabaseConfig.client.from('usual_cart_items').insert({
          'customer_id': userId,
          'product_id': productId,
        });
      }
    } catch (_) {
      state = wasIn
          ? ({...state, productId})
          : (state.where((id) => id != productId).toSet());
    }
  }
}

final usualCartProvider =
    StateNotifierProvider<UsualCartNotifier, Set<String>>((ref) {
  return UsualCartNotifier();
});
