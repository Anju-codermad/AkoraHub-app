import '../supabase/supabase_config.dart';

/// Fiche technique "Académie Matières Premières" (voir
/// supabase/phase81_patch_academie_matieres_premieres.sql) — contenu
/// avancé (nom chimique, grade, pH, EPI, premiers secours,
/// incompatibilités, dosages précis par domaine d'application...) sur
/// la fiche d'une matière première déjà achetée.
///
/// Depuis le 06/08 (phase83) : plus d'achat séparé — avoir acheté la
/// fiche produit (`FormationRepo`/`formation_purchases`) donne
/// automatiquement accès à cette fiche technique aussi (la RLS de
/// `matieres_premieres_academie`/`matieres_premieres_usages` utilise
/// désormais `has_purchased_raw_material`, voir
/// phase83_patch_fusion_academie_matieres.sql).
class AcademieRepo {
  AcademieRepo._();

  /// Fiche technique Académie d'une matière première (null si pas
  /// encore créée par le staff, ou si l'utilisateur n'a pas acheté la
  /// fiche produit — la RLS bloque déjà la lecture, un retour vide côté
  /// client suffit pour afficher un message d'attente).
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
