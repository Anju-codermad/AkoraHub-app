import 'package:flutter/material.dart';

import '../formation_courses_management/formation_courses_management.dart';
import '../formation_purchases_management/formation_purchases_hub.dart';
import 'raw_materials_management.dart';

/// Point d'entrée unique "Formation" (06/08) — fusionne "Matières
/// premières (Formation)" (gestion du contenu des fiches, y compris
/// désormais les fiches Académie), "AkoraFormation — Cours & Modules"
/// (gestion du contenu des cours) et "Achats Formation" (validation des
/// paiements matières/cours/Académie) en un seul écran à onglets, pour
/// réduire le menu Plus admin (retour explicite de l'utilisatrice : ces
/// entrées séparées créaient de la confusion). Chacune reste un
/// écran/table Supabase distinct, seule la navigation est regroupée —
/// même principe que la fusion précédente de FormationPurchasesHub.
/// "Groupes Formation" (modération des fils communautaires) reste
/// volontairement à part : ce n'est pas de la gestion de catalogue.
class FormationHub extends StatelessWidget {
  const FormationHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Formation'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Matières'),
              Tab(text: 'Cours'),
              Tab(text: 'Achats'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            RawMaterialsManagement(),
            FormationCoursesManagement(),
            FormationPurchasesHub(),
          ],
        ),
      ),
    );
  }
}
