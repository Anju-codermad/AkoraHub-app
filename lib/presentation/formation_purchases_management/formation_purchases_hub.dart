import 'package:flutter/material.dart';

import '../course_purchases_management/course_purchases_management.dart';
import 'academie_purchases_management.dart';
import 'formation_purchases_management.dart';

/// Validation des achats Formation (02/08) — fusionne les écrans de
/// validation qui existaient séparément dans le menu Plus (Matières
/// premières / Cours AkoraFormation), sources de confusion pour le
/// staff. Les catalogues restent des tables Supabase distinctes
/// (`formation_purchases` / `course_purchases` / `academie_purchases`
/// depuis le 06/08), seule la navigation est regroupée ici via un TabBar.
///
/// Depuis le 06/08 : sans AppBar/titre propre (toolbarHeight: 0, juste
/// la barre d'onglets) — utilisé comme onglet "Achats" de FormationHub
/// (fusion avec "Matières premières (Formation)"), voir
/// raw_materials_management/formation_hub.dart. Plus jamais poussé seul,
/// donc pas besoin de bouton retour.
class FormationPurchasesHub extends StatelessWidget {
  const FormationPurchasesHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Demandes Matières'),
              Tab(text: 'Demandes Cours'),
              Tab(text: 'Demandes Académie'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FormationPurchasesManagement(),
            CoursePurchasesManagement(),
            AcademiePurchasesManagement(),
          ],
        ),
      ),
    );
  }
}
