import '../supabase/supabase_config.dart';

/// Génère un paiement FiveOne Pay pour une commande (voir
/// supabase/functions/create-fiveonepay-payment-link) — la clé API
/// FiveOne Pay ne doit jamais être présente côté client. Même forme de
/// réponse que PapiPaymentRepo (`paymentLink`) pour que payment_screen.dart
/// puisse traiter les deux fournisseurs de façon identique côté UI.
class FiveOnePayPaymentRepo {
  FiveOnePayPaymentRepo._();

  static Future<String> createPaymentLink(String orderId) async {
    final response = await SupabaseConfig.client.functions.invoke(
      'create-fiveonepay-payment-link',
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
