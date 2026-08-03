import '../supabase/supabase_config.dart';

/// Accès "Demandes de service" côté client (onglet "Services", voir
/// supabase/phase65_patch_service_requests.sql) — distinct d'une commande
/// de produit ou d'un devis : le client décrit un besoin (installation,
/// intervention, consultation...) que le staff traite manuellement, pas
/// de tarification automatique.
class ServiceRequestRepo {
  ServiceRequestRepo._();

  static Future<List<Map<String, dynamic>>> fetchMine() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return [];
    final rows = await SupabaseConfig.client
        .from('service_requests')
        .select('*, business_units(name)')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> submit({
    required String businessUnitId,
    required String title,
    required String description,
    DateTime? preferredDate,
    String? address,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Non connecté.');
    await SupabaseConfig.client.from('service_requests').insert({
      'customer_id': userId,
      'business_unit_id': businessUnitId,
      'title': title,
      'description': description,
      if (preferredDate != null)
        'preferred_date': preferredDate.toIso8601String().split('T').first,
      if (address != null && address.isNotEmpty) 'address': address,
    });
  }
}
