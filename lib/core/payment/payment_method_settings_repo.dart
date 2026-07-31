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

  /// Réglage spécial (pas un `PaymentMethod`, voir
  /// supabase/phase38_patch_papi_payment.sql) : quand activé, Mvola/
  /// Orange Money/Airtel Money reviennent au flux manuel historique
  /// (référence + photo) au lieu du paiement en ligne automatique via
  /// Papi — utile en secours si Papi est indisponible. Désactivé par
  /// défaut (le paiement Papi est le comportement normal).
  static const manualFallbackId = 'manuel_fallback';

  static Future<bool> isManualFallbackEnabled() async {
    if (!SupabaseConfig.isConfigured) return false;
    try {
      final row = await SupabaseConfig.client
          .from('payment_method_settings')
          .select('enabled')
          .eq('method_id', manualFallbackId)
          .maybeSingle();
      return row?['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setManualFallbackEnabled(bool enabled) async {
    await SupabaseConfig.client.from('payment_method_settings').upsert({
      'method_id': manualFallbackId,
      'enabled': enabled,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
