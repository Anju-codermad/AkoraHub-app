import '../supabase/supabase_config.dart';

/// Accès à l'abonnement Formation du client courant (voir
/// supabase/phase40_schema.sql) — donne accès aux fiches détaillées de
/// matières premières moyennant un abonnement payant, validé manuellement
/// par le staff (même modèle que les commandes : référence + preuve de
/// paiement, voir phase29).
class FormationRepo {
  FormationRepo._();

  /// Dernier abonnement (le plus récent) du client connecté, quel que
  /// soit son statut — `null` s'il n'en a jamais demandé.
  static Future<Map<String, dynamic>?> fetchMySubscription() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return null;
    try {
      final rows = await SupabaseConfig.client
          .from('formation_subscriptions')
          .select()
          .eq('customer_id', userId)
          .order('created_at', ascending: false)
          .limit(1);
      final list = List<Map<String, dynamic>>.from(rows);
      return list.isEmpty ? null : list.first;
    } catch (_) {
      return null;
    }
  }

  static bool isActive(Map<String, dynamic>? subscription) {
    if (subscription == null) return false;
    if (subscription['status'] != 'actif') return false;
    final expiresAt = subscription['expires_at'] as String?;
    if (expiresAt == null) return true;
    return DateTime.parse(expiresAt).isAfter(DateTime.now());
  }

  static Future<List<Map<String, dynamic>>> fetchPlanPricing() async {
    if (!SupabaseConfig.isConfigured) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('formation_plan_pricing')
          .select()
          .order('price');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  static Future<void> requestSubscription({
    required String plan,
    required num amount,
    required String paymentMethodId,
    String? paymentReference,
    String? paymentProofPath,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non connecté.');
    await SupabaseConfig.client.from('formation_subscriptions').insert({
      'customer_id': userId,
      'plan': plan,
      'amount': amount,
      'payment_method': paymentMethodId,
      'payment_reference': paymentReference,
      'payment_proof_path': paymentProofPath,
    });
  }
}
