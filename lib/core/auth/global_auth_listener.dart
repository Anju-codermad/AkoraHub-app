import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../supabase/auth_helpers.dart';
import '../supabase/supabase_config.dart';

/// Écoute de connexion active pendant toute la durée de vie de l'app —
/// pas seulement quand l'écran de connexion est affiché.
///
/// Nécessaire pour la connexion Google : le retour du navigateur externe
/// peut arriver après qu'Android a tué le processus Flutter en arrière-plan
/// (l'app redémarre alors froid sur `SplashScreen`). `SplashScreen` vérifie
/// `currentSession` avant que l'échange PKCE du lien de redirection (appel
/// réseau asynchrone) ne soit terminé, donc elle ne voit pas encore de
/// session et affiche l'écran de connexion — dont l'écouteur local, monté
/// après coup, arrive trop tard pour l'événement `signedIn` qui suit.
/// Cet écouteur global, actif dès `main()`, ne rate jamais cet événement
/// quel que soit l'écran affiché au moment où l'échange se termine.
class GlobalAuthListener {
  GlobalAuthListener._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final routeObserver = _RouteNameTracker();
  static bool _listening = false;

  static const _preAuthRoutes = {
    '/',
    '/splash-screen',
    '/authentication-screen',
    '/onboarding-flow',
  };

  static bool _isOnPreAuthRoute() {
    final name = routeObserver.currentRouteName;
    return name == null || _preAuthRoutes.contains(name);
  }

  static void init() {
    if (_listening || !SupabaseConfig.isConfigured) return;
    _listening = true;
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        // Lien "Mot de passe oublié" ouvert (email) — même situation que
        // le retour OAuth : peut arriver après un redémarrage à froid,
        // donc on navigue depuis cet écouteur global plutôt que depuis un
        // écran qui ne serait peut-être plus monté. Sans condition de
        // route pré-connexion : ce lien peut s'ouvrir depuis n'importe où.
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil(AppRoutes.resetPassword, (r) => false);
        return;
      }
      if (data.event != AuthChangeEvent.signedIn) return;
      if (!_isOnPreAuthRoute()) return;
      final route = await AuthRouting.homeRouteForCurrentUser();
      // Revérifie après l'appel réseau : si authentication_screen (encore
      // montée et déjà en train d'écouter) a navigué entre-temps, on évite
      // de naviguer une seconde fois par-dessus.
      if (!_isOnPreAuthRoute()) return;
      navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (r) => false);
    });
  }
}

/// Garde en mémoire le nom de la route actuellement affichée, pour que
/// [GlobalAuthListener] sache si l'app est encore sur un écran "pré-connexion"
/// (splash/auth/onboarding) ou déjà à l'intérieur (client/admin).
class _RouteNameTracker extends NavigatorObserver {
  String? currentRouteName;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRouteName = route.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    currentRouteName = newRoute?.settings.name ?? currentRouteName;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRouteName = previousRoute?.settings.name;
  }
}
