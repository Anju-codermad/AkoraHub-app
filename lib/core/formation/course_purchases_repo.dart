import '../supabase/supabase_config.dart';

/// Accès Formation "achat de cours AkoraFormation" (voir
/// supabase/phase50_patch_course_purchases_and_content.sql) — distinct de
/// FormationRepo (matières premières). Paiement manuel (référence +
/// preuve), validé par le staff, via la page web externe
/// (web/formation-access) pour rester conforme aux règles Google Play sur
/// le contenu numérique.
class CoursePurchasesRepo {
  CoursePurchasesRepo._();

  /// IDs des cours déjà achetés (validés) par le client connecté.
  static Future<Set<String>> fetchMyPurchasedCourseIds() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return {};
    try {
      final rows = await SupabaseConfig.client
          .from('course_purchases')
          .select('course_id')
          .eq('customer_id', userId)
          .eq('status', 'validee');
      return List<Map<String, dynamic>>.from(rows)
          .map((r) => r['course_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// IDs des cours déjà demandés mais pas encore validés.
  static Future<Set<String>> fetchMyPendingCourseIds() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return {};
    try {
      final rows = await SupabaseConfig.client
          .from('course_purchases')
          .select('course_id')
          .eq('customer_id', userId)
          .eq('status', 'en_attente');
      return List<Map<String, dynamic>>.from(rows)
          .map((r) => r['course_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// Historique complet des demandes d'achat de cours du client connecté
  /// (tous statuts), avec le titre du cours — pour l'écran "Mes accès".
  static Future<List<Map<String, dynamic>>> fetchMyCoursePurchases() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('course_purchases')
          .select('*, formation_courses(title, category)')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  /// Modules réels (vidéo/document/texte) d'un cours — la RLS ne renvoie
  /// des lignes que si l'achat est validé (ou pour le staff) : un client
  /// non-acheteur reçoit simplement une liste vide, jamais les URLs.
  static Future<List<Map<String, dynamic>>> fetchCourseModules(
      String courseId) async {
    if (!SupabaseConfig.isConfigured) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('formation_course_modules')
          .select()
          .eq('course_id', courseId)
          .order('sort_order');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }
}
