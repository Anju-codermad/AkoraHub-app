import 'package:flutter/material.dart';

/// Modes de paiement disponibles au checkout. Le paiement en ligne
/// (carte bancaire, marchand Mobile Money) n'existe pas encore — voir
/// PROJECT_CONTEXT.md, dossier BNI/Mobile Money en cours. En attendant,
/// ces 4 modes sont manuels : le client transfère lui-même vers le
/// compte/numéro affiché, puis le staff vérifie la réception (relevé
/// bancaire ou SMS opérateur) et marque la commande payée depuis
/// `order_management_real.dart` (colonne `payment_status`, déjà
/// existante — aucun changement nécessaire côté vérification).
enum PaymentMethod { paiementLivraison, virementBancaire, orangeMoney, mvola, airtelMoney }

extension PaymentMethodX on PaymentMethod {
  /// Valeur stable stockée dans `orders.payment_method` (voir
  /// supabase/phase27_patch_orders_payment_method.sql).
  String get id {
    switch (this) {
      case PaymentMethod.paiementLivraison:
        return 'paiement_livraison';
      case PaymentMethod.virementBancaire:
        return 'virement_bancaire';
      case PaymentMethod.orangeMoney:
        return 'orange_money';
      case PaymentMethod.mvola:
        return 'mvola';
      case PaymentMethod.airtelMoney:
        return 'airtel_money';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.paiementLivraison:
        return 'Paiement à la livraison';
      case PaymentMethod.virementBancaire:
        return 'Virement bancaire';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.mvola:
        return 'Mvola';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.paiementLivraison:
        return Icons.local_shipping_outlined;
      case PaymentMethod.virementBancaire:
        return Icons.account_balance_outlined;
      case PaymentMethod.orangeMoney:
      case PaymentMethod.mvola:
      case PaymentMethod.airtelMoney:
        return Icons.phone_android_outlined;
    }
  }

  /// Logo réel de l'opérateur (fourni par l'utilisateur), affiché à la
  /// place de `icon` quand disponible. `null` pour les modes sans
  /// opérateur (paiement à la livraison, virement bancaire) — l'icône
  /// générique ci-dessus est utilisée à la place.
  String? get logoAsset {
    switch (this) {
      case PaymentMethod.paiementLivraison:
      case PaymentMethod.virementBancaire:
        return null;
      case PaymentMethod.orangeMoney:
        return 'assets/images/payment_orange_money.jpg';
      case PaymentMethod.mvola:
        return 'assets/images/payment_mvola.jpg';
      case PaymentMethod.airtelMoney:
        return 'assets/images/payment_airtel_money.jpg';
    }
  }

  /// Coordonnées réelles à afficher au client pour effectuer le paiement
  /// avant validation de la commande. `null` pour le paiement à la
  /// livraison, qui n'en a pas besoin.
  String? get instructions {
    switch (this) {
      case PaymentMethod.paiementLivraison:
        return null;
      case PaymentMethod.virementBancaire:
        return 'BNI Madagascar — Agence Analakely\n'
            'Titulaire : ANDRINIRINA\n'
            'IBAN : MG46 0000 5000 8175 0487 0000 141\n'
            'BIC : CLMDMGMG';
      case PaymentMethod.orangeMoney:
        return 'Orange Money : 037 34 786 84\n'
            'Titulaire : ANDRINIRINA Julio';
      case PaymentMethod.mvola:
        return 'Mvola : 034 08 746 96\n'
            'Titulaire : Akora Fanadiovana';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money : 033 19 581 85\n'
            'Titulaire : ANDRINIRINA Julio';
    }
  }

  static PaymentMethod fromId(String? id) {
    for (final m in PaymentMethod.values) {
      if (m.id == id) return m;
    }
    return PaymentMethod.paiementLivraison;
  }
}
