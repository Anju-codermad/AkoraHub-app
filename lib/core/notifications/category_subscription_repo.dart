import '../supabase/supabase_config.dart';

/// Abonnement d'un client à une catégorie précise d'un pilier — reçoit
/// une notification push quand un nouveau produit y est ajouté (voir
/// supabase/phase36_patch_product_category_subscriptions.sql + le
/// trigger `on_new_product_push`). RLS : chacun ne voit/gère que ses
/// propres abonnements.
class CategorySubscriptionRepo {
  CategorySubscriptionRepo._();

  static Future<bool> isSubscribed(
      String businessUnitId, String categoryName) async {
    if (!SupabaseConfig.isConfigured) return false;
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final row = await SupabaseConfig.client
          .from('product_category_subscriptions')
          .select('id')
          .eq('customer_id', userId)
          .eq('business_unit_id', businessUnitId)
          .eq('category_name', categoryName)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> subscribe(
      String businessUnitId, String categoryName) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseConfig.client.from('product_category_subscriptions').insert({
      'customer_id': userId,
      'business_unit_id': businessUnitId,
      'category_name': categoryName,
    });
  }

  static Future<void> unsubscribe(
      String businessUnitId, String categoryName) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseConfig.client
        .from('product_category_subscriptions')
        .delete()
        .eq('customer_id', userId)
        .eq('business_unit_id', businessUnitId)
        .eq('category_name', categoryName);
  }
}
