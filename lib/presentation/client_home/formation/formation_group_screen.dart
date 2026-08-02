import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/formation/formation_groups_repo.dart';
import '../../../core/supabase/supabase_config.dart';
import '../community/public_profile_screen.dart';
import '../community/public_profiles_repo.dart';

/// Fil du groupe communautaire d'une catégorie de formation — voir
/// supabase/phase56_patch_formation_groups.sql. La RLS garantit que
/// seuls les participants VALIDÉS de cette catégorie (ou le staff)
/// reçoivent quoi que ce soit ; cet écran n'a donc pas besoin de
/// revérifier l'accès lui-même — un client non-participant obtient
/// simplement une liste vide depuis l'API.
class FormationGroupScreen extends StatefulWidget {
  final String category;

  const FormationGroupScreen({super.key, required this.category});

  @override
  State<FormationGroupScreen> createState() => _FormationGroupScreenState();
}

class _FormationGroupScreenState extends State<FormationGroupScreen> {
  List<Map<String, dynamic>> _posts = [];
  Map<String, Map<String, dynamic>> _authorProfiles = {};
  bool _isLoading = true;
  final _dateFormat = DateFormat('d MMM à HH:mm', 'fr_FR');

  String? get _myId => SupabaseConfig.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final posts = await FormationGroupsRepo.fetchGroupPosts(widget.category);
    final authorIds =
        posts.map((p) => p['author_id'] as String?).whereType<String>().toSet();
    final profiles = await PublicProfilesRepo.fetchByIds(authorIds);
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _authorProfiles = profiles;
      _isLoading = false;
    });
  }

  Future<void> _openComposer() async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GroupPostComposer(category: widget.category),
    );
    if (posted == true) _load();
  }

  Future<void> _editPost(Map<String, dynamic> post) async {
    final controller =
        TextEditingController(text: (post['content'] ?? '').toString());
    final newContent = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la publication'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (newContent == null || !mounted) return;
    try {
      await FormationGroupsRepo.updateGroupPost(post['id'], newContent);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de modifier la publication.')));
    }
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await FormationGroupsRepo.deleteGroupPost(post['id']);
      if (!mounted) return;
      setState(() => _posts.removeWhere((p) => p['id'] == post['id']));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de supprimer la publication.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Groupe — ${widget.category}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComposer,
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _posts.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 20.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            'Aucune publication pour le moment — soyez le premier à partager quelque chose avec les autres participants de "${widget.category}".',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 10.h),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        final author = _authorProfiles[post['author_id']];
                        final authorName =
                            PublicProfilesRepo.displayName(author);
                        final isOwn = post['author_id'] == _myId;
                        return Card(
                          margin: EdgeInsets.only(bottom: 1.5.h),
                          child: Padding(
                            padding: EdgeInsets.all(3.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: post['author_id'] == null
                                            ? null
                                            : () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        PublicProfileScreen(
                                                      userId:
                                                          post['author_id'],
                                                    ),
                                                  ),
                                                ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundImage: author?[
                                                          'avatar_url'] !=
                                                      null
                                                  ? NetworkImage(
                                                      author!['avatar_url'])
                                                  : null,
                                              child: author?['avatar_url'] ==
                                                      null
                                                  ? const Icon(Icons.person,
                                                      size: 16)
                                                  : null,
                                            ),
                                            SizedBox(width: 2.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(authorName,
                                                      style: theme.textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                  Text(
                                                    [
                                                      _dateFormat.format(
                                                          DateTime.parse(
                                                              post[
                                                                  'created_at'])),
                                                      if (post['updated_at'] !=
                                                          null)
                                                        'Modifié',
                                                    ].join(' · '),
                                                    style: theme
                                                        .textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isOwn)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            size: 20),
                                        onSelected: (v) {
                                          if (v == 'edit') _editPost(post);
                                          if (v == 'delete') _deletePost(post);
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Modifier')),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Supprimer',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                if ((post['content'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  SizedBox(height: 1.h),
                                  Text(post['content']),
                                ],
                                if (post['image_url'] != null) ...[
                                  SizedBox(height: 1.h),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      post['image_url'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 20.h,
                                      cacheWidth: 800,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
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

class _GroupPostComposer extends StatefulWidget {
  final String category;

  const _GroupPostComposer({required this.category});

  @override
  State<_GroupPostComposer> createState() => _GroupPostComposerState();
}

class _GroupPostComposerState extends State<_GroupPostComposer> {
  final _controller = TextEditingController();
  File? _image;
  bool _isPosting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 60, maxWidth: 800);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty && _image == null) return;
    setState(() => _isPosting = true);
    try {
      await FormationGroupsRepo.createGroupPost(
        category: widget.category,
        content: _controller.text.trim(),
        image: _image,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la publication.')));
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        top: 2.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nouvelle publication — ${widget.category}',
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 2.h),
          TextField(
            controller: _controller,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Partagez quelque chose avec le groupe...',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 1.h),
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_image!, height: 15.h, fit: BoxFit.cover),
            ),
          SizedBox(height: 1.h),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_outlined),
                label: const Text('Photo'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isPosting ? null : _submit,
                child: _isPosting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Publier'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
