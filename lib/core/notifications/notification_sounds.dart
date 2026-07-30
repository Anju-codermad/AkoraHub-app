/// Catalogue partagé des sons de notification disponibles, et des
/// catégories de notification que l'app distingue (Message/Devis/
/// Commande — voir supabase/functions/send-push-notification/index.ts).
///
/// Tous les fichiers son sont dans `android/app/src/main/res/raw/` (nom
/// de fichier = `id` ci-dessous, sans extension — obligatoire pour un nom
/// de ressource Android : lettres minuscules/chiffres/underscore
/// uniquement). Réservoir commun : n'importe quel son peut être choisi
/// pour n'importe quelle catégorie (demande explicite de l'utilisateur,
/// plutôt qu'une liste figée par catégorie).
library;

enum NotificationCategory { message, devis, commande }

extension NotificationCategoryX on NotificationCategory {
  /// Identifiant stable utilisé en base (colonne `profiles.notification_sound_<id>`),
  /// dans le nom du canal Android, et dans le champ `data.category` envoyé
  /// par l'Edge Function.
  String get id {
    switch (this) {
      case NotificationCategory.message:
        return 'message';
      case NotificationCategory.devis:
        return 'devis';
      case NotificationCategory.commande:
        return 'commande';
    }
  }

  String get label {
    switch (this) {
      case NotificationCategory.message:
        return 'Messagerie';
      case NotificationCategory.devis:
        return 'Devis';
      case NotificationCategory.commande:
        return 'Commandes';
    }
  }

  String get preferenceColumn => 'notification_sound_$id';

  String get defaultSoundId {
    switch (this) {
      case NotificationCategory.message:
        return 'notif_message_classique';
      case NotificationCategory.devis:
        return 'notif_devis_classique';
      case NotificationCategory.commande:
        return 'notif_commande_classique';
    }
  }

  static NotificationCategory? fromId(String? id) {
    for (final c in NotificationCategory.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class NotificationSoundOption {
  final String id;
  final String label;
  const NotificationSoundOption(this.id, this.label);
}

const List<NotificationSoundOption> kNotificationSounds = [
  NotificationSoundOption('notif_message_classique', 'Carillon classique'),
  NotificationSoundOption('notif_message_bulle', 'Bulle discrète'),
  NotificationSoundOption('notif_message_brillant', 'Carillon brillant'),
  NotificationSoundOption('notif_message_doux', 'Carillon doux'),
  NotificationSoundOption('notif_message_fun', 'Rebond ludique'),
  NotificationSoundOption('notif_devis_classique', 'Ton posé'),
  NotificationSoundOption('notif_devis_chaleureux', 'Ton chaleureux'),
  NotificationSoundOption('notif_devis_serieux', 'Ton sérieux'),
  NotificationSoundOption('notif_devis_discret', 'Ton discret'),
  NotificationSoundOption('notif_devis_fun', 'Rebond léger'),
  NotificationSoundOption('notif_commande_classique', 'Arpège classique'),
  NotificationSoundOption('notif_commande_rapide', 'Pop rapide'),
  NotificationSoundOption('notif_commande_festif', 'Arpège festif'),
  NotificationSoundOption('notif_commande_doux', 'Arpège doux'),
  NotificationSoundOption('notif_commande_fun', 'Rebond festif'),
  NotificationSoundOption('notif_bulle_eau', "Bulle d'eau"),
  NotificationSoundOption('notif_bulle_savon', 'Bulle de savon'),
  NotificationSoundOption('notif_bulle_liquide', 'Bulle liquide'),
  NotificationSoundOption('notif_bulles_profondes', 'Bulles profondes'),
  NotificationSoundOption('notif_radar', 'Radar'),
];

/// Nom du canal de notification Android pour un (catégorie, son) donné.
/// Un canal Android est immuable une fois créé (son/importance figés) —
/// changer de son pour une catégorie doit donc utiliser un NOUVEL id de
/// canal, jamais réutiliser l'ancien.
String androidChannelId(NotificationCategory category, String soundId) =>
    'akorahub_${category.id}_$soundId';
