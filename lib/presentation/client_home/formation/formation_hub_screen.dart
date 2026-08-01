import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/supabase/supabase_config.dart';
import 'akora_formation_screen.dart';
import 'formation_catalog_screen.dart';

/// Point d'accès unique "A-Formation" (onglet dédié de la barre de
/// navigation) — regroupe en une seule liste les catégories de cours
/// AkoraFormation ET les matières premières, comme une catégorie de plus
/// parmi les autres (demande explicite de l'utilisatrice, 01/08 : "le
/// matières premières fait partie d'autres modules de formation").
/// Chaque carte ouvre soit la liste des formations de cette catégorie
/// (`AkoraFormationScreen`), soit la base de matières premières
/// (`FormationCatalogScreen`, abonnement requis pour le détail complet).
class FormationHubScreen extends StatefulWidget {
  const FormationHubScreen({super.key});

  @override
  State<FormationHubScreen> createState() => _FormationHubScreenState();
}

class _FormationHubScreenState extends State<FormationHubScreen> {
  List<Map<String, dynamic>> _categoryCounts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseConfig.client
          .from('formation_courses')
          .select('category');
      final rows = List<Map<String, dynamic>>.from(data);
      final counts = <String, int>{};
      for (final row in rows) {
        final category = row['category'] as String;
        counts[category] = (counts[category] ?? 0) + 1;
      }
      final list = counts.entries
          .map((e) => {'category': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) =>
            (a['category'] as String).compareTo(b['category'] as String));
      setState(() {
        _categoryCounts = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger A-Formation pour le moment.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('A-Formation')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: EdgeInsets.all(4.w),
                    children: [
                      Text(
                        'Cours, modules et matières premières — tout au même endroit.',
                        style: theme.textTheme.bodySmall,
                      ),
                      SizedBox(height: 2.h),
                      for (final c in _categoryCounts)
                        Card(
                          margin: EdgeInsets.only(bottom: 1.h),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(
                                iconForFormationCategory(
                                    c['category'] as String),
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(c['category'] as String),
                            subtitle: Text('${c['count']} formations'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AkoraFormationScreen(
                                  initialCategory: c['category'] as String,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Card(
                        margin: EdgeInsets.only(bottom: 1.h),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            child: Icon(Icons.science_outlined,
                                color: theme.colorScheme.onSecondaryContainer),
                          ),
                          title: const Text('Matières premières'),
                          subtitle: const Text(
                              'Fiches ingrédients — détail complet sur abonnement'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FormationCatalogScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
