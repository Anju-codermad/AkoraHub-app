import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/supabase/supabase_config.dart';

/// Mur social : publications texte + photo, avec likes et commentaires.
/// Filtrable par secteur (Hôtellerie / Santé / Entreprises / Particuliers)
/// et par "Mes publications". Accessible depuis le Profil (aucun onglet de
/// navigation dédié — décision utilisateur du 23/07, voir PROJECT_CONTEXT.md
/// section 3bis).
class WallTab extends StatefulWidget {
  final bool initialOnlyMine;

  const WallTab({super.key, this.initialOnlyMine = false});

  @override
  State<WallTab> createState() => _WallTabState();
}

class _WallTabState extends State<WallTab> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _error;
  String _sectorFilter = 'tous';
  bool _onlyMine = false;
  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _likedByMe = {};
  final Map<String, int> _commentCounts = {};

  final Map<String, String> _sectorLabels = const {
    'hotel': 'Hôtellerie',
    'hopital': 'Santé',
    'entreprise': 'Entreprises',
    'particulier': 'Particuliers',
  };

  String? get _myId => SupabaseConfig.isConfigured
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  @override
  void initState() {
    super.initState();
    _onlyMine = widget.initialOnlyMine;
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final posts = await SupabaseConfig.client
          .from('posts')
          .select('*, profiles(full_name, company_name, client_type)')
          .order('created_at', ascending: false)
          .limit(50);

      final list = List<Map<String, dynamic>>.from(posts);

      for (final p in list) {
        final likes = await SupabaseConfig.client
            .from('post_likes')
            .select('user_id')
            .eq('post_id', p['id']);
        final likesList = List<Map<String, dynamic>>.from(likes);
        _likeCounts[p['id']] = likesList.length;
        _likedByMe[p['id']] =
            likesList.any((l) => l['user_id'] == _myId);

        final comments = await SupabaseConfig.client
            .from('post_comments')
            .select('id')
            .eq('post_id', p['id']);
        _commentCounts[p['id']] =
            List<Map<String, dynamic>>.from(comments).length;
      }

      setState(() {
        _posts = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger le mur.';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPosts {
    Iterable<Map<String, dynamic>> result = _posts;
    if (_sectorFilter != 'tous') {
      result = result.where((p) {
        final author = p['profiles'];
        return author != null && author['client_type'] == _sectorFilter;
      });
    }
    if (_onlyMine) {
      result = result.where((p) => p['author_id'] == _myId);
    }
    return result.toList();
  }

  Future<void> _toggleLike(String postId) async {
    final myId = _myId;
    if (myId == null) return;
    final liked = _likedByMe[postId] ?? false;

    setState(() {
      _likedByMe[postId] = !liked;
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + (liked ? -1 : 1);
    });

    try {
      if (liked) {
        await SupabaseConfig.client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', myId);
      } else {
        await SupabaseConfig.client
            .from('post_likes')
            .insert({'post_id': postId, 'user_id': myId});
      }
    } catch (_) {
      // Revert en cas d'échec réseau.
      setState(() {
        _likedByMe[postId] = liked;
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) + (liked ? 1 : -1);
      });
    }
  }

  Future<void> _openComments(Map<String, dynamic> post) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CommentsSheet(
        postId: post['id'],
        onCommentAdded: () {
          setState(() {
            _commentCounts[post['id']] =
                (_commentCounts[post['id']] ?? 0) + 1;
          });
        },
      ),
    );
  }

  Future<void> _createPost() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _NewPostSheet(onPosted: _loadPosts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mur — Communauté AkoraHub'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        icon: const Icon(Icons.add),
        label: const Text('Publier'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 5.h,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  avatar: const Icon(Icons.person_outline,
                                      size: 16),
                                  label: const Text('Mes publications'),
                                  selected: _onlyMine,
                                  onSelected: (v) =>
                                      setState(() => _onlyMine = v),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: const Text('Tous'),
                                  selected: _sectorFilter == 'tous',
                                  onSelected: (_) =>
                                      setState(() => _sectorFilter = 'tous'),
                                ),
                              ),
                              ..._sectorLabels.entries.map((e) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(e.value),
                                      selected: _sectorFilter == e.key,
                                      onSelected: (_) => setState(
                                          () => _sectorFilter = e.key),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      if (_filteredPosts.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                              child: Text(_onlyMine
                                  ? 'Vous n\'avez encore rien publié.'
                                  : 'Aucune publication pour le moment.')),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final post = _filteredPosts[index];
                              final author = post['profiles'];
                              final authorName = author != null
                                  ? (author['company_name'] ??
                                      author['full_name'] ??
                                      'Utilisateur')
                                  : 'Utilisateur';
                              final sector = author != null
                                  ? _sectorLabels[author['client_type']]
                                  : null;
                              final liked = _likedByMe[post['id']] ?? false;

                              return Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 4.w, vertical: 1.h),
                                child: Padding(
                                  padding: EdgeInsets.all(3.w),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            child: Text(authorName.isNotEmpty
                                                ? authorName[0].toUpperCase()
                                                : '?'),
                                          ),
                                          SizedBox(width: 2.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(authorName,
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                if (sector != null)
                                                  Text(sector,
                                                      style: theme
                                                          .textTheme
                                                          .bodySmall),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 1.h),
                                      if ((post['content'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text(post['content']),
                                      if (post['image_url'] != null) ...[
                                        SizedBox(height: 1.h),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            post['image_url'],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 20.h,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox.shrink(),
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: 1.h),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              liked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: liked
                                                  ? Colors.red
                                                  : null,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _toggleLike(post['id']),
                                          ),
                                          Text(
                                              '${_likeCounts[post['id']] ?? 0}'),
                                          SizedBox(width: 4.w),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.mode_comment_outlined,
                                                size: 20),
                                            onPressed: () =>
                                                _openComments(post),
                                          ),
                                          Text(
                                              '${_commentCounts[post['id']] ?? 0}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _filteredPosts.length,
                          ),
                        ),
                      SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                    ],
                  ),
                ),
    );
  }
}

class _NewPostSheet extends StatefulWidget {
  final VoidCallback onPosted;

  const _NewPostSheet({required this.onPosted});

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _controller = TextEditingController();
  File? _image;
  bool _isPosting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 1280);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    if (_controller.text.trim().isEmpty && _image == null) return;

    setState(() => _isPosting = true);

    try {
      String? imageUrl;
      if (_image != null) {
        final fileName =
            '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await SupabaseConfig.client.storage
            .from('wall-photos')
            .upload(fileName, _image!);
        imageUrl = SupabaseConfig.client.storage
            .from('wall-photos')
            .getPublicUrl(fileName);
      }

      await SupabaseConfig.client.from('posts').insert({
        'author_id': userId,
        'content': _controller.text.trim(),
        'image_url': imageUrl,
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onPosted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la publication.')),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
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
          Text('Nouvelle publication',
              style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 2.h),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Partagez un événement, une photo, votre journée...',
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
                label: const Text('Ajouter une photo'),
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

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final VoidCallback onCommentAdded;

  const _CommentsSheet(
      {required this.postId, required this.onCommentAdded});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseConfig.client
          .from('post_comments')
          .select('*, profiles(full_name, company_name)')
          .eq('post_id', widget.postId)
          .order('created_at');
      setState(() {
        _comments = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || _controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    _controller.clear();

    try {
      await SupabaseConfig.client.from('post_comments').insert({
        'post_id': widget.postId,
        'author_id': userId,
        'content': text,
      });
      widget.onCommentAdded();
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: 60.h,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Text('Commentaires',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(child: Text('Aucun commentaire.'))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            final author = c['profiles'];
                            final name = author != null
                                ? (author['company_name'] ??
                                    author['full_name'] ??
                                    'Utilisateur')
                                : 'Utilisateur';
                            return ListTile(
                              dense: true,
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(c['content'] ?? ''),
                            );
                          },
                        ),
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
