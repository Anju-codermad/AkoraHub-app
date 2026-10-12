import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics — demande explicite de la propriétaire (12/10) :
/// savoir combien de personnes utilisent l'app souvent (utilisateurs
/// actifs) et pouvoir créer des audiences (segments d'utilisateurs).
///
/// Une fois cette collecte active, Firebase calcule automatiquement les
/// utilisateurs actifs sur 1/7/28 jours (Firebase Console -> Analytics ->
/// Utilisateurs actifs) à partir des événements `session_start`/
/// `user_engagement` déjà envoyés automatiquement par le SDK — aucun
/// événement personnalisé n'est nécessaire pour ça. Les "Audiences"
/// (Firebase Console -> Audiences) se configurent entièrement côté
/// Firebase, à partir des événements/propriétés collectés ici
/// (ex. `user_role`) : rien d'autre à coder dans l'app pour les créer.
///
/// ⚠️ Nécessite que Google Analytics soit lié au projet Firebase
/// (Firebase Console -> Paramètres du projet -> Intégrations -> Google
/// Analytics). Si ce n'est pas déjà le cas, les événements sont tout de
/// même envoyés mais n'apparaîtront dans aucun tableau de bord tant que
/// le lien n'est pas fait.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics instance = FirebaseAnalytics.instance;

  /// À ajouter à `navigatorObservers` du `MaterialApp` — envoie
  /// automatiquement un événement `screen_view` à chaque changement
  /// d'écran, utile à la fois pour les utilisateurs actifs et pour
  /// construire des audiences par écran visité.
  static final FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: instance);

  /// Associe les événements analytics à l'utilisateur Supabase connecté
  /// (ou les détache à la déconnexion, `userId: null`) — sans ça,
  /// Firebase ne peut compter que des appareils, pas des personnes
  /// identifiées. `role` (client/commercial/admin...) devient une
  /// propriété utilisateur ("user_role"), utilisable pour filtrer les
  /// statistiques ou créer une audience par rôle.
  ///
  /// Non bloquant et sans effet si Analytics n'est pas disponible
  /// (google-services.json absent en build de dev, etc.) — ne doit
  /// jamais perturber le flux de connexion/déconnexion.
  static Future<void> setUser({required String? userId, String? role}) async {
    try {
      await instance.setUserId(id: userId);
      if (role != null && role.isNotEmpty) {
        await instance.setUserProperty(name: 'user_role', value: role);
      }
    } catch (_) {}
  }
}
