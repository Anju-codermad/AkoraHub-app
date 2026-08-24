import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/global_auth_listener.dart';
import '../supabase/supabase_config.dart';
import '../../presentation/calls/incoming_call_screen.dart';
import 'notification_sounds.dart';

/// Nom du canal Android dédié aux appels entrants — volontairement en
/// dehors du système catégorie/son personnalisable (message/devis/
/// commande/produit) : un appel doit toujours utiliser un son d'appel
/// reconnaissable, pas une préférence utilisateur.
const _callsChannelId = 'akorahub_calls';

/// Gère l'enregistrement du token FCM (Firebase Cloud Messaging) de
/// l'appareil et l'affichage des notifications reçues pendant que l'app
/// est ouverte (Android/iOS affichent automatiquement les notifications
/// reçues en arrière-plan/app fermée, sans code supplémentaire — c'est
/// uniquement le cas "app ouverte" qui demande de les afficher soi-même).
///
/// Ce service ne fait qu'ENREGISTRER l'appareil pour recevoir des
/// notifications — l'ENVOI se fait côté serveur (Supabase Edge Function),
/// pas depuis l'app elle-même (une app cliente ne doit jamais avoir les
/// identifiants nécessaires pour envoyer des notifications, ce serait un
/// risque de sécurité).
///
/// Depuis la Phase 24, chaque utilisateur choisit son propre son de
/// notification par catégorie (Message/Devis/Commande/Produit, voir
/// core/notifications/notification_sounds.dart) — un canal Android est
/// créé pour chaque combinaison (catégorie, son) choisie, puisqu'un canal
/// est immuable une fois créé.
class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const _prefsKeyPrefix = 'notification_sound_';

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase pas configuré (google-services.json absent) — l'app
      // continue de fonctionner normalement, juste sans notifications.
      _initialized = false;
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // Demande explicite côté Android (au cas où requestPermission()
    // ci-dessus ne couvre pas POST_NOTIFICATIONS sur cet appareil) —
    // sans cette autorisation (Android 13+), aucune notification ne
    // peut s'afficher, avec ou sans son.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // S'assure que les canaux Android existent pour les préférences
    // actuelles (cache local si disponible, sinon défauts) avant même
    // qu'une notification n'arrive.
    for (final category in NotificationCategory.values) {
      final soundId = await getSoundPreference(category);
      await ensureAndroidChannel(category, soundId);
    }
    await _ensureCallsChannel();

    // Affiche une notification locale quand un message arrive pendant
    // que l'app est au premier plan (sinon, rien ne s'afficherait tant
    // que l'utilisateur ne quitte pas l'app).
    FirebaseMessaging.onMessage.listen((message) async {
      // Appel entrant : app déjà ouverte -> on affiche directement
      // l'écran d'appel entrant plutôt qu'une notification classique.
      if (await _handleCallInvite(message)) return;

      final notification = message.notification;
      if (notification == null) return;

      final category = NotificationCategoryX.fromId(message.data['category']) ??
          NotificationCategory.message;
      final soundId = await getSoundPreference(category);
      final channelId = androidChannelId(category, soundId);
      await ensureAndroidChannel(category, soundId);

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'AkoraHub — ${category.label}',
            importance: Importance.high,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound(soundId),
          ),
          iOS: DarwinNotificationDetails(sound: '$soundId.wav'),
        ),
      );
    });

    // App en arrière-plan, notification tapée -> ouvre l'écran d'appel
    // entrant si c'en est un.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleCallInvite);

    // App complètement fermée, ouverte via le tap sur la notification.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _handleCallInvite(initialMessage);
    }

    await _registerToken();
    await _syncSoundPreferencesFromServer();
    messaging.onTokenRefresh.listen((_) => _registerToken());
  }

  static Future<void> _ensureCallsChannel() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    try {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _callsChannelId,
          'AkoraHub — Appels',
          importance: Importance.max,
        ),
      );
    } catch (_) {
      // Pas grave si la création échoue (ex: appareil non-Android).
    }
  }

  /// Détecte un message "appel entrant" (`data.type == 'call_invite'`) et
  /// pousse `IncomingCallScreen` par-dessus l'écran actuel, quel qu'il
  /// soit (via le navigateur global — ce service n'a pas son propre
  /// `BuildContext`). Retourne `true` si le message était bien un appel
  /// (pour que l'appelant sache s'arrêter là plutôt que d'afficher aussi
  /// une notification classique).
  static Future<bool> _handleCallInvite(RemoteMessage message) async {
    if (message.data['type'] != 'call_invite') return false;
    final navigator = GlobalAuthListener.navigatorKey.currentState;
    if (navigator == null) return true;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          invitationId: message.data['invitation_id'] as String,
          channelName: message.data['channel_name'] as String,
          callType: message.data['call_type'] as String? ?? 'audio',
          callerId: '',
          callerName: message.data['caller_name'] as String?,
        ),
      ),
    );
    return true;
  }

  /// Crée (ou confirme l'existence de) le canal Android pour ce couple
  /// (catégorie, son). Sans effet sur iOS (pas de notion de canal). Sans
  /// effet si Firebase n'est pas configuré sur cet appareil.
  static Future<void> ensureAndroidChannel(
      NotificationCategory category, String soundId) async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    try {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          androidChannelId(category, soundId),
          'AkoraHub — ${category.label}',
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundId),
        ),
      );
    } catch (_) {
      // Pas grave si la création échoue (ex: appareil non-Android) — le
      // système utilisera son canal/son par défaut.
    }
  }

  /// Lit la préférence de son en cache local (rapide, pas d'appel réseau
  /// à chaque notification reçue). Repli sur le son par défaut de la
  /// catégorie si jamais choisi.
  static Future<String> getSoundPreference(
      NotificationCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefsKeyPrefix${category.id}') ??
        category.defaultSoundId;
  }

  /// Change la préférence de son pour une catégorie : sauvegarde en base
  /// (pour que le serveur envoie le bon son même app fermée), en cache
  /// local (lecture rapide côté app ouverte), et crée le canal Android
  /// correspondant immédiatement (pour qu'il existe avant la prochaine
  /// notification).
  static Future<void> setSoundPreference(
      NotificationCategory category, String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsKeyPrefix${category.id}', soundId);
    await ensureAndroidChannel(category, soundId);

    if (!SupabaseConfig.isConfigured) return;
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({category.preferenceColumn: soundId}).eq('id', userId);
    } catch (_) {
      // Repli tolérant : la préférence reste appliquée localement même
      // si la sauvegarde serveur échoue (ex: hors-ligne) ; resynchronisée
      // au prochain appel de _syncSoundPreferencesFromServer.
    }
  }

  /// Recharge les 3 préférences depuis `profiles` (source de vérité) vers
  /// le cache local, au cas où l'utilisateur ait changé de préférence
  /// depuis un autre appareil.
  static Future<void> _syncSoundPreferencesFromServer() async {
    if (!SupabaseConfig.isConfigured) return;
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select(
              'notification_sound_message, notification_sound_devis, notification_sound_commande, notification_sound_produit')
          .eq('id', userId)
          .single();
      final prefs = await SharedPreferences.getInstance();
      for (final category in NotificationCategory.values) {
        final soundId =
            (row[category.preferenceColumn] as String?) ?? category.defaultSoundId;
        await prefs.setString('$_prefsKeyPrefix${category.id}', soundId);
        await ensureAndroidChannel(category, soundId);
      }
    } catch (_) {
      // Colonnes pas encore migrées, ou hors-ligne : le cache local
      // (défauts si premier lancement) reste utilisé.
    }
  }

  /// Sauvegarde le token FCM de cet appareil dans `profiles.fcm_token`,
  /// pour que le serveur puisse cibler cet utilisateur plus tard.
  static Future<void> _registerToken() async {
    if (!SupabaseConfig.isConfigured) return;
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await SupabaseConfig.client
          .from('profiles')
          .update({'fcm_token': token}).eq('id', userId);
    } catch (_) {
      // Pas grave si l'enregistrement échoue (ex: hors-ligne) — sera
      // retenté au prochain lancement de l'app ou rafraîchissement du
      // token.
    }
  }

  /// À appeler juste après la connexion réussie (le token doit être
  /// associé à l'utilisateur qui vient de se connecter, pas à celui
  /// d'avant sur le même appareil).
  static Future<void> onUserSignedIn() async {
    await _registerToken();
    await _syncSoundPreferencesFromServer();
  }
}
