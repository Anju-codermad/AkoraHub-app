import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vrai si l'appareil a une connexion réseau active (Wi-Fi ou données
/// mobiles) — ne garantit pas qu'Internet fonctionne réellement derrière
/// (ex: Wi-Fi sans accès Internet), mais suffit pour décider si on tente
/// un appel Supabase ou si on passe directement en mode hors-ligne.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none));
});

/// Vérification ponctuelle (pas un flux) — utile avant de tenter un envoi
/// pour décider immédiatement s'il faut mettre en attente ou envoyer tout
/// de suite, sans attendre le prochain événement du flux.
Future<bool> isCurrentlyOnline() async {
  final results = await Connectivity().checkConnectivity();
  return !results.contains(ConnectivityResult.none);
}
