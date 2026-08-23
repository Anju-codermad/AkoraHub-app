import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';
import 'product_management_real.dart';

/// Audit des "Usages" déjà enregistrés sur chaque produit (14/08, sur
/// demande) : compare `products.use_cases` à la liste valide pour la
/// catégorie du produit (même source que le sélecteur du formulaire —
/// `kProductUsageSuggestionsByCategory` + les usages dérivés de
/// l'Académie) et signale les produits sans usage renseigné ou avec des
/// usages qui ne correspondent pas à leur catégorie (probablement laissés
/// par une catégorie précédente). Lecture seule : ne modifie rien tout
/// seul, la correction reste manuelle (bouton "Corriger" -> réouvre la
/// fiche produit).
class UsageAuditScreen extends StatefulWidget {
  const UsageAuditScreen({super.key});

  @override
  State<UsageAuditScreen> createState() => _UsageAuditScreenState();
}

class _UsageAuditScreenState extends State<UsageAuditScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _flagged = [];
  int _totalChecked = 0;

  @override
  void initState() {
    super.initState();
    _runAudit();
  }

  Future<void> _runAudit() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await SupabaseConfig.client
          .from('products')
          .select('id, name, category, use_cases, visibility')
          .order('name');

      final rawMaterialRows = await SupabaseConfig.client
          .from('raw_materials')
          .select('id, category_name');
      final rawMaterialOptions =
          List<Map<String, dynamic>>.from(rawMaterialRows);

      // Même dérivation que dans _showProductDialog (product_management_real.dart)
      // pour rester cohérent avec ce que le formulaire propose réellement.
      final academieUsagesByCategory = <String, Set<String>>{};
      try {
        final academieRows = await SupabaseConfig.client
            .from('matieres_premieres_academie')
            .select('id, matiere_premiere_id');
        final materialIdToAcademieId = <String, String>{
          for (final row in List<Map<String, dynamic>>.from(academieRows))
            row['matiere_premiere_id'] as String: row['id'] as String,
        };
        final academieIdToCategory = <String, String>{
          for (final m in rawMaterialOptions)
            if (materialIdToAcademieId[m['id']] != null &&
                m['category_name'] != null)
              materialIdToAcademieId[m['id']]!: m['category_name'] as String,
        };
        if (academieIdToCategory.isNotEmpty) {
          final usageRows = await SupabaseConfig.client
              .from('matieres_premieres_usages')
              .select('academie_id, domaine_application')
              .inFilter('academie_id', academieIdToCategory.keys.toList());
          for (final row in List<Map<String, dynamic>>.from(usageRows)) {
            final category = academieIdToCategory[row['academie_id']];
            final domaine = row['domaine_application'] as String?;
            if (category != null && domaine != null && domaine.isNotEmpty) {
              academieUsagesByCategory
                  .putIfAbsent(category, () => <String>{})
                  .add(domaine);
            }
          }
        }
      } catch (_) {
        // Repli silencieux : l'audit continue avec kProductUsageSuggestionsByCategory
        // seul si cette requête échoue.
      }

      final flagged = <Map<String, dynamic>>[];
      final allProducts = List<Map<String, dynamic>>.from(products);
      for (final p in allProducts) {
        final category = p['category'] as String?;
        final useCases =
            List<String>.from(p['use_cases'] ?? const []).toSet();

        final validList = kProductUsageSuggestionsByCategory[category] ??
            academieUsagesByCategory[category]?.toList();

        String? issue;
        if (useCases.isEmpty) {
          issue = 'Aucun usage renseigné';
        } else if (validList != null) {
          final validSet = validList.toSet();
          final unexpected = useCases.difference(validSet);
          if (unexpected.isNotEmpty) {
            issue =
                'Usage(s) hors catégorie "$category" : ${unexpected.join(', ')}';
          }
        }

        if (issue != null) {
          flagged.add({...p, '_issue': issue});
        }
      }

      if (!mounted) return;
      setState(() {
        _flagged = flagged;
        _totalChecked = allProducts.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de vérifier les usages.\n\nDétail : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification des Usages')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        SizedBox(height: 2.h),
                        FilledButton.icon(
                          onPressed: _runAudit,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _runAudit,
                  child: _flagged.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 15.h),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 48,
                                      color: theme.colorScheme.primary),
                                  SizedBox(height: 1.h),
                                  Text(
                                      '$_totalChecked produits vérifiés, aucun problème trouvé.'),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: EdgeInsets.all(4.w),
                          children: [
                            Text(
                              '${_flagged.length} produit(s) sur $_totalChecked à vérifier :',
                              style: theme.textTheme.titleMedium,
                            ),
                            SizedBox(height: 1.h),
                            ..._flagged.map((p) {
                              final isDraft = p['visibility'] == false;
                              return Card(
                                color: theme.colorScheme.errorContainer
                                    .withValues(alpha: 0.3),
                                child: ListTile(
                                  leading: Icon(Icons.report_outlined,
                                      color: theme.colorScheme.error),
                                  title: Text(p['name'] ?? ''),
                                  subtitle: Text(
                                    '${p['category'] ?? 'Sans catégorie'}'
                                    '${isDraft ? ' · Brouillon' : ''}\n'
                                    '${p['_issue']}',
                                  ),
                                  isThreeLine: true,
                                  trailing: FilledButton.tonal(
                                    onPressed: () =>
                                        Navigator.pop(context, p),
                                    child: const Text('Corriger'),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                ),
    );
  }
}
