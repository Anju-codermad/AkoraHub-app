import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/community/community_moderation_repo.dart';
import 'public_profiles_repo.dart';

/// Publications enregistrées ("Sauvegardés", Lot 1 Communauté, 02/08) —
/// voir supabase/phase51_patch_block_hide_save_posts.sql. Vue en lecture
/// simple (pas de réactions/commentaires ici, juste retrouver un post
/// mis de côté) — pour interagir, l'utilisateur retourne dans le fil.
class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<Map<String, dynamic>> _posts = [];
  Map<String, Map<String, dynamic>> _profiles = {};
  bool _isLoading = true;
  final Set<String> _removing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final posts = await CommunityModerationRepo.fetchSavedPosts();
    final authorIds = posts
        .map((p) => p['author_id'] as String?)
        .whereType<String>()
        .toSet();
    final profiles = await PublicProfilesRepo.fetchByIds(authorIds);
    if (!mounted) return;
    setState(() {
      _posts = posts;
      _profiles = profiles;
      _isLoading = false;
    });
  }

  Future<void> _unsave(String postId) async {
    setState(() => _removing.add(postId));
    try {
      await CommunityModerationRepo.unsavePost(postId);
      if (!mounted) return;
      setState(() {
        _posts.removeWhere((p) => p['id'] == postId);
        _removing.remove(postId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _removing.remove(postId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur, réessayez.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegardés')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Text(
                      'Aucune publication enregistrée.\nAppuyez sur ⋮ sur une publication pour l\'ajouter ici.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _posts.length,
                  separatorBuilder: (_, __) => SizedBox(height: 1.h),
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final postId = post['id'] as String;
                    final profile = _profiles[post['author_id']];
                    final isRemoving = _removing.contains(postId);
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage:
                                      profile?['avatar_url'] != null
                                          ? NetworkImage(profile!['avatar_url'])
                                          : null,
                                  child: profile?['avatar_url'] == null
                                      ? const Icon(Icons.person, size: 16)
                                      : null,
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Text(
                                    PublicProfilesRepo.displayName(profile),
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Retirer des enregistrés',
                                  icon: isRemoving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.bookmark, size: 20),
                                  onPressed: isRemoving
                                      ? null
                                      : () => _unsave(postId),
                                ),
                              ],
                            ),
                            if ((post['content'] ?? '').toString().isNotEmpty) ...[
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
                                  height: 18.h,
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
    );
  }
}
