import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/formation/formation_groups_repo.dart';
import '../client_home/formation/akora_formation_screen.dart'
    show iconForFormationCategory;
import '../client_home/formation/formation_group_screen.dart';

/// Liste de toutes les catégories de formation, pour que le staff
/// accède au fil de n'importe quel groupe à des fins de modération —
/// voir supabase/phase56_patch_formation_groups.sql : le staff
/// contourne la vérification "participant" via la RLS
/// (`current_role_is_staff()`), mais a besoin de connaître les
/// catégories existantes pour y accéder (contrairement au client, il
/// n'a pas forcément de cours acheté dans chacune).
class FormationGroupsManagement extends StatefulWidget {
  const FormationGroupsManagement({super.key});

  @override
  State<FormationGroupsManagement> createState() =>
      _FormationGroupsManagementState();
}

class _FormationGroupsManagementState
    extends State<FormationGroupsManagement> {
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final categories = await FormationGroupsRepo.fetchAllCourseCategories();
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
      appBar: AppBar(title: const Text('Groupes Formation')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _categories.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 20.h),
                        Center(
                          child: Text('Aucune catégorie pour le moment.',
                              style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    )
                  : ListView(
                      padding: EdgeInsets.all(4.w),
                      children: [
                        for (final category in _categories)
                          Card(
                            margin: EdgeInsets.only(bottom: 1.h),
                            child: ListTile(
                              leading: Icon(
                                  iconForFormationCategory(category)),
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
