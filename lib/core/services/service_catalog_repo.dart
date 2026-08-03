import '../supabase/supabase_config.dart';

/// Catalogue de services proposés (voir
/// supabase/phase66_patch_service_catalog.sql) : catégories + services,
/// chacun activable/désactivable depuis l'admin. Un client ne voit que les
/// services `available = true` (RLS) ; le staff voit tout pour pouvoir
/// gérer le catalogue.
class ServiceCatalogRepo {
  ServiceCatalogRepo._();

  /// Catégories avec leurs services imbriqués, triées par `sort_order`.
  /// [onlyAvailable] filtre les services non disponibles (utilisé côté
  /// client) — les catégories qui n'ont alors plus aucun service sont
  /// retirées du résultat.
  static Future<List<Map<String, dynamic>>> fetchCategoriesWithItems({
    bool onlyAvailable = true,
  }) async {
    final categories = await SupabaseConfig.client
        .from('service_categories')
        .select()
        .order('sort_order');
    final items = await SupabaseConfig.client
        .from('service_catalog_items')
        .select()
        .order('sort_order');

    final itemsByCategory = <String, List<Map<String, dynamic>>>{};
    for (final item in List<Map<String, dynamic>>.from(items)) {
      if (onlyAvailable && item['available'] != true) continue;
      itemsByCategory
          .putIfAbsent(item['category_id'] as String, () => [])
          .add(item);
    }

    final result = <Map<String, dynamic>>[];
    for (final category in List<Map<String, dynamic>>.from(categories)) {
      final categoryItems = itemsByCategory[category['id']] ?? [];
      if (onlyAvailable && categoryItems.isEmpty) continue;
      result.add({...category, 'items': categoryItems});
    }
    return result;
  }

  static Future<void> createCategory(String name) async {
    await SupabaseConfig.client
        .from('service_categories')
        .insert({'name': name});
  }

  static Future<void> renameCategory(String id, String name) async {
    await SupabaseConfig.client
        .from('service_categories')
        .update({'name': name}).eq('id', id);
  }

  static Future<void> deleteCategory(String id) async {
    await SupabaseConfig.client
        .from('service_categories')
        .delete()
        .eq('id', id);
  }

  static Future<void> createItem({
    required String categoryId,
    required String name,
    String? description,
  }) async {
    await SupabaseConfig.client.from('service_catalog_items').insert({
      'category_id': categoryId,
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
  }

  static Future<void> updateItem({
    required String id,
    required String name,
    String? description,
  }) async {
    await SupabaseConfig.client.from('service_catalog_items').update({
      'name': name,
      'description': description,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> setAvailable(String id, bool available) async {
    await SupabaseConfig.client.from('service_catalog_items').update({
      'available': available,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> deleteItem(String id) async {
    await SupabaseConfig.client
        .from('service_catalog_items')
        .delete()
        .eq('id', id);
  }
}
