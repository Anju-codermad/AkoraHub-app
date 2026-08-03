import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Système de traduction simple par clé, pour Français/Malagasy.
/// Pas de package `intl`/`.arb` (trop lourd à mettre en place sur un
/// projet déjà avancé) — juste une table de correspondance centralisée,
/// complétée progressivement écran par écran.
///
/// Utilisation : `ref.watch(localeProvider)` pour la langue actuelle,
/// `AppTranslations.t(key, locale)` pour traduire, ou l'extension
/// `context.tr(key)` dans un widget qui a accès au `WidgetRef`.
class AppTranslations {
  AppTranslations._();

  static const Map<String, Map<String, String>> _strings = {
    // --- Navigation générale (barre du bas, en-têtes) ---
    'nav_home': {'fr': 'Accueil', 'mg': 'Fandraisana'},
    'nav_orders': {'fr': 'Commandes', 'mg': 'Baiko'},
    'nav_profile': {'fr': 'Profil', 'mg': 'Mombamomba'},
    'nav_services': {'fr': 'Services', 'mg': 'Serivisy'},
    'nav_cart': {'fr': 'Panier', 'mg': 'Sobika'},

    // --- Catalogue / Accueil client ---
    'search_hint': {
      'fr': 'Rechercher un produit...',
      'mg': 'Mitady vokatra...'
    },
    'our_activities': {'fr': 'Nos activités', 'mg': 'Ny asa ataonay'},
    'for_you': {'fr': 'Pour vous', 'mg': 'Ho anao'},
    'products': {'fr': 'Produits', 'mg': 'Vokatra'},
    'all_categories': {'fr': 'Toutes catégories', 'mg': 'Karazana rehetra'},
    'add_to_cart': {'fr': 'Ajouter au panier', 'mg': 'Ampidiro ao an-tsobika'},
    'from_price': {'fr': 'Dès', 'mg': 'Manomboka amin\'ny'},

    // --- Panier / Commande ---
    'cart_empty': {
      'fr': 'Votre panier est vide.',
      'mg': 'Foana ny sobikanao.'
    },
    'total': {'fr': 'Total', 'mg': 'Fitambarany'},
    'order_now': {'fr': 'Commander', 'mg': 'Manao baiko'},
    'request_quote': {'fr': 'Demander un devis', 'mg': 'Angataho tombana'},
    'quantity': {'fr': 'Quantité', 'mg': 'Habetsahana'},

    // --- Commandes / Devis (suivi) ---
    'my_orders': {'fr': 'Mes commandes', 'mg': 'Ny baikoko'},
    'my_quotes': {'fr': 'Mes devis', 'mg': 'Ny tombanako'},
    'status_recue': {'fr': 'Reçue', 'mg': 'Voaray'},
    'status_en_preparation': {
      'fr': 'En préparation',
      'mg': 'Am-piomanana'
    },
    'status_expediee': {'fr': 'Expédiée', 'mg': 'Nalefa'},
    'status_livree': {'fr': 'Livrée', 'mg': 'Voatolotra'},
    'reorder': {'fr': 'Recommander', 'mg': 'Baiko indray'},

    // --- Profil ---
    'edit_profile': {'fr': 'Modifier mon profil', 'mg': 'Ovay ny mombamomba'},
    'my_favorites': {'fr': 'Mes favoris', 'mg': 'Ny tiako indrindra'},
    'messaging': {'fr': 'Messagerie', 'mg': 'Hafatra'},
    'logout': {'fr': 'Déconnexion', 'mg': 'Hivoaka'},
    'language': {'fr': 'Langue', 'mg': 'Fiteny'},

    // --- Actions génériques ---
    'save': {'fr': 'Enregistrer', 'mg': 'Tehirizo'},
    'cancel': {'fr': 'Annuler', 'mg': 'Aoka ihany'},
    'confirm': {'fr': 'Confirmer', 'mg': 'Hamarino'},
  };

  static String t(String key, String locale) {
    return _strings[key]?[locale] ?? _strings[key]?['fr'] ?? key;
  }
}

/// StateNotifier pour la langue courante ('fr' ou 'mg'), persistée en
/// local (SharedPreferences) pour se souvenir du choix entre deux
/// ouvertures de l'app.
class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('fr') {
    _load();
  }

  static const _prefsKey = 'app_locale';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) state = saved;
    } catch (_) {
      // Pas grave si indisponible (ex: web sans stockage) — reste en FR.
    }
  }

  Future<void> setLocale(String locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, locale);
    } catch (_) {}
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

/// Raccourci pratique dans un `ConsumerWidget`/`ConsumerState` :
/// `ref.tr('nav_home')` au lieu de
/// `AppTranslations.t('nav_home', ref.watch(localeProvider))`.
extension TranslationRefExtension on WidgetRef {
  String tr(String key) => AppTranslations.t(key, watch(localeProvider));
}
