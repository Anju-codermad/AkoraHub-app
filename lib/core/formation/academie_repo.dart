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
  ///
  /// Depuis le 06/08 (phase85) : inclut aussi les pictogrammes SGH et
  /// phrases H/P sélectionnés (jointure vers les tables catalogue pour
  /// récupérer directement code/nom/texte, pas juste les ids) — ces 3
  /// requêtes sont en repli tolérant (try/catch séparé) pour ne pas
  /// bloquer l'affichage du reste de la fiche si phase85/86 n'est pas
  /// encore exécuté.
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

      List<Map<String, dynamic>> pictograms = [];
      List<Map<String, dynamic>> phrasesH = [];
      List<Map<String, dynamic>> phrasesP = [];
      try {
        final linkResults = await Future.wait<dynamic>([
          SupabaseConfig.client
              .from('academie_pictograms')
              .select('danger_pictograms(*)')
              .eq('academie_id', sheet['id']),
          SupabaseConfig.client
              .from('academie_phrases_h')
              .select('phrases_h(*)')
              .eq('academie_id', sheet['id']),
          SupabaseConfig.client
              .from('academie_phrases_p')
              .select('phrases_p(*)')
              .eq('academie_id', sheet['id']),
        ]);
        pictograms = List<Map<String, dynamic>>.from(linkResults[0] as List)
            .map((r) => r['danger_pictograms'] as Map<String, dynamic>)
            .toList();
        phrasesH = List<Map<String, dynamic>>.from(linkResults[1] as List)
            .map((r) => r['phrases_h'] as Map<String, dynamic>)
            .toList();
        phrasesP = List<Map<String, dynamic>>.from(linkResults[2] as List)
            .map((r) => r['phrases_p'] as Map<String, dynamic>)
            .toList();
      } catch (_) {}

      return {
        ...sheet,
        'usages': List<Map<String, dynamic>>.from(usages),
        'pictograms': pictograms,
        'phrases_h': phrasesH,
        'phrases_p': phrasesP,
      };
    } catch (_) {
      return null;
    }
  }
}
