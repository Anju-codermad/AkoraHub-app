import '../supabase/supabase_config.dart';
import 'payment_methods.dart';

/// Charge/modifie l'activation de chaque mode de paiement, contrôlée par
/// l'Admin (`payment_method_settings`, voir
/// supabase/phase28_patch_payment_method_settings.sql). Tolérant : si la
/// table n'existe pas encore (migration pas exécutée) ou en cas d'échec
/// réseau, tous les modes sont considérés actifs par défaut plutôt que de
/// bloquer le checkout.
class PaymentMethodSettingsRepo {
  PaymentMethodSettingsRepo._();

  static Future<Set<PaymentMethod>> fetchEnabled() async {
    if (!SupabaseConfig.isConfigured) {
      return PaymentMethod.values.toSet();
    }
    try {
      final rows = await SupabaseConfig.client
          .from('payment_method_settings')
          .select('method_id, enabled');
      final disabledIds = <String>{
        for (final row in rows)
          if (row['enabled'] == false) row['method_id'] as String,
      };
      return PaymentMethod.values
          .where((m) => !disabledIds.contains(m.id))
          .toSet();
    } catch (_) {
      return PaymentMethod.values.toSet();
    }
  }

  static Future<void> setEnabled(PaymentMethod method, bool enabled) async {
    await SupabaseConfig.client.from('payment_method_settings').upsert({
      'method_id': method.id,
      'enabled': enabled,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
