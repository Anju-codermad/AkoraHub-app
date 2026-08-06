import '../supabase/supabase_config.dart';

/// Accès "Académie Matières Premières" (voir
/// supabase/phase81_patch_academie_matieres_premieres.sql) — achat payant
/// DISTINCT de l'achat de la fiche produit (`FormationRepo`), produit par
/// produit, à vie, tarif dégressif propre. Débloque le second onglet
/// "Académie" (fiche technique complète) sur la fiche d'une matière
/// première déjà achetée. L'achat lui-même se fait sur la page web
/// externe (docs/formation-access/index.html, onglet "Académie"), pas
/// dans l'app — conformité Google Play, même principe que Formation et
/// Cours.
class AcademieRepo {
  AcademieRepo._();

  /// IDs des matières premières dont l'Académie est déjà débloquée
  /// (achat validé) par le client connecté.
  static Future<Set<String>> fetchMyPurchasedIds() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return {};
    try {
      final rows = await SupabaseConfig.client
          .from('academie_purchases')
          .select('raw_material_id')
          .eq('customer_id', userId)
          .eq('status', 'validee');
      return List<Map<String, dynamic>>.from(rows)
          .map((r) => r['raw_material_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// IDs déjà demandés mais pas encore validés par le staff.
  static Future<Set<String>> fetchMyPendingIds() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return {};
    try {
      final rows = await SupabaseConfig.client
          .from('academie_purchases')
          .select('raw_material_id')
          .eq('customer_id', userId)
          .eq('status', 'en_attente');
      return List<Map<String, dynamic>>.from(rows)
          .map((r) => r['raw_material_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// Fiche technique Académie d'une matière première (null si pas encore
  /// créée par le staff) + ses usages détaillés, triés. La RLS bloque déjà
  /// la lecture sans achat validé — un retour vide côté client (plutôt
  /// qu'une exception) suffit pour afficher le CTA d'achat.
  static Future<Map<String, dynamic>?> fetchSheet(String rawMaterialId) async {
    try {
      final sheet = await SupabaseConfig.client
          .from('matieres_premieres_academie')
          .select()
          .eq('matiere_premiere_id', rawMaterialId)
          .maybeSingle();
      if (sheet == null) return null;
      final usages = await SupabaseConfig.client
          .from('matieres_premieres_usages')
          .select()
          .eq('academie_id', sheet['id'])
          .order('ordre');
      return {
        ...sheet,
        'usages': List<Map<String, dynamic>>.from(usages),
      };
    } catch (_) {
      return null;
    }
  }
}
