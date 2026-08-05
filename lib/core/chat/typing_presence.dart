import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';

/// Indicateur "en train d'écrire" partagé entre la messagerie client/staff
/// (`chat_screen.dart`) et la messagerie privée entre amis
/// (`friend_chat_screen.dart`) — 05/08.
///
/// Basé sur le Broadcast de Supabase Realtime (canal éphémère, pas une
/// table) : aucun message "typing" n'est jamais stocké en base, juste
/// diffusé en direct aux participants connectés au même canal. Un même
/// `topic` doit être utilisé par les deux côtés d'une conversation pour
/// qu'ils se voient mutuellement (ex : id de conversation, ou paire
/// d'ids triée pour un chat 1:1 sans conversation dédiée).
class TypingPresence {
  final RealtimeChannel _channel;
  final String _selfId;
  Timer? _debounce;
  Timer? _remoteExpiry;
  bool _subscribed = false;

  /// Appelé quand l'autre participant commence/arrête d'écrire.
  final ValueChanged<bool> onRemoteTypingChanged;

  TypingPresence({
    required String topic,
    required String selfId,
    required this.onRemoteTypingChanged,
  })  : _selfId = selfId,
        _channel = SupabaseConfig.client.channel('typing:$topic') {
    _channel.onBroadcast(
      event: 'typing',
      callback: (payload) {
        if (payload['senderId'] == _selfId) return;
        onRemoteTypingChanged(true);
        // Pas de message explicite "j'ai arrêté d'écrire" (pas fiable si
        // l'app passe en arrière-plan) — on considère simplement que
        // l'autre a arrêté si aucun nouvel événement n'arrive pendant 3s.
        _remoteExpiry?.cancel();
        _remoteExpiry = Timer(
            const Duration(seconds: 3), () => onRemoteTypingChanged(false));
      },
    );
    _channel.subscribe((status, error) {
      _subscribed = status == RealtimeSubscribeStatus.subscribed;
    });
  }

  /// À appeler à chaque frappe dans le champ de saisie. Throttle (pas un
  /// debounce classique) : diffuse immédiatement au premier appel, puis
  /// ignore les suivants pendant 300 ms — évite un événement réseau par
  /// lettre tapée tout en gardant l'indicateur réactif côté destinataire.
  void notifyTyping() {
    if (!_subscribed) return;
    if (_debounce?.isActive ?? false) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {});
    _channel.sendBroadcastMessage(
      event: 'typing',
      payload: {'senderId': _selfId},
    );
  }

  void dispose() {
    _debounce?.cancel();
    _remoteExpiry?.cancel();
    SupabaseConfig.client.removeChannel(_channel);
  }
}
