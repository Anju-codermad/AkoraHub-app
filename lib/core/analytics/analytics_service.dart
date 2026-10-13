import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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
///
/// ⚠️ Tout ici est paresseux et défensif (13/10, correctif) : accéder à
/// `FirebaseAnalytics.instance` avant que `Firebase.initializeApp()` ne
/// soit terminé fait planter l'app au tout premier écran (écran noir
/// indéfini constaté par la propriétaire juste après l'ajout de ce
/// service — `PushNotificationService.initialize()` appelle
/// `Firebase.initializeApp()` mais SANS "await" dans `main()`, pour ne
/// pas retarder le premier écran ; `MyApp.build()` s'exécutait donc
/// souvent avant que Firebase soit prêt). Plus aucun accès à
/// `FirebaseAnalytics.instance` ne doit avoir lieu tant que
/// `Firebase.apps` est vide.
class AnalyticsService {
  AnalyticsService._();

  static bool get _isReady => Firebase.apps.isNotEmpty;

  static FirebaseAnalytics? _instance;
  static FirebaseAnalytics? get _instanceOrNull {
    if (!_isReady) return null;
    return _instance ??= FirebaseAnalytics.instance;
  }

  static FirebaseAnalyticsObserver? _observer;

  /// À ajouter à `navigatorObservers` du `MaterialApp` — envoie
  /// automatiquement un événement `screen_view` à chaque changement
  /// d'écran, utile à la fois pour les utilisateurs actifs et pour
  /// construire des audiences par écran visité. Liste vide (pas
  /// d'observer) tant que Firebase n'est pas prêt — à inclure avec
  /// l'opérateur de décomposition (`...AnalyticsService.observers`).
  static List<NavigatorObserver> get observers {
    final analytics = _instanceOrNull;
    if (analytics == null) return const [];
    _observer ??= FirebaseAnalyticsObserver(analytics: analytics);
    return [_observer!];
  }

  /// Associe les événements analytics à l'utilisateur Supabase connecté
  /// (ou les détache à la déconnexion, `userId: null`) — sans ça,
  /// Firebase ne peut compter que des appareils, pas des personnes
  /// identifiées. `role` (client/commercial/admin...) devient une
  /// propriété utilisateur ("user_role"), utilisable pour filtrer les
  /// statistiques ou créer une audience par rôle.
  ///
  /// Non bloquant et sans effet si Analytics n'est pas disponible
  /// (google-services.json absent en build de dev, Firebase pas encore
  /// initialisé, etc.) — ne doit jamais perturber le flux de
  /// connexion/déconnexion.
  static Future<void> setUser({required String? userId, String? role}) async {
    final analytics = _instanceOrNull;
    if (analytics == null) return;
    try {
      await analytics.setUserId(id: userId);
      if (role != null && role.isNotEmpty) {
        await analytics.setUserProperty(name: 'user_role', value: role);
      }
    } catch (_) {}
  }
}
