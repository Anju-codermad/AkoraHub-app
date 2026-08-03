import '../supabase/supabase_config.dart';

/// Activation/désactivation de la bulle de chat flottante (voir
/// supabase/phase68_patch_chat_bubble_toggle.sql) — deux réglages
/// indépendants, comme demandé par l'utilisateur ("les deux côtés
/// peuvent choisir ce qu'ils veulent") :
/// - un interrupteur **global** côté admin (`company_settings`, visible
///   depuis `business_profile_settings.dart`) qui coupe la bulle pour
///   TOUS les clients ;
/// - un interrupteur **personnel** côté client (`profiles.hide_chat_bubble`,
///   visible depuis `settings_screen.dart`) qui la cache juste pour lui.
/// La bulle ne s'affiche que si les deux l'autorisent.
class ChatBubbleSettingsRepo {
  ChatBubbleSettingsRepo._();

  static Future<bool> isEnabledGlobally() async {
    if (!SupabaseConfig.isConfigured) return true;
    try {
      final row = await SupabaseConfig.client
          .from('app_feature_flags')
          .select('floating_chat_bubble_enabled')
          .maybeSingle();
      return row?['floating_chat_bubble_enabled'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> setEnabledGlobally(bool enabled) async {
    await SupabaseConfig.client.from('company_settings').upsert({
      'id': 1,
      'floating_chat_bubble_enabled': enabled,
    });
  }

  static Future<bool> isHiddenByClient() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return false;
    try {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select('hide_chat_bubble')
          .eq('id', userId)
          .maybeSingle();
      return row?['hide_chat_bubble'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setHiddenByClient(bool hidden) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseConfig.client
        .from('profiles')
        .update({'hide_chat_bubble': hidden}).eq('id', userId);
  }
}
