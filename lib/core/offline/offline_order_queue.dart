import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../supabase/supabase_config.dart';

/// File d'attente des commandes/devis passés sans connexion. Enregistrée
/// en local (SharedPreferences, en JSON) jusqu'à ce que la connexion
/// revienne, puis envoyée automatiquement à Supabase.
///
/// Ne gère PAS de logique de conflit (deux appareils qui modifieraient la
/// même donnée) — un seul appareil crée ses propres commandes, donc pas
/// de vrai risque de conflit ici, contrairement à un mode hors-ligne
/// complet type "édition collaborative".
class OfflineOrderQueue {
  OfflineOrderQueue._();

  static const _prefsKey = 'offline_pending_orders';

  /// Ajoute une commande/devis à la file d'attente locale. `type` vaut
  /// 'order' ou 'quote'. `payload` contient tout ce qu'il faut pour
  /// reconstruire l'insertion Supabase plus tard (items inclus).
  static Future<void> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readAll(prefs);
    list.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'payload': payload,
      'queuedAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_prefsKey, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> _readAll(
      SharedPreferences prefs) async {
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPending() async {
    final prefs = await SharedPreferences.getInstance();
    return _readAll(prefs);
  }

  static Future<int> pendingCount() async {
    final list = await getPending();
    return list.length;
  }

  /// Tente d'envoyer toutes les commandes/devis en attente à Supabase.
  /// Chaque élément réussi est retiré de la file ; les échecs restent en
  /// attente pour la prochaine tentative (ex: connexion encore instable).
  /// Retourne le nombre d'éléments envoyés avec succès.
  static Future<int> trySync() async {
    if (!SupabaseConfig.isConfigured) return 0;
    final prefs = await SharedPreferences.getInstance();
    final list = await _readAll(prefs);
    if (list.isEmpty) return 0;

    final remaining = <Map<String, dynamic>>[];
    var sentCount = 0;

    for (final entry in list) {
      try {
        final type = entry['type'] as String;
        final payload = Map<String, dynamic>.from(entry['payload']);
        final items =
            List<Map<String, dynamic>>.from(payload['items'] as List);
        final header = Map<String, dynamic>.from(payload['header']);

        if (type == 'quote') {
          final quote = await SupabaseConfig.client
              .from('quotes')
              .insert(header)
              .select()
              .single();
          await SupabaseConfig.client.from('quote_items').insert(
                items.map((i) => {...i, 'quote_id': quote['id']}).toList(),
              );
        } else {
          final order = await SupabaseConfig.client
              .from('orders')
              .insert(header)
              .select()
              .single();
          await SupabaseConfig.client.from('order_items').insert(
                items.map((i) => {...i, 'order_id': order['id']}).toList(),
              );
        }
        sentCount++;
      } catch (_) {
        // Échec (probablement toujours hors-ligne, ou connexion
        // instable) : on garde cet élément pour la prochaine tentative.
        remaining.add(entry);
      }
    }

    await prefs.setString(_prefsKey, jsonEncode(remaining));
    return sentCount;
  }
}
