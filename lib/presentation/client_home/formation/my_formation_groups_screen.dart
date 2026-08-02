import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/formation/formation_groups_repo.dart';
import 'akora_formation_screen.dart' show iconForFormationCategory;
import 'formation_group_screen.dart';

/// "Mes groupes" — liste des catégories de formation dont le client
/// connecté est participant validé (au moins un cours acheté et validé
/// dans cette catégorie, voir supabase/phase56_patch_formation_groups.sql).
/// Un client qui n'a encore rien acheté voit une liste vide avec un
/// message explicite plutôt qu'un écran cassé.
class MyFormationGroupsScreen extends StatefulWidget {
  const MyFormationGroupsScreen({super.key});

  @override
  State<MyFormationGroupsScreen> createState() =>
      _MyFormationGroupsScreenState();
}

class _MyFormationGroupsScreenState extends State<MyFormationGroupsScreen> {
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final categories = await FormationGroupsRepo.fetchMyGroupCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes groupes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _categories.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 20.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            'Achetez et faites valider un cours AkoraFormation pour rejoindre le groupe de sa catégorie.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: EdgeInsets.all(4.w),
                      children: [
                        Text(
                          'Réservés aux clients ayant un cours validé dans cette catégorie.',
                          style: theme.textTheme.bodySmall,
                        ),
                        SizedBox(height: 1.h),
                        for (final category in _categories)
                          Card(
                            margin: EdgeInsets.only(bottom: 1.h),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Icon(
                                    iconForFormationCategory(category),
                                    color: theme
                                        .colorScheme.onPrimaryContainer),
                              ),
                              title: Text(category),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FormationGroupScreen(
                                      category: category),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
    );
  }
}
