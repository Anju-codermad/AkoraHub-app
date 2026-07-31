import '../supabase/supabase_config.dart';

/// Génère un lien de paiement Papi.mg pour une commande (voir
/// supabase/functions/create-papi-payment-link) — la clé API Papi ne
/// doit jamais être présente côté client.
class PapiPaymentRepo {
  PapiPaymentRepo._();

  static Future<String> createPaymentLink(String orderId) async {
    final response = await SupabaseConfig.client.functions.invoke(
      'create-papi-payment-link',
      body: {'orderId': orderId},
    );
    final data = response.data as Map;
    final link = data['paymentLink'] as String?;
    if (link == null) {
      throw Exception(
          data['error'] as String? ?? 'Lien de paiement indisponible');
    }
    return link;
  }
}
