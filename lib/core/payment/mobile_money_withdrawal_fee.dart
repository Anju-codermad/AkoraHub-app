/// Estimation du frais de retrait Mobile Money (grille tarifaire "Retrait"
/// — captures fournies par l'utilisatrice : Mvola le 31/07, Orange Money
/// le 01/08) — purement informatif pour le client, ne change jamais le
/// montant qu'il paie. Le vrai palier appliqué dépend du montant total
/// retiré en une fois par le marchand (qui peut cumuler plusieurs
/// commandes avant un seul retrait) : ce calcul suppose que cette
/// commande serait retirée seule, donc n'est qu'une approximation.
///
/// Mvola et Orange Money partagent exactement les mêmes paliers "Retrait"
/// sur toute la plage confirmée par capture (200 Ar à 1 000 000 Ar) — une
/// seule grille sert donc aux deux opérateurs. Au-delà de 1 000 000 Ar,
/// seuls les paliers Mvola ont été vus en capture ; ils sont réutilisés
/// par extrapolation pour Orange Money (mêmes paliers jusque-là).
class MobileMoneyWithdrawalFee {
  MobileMoneyWithdrawalFee._();

  static const List<(double maxAmount, double fee)> _tiers = [
    (1000, 100),
    (5000, 150),
    (10000, 275),
    (20000, 550),
    (25000, 650),
    (50000, 1300),
    (100000, 1900),
    (250000, 3400),
    (500000, 4700),
    (1000000, 8800),
    (2000000, 14700),
    (3000000, 19600),
    (4000000, 24500),
    (5000000, 29400),
    (6000000, 34300),
    (7000000, 39200),
    (8000000, 44100),
    (9000000, 49000),
    (10000000, 53900),
    (11000000, 59000),
    (12000000, 64000),
    (13000000, 69000),
    (14000000, 74000),
    (15000000, 79000),
    (16000000, 84000),
    (17000000, 89000),
    (18000000, 94000),
    (19000000, 98000),
    (20000000, 100000),
  ];

  static double estimate(double amount) {
    for (final (maxAmount, fee) in _tiers) {
      if (amount <= maxAmount) return fee;
    }
    return _tiers.last.$2;
  }
}
