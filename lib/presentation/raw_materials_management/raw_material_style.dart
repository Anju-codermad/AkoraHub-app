import 'package:flutter/material.dart';

/// Icônes/couleurs partagées entre les écrans Admin et Client de la base de
/// matières premières ("Formation") — centralisé ici pour que les deux
/// côtés restent visuellement cohérents.

/// "Nom" (06/08) peut contenir plusieurs synonymes séparés par des
/// virgules (ex : "Soude caustique, soude en perles, soude écailles,
/// lessive de soude") depuis la fusion avec "Nom commun" — trop long
/// comme titre de carte/écran. Affiche juste le premier, la liste
/// complète reste consultable dans le champ "Synonymes" de la fiche
/// Académie.
String rawMaterialShortName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '';
  return fullName.split(',').first.trim();
}

Color rawMaterialStatusColor(String status) {
  switch (status) {
    case 'stock_faible':
      return Colors.orange;
    case 'rupture':
      return Colors.red;
    case 'en_stock':
    default:
      return Colors.green;
  }
}

String rawMaterialStatusLabel(String status) {
  switch (status) {
    case 'stock_faible':
      return 'Stock faible';
    case 'rupture':
      return 'Rupture';
    case 'en_stock':
    default:
      return 'En stock';
  }
}

const List<String> rawMaterialStockStatuses = [
  'en_stock',
  'stock_faible',
  'rupture',
];

/// Icône approximative par mot-clé de catégorie chimique — même principe
/// que `_iconForCategory` du catalogue client (mot-clé, pas de table de
/// mapping dédiée, pour rester simple à étendre).
IconData iconForChemicalCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('tensioactif')) return Icons.bubble_chart_outlined;
  if (c.contains('solvant')) return Icons.opacity_outlined;
  if (c.contains('acide') || c.contains('base')) return Icons.science_outlined;
  if (c.contains('colorant')) return Icons.palette_outlined;
  if (c.contains('parfum')) return Icons.local_florist_outlined;
  if (c.contains('conservateur') || c.contains('antioxydant')) {
    return Icons.shield_outlined;
  }
  if (c.contains('épaississant') || c.contains('epaississant')) {
    return Icons.water_drop_outlined;
  }
  if (c.contains('chélatant') || c.contains('chelatant')) {
    return Icons.link_outlined;
  }
  if (c.contains('huile') || c.contains('beurre')) return Icons.spa_outlined;
  if (c.contains('charge') || c.contains('minérale') || c.contains('minerale')) {
    return Icons.grain_outlined;
  }
  if (c.contains('polymère') || c.contains('polymere') || c.contains('résine') || c.contains('resine')) {
    return Icons.hexagon_outlined;
  }
  if (c.contains('désinfectant') || c.contains('desinfectant')) {
    return Icons.sanitizer_outlined;
  }
  if (c.contains('pigment')) return Icons.format_paint_outlined;
  if (c.contains('siccatif')) return Icons.whatshot_outlined;
  if (c.contains('oxydant') || c.contains('blanchiment')) {
    return Icons.brightness_high_outlined;
  }
  if (c.contains('insecticide') || c.contains('raticide') || c.contains('fourmis') ||
      c.contains('moustique') || c.contains('puce') || c.contains('agrivet')) {
    return Icons.pest_control_outlined;
  }
  return Icons.science_outlined;
}

/// Icône Material approximant chaque type d'EPI (aucune icône dédiée
/// "gants"/"bottes" n'existe dans Material Symbols) — mêmes libellés que
/// `_academieEpiSuggestions` (raw_material_editor_screen.dart).
/// Partagé (06/08) entre l'admin (chips de sélection) et le client
/// (avatars d'icônes) pour rester visuellement cohérent.
IconData epiIcon(String epi) {
  switch (epi) {
    case 'gants':
      return Icons.back_hand_outlined;
    case 'lunettes':
      return Icons.visibility_outlined;
    case 'masque':
      return Icons.masks_outlined;
    case 'ventilation':
      return Icons.air;
    case 'tablier':
      return Icons.checkroom_outlined;
    case 'bottes':
      return Icons.hiking_outlined;
    default:
      return Icons.shield_outlined;
  }
}

/// Couleur du badge "Niveau de danger" selon la sévérité — les 4
/// valeurs possibles sont `_academieNiveauxDanger`
/// (raw_material_editor_screen.dart).
Color dangerLevelColor(String? niveau) {
  switch (niveau) {
    case 'Corrosif':
      return Colors.red;
    case 'Élevé':
      return Colors.deepOrange;
    case 'Modéré':
      return Colors.amber.shade800;
    default:
      return Colors.grey;
  }
}

const List<String> rawMaterialUsageDomains = [
  'Nettoyage',
  'Cosmétique',
  'Agroalimentaire',
  'Industriel',
];

IconData iconForUsageDomain(String domain) {
  switch (domain) {
    case 'Cosmétique':
      return Icons.spa_outlined;
    case 'Agroalimentaire':
      return Icons.restaurant_outlined;
    case 'Industriel':
      return Icons.factory_outlined;
    case 'Nettoyage':
    default:
      return Icons.cleaning_services_outlined;
  }
}

Color colorForUsageDomain(String domain) {
  switch (domain) {
    case 'Cosmétique':
      return Colors.pink;
    case 'Agroalimentaire':
      return Colors.green;
    case 'Industriel':
      return Colors.blueGrey;
    case 'Nettoyage':
    default:
      return Colors.blue;
  }
}
