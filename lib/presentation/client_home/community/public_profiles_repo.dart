import '../../../core/supabase/supabase_config.dart';

/// Récupère des infos publiques "légères" (nom, société, secteur, avatar)
/// sur d'autres clients, via la vue `public_profiles`
/// (supabase/phase9_patch_public_profiles.sql) qui contourne la RLS
/// restrictive de `profiles` (laquelle ne laisse un client lire que sa
/// propre ligne — voir le commentaire en tête de cette migration).
///
/// Utilisé par le Mur, les commentaires, et l'écran de profil public
/// pour afficher correctement le nom des AUTRES clients (pas seulement
/// le sien), avec repli silencieux si la migration n'est pas encore
/// appliquée.
class PublicProfilesRepo {
  PublicProfilesRepo._();

  static final Map<String, Map<String, dynamic>> _cache = {};

  /// Retourne les profils déjà en cache pour [ids], et complète le cache
  /// en base pour les identifiants manquants. Ne lève jamais d'exception :
  /// en cas d'échec (migration absente, hors-ligne...), retourne ce qui
  /// est disponible en cache (potentiellement vide) et l'appelant garde
  /// son repli habituel ("Utilisateur").
  static Future<Map<String, Map<String, dynamic>>> fetchByIds(
      Iterable<String> ids) async {
    final idSet = ids.toSet();
    final missing =
        idSet.where((id) => !_cache.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      try {
        final data = await SupabaseConfig.client
            .from('public_profiles')
            .select()
            .inFilter('id', missing);
        for (final row in List<Map<String, dynamic>>.from(data)) {
          _cache[row['id'] as String] = row;
        }
      } catch (_) {
        // Repli silencieux : vue pas encore migrée ou hors-ligne.
      }
    }
    return {
      for (final id in idSet)
        if (_cache.containsKey(id)) id: _cache[id]!,
    };
  }

  /// Nom d'affichage pour un profil déjà résolu par [fetchByIds] :
  /// société si renseignée, sinon nom complet, sinon "Utilisateur".
  static String displayName(Map<String, dynamic>? profile) {
    if (profile == null) return 'Utilisateur';
    final company = (profile['company_name'] as String?)?.trim();
    if (company != null && company.isNotEmpty) return company;
    final name = (profile['full_name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Utilisateur';
  }
}
