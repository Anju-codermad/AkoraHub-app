import '../supabase/supabase_config.dart';

/// Présence "En ligne" / "Vu(e) pour la dernière fois" (29/09) —
/// approximée via `profiles.last_seen_at`, mis à jour par polling léger
/// pendant qu'un écran de chat est ouvert (voir chat_screen.dart /
/// messaging_center_real.dart), plutôt que via Presence Realtime (canal
/// éphémère jamais utilisé ailleurs dans ce projet à ce jour — évite
/// d'introduire une API non éprouvée ici pour un gain marginal, un
/// "en ligne" à 20-25s près reste largement suffisant pour ce cas
/// d'usage). "En ligne" = dernière activité vue il y a moins de 45s.
class PresenceHelper {
  static const onlineThreshold = Duration(seconds: 45);

  /// Marque l'utilisateur courant comme actif maintenant. Best-effort,
  /// ne doit jamais faire planter le chat si ça échoue (offline, RLS...).
  static Future<void> touch() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'last_seen_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (_) {}
  }

  static bool isOnline(String? lastSeenAtIso) {
    final t = lastSeenAtIso != null ? DateTime.tryParse(lastSeenAtIso) : null;
    if (t == null) return false;
    return DateTime.now().toUtc().difference(t.toUtc()) < onlineThreshold;
  }

  /// "En ligne", "Vu(e) à HH:MM" (aujourd'hui) ou "Vu(e) le J/M à HH:MM" —
  /// chaîne vide si jamais vu (nouveau compte, jamais ouvert le chat).
  static String label(String? lastSeenAtIso) {
    final t = lastSeenAtIso != null ? DateTime.tryParse(lastSeenAtIso) : null;
    if (t == null) return '';
    if (isOnline(lastSeenAtIso)) return 'En ligne';

    final local = t.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final time = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return sameDay ? 'Vu(e) à $time' : 'Vu(e) le ${local.day}/${local.month} à $time';
  }
}
