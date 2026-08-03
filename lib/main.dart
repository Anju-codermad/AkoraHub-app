import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../core/auth/global_auth_listener.dart';
import '../core/notifications/push_notification_service.dart';
import '../core/providers/theme_provider.dart';
import '../core/supabase/supabase_config.dart';
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

  // Écoute de connexion active pour toute la durée de vie de l'app (voir
  // global_auth_listener.dart) — capte la connexion Google même si le
  // retour du navigateur a fait redémarrer l'app à froid sur le splash.
  GlobalAuthListener.init();

  // Notifications push (Firebase). Volontairement PAS "await" ici :
  // l'initialisation inclut la demande d'autorisation de notifications
  // (popup système), qui bloquerait sinon l'affichage du tout premier
  // écran — l'utilisateur verrait un écran blanc suivi d'une popup
  // système avant même le logo AkoraHub. On lance l'app immédiatement,
  // et les notifications s'initialisent en arrière-plan une fois l'app
  // déjà visible. Si google-services.json est absent, échoue en
  // silence (try/catch dans le service) sans rien casser.
  PushNotificationService.initialize();

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
        navigatorObservers: [GlobalAuthListener.routeObserver],
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
            child: child!,
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
