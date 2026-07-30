/// Modèle représentant un mode de paiement mobile money disponible
/// pour les commandes AkoraHub (Madagascar).
class PaymentMethod {
  final String id;
  final String label;
  final String logoAsset;

  const PaymentMethod({
    required this.id,
    required this.label,
    required this.logoAsset,
  });

  static const List<PaymentMethod> available = [
    PaymentMethod(
      id: 'orange_money',
      label: 'Orange Money',
      logoAsset: 'assets/images/payment_orange_money.jpg',
    ),
    PaymentMethod(
      id: 'mvola',
      label: 'Mvola',
      logoAsset: 'assets/images/payment_mvola.jpg',
    ),
    PaymentMethod(
      id: 'airtel_money',
      label: 'Airtel Money',
      logoAsset: 'assets/images/payment_airtel_money.jpg',
    ),
  ];
}
