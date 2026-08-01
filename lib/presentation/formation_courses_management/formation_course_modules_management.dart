import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Gestion Admin des modules (vidéo/document/texte) d'un cours
/// AkoraFormation — voir supabase/phase50_patch_course_purchases_and_content.sql.
/// Ce sont ces URLs qui constituent le vrai contenu vendu ; la RLS de
/// `formation_course_modules` bloque déjà leur lecture aux clients qui
/// n'ont pas validé leur achat de ce cours précis.
class FormationCourseModulesManagement extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const FormationCourseModulesManagement({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<FormationCourseModulesManagement> createState() =>
      _FormationCourseModulesManagementState();
}

class _FormationCourseModulesManagementState
    extends State<FormationCourseModulesManagement> {
  List<Map<String, dynamic>> _modules = [];
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
          .from('formation_course_modules')
          .select()
          .eq('course_id', widget.courseId)
          .order('sort_order');
      setState(() {
        _modules = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger les modules (migration phase50 exécutée ?).';
      });
    }
  }

  Future<void> _showModuleDialog({Map<String, dynamic>? module}) async {
    final isEditing = module != null;
    final titleCtrl = TextEditingController(text: module?['title'] ?? '');
    final videoCtrl = TextEditingController(text: module?['video_url'] ?? '');
    final documentCtrl =
        TextEditingController(text: module?['document_url'] ?? '');
    final contentCtrl =
        TextEditingController(text: module?['content_text'] ?? '');
    final sortOrderCtrl = TextEditingController(
        text: (module?['sort_order'] ?? _modules.length).toString());
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Modifier le module' : 'Nouveau module'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre du module'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: videoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL vidéo (optionnel)',
                    helperText: 'Lien direct vers le fichier vidéo hébergé',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: documentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL document (optionnel)',
                    helperText: 'PDF ou autre document hébergé',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Texte du module (optionnel)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sortOrderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ordre d\'affichage'),
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
                      if (titleCtrl.text.trim().isEmpty) return;
                      setDialogState(() => isSaving = true);
                      final payload = {
                        'course_id': widget.courseId,
                        'title': titleCtrl.text.trim(),
                        'video_url': videoCtrl.text.trim().isEmpty
                            ? null
                            : videoCtrl.text.trim(),
                        'document_url': documentCtrl.text.trim().isEmpty
                            ? null
                            : documentCtrl.text.trim(),
                        'content_text': contentCtrl.text.trim().isEmpty
                            ? null
                            : contentCtrl.text.trim(),
                        'sort_order':
                            int.tryParse(sortOrderCtrl.text.trim()) ?? 0,
                      };
                      try {
                        if (isEditing) {
                          await SupabaseConfig.client
                              .from('formation_course_modules')
                              .update(payload)
                              .eq('id', module['id']);
                        } else {
                          await SupabaseConfig.client
                              .from('formation_course_modules')
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
                              content: Text('Erreur lors de l\'enregistrement.')),
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

  Future<void> _deleteModule(Map<String, dynamic> module) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce module ?'),
        content: Text('"${module['title']}" sera définitivement supprimé.'),
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
          .from('formation_course_modules')
          .delete()
          .eq('id', module['id']);
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
      appBar: AppBar(title: Text('Modules — ${widget.courseTitle}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showModuleDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Module'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _modules.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            Center(
                              child: Text(
                                'Aucun module — ajoutez le premier contenu de ce cours.',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _modules.length,
                          itemBuilder: (context, index) {
                            final m = _modules[index];
                            return Card(
                              child: ListTile(
                                title: Text(m['title'] ?? ''),
                                subtitle: Text([
                                  if (m['video_url'] != null) 'Vidéo',
                                  if (m['document_url'] != null) 'Document',
                                  if (m['content_text'] != null) 'Texte',
                                ].join(' · ')),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _deleteModule(m),
                                ),
                                onTap: () => _showModuleDialog(module: m),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
