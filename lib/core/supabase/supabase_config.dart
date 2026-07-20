import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralise l'accès à Supabase pour toute l'application.
///
/// Les clés (URL + clé publique) sont lues depuis `env.json`, un fichier
/// qui n'est JAMAIS commité avec de vraies valeurs (voir .gitignore).
/// En local, copiez env.example.json vers env.json et remplissez vos clés.
/// En CI (GitHub Actions), ce fichier est généré automatiquement à partir
/// des secrets du dépôt (SUPABASE_URL, SUPABASE_ANON_KEY).
class SupabaseConfig {
  SupabaseConfig._();

  static Future<void> initialize() async {
    String url = '';
    String anonKey = '';

    try {
      final raw = await rootBundle.loadString('env.json');
      final Map<String, dynamic> data = jsonDecode(raw);
      url = (data['SUPABASE_URL'] ?? '').toString();
      anonKey = (data['SUPABASE_ANON_KEY'] ?? '').toString();
    } catch (_) {
      // env.json absent ou invalide : l'app démarre quand même,
      // mais les fonctionnalités liées à Supabase resteront indisponibles.
    }

    if (url.isEmpty || anonKey.isEmpty || url.contains('your-project-id')) {
      // Pas de configuration valide : on n'initialise pas Supabase pour
      // éviter un crash au démarrage. isConfigured permettra à l'UI de le
      // signaler proprement plutôt que de planter.
      _configured = false;
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _configured = true;
  }

  static bool _configured = false;
  static bool get isConfigured => _configured;

  static SupabaseClient get client => Supabase.instance.client;
}
