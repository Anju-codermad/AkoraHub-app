import 'package:flutter/material.dart';

/// Couleurs et icônes cycliques pour les vignettes de module (Admin et
/// Client) — même palette des deux côtés pour que ce que la
/// propriétaire voit dans l'Admin corresponde à ce que voit le client
/// (demande explicite 29/10, inspirée de la maquette "formation af").
const List<Color> kModuleColors = [
  Color(0xFF127A6E), // teal
  Color(0xFF1E5FBF), // bleu
  Color(0xFF5B3FA6), // violet
  Color(0xFFC77A1E), // orange
  Color(0xFF0E8A6A), // vert
  Color(0xFF7A2FB0), // violet 2
  Color(0xFFB3261E), // rouge
  Color(0xFFA8891A), // or
];

const List<IconData> kModuleIcons = [
  Icons.science_outlined,
  Icons.inventory_2_outlined,
  Icons.auto_fix_high_outlined,
  Icons.precision_manufacturing_outlined,
  Icons.verified_outlined,
  Icons.flag_outlined,
  Icons.shield_outlined,
  Icons.payments_outlined,
];

Color moduleColor(int index) => kModuleColors[index % kModuleColors.length];

IconData moduleIcon(int index) => kModuleIcons[index % kModuleIcons.length];
