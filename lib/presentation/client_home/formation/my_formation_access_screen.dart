import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/formation/course_purchases_repo.dart';
import '../../../core/formation/formation_repo.dart';

String _statusLabel(String status) {
  switch (status) {
    case 'validee':
      return 'Validé';
    case 'refusee':
      return 'Refusé';
    case 'en_attente':
    default:
      return 'En attente';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'validee':
      return Colors.green;
    case 'refusee':
      return Colors.red;
    case 'en_attente':
    default:
      return Colors.orange;
  }
}

/// "Mes accès" — historique de TOUTES les demandes d'achat du client
/// (matières premières + cours AkoraFormation, tous statuts), toutes
/// origines confondues (page externe conforme Google Play, phase49/50).
///
/// Ajouté le 02/08 suite à une confusion réelle : après un achat sur la
/// page externe, le client ne voyait aucun changement dans l'app (normal,
/// l'accès n'est débloqué qu'après validation staff) et ne retrouvait pas
/// non plus sa demande côté Admin (bug de repérage réel — voir
/// "Achats Formation" ajouté au menu Plus le même jour). Cet écran donne
/// au client une preuve directe que sa demande a bien été enregistrée,
/// avec son statut, sans devoir passer par l'Admin pour vérifier.
class MyFormationAccessScreen extends StatefulWidget {
  const MyFormationAccessScreen({super.key});

  @override
  State<MyFormationAccessScreen> createState() =>
      _MyFormationAccessScreenState();
}

class _MyFormationAccessScreenState extends State<MyFormationAccessScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      FormationRepo.fetchMyPurchases(),
      CoursePurchasesRepo.fetchMyCoursePurchases(),
    ]);
    final materials = results[0].map((p) {
      final material = p['raw_materials'] as Map?;
      return {
        'title': material?['name'] ?? 'Produit',
        'subtitle': material?['category_name'],
        'status': p['status'],
        'amount': p['amount'],
        'date': p['requested_at'],
        'icon': Icons.science_outlined,
      };
    });
    final courses = results[1].map((p) {
      final course = p['formation_courses'] as Map?;
      return {
        'title': course?['title'] ?? 'Cours',
        'subtitle': course?['category'],
        'status': p['status'],
        'amount': p['amount'],
        'date': p['created_at'],
        'icon': Icons.school_outlined,
      };
    });
    final merged = [...materials, ...courses]
      ..sort((a, b) =>
          (b['date'] as String).compareTo(a['date'] as String));
    if (!mounted) return;
    setState(() {
      _items = merged;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes accès')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 20.h),
                        Center(
                          child: Text(
                            'Aucun achat pour le moment.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => SizedBox(height: 1.h),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final status = item['status'] as String;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _statusColor(status).withValues(alpha: 0.15),
                              child: Icon(item['icon'] as IconData,
                                  color: _statusColor(status)),
                            ),
                            title: Text(item['title'] as String),
                            subtitle: Text([
                              if (item['subtitle'] != null) item['subtitle'],
                              _currency.format(item['amount']),
                              _dateFormat
                                  .format(DateTime.parse(item['date'] as String)),
                            ].where((e) => e != null).join(' · ')),
                            trailing: Chip(
                              label: Text(_statusLabel(status),
                                  style: const TextStyle(fontSize: 11)),
                              backgroundColor:
                                  _statusColor(status).withValues(alpha: 0.15),
                              labelStyle:
                                  TextStyle(color: _statusColor(status)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
