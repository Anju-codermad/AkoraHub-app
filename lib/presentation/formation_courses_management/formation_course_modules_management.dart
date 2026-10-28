import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/private_storage_image.dart';
import '../../core/supabase/supabase_config.dart';

/// Taille max d'une vidéo de formation (bucket privé `formation-videos`,
/// voir supabase/phase275_patch_formation_videos_bucket.sql) — plus
/// généreuse que les 25 Mo des pièces jointes de messagerie, ces vidéos
/// étant du contenu pédagogique potentiellement long.
const int _kMaxVideoSizeBytes = 300 * 1024 * 1024;

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
    final photoUrls = List<String>.from(
        ((module?['photo_urls'] as List?) ?? []).map((e) => e.toString()));
    bool isSaving = false;
    bool isUploadingVideo = false;
    bool isUploadingPhotos = false;

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
                    labelText: 'Vidéo (optionnel)',
                    helperText: 'Utilisez le bouton ci-dessous — ce champ se '
                        'remplit automatiquement (bucket privé, pas de lien '
                        'à coller).',
                  ),
                ),
                const SizedBox(height: 6),
                if (isUploadingVideo)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: LinearProgressIndicator(minHeight: 3),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker()
                          .pickVideo(source: ImageSource.gallery);
                      if (picked == null) return;
                      final file = File(picked.path);
                      final sizeBytes = await file.length();
                      if (sizeBytes > _kMaxVideoSizeBytes) {
                        if (!context.mounted) return;
                        final mb =
                            (_kMaxVideoSizeBytes / (1024 * 1024)).round();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Vidéo trop volumineuse (max $mb Mo).')),
                        );
                        return;
                      }
                      setDialogState(() => isUploadingVideo = true);
                      try {
                        final ext = picked.path.contains('.')
                            ? picked.path.split('.').last
                            : 'mp4';
                        final path =
                            '${widget.courseId}/${DateTime.now().millisecondsSinceEpoch}.$ext';
                        await SupabaseConfig.client.storage
                            .from('formation-videos')
                            .upload(path, file);
                        // Bucket privé (phase275) : on stocke le CHEMIN,
                        // pas une URL publique — la lecture passe par le
                        // SDK authentifié (storage.download()), jamais
                        // par un lien qui pourrait être copié/partagé.
                        videoCtrl.text = path;
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Échec de l\'envoi de la vidéo.')),
                          );
                        }
                      } finally {
                        setDialogState(() => isUploadingVideo = false);
                      }
                    },
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: const Text('Uploader une vidéo depuis le téléphone'),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: documentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL document (optionnel)',
                    helperText: 'PDF ou autre document hébergé',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Photos (optionnel)'),
                const SizedBox(height: 6),
                if (photoUrls.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: photoUrls.map((url) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: PrivateStorageImage(
                              bucket: 'formation-videos',
                              path: url,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: InkWell(
                              onTap: () =>
                                  setDialogState(() => photoUrls.remove(url)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                if (photoUrls.isNotEmpty) const SizedBox(height: 8),
                if (isUploadingPhotos)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: LinearProgressIndicator(minHeight: 3),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked =
                          await ImagePicker().pickMultiImage(imageQuality: 85);
                      if (picked.isEmpty) return;
                      setDialogState(() => isUploadingPhotos = true);
                      for (final picture in picked) {
                        try {
                          final file = File(picture.path);
                          final ext = picture.path.contains('.')
                              ? picture.path.split('.').last
                              : 'jpg';
                          final path =
                              '${widget.courseId}/${DateTime.now().millisecondsSinceEpoch}_${photoUrls.length}.$ext';
                          await SupabaseConfig.client.storage
                              .from('formation-videos')
                              .upload(path, file);
                          // Bucket privé (phase275) : chemin stocké, pas
                          // d'URL publique — voir PrivateStorageImage.
                          photoUrls.add(path);
                        } catch (_) {
                          // Continue avec les photos suivantes de la
                          // sélection même si l'une d'elles échoue.
                        }
                      }
                      setDialogState(() => isUploadingPhotos = false);
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 18),
                    label: const Text('Ajouter des photos'),
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
              onPressed: isSaving || isUploadingVideo || isUploadingPhotos
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
                        'photo_urls': photoUrls,
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
                                  if ((m['photo_urls'] as List?)
                                          ?.isNotEmpty ==
                                      true)
                                    '${(m['photo_urls'] as List).length} photo(s)',
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
