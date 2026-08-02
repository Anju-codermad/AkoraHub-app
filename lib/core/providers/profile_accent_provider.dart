import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Couleur d'accent personnelle, appliquée UNIQUEMENT à l'écran Profil du
/// client (stats, barre de complétion) — Lot 4 du Profil, 03/08.
///
/// Volontairement locale à l'appareil (`SharedPreferences`, même pattern
/// que `theme_provider.dart`), jamais synchronisée en base ni appliquée
/// au thème global de l'app (boutons, FAB...) : les 3 couleurs de marque
/// définies dans `app_theme.dart` sont délibérées et documentées comme
/// telles — cette personnalisation reste une touche perso cantonnée à
/// l'espace du client, sans jamais entrer en conflit avec l'identité
/// visuelle de l'app.
class ProfileAccentNotifier extends StateNotifier<Color?> {
  ProfileAccentNotifier() : super(null) {
    _load();
  }

  static const _prefsKey = 'profile_accent_color';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_prefsKey);
    if (saved != null) state = Color(saved);
  }

  Future<void> setAccent(Color? color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setInt(_prefsKey, color.value);
    }
  }
}

final profileAccentProvider =
    StateNotifierProvider<ProfileAccentNotifier, Color?>((ref) {
  return ProfileAccentNotifier();
});

/// Palette de choix proposée (couleurs de marque + quelques variantes),
/// jamais une roue de couleurs libre — reste cohérent avec l'identité
/// visuelle plutôt que de permettre n'importe quelle teinte.
const kProfileAccentChoices = [
  Color(0xFF085041), // vert (icône)
  Color(0xFF0B2C64), // marine (icône)
  Color(0xFFFE5905), // orange (icône)
  Color(0xFF6B4C6B),
  Color(0xFFB3261E),
  Color(0xFF3D5A6C),
];
