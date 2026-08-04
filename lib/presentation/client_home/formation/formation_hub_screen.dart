import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/supabase/supabase_config.dart';
import 'akora_formation_screen.dart';
import 'formation_catalog_screen.dart';
import 'my_formation_access_screen.dart';
import 'my_formation_groups_screen.dart';

/// Point d'accès unique "Académie" (onglet dédié de la barre de
/// navigation) — regroupe en une seule liste les catégories de cours
/// AkoraFormation ET les matières premières, comme une catégorie de plus
/// parmi les autres (demande explicite de l'utilisatrice, 01/08 : "le
/// matières premières fait partie d'autres modules de formation").
/// Chaque carte ouvre soit la liste des formations de cette catégorie
/// (`AkoraFormationScreen`), soit la base de matières premières
/// (`FormationCatalogScreen`, achat par produit requis pour le détail
/// complet — voir supabase/phase45_patch_formation_per_product_pricing.sql).
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
        _error = 'Impossible de charger Académie pour le moment.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Académie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Mes groupes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MyFormationGroupsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Mes accès',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MyFormationAccessScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(4.w, 4.w, 4.w, 0),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Cours, modules et matières premières — tout au même endroit.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.all(4.w),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 3.w,
                            crossAxisSpacing: 3.w,
                            childAspectRatio: 0.92,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              // Matières premières apparaît comme une
                              // catégorie de plus, en dernière position
                              // (demande explicite de l'utilisatrice :
                              // "le matières premières fait partie
                              // d'autres modules de formation").
                              if (index == _categoryCounts.length) {
                                return _buildCategoryTile(
                                  theme,
                                  icon: Icons.science_outlined,
                                  iconBg: theme.colorScheme.secondaryContainer,
                                  iconColor:
                                      theme.colorScheme.onSecondaryContainer,
                                  title: 'Matières premières',
                                  subtitle: 'Fiches ingrédients',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const FormationCatalogScreen()),
                                  ),
                                );
                              }
                              final c = _categoryCounts[index];
                              return _buildCategoryTile(
                                theme,
                                icon: iconForFormationCategory(
                                    c['category'] as String),
                                iconBg: theme.colorScheme.primaryContainer,
                                iconColor: theme.colorScheme.onPrimaryContainer,
                                title: c['category'] as String,
                                subtitle: '${c['count']} formations',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AkoraFormationScreen(
                                      initialCategory: c['category'] as String,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _categoryCounts.length + 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCategoryTile(
    ThemeData theme, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 7.w,
                backgroundColor: iconBg,
                child: Icon(icon, color: iconColor, size: 7.w),
              ),
              SizedBox(height: 1.5.h),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: 0.5.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
