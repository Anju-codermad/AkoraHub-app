import '../supabase/supabase_config.dart';

/// "M'alerter quand disponible" (06/08) — un client s'abonne à un produit
/// en rupture de stock et reçoit une notification push dès qu'il repasse
/// en stock (voir supabase/phase77_patch_product_stock_alerts.sql, trigger
/// `on_product_back_in_stock`). Même pattern que
/// `CategorySubscriptionRepo`, mais consommé côté serveur après
/// notification (un client doit se réabonner s'il veut être alerté au
/// prochain retour en stock).
class ProductStockAlertRepo {
  ProductStockAlertRepo._();

  static Future<bool> isSubscribed(String productId) async {
    if (!SupabaseConfig.isConfigured) return false;
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final row = await SupabaseConfig.client
          .from('product_stock_alerts')
          .select('id')
          .eq('customer_id', userId)
          .eq('product_id', productId)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> subscribe(String productId) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseConfig.client.from('product_stock_alerts').insert({
      'customer_id': userId,
      'product_id': productId,
    });
  }

  static Future<void> unsubscribe(String productId) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseConfig.client
        .from('product_stock_alerts')
        .delete()
        .eq('customer_id', userId)
        .eq('product_id', productId);
  }
}
