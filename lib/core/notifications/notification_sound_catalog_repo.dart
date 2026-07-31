import '../supabase/supabase_config.dart';
import 'notification_sounds.dart';

/// Une ligne du catalogue de sons pour une catégorie donnée (voir
/// `notification_sound_catalog`, phase32) — inclut les sons masqués,
/// contrairement à `NotificationSoundCatalogRepo.visibleSounds`.
class SoundCatalogEntry {
  final String soundId;
  final int sortOrder;
  final bool enabled;
  const SoundCatalogEntry({
    required this.soundId,
    required this.sortOrder,
    required this.enabled,
  });
}

/// Catalogue de sons de notification géré par l'Admin (réordonner/masquer
/// parmi les 20 sons intégrés à l'app, par catégorie) — voir
/// `supabase/phase32_patch_notification_sound_catalog.sql`. Lecture
/// publique, écriture réservée à l'Admin (RLS `current_role_is_admin()`).
class NotificationSoundCatalogRepo {
  NotificationSoundCatalogRepo._();

  /// Sons visibles pour une catégorie, dans l'ordre choisi par l'Admin —
  /// utilisé par le sélecteur personnel (client ET staff). Repli sur la
  /// liste complète non filtrée si la table est vide/inaccessible (ex:
  /// migration pas encore exécutée), pour ne jamais bloquer le choix
  /// d'un son.
  static Future<List<NotificationSoundOption>> visibleSounds(
      NotificationCategory category) async {
    if (!SupabaseConfig.isConfigured) return kNotificationSounds;
    try {
      final rows = await SupabaseConfig.client
          .from('notification_sound_catalog')
          .select('sound_id, sort_order, enabled')
          .eq('category', category.id)
          .eq('enabled', true)
          .order('sort_order');
      if (rows.isEmpty) return kNotificationSounds;
      final byId = {for (final s in kNotificationSounds) s.id: s};
      return List<Map<String, dynamic>>.from(rows)
          .map((r) => byId[r['sound_id'] as String])
          .whereType<NotificationSoundOption>()
          .toList();
    } catch (_) {
      return kNotificationSounds;
    }
  }

  /// Catalogue complet (y compris les sons masqués) pour l'écran de
  /// gestion Admin.
  static Future<List<SoundCatalogEntry>> fullCatalog(
      NotificationCategory category) async {
    final rows = await SupabaseConfig.client
        .from('notification_sound_catalog')
        .select('sound_id, sort_order, enabled')
        .eq('category', category.id)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows)
        .map((r) => SoundCatalogEntry(
              soundId: r['sound_id'] as String,
              sortOrder: r['sort_order'] as int,
              enabled: r['enabled'] as bool,
            ))
        .toList();
  }

  static Future<void> setEnabled(
      NotificationCategory category, String soundId, bool enabled) async {
    await SupabaseConfig.client
        .from('notification_sound_catalog')
        .update({
          'enabled': enabled,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('category', category.id)
        .eq('sound_id', soundId);
  }

  /// Réordonne : `orderedSoundIds` est la nouvelle liste complète (masqués
  /// inclus) dans l'ordre voulu pour cette catégorie.
  static Future<void> reorder(
      NotificationCategory category, List<String> orderedSoundIds) async {
    for (var i = 0; i < orderedSoundIds.length; i++) {
      await SupabaseConfig.client
          .from('notification_sound_catalog')
          .update({
            'sort_order': i,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('category', category.id)
          .eq('sound_id', orderedSoundIds[i]);
    }
  }
}
