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

  /// Réglages vus par le CLIENT au moment de payer (23/11, voir
  /// supabase/phase309_patch_airtel_wallet_marchand.sql) : en plus de
  /// `enabled`, l'Admin peut désactiver le paiement manuel d'un moyen
  /// (`manual_enabled`) et personnaliser les coordonnées affichées
  /// (`manual_instructions`) depuis groupe-akora.com/admin-paiements. Dans
  /// l'App, tous les moyens sauf le paiement à la livraison sont manuels :
  /// un moyen dont le manuel est désactivé n'est donc pas proposé.
  /// Tolérant comme [fetchEnabled] : patch pas encore exécuté -> lecture
  /// de `enabled` seul ; échec réseau -> tous les modes proposés.
  static Future<PaymentClientSettings> fetchClientSettings() async {
    final all = PaymentMethod.values.toSet();
    if (!SupabaseConfig.isConfigured) {
      return PaymentClientSettings(available: all);
    }
    try {
      List<Map<String, dynamic>> rows;
      try {
        rows = await SupabaseConfig.client
            .from('payment_method_settings')
            .select('method_id, enabled, manual_enabled, manual_instructions');
      } catch (_) {
        rows = await SupabaseConfig.client
            .from('payment_method_settings')
            .select('method_id, enabled');
      }
      final byId = {for (final row in rows) row['method_id'] as String: row};
      final available = <PaymentMethod>{};
      final custom = <PaymentMethod, String>{};
      for (final m in PaymentMethod.values) {
        final row = byId[m.id];
        if (row == null) {
          available.add(m);
          continue;
        }
        if (row['enabled'] == false) continue;
        if (m != PaymentMethod.paiementLivraison &&
            row['manual_enabled'] == false) {
          continue;
        }
        available.add(m);
        final text = (row['manual_instructions'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) custom[m] = text;
      }
      return PaymentClientSettings(available: available, customInstructions: custom);
    } catch (_) {
      return PaymentClientSettings(available: all);
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

/// Ce que le client peut utiliser pour payer, d'après les réglages Admin.
class PaymentClientSettings {
  final Set<PaymentMethod> available;
  final Map<PaymentMethod, String> customInstructions;

  const PaymentClientSettings({
    required this.available,
    this.customInstructions = const {},
  });

  /// Coordonnées à afficher : celles saisies par l'Admin, sinon le texte
  /// par défaut de [PaymentMethodX.instructions].
  String? instructionsFor(PaymentMethod method) =>
      method.instructions == null
          ? null
          : (customInstructions[method] ?? method.instructions);
}
