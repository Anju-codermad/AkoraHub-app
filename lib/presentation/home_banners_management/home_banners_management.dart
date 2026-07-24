import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';

/// Gestion de la bannière "hero" de l'écran d'accueil client.
/// Strictement réservé à l'Admin (RLS côté serveur : voir
/// supabase/phase6_patch_home_banners.sql) — le reste du staff (commercial,
/// production, comptable) ne peut ni ajouter ni changer les photos ici.
class HomeBannersManagement extends StatefulWidget {
  const HomeBannersManagement({super.key});

  @override
  State<HomeBannersManagement> createState() => _HomeBannersManagementState();
}

class _HomeBannersManagementState extends State<HomeBannersManagement> {
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
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
          .from('home_banners')
          .select()
          .order('sort_order');
      setState(() {
        _banners = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } on PostgrestException catch (e) {
      setState(() {
        _isLoading = false;
        // Erreur 42501 typique = policy RLS qui bloque un non-Admin.
        _error = e.code == '42501'
            ? 'Accès réservé à l\'Admin.'
            : 'Impossible de charger les bannières.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les bannières.';
      });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> banner) async {
    try {
      await SupabaseConfig.client
          .from('home_banners')
          .update({'active': !(banner['active'] as bool? ?? true)}).eq(
              'id', banner['id']);
      _loadBanners();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de modifier le statut.')),
      );
    }
  }

  Future<void> _reorder(Map<String, dynamic> banner, int delta) async {
    final currentOrder = banner['sort_order'] as int? ?? 0;
    try {
      await SupabaseConfig.client
          .from('home_banners')
          .update({'sort_order': currentOrder + delta}).eq('id', banner['id']);
      _loadBanners();
    } catch (_) {
      // Silencieux : réordonner n'est pas critique.
    }
  }

  Future<void> _delete(Map<String, dynamic> banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette bannière ?'),
        content: Text(
            'La bannière "${banner['title']}" sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseConfig.client
          .from('home_banners')
          .delete()
          .eq('id', banner['id']);
      _loadBanners();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer la bannière.')),
      );
    }
  }

  Future<void> _showEditSheet({Map<String, dynamic>? banner}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _BannerEditForm(
          banner: banner,
          onSaved: _loadBanners,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Bannière hero — Accueil')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditSheet(),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Ajouter'),
      ),
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
                        OutlinedButton(
                          onPressed: _loadBanners,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBanners,
                  child: _banners.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Text(
                                  'Aucune bannière pour le moment.\nTant qu\'aucune n\'est active, l\'accueil client garde ses 3 slides par défaut.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _banners.length,
                          separatorBuilder: (_, __) => SizedBox(height: 1.h),
                          itemBuilder: (context, index) {
                            final banner = _banners[index];
                            final active = banner['active'] as bool? ?? true;
                            final imageUrl = banner['image_url'] as String?;
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  backgroundImage: imageUrl != null
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  child: imageUrl == null
                                      ? Icon(Icons.image_outlined,
                                          color: theme.colorScheme.outline)
                                      : null,
                                ),
                                title: Text(banner['title'] ?? ''),
                                subtitle: Text(
                                  banner['subtitle'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.arrow_upward_rounded, size: 18),
                                      tooltip: 'Monter',
                                      onPressed: () => _reorder(banner, -1),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.arrow_downward_rounded,
                                          size: 18),
                                      tooltip: 'Descendre',
                                      onPressed: () => _reorder(banner, 1),
                                    ),
                                    Switch(
                                      value: active,
                                      onChanged: (_) => _toggleActive(banner),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') {
                                          _showEditSheet(banner: banner);
                                        } else if (v == 'delete') {
                                          _delete(banner);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Modifier'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

class _BannerEditForm extends StatefulWidget {
  final Map<String, dynamic>? banner;
  final VoidCallback onSaved;

  const _BannerEditForm({this.banner, required this.onSaved});

  @override
  State<_BannerEditForm> createState() => _BannerEditFormState();
}

class _BannerEditFormState extends State<_BannerEditForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  File? _newImage;
  bool _isSaving = false;

  bool get _isEditing => widget.banner != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.banner?['title'] ?? '');
    _subtitleController =
        TextEditingController(text: widget.banner?['subtitle'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? imageUrl = widget.banner?['image_url'] as String?;
      if (_newImage != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${userId ?? 'admin'}.jpg';
        await SupabaseConfig.client.storage
            .from('home-banners')
            .upload(fileName, _newImage!);
        imageUrl = SupabaseConfig.client.storage
            .from('home-banners')
            .getPublicUrl(fileName);
      }

      final payload = {
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'image_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_isEditing) {
        await SupabaseConfig.client
            .from('home_banners')
            .update(payload)
            .eq('id', widget.banner!['id']);
      } else {
        await SupabaseConfig.client.from('home_banners').insert({
          ...payload,
          'sort_order': 0,
          'active': true,
          'created_by': userId,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.code == '42501'
              ? 'Action réservée à l\'Admin.'
              : 'Erreur : ${e.message}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'enregistrer la bannière.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingImageUrl = widget.banner?['image_url'] as String?;

    return Padding(
      padding: EdgeInsets.fromLTRB(5.w, 3.h, 5.w, 3.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing ? 'Modifier la bannière' : 'Nouvelle bannière',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 2.h),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 16.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                image: _newImage != null
                    ? DecorationImage(
                        image: FileImage(_newImage!), fit: BoxFit.cover)
                    : (existingImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(existingImageUrl),
                            fit: BoxFit.cover)
                        : null),
              ),
              child: (_newImage == null && existingImageUrl == null)
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: theme.colorScheme.outline, size: 32),
                          SizedBox(height: 0.5.h),
                          Text('Choisir une photo',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.edit,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              hintText: 'ex: Vos produits, en un clic',
            ),
            maxLines: 2,
          ),
          SizedBox(height: 1.5.h),
          TextField(
            controller: _subtitleController,
            decoration: const InputDecoration(
              labelText: 'Sous-titre',
              hintText: 'ex: Rapide, fiable, adapté à votre activité',
            ),
            maxLines: 2,
          ),
          SizedBox(height: 2.5.h),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
