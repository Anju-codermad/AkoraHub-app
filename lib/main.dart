import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sizer/sizer.dart';

import 'dart:async';

import '../core/analytics/activity_tracker.dart';
import '../core/analytics/analytics_service.dart';
import '../core/app_export.dart';
import '../core/auth/global_auth_listener.dart';
import '../core/chat/presence_helper.dart';
import '../core/deeplink/deep_link_service.dart';
import '../core/notifications/push_notification_service.dart';
import '../core/providers/theme_provider.dart';
import '../core/supabase/supabase_config.dart';
import '../core/updates/update_checker.dart';
import '../widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // L'app utilise `DateFormat(..., 'fr_FR')` dans une quinzaine d'écrans
  // (Commandes, Services, Achats Formation, CRM...) sans jamais initialiser
  // les données de locale `intl` — le package ne connaît que la locale par
  // défaut ('en_US') tant que `initializeDateFormatting` n'a pas été appelé.
  // Résultat : ça ne plante PAS à l'écran (le champ `DateFormat` se crée
  // sans erreur), mais `.format()` lève une `LocaleDataException` dès qu'un
  // motif a besoin d'un nom de mois/jour ('MMM', 'MMMM'...) ET qu'il y a
  // une vraie date à afficher — d'où des crashs "Something went wrong"
  // qui n'apparaissent qu'une fois des données réelles présentes (onglets
  // Commandes puis Services, 03/08).
  await initializeDateFormatting('fr_FR');

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(
        errorDetails: details,
      );
    }
    return SizedBox.shrink();
  };

  // Connexion à Supabase (base de données, authentification).
  // Si env.json est absent/incomplet, l'app démarre quand même en mode
  // "hors-ligne" plutôt que de planter (utile pour du dev sans backend).
  await SupabaseConfig.initialize();

  // Firebase (13/10, correctif) : DOIT être prêt (et "await"-é) avant le
  // premier `runApp()`, contrairement à `PushNotificationService.initialize()`
  // plus bas qui reste volontairement non "await" (popup de permission).
  // Sans ce bloc, `MyApp.build()` pouvait s'exécuter avant la fin de
  // `Firebase.initializeApp()` (appelée, elle, dans
  // `PushNotificationService.initialize()` sans "await") et tout accès à
  // Firebase Analytics dans `navigatorObservers` plantait l'app au tout
  // premier écran (écran noir indéfini constaté par la propriétaire juste
  // après l'ajout de l'Analytics). Rapide (pas d'appel réseau bloquant,
  // pas de popup) : ne retarde pas perceptiblement le premier écran.
  // Si google-services.json est absent, échoue en silence (l'app continue
  // normalement, juste sans Firebase — `AnalyticsService` et
  // `PushNotificationService` gèrent déjà ce cas).
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  // Écoute de connexion active pour toute la durée de vie de l'app (voir
  // global_auth_listener.dart) — capte la connexion Google même si le
  // retour du navigateur a fait redémarrer l'app à froid sur le splash.
  GlobalAuthListener.init();

  // Lien produit partageable (akorahub://produit/{id}, 24/08) — voir
  // core/deeplink/deep_link_service.dart. Sans "await" pour la même
  // raison que les notifications push ci-dessous : ne doit jamais
  // retarder le premier écran.
  DeepLinkService.init();

  // Notifications push (Firebase). Volontairement PAS "await" ici :
  // l'initialisation inclut la demande d'autorisation de notifications
  // (popup système), qui bloquerait sinon l'affichage du tout premier
  // écran — l'utilisateur verrait un écran blanc suivi d'une popup
  // système avant même le logo AkoraHub. On lance l'app immédiatement,
  // et les notifications s'initialisent en arrière-plan une fois l'app
  // déjà visible. Si google-services.json est absent, échoue en
  // silence (try/catch dans le service) sans rien casser.
  PushNotificationService.initialize();

  // Vérification de mise à jour in-app (04/08) — même raison que
  // ci-dessus pour ne pas "await" : ne doit jamais retarder le premier
  // écran. Fonctionne à l'identique côté client et admin.
  UpdateChecker.checkAndPrompt();

  // Utilisateurs actifs (12/10, demande explicite) : marque l'utilisateur
  // comme actif à CHAQUE démarrage de l'app (pas seulement à la connexion
  // — une session Supabase persistante ne redéclenche pas d'événement
  // `signedIn` à chaque réouverture, voir global_auth_listener.dart pour
  // ce cas-là). Sans "await", même raison que ci-dessus.
  ActivityTracker.touch();

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(ProviderScope(child: MyApp()));
  });
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        navigatorKey: GlobalAuthListener.navigatorKey,
        // AnalyticsService.observers (12/10, demande explicite) : envoie un
        // événement `screen_view` à chaque écran, base des utilisateurs
        // actifs et des audiences Firebase — voir analytics_service.dart.
        // Liste vide (donc sans effet) si Firebase n'est pas disponible.
        navigatorObservers: [
          GlobalAuthListener.routeObserver,
          ...AnalyticsService.observers,
        ],
        title: 'AkoraHub',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: _GlobalPresenceHeartbeat(child: child!),
          );
        },
        // 🚨 END CRITICAL SECTION
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.initial,
      );
    });
  }
}

/// Présence "en ligne" à l'échelle de toute l'app (26/10, demande
/// explicite : savoir en temps réel qui est connecté, pas seulement qui
/// a ouvert l'app dans les 7 derniers jours). Jusqu'ici,
/// `PresenceHelper.touch()` ne tournait que pendant qu'un écran de chat
/// était ouvert (29/09) — ce battement tourne pendant toute la durée de
/// vie de l'app, mais uniquement au premier plan (s'arrête quand l'app
/// passe en arrière-plan, pour ne pas afficher "en ligne" quelqu'un qui a
/// juste laissé l'app ouverte sans y être). Alimente
/// `profiles.last_seen_at`, utilisé par `ActiveUsersScreen` (tableau de
/// bord staff) et déjà par la présence en chat.
class _GlobalPresenceHeartbeat extends StatefulWidget {
  final Widget child;
  const _GlobalPresenceHeartbeat({required this.child});

  @override
  State<_GlobalPresenceHeartbeat> createState() =>
      _GlobalPresenceHeartbeatState();
}

class _GlobalPresenceHeartbeatState extends State<_GlobalPresenceHeartbeat>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    PresenceHelper.touch();
    _timer?.cancel();
    _timer = Timer.periodic(
        const Duration(seconds: 30), (_) => PresenceHelper.touch());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
