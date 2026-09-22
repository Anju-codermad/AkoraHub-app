import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_config.dart';

/// Interrupteur global "Stock géré par ComptivA" (22/09/2026, demande
/// explicite) — voir supabase/phase246_patch_stock_managed_externally.sql.
/// Une fois activé, le stock réel n'est plus suivi dans AkoraHub (géré
/// dans le logiciel de comptabilité ComptivA, synchronisé séparément
/// via phase245_patch_sync_stock_comptiva.sql) : l'app arrête de
/// bloquer les commandes ou d'afficher "rupture de stock"/"stock bas"
/// à partir de `products.stock_quantity`, qui devient une donnée non
/// fiable à ne plus utiliser côté client. Même modèle (colonne à part
/// de `data` sur `company_settings`, exposée en lecture via la vue
/// `app_feature_flags`) que `ChatBubbleSettingsRepo`.
class StockSettingsRepo {
  StockSettingsRepo._();

  static Future<bool> isManagedExternally() async {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      final row = await SupabaseConfig.client
          .from('app_feature_flags')
          .select('stock_managed_externally')
          .maybeSingle();
      return row?['stock_managed_externally'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setManagedExternally(bool managedExternally) async {
    await SupabaseConfig.client.from('company_settings').upsert({
      'id': 1,
      'stock_managed_externally': managedExternally,
    });
  }
}

/// Cache mémoire (durée de vie du provider, pas de TTL — ce réglage
/// change rarement) pour éviter une requête à chaque `ProductCard`
/// affichée dans une grille catalogue.
final stockManagedExternallyProvider = FutureProvider<bool>(
  (ref) => StockSettingsRepo.isManagedExternally(),
);
