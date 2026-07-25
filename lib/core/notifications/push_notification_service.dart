import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../supabase/supabase_config.dart';

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
class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

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

    // Affiche une notification locale quand un message arrive pendant
    // que l'app est au premier plan (sinon, rien ne s'afficherait tant
    // que l'utilisateur ne quitte pas l'app).
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'akorahub_default',
            'AkoraHub',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    await _registerToken();
    messaging.onTokenRefresh.listen((_) => _registerToken());
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
  static Future<void> onUserSignedIn() => _registerToken();
}
