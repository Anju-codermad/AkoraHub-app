import 'package:flutter/material.dart';

/// Un palier de fidélité = seuil de points minimum + avantage associé.
/// Seuils et avantages confirmés par l'utilisateur (25/07) : Bronze 0 (aucune
/// remise), Argent 1000 (-50% livraison), Or 5000 (livraison gratuite).
/// Partagé entre `client_home/loyalty/loyalty_screen.dart` (affichage) et
/// `client_home/cart_tab.dart` (application réelle de la remise).
class LoyaltyTier {
  final String name;
  final int minPoints;
  final Color color;
  final String perk;

  /// Fraction de réduction sur les frais de livraison (0.0 = aucune,
  /// 1.0 = livraison gratuite).
  final double deliveryDiscount;

  const LoyaltyTier(
    this.name,
    this.minPoints,
    this.color,
    this.perk,
    this.deliveryDiscount,
  );
}

const kLoyaltyTiers = [
  LoyaltyTier('Bronze', 0, Color(0xFFCD7F32), 'Membre AkoraHub', 0.0),
  LoyaltyTier(
      'Argent', 1000, Color(0xFFA8A9AD), '-50% sur les frais de livraison', 0.5),
  LoyaltyTier('Or', 5000, Color(0xFFD4AF37), 'Livraison gratuite', 1.0),
];

LoyaltyTier tierForPoints(int points) {
  var result = kLoyaltyTiers.first;
  for (final tier in kLoyaltyTiers) {
    if (points >= tier.minPoints) result = tier;
  }
  return result;
}

LoyaltyTier? nextTierForPoints(int points) {
  for (final tier in kLoyaltyTiers) {
    if (tier.minPoints > points) return tier;
  }
  return null;
}
