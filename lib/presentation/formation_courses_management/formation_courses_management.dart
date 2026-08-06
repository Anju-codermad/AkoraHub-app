import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';
import 'formation_course_modules_management.dart';

const _statusOptions = ['deja_developpee', 'en_projet', 'a_creer'];

String _statusLabel(String status) {
  switch (status) {
    case 'deja_developpee':
      return 'Déjà développée';
    case 'en_projet':
      return 'En projet';
    case 'a_creer':
    default:
      return 'À créer';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'deja_developpee':
      return Colors.green;
    case 'en_projet':
      return Colors.orange;
    case 'a_creer':
    default:
      return Colors.blueGrey;
  }
}

/// Gestion Admin de la liste des formations/modules AkoraFormation — voir
/// supabase/phase43_patch_formation_courses.sql. Pour l'instant juste la
/// structure (catégorie, titre, statut, nombre de modules), pas encore
/// le contenu réel des cours.
///
/// Depuis le 06/08 : sans Scaffold propre d'AppBar (juste body + FAB) —
/// utilisé comme onglet "Cours" de FormationHub (fusion avec "Matières
/// premières" et "Achats Formation"), voir
/// raw_materials_management/formation_hub.dart.
class FormationCoursesManagement extends StatefulWidget {
  const FormationCoursesManagement({super.key});

  @override
  State<FormationCoursesManagement> createState() =>
      _FormationCoursesManagementState();
}

class _FormationCoursesManagementState
    extends State<FormationCoursesManagement> {
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion au serveur indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseConfig.client
          .from('formation_courses')
          .select()
          .order('category')
          .order('sort_order');
      setState(() {
        _courses = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger les formations (migration phase43 exécutée ?).';
      });
    }
  }

  List<String> get _categories =>
      _courses.map((c) => c['category'] as String).toSet().toList()..sort();

  Future<void> _showCourseDialog({Map<String, dynamic>? course}) async {
    final isEditing = course != null;
    final categoryCtrl =
        TextEditingController(text: course?['category'] ?? '');
    final titleCtrl = TextEditingController(text: course?['title'] ?? '');
    final moduleCountCtrl =
        TextEditingController(text: (course?['module_count'] ?? '').toString());
    final priceCtrl =
        TextEditingController(text: (course?['price'] ?? '').toString());
    String status = course?['status'] ?? 'a_creer';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Modifier la formation' : 'Nouvelle formation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Autocomplete<String>(
                  optionsBuilder: (v) => v.text.trim().isEmpty
                      ? const Iterable<String>.empty()
                      : _categories.where(
                          (c) => c.toLowerCase().contains(v.text.toLowerCase())),
                  onSelected: (v) => categoryCtrl.text = v,
                  fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                    controller.text = categoryCtrl.text;
                    controller.selection = TextSelection.collapsed(
                        offset: controller.text.length);
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                      onChanged: (v) => categoryCtrl.text = v,
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre de la formation'),
                ),
                const SizedBox(height: 12),
                const Text('Statut'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: _statusOptions.map((s) {
                    return ChoiceChip(
                      label: Text(_statusLabel(s)),
                      selected: status == s,
                      selectedColor: _statusColor(s).withValues(alpha: 0.25),
                      onSelected: (_) => setDialogState(() => status = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: moduleCountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Nombre de modules (optionnel)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prix (Ar, optionnel)',
                    helperText:
                        'Laissez vide tant que le cours n\'est pas en vente — '
                        'un prix rend le bouton "Acheter" visible côté client.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (categoryCtrl.text.trim().isEmpty ||
                          titleCtrl.text.trim().isEmpty) {
                        return;
                      }
                      setDialogState(() => isSaving = true);
                      final payload = {
                        'category': categoryCtrl.text.trim(),
                        'title': titleCtrl.text.trim(),
                        'status': status,
                        'module_count': int.tryParse(moduleCountCtrl.text),
                        'price': num.tryParse(priceCtrl.text.trim()),
                      };
                      try {
                        if (isEditing) {
                          await SupabaseConfig.client
                              .from('formation_courses')
                              .update(payload)
                              .eq('id', course['id']);
                        } else {
                          await SupabaseConfig.client
                              .from('formation_courses')
                              .insert(payload);
                        }
                        if (!mounted) return;
                        Navigator.pop(context);
                        _loadData();
                      } catch (e) {
                        if (!mounted) return;
                        setDialogState(() => isSaving = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Erreur — ce titre existe peut-être déjà dans cette catégorie.')),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCourse(Map<String, dynamic> course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette formation ?'),
        content: Text('"${course['title']}" sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseConfig.client
          .from('formation_courses')
          .delete()
          .eq('id', course['id']);
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur lors de la suppression.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Formation'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _courses.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            Center(
                              child: Text(
                                'Aucune formation pour le moment.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: EdgeInsets.all(4.w),
                          children: [
                            for (final category in _categories) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(category,
                                    style: theme.textTheme.titleMedium),
                              ),
                              ..._courses
                                  .where((c) => c['category'] == category)
                                  .map((c) {
                                final status = c['status'] as String;
                                final price = c['price'] as num?;
                                return Card(
                                  child: ListTile(
                                    title: Text(c['title'] ?? ''),
                                    subtitle: Text([
                                      if (c['module_count'] != null)
                                        '${c['module_count']} modules',
                                      if (price != null)
                                        NumberFormat.currency(
                                                locale: 'fr_FR',
                                                symbol: 'Ar',
                                                decimalDigits: 0)
                                            .format(price),
                                    ].join(' · ')),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Chip(
                                          label: Text(_statusLabel(status),
                                              style: const TextStyle(fontSize: 11)),
                                          backgroundColor: _statusColor(status)
                                              .withValues(alpha: 0.15),
                                          labelStyle: TextStyle(
                                              color: _statusColor(status)),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.video_collection_outlined,
                                              size: 20),
                                          tooltip: 'Modules (vidéo/document)',
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  FormationCourseModulesManagement(
                                                courseId: c['id'],
                                                courseTitle: c['title'] ?? '',
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 20),
                                          onPressed: () => _deleteCourse(c),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _showCourseDialog(course: c),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                ),
    );
  }
}
