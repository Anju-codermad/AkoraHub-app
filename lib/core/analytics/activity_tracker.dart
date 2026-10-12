import '../supabase/supabase_config.dart';

/// Mesure des utilisateurs actifs directement dans l'app (12/10, demande
/// explicite) — complète `AnalyticsService` (Firebase, lisible seulement
/// depuis la Firebase Console) avec une donnée gratuite et consultable
/// directement dans l'Admin : `profiles.last_active_at` (phase263),
/// mise à jour à chaque ouverture de l'app.
///
/// Distinct de `PresenceHelper.touch()` (last_seen_at) : celui-ci ne
/// sert qu'au statut "En ligne" de la messagerie, mis à jour seulement
/// pendant qu'un écran de chat reste ouvert — pas représentatif de
/// l'usage réel de l'app.
class ActivityTracker {
  /// Marque l'utilisateur courant comme actif maintenant. Best-effort,
  /// ne doit jamais bloquer ni faire planter le démarrage de l'app.
  static Future<void> touch() async {
    if (!SupabaseConfig.isConfigured) return;
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'last_active_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (_) {}
  }
}
