import 'package:flutter/material.dart';

/// Paliers de fidélité — extraits de `loyalty_screen.dart` (03/08, Lot 4
/// du Profil) pour être réutilisés ailleurs (badge sur le Profil) sans
/// dupliquer la liste. Purement informatif pour l'instant (pas de
/// remise automatique) — les avantages concrets par palier restent à
/// définir avec l'utilisateur.
class LoyaltyTier {
  final String name;
  final int minPoints;
  final Color color;
  final String perk;

  const LoyaltyTier(this.name, this.minPoints, this.color, this.perk);
}

const kLoyaltyTiers = [
  LoyaltyTier('Bronze', 0, Color(0xFFCD7F32), 'Membre AkoraHub'),
  LoyaltyTier('Argent', 1000, Color(0xFFA8A9AD), 'Client régulier reconnu'),
  LoyaltyTier('Or', 5000, Color(0xFFD4AF37), 'Client fidèle privilégié'),
];

LoyaltyTier currentLoyaltyTier(int points) {
  var result = kLoyaltyTiers.first;
  for (final tier in kLoyaltyTiers) {
    if (points >= tier.minPoints) result = tier;
  }
  return result;
}

LoyaltyTier? nextLoyaltyTier(int points) {
  for (final tier in kLoyaltyTiers) {
    if (tier.minPoints > points) return tier;
  }
  return null;
}
