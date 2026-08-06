import 'package:flutter/material.dart';

import '../formation_purchases_management/formation_purchases_hub.dart';
import 'raw_materials_management.dart';

/// Point d'entrée unique "Formation" (06/08) — fusionne "Matières
/// premières (Formation)" (gestion du contenu des fiches, y compris
/// désormais les fiches Académie) et "Achats Formation" (validation des
/// paiements matières/cours/Académie) en un seul écran à onglets, pour
/// réduire le menu Plus admin (retour explicite de l'utilisatrice : les
/// deux entrées séparées créaient de la confusion). Les deux restent des
/// écrans/tables Supabase distincts, seule la navigation est regroupée —
/// même principe que la fusion précédente de FormationPurchasesHub.
class FormationHub extends StatelessWidget {
  const FormationHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Formation'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Fiches'),
              Tab(text: 'Achats'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RawMaterialsManagement(),
            FormationPurchasesHub(),
          ],
        ),
      ),
    );
  }
}
