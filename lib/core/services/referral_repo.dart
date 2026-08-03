import '../supabase/supabase_config.dart';

/// Programme de parrainage (voir supabase/phase67_patch_referral_program.sql)
/// : chaque compte a un code unique généré automatiquement à
/// l'inscription. Volontairement **pas de récompense automatique** —
/// juste un suivi parrain/filleul, le staff décide manuellement quoi
/// offrir en dehors de l'app.
class ReferralRepo {
  ReferralRepo._();

  static Future<String?> fetchMyCode() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return null;
    final row = await SupabaseConfig.client
        .from('profiles')
        .select('referral_code')
        .eq('id', userId)
        .maybeSingle();
    return row?['referral_code'] as String?;
  }

  /// Filleuls (comptes créés avec mon code) — plus récents d'abord.
  static Future<List<Map<String, dynamic>>> fetchMyReferrals() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return [];
    final rows = await SupabaseConfig.client
        .from('public_profiles')
        .select('id, full_name, company_name, avatar_url, created_at')
        .eq('referred_by', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Résout un code de parrainage saisi à l'inscription en id de compte
  /// parrain — renvoie `null` si le code n'existe pas.
  static Future<String?> resolveCode(String code) async {
    if (code.trim().isEmpty || !SupabaseConfig.isConfigured) return null;
    final result = await SupabaseConfig.client
        .rpc('resolve_referral_code', params: {'p_code': code.trim()});
    return result as String?;
  }
}
