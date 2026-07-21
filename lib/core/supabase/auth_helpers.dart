import 'supabase_config.dart';

/// Détermine où rediriger un utilisateur après connexion/inscription,
/// selon son rôle (staff -> Espace Admin, client -> Espace Client).
class AuthRouting {
  AuthRouting._();

  static Future<String> homeRouteForCurrentUser() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return '/authentication-screen';

    try {
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      final role = profile['role'] as String?;
      if (role != null && role != 'client') {
        return '/business-dashboard';
      }
      return '/client-home';
    } catch (_) {
      // Par défaut, en cas d'erreur réseau/lecture, on considère l'utilisateur
      // comme client (comportement le moins privilégié, donc le plus sûr).
      return '/client-home';
    }
  }
}
