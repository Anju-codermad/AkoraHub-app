import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../supabase/supabase_config.dart';

/// Cache local (mémoire + `SharedPreferences`) pour une table de référence
/// qui change rarement (formats, parfums, catégories) — évite une requête
/// Supabase à chaque écran qui en a besoin (jusqu'à 6-7 points d'appel
/// différents avant ce cache). Ces tables n'ont pas de colonne
/// `updated_at` pour détecter un changement à distance : la fraîcheur
/// repose sur une durée de vie (TTL) + une invalidation explicite après
/// une écriture faite depuis l'app elle-même (voir `refresh(force: true)`,
/// à appeler juste après un insert/update sur la table concernée).
class ReferenceTableCache extends StateNotifier<List<Map<String, dynamic>>> {
  ReferenceTableCache(this._table, String prefsKeySuffix)
      : _prefsKey = 'ref_cache_$prefsKeySuffix',
        super([]) {
    _hydrate();
  }

  final String _table;
  final String _prefsKey;
  static const _ttl = Duration(hours: 6);
  DateTime? _lastFetch;

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        state = List<Map<String, dynamic>>.from(
          (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
    } catch (_) {
      // Repli silencieux : le refresh() ci-dessous alimentera l'état.
    }
    await refresh();
  }

  /// [force] ignore le TTL — à utiliser juste après une écriture (ajout,
  /// renommage, activation/désactivation) pour que l'admin voie
  /// immédiatement son changement, plutôt que d'attendre jusqu'à 6h.
  Future<void> refresh({bool force = false}) async {
    if (!force &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _ttl) {
      return;
    }
    if (!SupabaseConfig.isConfigured) return;
    try {
      final rows =
          await SupabaseConfig.client.from(_table).select().order('name');
      final list = List<Map<String, dynamic>>.from(rows);
      state = list;
      _lastFetch = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(list));
    } catch (_) {
      // Repli silencieux : garde la dernière valeur connue (mémoire ou
      // cache local) — pas d'erreur affichée pour une donnée de référence.
    }
  }
}

final formatsCacheProvider =
    StateNotifierProvider<ReferenceTableCache, List<Map<String, dynamic>>>(
  (ref) => ReferenceTableCache('formats', 'formats'),
);

final parfumsCacheProvider =
    StateNotifierProvider<ReferenceTableCache, List<Map<String, dynamic>>>(
  (ref) => ReferenceTableCache('parfums', 'parfums'),
);

final categoriesCacheProvider =
    StateNotifierProvider<ReferenceTableCache, List<Map<String, dynamic>>>(
  (ref) => ReferenceTableCache('categories', 'categories'),
);
