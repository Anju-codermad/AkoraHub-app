import 'package:flutter/material.dart';

import '../course_purchases_management/course_purchases_management.dart';
import 'academie_purchases_management.dart';
import 'formation_purchases_management.dart';

/// Point d'entrée unique "Achats Formation" (02/08) — fusionne les
/// écrans de validation qui existaient séparément dans le menu Plus
/// (Matières premières / Cours AkoraFormation), sources de confusion pour
/// le staff. Les catalogues restent des tables Supabase distinctes
/// (`formation_purchases` / `course_purchases` / `academie_purchases`
/// depuis le 06/08), seule la navigation est regroupée ici via un TabBar.
class FormationPurchasesHub extends StatelessWidget {
  const FormationPurchasesHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Achats Formation'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Matières premières'),
              Tab(text: 'Cours'),
              Tab(text: 'Académie'),
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
