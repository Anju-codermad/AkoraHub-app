import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../../core/supabase/supabase_config.dart';
import '../product_detail_client.dart';
import '../community/public_profile_screen.dart';
import '../community/public_profiles_repo.dart';

/// Réactions emoji disponibles sur une publication (01/08, demande
/// explicite : "différents emoji pour la réaction") — même jeu que
/// Facebook, reconnu sans explication. Limité aux publications pour
/// cette première version (pas encore sur les commentaires ni la
/// messagerie privée — voir PROJECT_CONTEXT.md).
const Map<String, String> kPostReactionEmojis = {
  'like': '👍',
  'love': '❤️',
  'haha': '😂',
  'wow': '😮',
  'sad': '😢',
  'angry': '😡',
};

/// Communauté AkoraHub (ex-"Mur", renommé 01/08 — terme plus parlant que le
/// calque Facebook) : publications texte + photo, avec likes et
/// commentaires. Filtrable par secteur (Hôtellerie / Santé / Entreprises /
/// Particuliers) et par "Mes publications". Accessible depuis le Profil
/// (aucun onglet de navigation dédié — décision utilisateur du 23/07, voir
/// PROJECT_CONTEXT.md section 3bis).
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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  final Map<String, int> _likeCounts = {};
  final Map<String, String?> _myReactionByPost = {};
  final Map<String, int> _commentCounts = {};
  Map<String, Map<String, dynamic>> _authorProfiles = {};
  Map<String, Map<String, dynamic>> _mentionedProducts = {};

  final Map<String, String> _sectorLabels = const {
    'hotel': 'Hôtellerie',
    'hopital': 'Santé',
    'entreprise': 'Entreprises',
    'particulier': 'Particuliers',
  };

  // Pagination : le Mur était plafonné à 50 posts (limit(50)) sans moyen
  // d'aller plus loin — remplacé par un chargement par pages de 20, la
  // suite arrivant en scrollant vers le bas. Les filtres (secteur, "mes
  // publications") passent désormais côté serveur pour rester compatibles
  // avec la pagination (sinon une page filtrée pourrait sembler vide alors
  // que des posts correspondants existent plus loin, pas encore chargés).
  static const _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final _scrollController = ScrollController();

  String? get _myId => SupabaseConfig.isConfigured
      ? SupabaseConfig.client.auth.currentUser?.id
      : null;

  @override
  void initState() {
    super.initState();
    _onlyMine = widget.initialOnlyMine;
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Recherche par mot-clé dans le contenu des publications (01/08) —
  /// débouncée pour ne pas relancer une requête à chaque frappe. Un
  /// `setState` immédiat sans effet sur la recherche elle-même rafraîchit
  /// juste l'icône "effacer" pendant que l'utilisateur tape.
  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      setState(() => _searchQuery = trimmed);
      _loadPosts();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMorePosts();
    }
  }

  /// Liste des `author_id` du secteur choisi (null si "Tous" — pas de
  /// restriction), pour traduire le filtre secteur (basé sur
  /// `profiles.client_type`, une table à part) en filtre Postgrest sur
  /// `posts.author_id`.
  Future<List<String>?> _sectorAuthorIds() async {
    if (_sectorFilter == 'tous') return null;
    try {
      final rows = await SupabaseConfig.client
          .from('public_profiles')
          .select('id')
          .eq('client_type', _sectorFilter);
      return List<Map<String, dynamic>>.from(rows)
          .map((r) => r['id'] as String)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPostsPage(int page) async {
    if (_onlyMine && _myId == null) return [];
    var query = SupabaseConfig.client.from('posts').select();
    if (_onlyMine) {
      query = query.eq('author_id', _myId!);
    }
    if (_searchQuery.isNotEmpty) {
      query = query.ilike('content', '%$_searchQuery%');
    }
    final sectorIds = await _sectorAuthorIds();
    if (sectorIds != null) {
      if (sectorIds.isEmpty) return [];
      query = query.inFilter('author_id', sectorIds);
    }
    final data = await query
        .order('created_at', ascending: false)
        .range(page * _pageSize, page * _pageSize + _pageSize - 1);
    return List<Map<String, dynamic>>.from(data);
  }

  void _onFilterChanged() {
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
      _page = 0;
      _hasMore = true;
    });
    try {
      final list = await _fetchPostsPage(0);
      final postIds = list.map((p) => p['id'] as String).toList();

      // Ex-boucle "1 requête like + 1 requête commentaire PAR post" (jusqu'à
      // ~100 allers-retours réseau séquentiels pour 50 posts) remplacée par
      // un seul `inFilter` groupé pour chacun, lancés en parallèle avec les
      // profils auteurs et les produits mentionnés — même logique que
      // catalog_tab.dart (blocs indépendants, chacun avec son repli
      // silencieux en cas d'échec).
      Future<List<Map<String, dynamic>>> loadLikes() async {
        if (postIds.isEmpty) return [];
        try {
          final rows = await SupabaseConfig.client
              .from('post_likes')
              .select('post_id, user_id, reaction_type')
              .inFilter('post_id', postIds);
          return List<Map<String, dynamic>>.from(rows);
        } catch (_) {
          return [];
        }
      }

      Future<List<Map<String, dynamic>>> loadComments() async {
        if (postIds.isEmpty) return [];
        try {
          final rows = await SupabaseConfig.client
              .from('post_comments')
              .select('post_id')
              .inFilter('post_id', postIds);
          return List<Map<String, dynamic>>.from(rows);
        } catch (_) {
          return [];
        }
      }

      // Profils auteurs : jointure PostgREST `profiles(...)` impossible ici
      // (RLS de `profiles` limite la lecture à sa propre ligne — voir
      // supabase/phase9_patch_public_profiles.sql), on passe donc par la
      // vue publique légère pour afficher correctement le nom des AUTRES
      // clients, pas seulement le sien.
      final authorIds =
          list.map((p) => p['author_id'] as String?).whereType<String>().toSet();

      // Produits mentionnés (tags) dans les posts (item "tags/mentions" du
      // 23/07).
      final mentionedIds = list
          .map((p) => p['mentioned_product_id'] as String?)
          .whereType<String>()
          .toSet();

      Future<Map<String, Map<String, dynamic>>> loadMentionedProducts() async {
        if (mentionedIds.isEmpty) return {};
        try {
          final products = await SupabaseConfig.client
              .from('products')
              .select('id, name, price_detail, image_url')
              .inFilter('id', mentionedIds.toList());
          return {
            for (final row in List<Map<String, dynamic>>.from(products))
              row['id'] as String: row,
          };
        } catch (_) {
          // Repli silencieux : le tag produit ne s'affichera juste pas.
          return {};
        }
      }

      final results = await Future.wait<dynamic>([
        loadLikes(),
        loadComments(),
        PublicProfilesRepo.fetchByIds(authorIds),
        loadMentionedProducts(),
      ]);
      final likesRows = results[0] as List<Map<String, dynamic>>;
      final commentsRows = results[1] as List<Map<String, dynamic>>;
      final profiles = results[2] as Map<String, Map<String, dynamic>>;
      final mentionedProducts =
          results[3] as Map<String, Map<String, dynamic>>;

      final likeCounts = <String, int>{};
      final myReactions = <String, String?>{};
      for (final l in likesRows) {
        final postId = l['post_id'] as String;
        likeCounts[postId] = (likeCounts[postId] ?? 0) + 1;
        if (l['user_id'] == _myId) {
          myReactions[postId] = l['reaction_type'] as String?;
        }
      }
      final commentCounts = <String, int>{};
      for (final c in commentsRows) {
        final postId = c['post_id'] as String;
        commentCounts[postId] = (commentCounts[postId] ?? 0) + 1;
      }

      setState(() {
        _posts = list;
        _likeCounts
          ..clear()
          ..addAll(likeCounts);
        _myReactionByPost
          ..clear()
          ..addAll(myReactions);
        _commentCounts
          ..clear()
          ..addAll(commentCounts);
        _authorProfiles = profiles;
        _mentionedProducts = mentionedProducts;
        _isLoading = false;
        _hasMore = list.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger la communauté.';
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final list = await _fetchPostsPage(nextPage);
      final postIds = list.map((p) => p['id'] as String).toList();

      Future<List<Map<String, dynamic>>> loadLikes() async {
        if (postIds.isEmpty) return [];
        try {
          final rows = await SupabaseConfig.client
              .from('post_likes')
              .select('post_id, user_id, reaction_type')
              .inFilter('post_id', postIds);
          return List<Map<String, dynamic>>.from(rows);
        } catch (_) {
          return [];
        }
      }

      Future<List<Map<String, dynamic>>> loadComments() async {
        if (postIds.isEmpty) return [];
        try {
          final rows = await SupabaseConfig.client
              .from('post_comments')
              .select('post_id')
              .inFilter('post_id', postIds);
          return List<Map<String, dynamic>>.from(rows);
        } catch (_) {
          return [];
        }
      }

      final authorIds = list
          .map((p) => p['author_id'] as String?)
          .whereType<String>()
          .toSet();
      final mentionedIds = list
          .map((p) => p['mentioned_product_id'] as String?)
          .whereType<String>()
          .toSet();

      Future<Map<String, Map<String, dynamic>>> loadMentionedProducts() async {
        if (mentionedIds.isEmpty) return {};
        try {
          final products = await SupabaseConfig.client
              .from('products')
              .select('id, name, price_detail, image_url')
              .inFilter('id', mentionedIds.toList());
          return {
            for (final row in List<Map<String, dynamic>>.from(products))
              row['id'] as String: row,
          };
        } catch (_) {
          return {};
        }
      }

      final results = await Future.wait<dynamic>([
        loadLikes(),
        loadComments(),
        PublicProfilesRepo.fetchByIds(authorIds),
        loadMentionedProducts(),
      ]);
      final likesRows = results[0] as List<Map<String, dynamic>>;
      final commentsRows = results[1] as List<Map<String, dynamic>>;
      final profiles = results[2] as Map<String, Map<String, dynamic>>;
      final mentionedProducts =
          results[3] as Map<String, Map<String, dynamic>>;

      final likeCounts = <String, int>{};
      final myReactions = <String, String?>{};
      for (final l in likesRows) {
        final postId = l['post_id'] as String;
        likeCounts[postId] = (likeCounts[postId] ?? 0) + 1;
        if (l['user_id'] == _myId) {
          myReactions[postId] = l['reaction_type'] as String?;
        }
      }
      final commentCounts = <String, int>{};
      for (final c in commentsRows) {
        final postId = c['post_id'] as String;
        commentCounts[postId] = (commentCounts[postId] ?? 0) + 1;
      }

      if (!mounted) return;
      setState(() {
        _posts = [..._posts, ...list];
        _likeCounts.addAll(likeCounts);
        _myReactionByPost.addAll(myReactions);
        _commentCounts.addAll(commentCounts);
        _authorProfiles = {..._authorProfiles, ...profiles};
        _mentionedProducts = {..._mentionedProducts, ...mentionedProducts};
        _page = nextPage;
        _hasMore = list.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // Le filtre secteur/"mes publications" est désormais appliqué côté
  // serveur (_fetchPostsPage) — _posts ne contient déjà que les posts
  // correspondants, plus besoin de filtrer ici.

  /// Réagit avec [reactionType] à une publication — retape la même
  /// réaction pour la retirer, ou une réaction différente pour la
  /// remplacer (suppression + réinsertion, pas de policy UPDATE
  /// nécessaire côté RLS, voir phase46_patch_communaute_replies_reactions.sql).
  Future<void> _react(String postId, String reactionType) async {
    final myId = _myId;
    if (myId == null) return;
    final previous = _myReactionByPost[postId];
    final removing = previous == reactionType;

    setState(() {
      _myReactionByPost[postId] = removing ? null : reactionType;
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) +
          (removing
              ? -1
              : previous == null
                  ? 1
                  : 0);
    });

    try {
      if (previous != null) {
        await SupabaseConfig.client
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', myId);
      }
      if (!removing) {
        await SupabaseConfig.client.from('post_likes').insert({
          'post_id': postId,
          'user_id': myId,
          'reaction_type': reactionType,
        });
      }
    } catch (_) {
      // Revert en cas d'échec réseau.
      setState(() {
        _myReactionByPost[postId] = previous;
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) +
            (removing
                ? 1
                : previous == null
                    ? -1
                    : 0);
      });
    }
  }

  Future<void> _showReactionPicker(String postId) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 12),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: kPostReactionEmojis.entries.map((entry) {
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.pop(context, entry.key),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(entry.value, style: const TextStyle(fontSize: 28)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (selected != null) _react(postId, selected);
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

  /// Modifier/Supprimer sa propre publication (01/08) — n'était pas
  /// possible auparavant, seule l'insertion existait. Les policies RLS
  /// `posts_update_own`/`posts_delete_own` (Phase 3) autorisent déjà
  /// l'auteur (ou le staff) à agir sur ses propres lignes, aucun script
  /// SQL supplémentaire n'est nécessaire.
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
      await SupabaseConfig.client
          .from('posts')
          .update({'content': newContent}).eq('id', post['id']);
      setState(() {
        final index = _posts.indexWhere((p) => p['id'] == post['id']);
        if (index != -1) _posts[index]['content'] = newContent;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de modifier la publication. Réessayez.')),
      );
    }
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text(
            'Cette action est définitive. Voulez-vous continuer ?'),
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
      await SupabaseConfig.client.from('posts').delete().eq('id', post['id']);
      setState(() {
        _posts.removeWhere((p) => p['id'] == post['id']);
        _likeCounts.remove(post['id']);
        _myReactionByPost.remove(post['id']);
        _commentCounts.remove(post['id']);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publication supprimée.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Impossible de supprimer la publication. Réessayez.')),
      );
    }
  }

  void _sharePost(Map<String, dynamic> post, String authorName) {
    final content = (post['content'] ?? '').toString();
    final mentioned = _mentionedProducts[post['mentioned_product_id']];
    final buffer = StringBuffer('$authorName sur AkoraHub');
    if (content.isNotEmpty) buffer.write(' : $content');
    if (mentioned != null) {
      buffer.write('\nProduit mentionné : ${mentioned['name']}');
    }
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communauté AkoraHub'),
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
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Rechercher (produit, mot-clé...)',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearchChanged('');
                                      },
                                    ),
                              isDense: true,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
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
                                  onSelected: (v) {
                                    setState(() => _onlyMine = v);
                                    _onFilterChanged();
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: const Text('Tous'),
                                  selected: _sectorFilter == 'tous',
                                  onSelected: (_) {
                                    setState(() => _sectorFilter = 'tous');
                                    _onFilterChanged();
                                  },
                                ),
                              ),
                              ..._sectorLabels.entries.map((e) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(e.value),
                                      selected: _sectorFilter == e.key,
                                      onSelected: (_) {
                                        setState(() => _sectorFilter = e.key);
                                        _onFilterChanged();
                                      },
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      if (_posts.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                              child: Text(_searchQuery.isNotEmpty
                                  ? 'Aucun résultat pour "$_searchQuery".'
                                  : _onlyMine
                                      ? 'Vous n\'avez encore rien publié.'
                                      : 'Aucune publication pour le moment.')),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index >= _posts.length) {
                                return Padding(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 2.h),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }
                              final post = _posts[index];
                              final author = _authorProfiles[post['author_id']];
                              final authorName =
                                  PublicProfilesRepo.displayName(author);
                              final sector = author != null
                                  ? _sectorLabels[author['client_type']]
                                  : null;
                              final myReaction = _myReactionByPost[post['id']];
                              final mentionedProduct = _mentionedProducts[
                                  post['mentioned_product_id']];

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
                                          Expanded(
                                            child: InkWell(
                                              onTap: post['author_id'] == null
                                                  ? null
                                                  : () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              PublicProfileScreen(
                                                            userId: post[
                                                                'author_id'],
                                                          ),
                                                        ),
                                                      ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    backgroundImage: author?[
                                                                'avatar_url'] !=
                                                            null
                                                        ? NetworkImage(author![
                                                            'avatar_url'])
                                                        : null,
                                                    child: author?[
                                                                'avatar_url'] ==
                                                            null
                                                        ? Text(authorName
                                                                .isNotEmpty
                                                            ? authorName[0]
                                                                .toUpperCase()
                                                            : '?')
                                                        : null,
                                                  ),
                                                  SizedBox(width: 2.w),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(authorName,
                                                            style: theme
                                                                .textTheme
                                                                .bodyMedium
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
                                            ),
                                          ),
                                          if (post['author_id'] == _myId)
                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                  Icons.more_vert,
                                                  size: 20),
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editPost(post);
                                                } else if (value == 'delete') {
                                                  _deletePost(post);
                                                }
                                              },
                                              itemBuilder: (context) => const [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Modifier'),
                                                ),
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
                                            // Ne décode jamais plus large
                                            // que ce qui est réellement
                                            // affiché — évite de gaspiller
                                            // de la mémoire même si
                                            // l'image source est plus
                                            // grande (ex : ancienne
                                            // publication d'avant cette
                                            // limite de taille).
                                            cacheWidth: 800,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox.shrink(),
                                            loadingBuilder: (context, child,
                                                progress) {
                                              if (progress == null) {
                                                return child;
                                              }
                                              // Connexion parfois très
                                              // lente (6 KB/s observés) —
                                              // un espace vide sans
                                              // indication donnerait
                                              // l'impression que l'app
                                              // est bloquée.
                                              return Container(
                                                width: double.infinity,
                                                height: 20.h,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                      if (mentionedProduct != null) ...[
                                        SizedBox(height: 1.h),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProductDetailClient(
                                                      product:
                                                          mentionedProduct),
                                            ),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.shopping_bag_outlined,
                                                    size: 18,
                                                    color: theme
                                                        .colorScheme.primary),
                                                SizedBox(width: 2.w),
                                                Expanded(
                                                  child: Text(
                                                    mentionedProduct['name'] ??
                                                        '',
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Icon(
                                                    Icons.chevron_right,
                                                    size: 18),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: 1.h),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onLongPress: () =>
                                                _showReactionPicker(
                                                    post['id']),
                                            child: IconButton(
                                              icon: myReaction != null
                                                  ? Text(
                                                      kPostReactionEmojis[
                                                              myReaction] ??
                                                          '👍',
                                                      style: const TextStyle(
                                                          fontSize: 18),
                                                    )
                                                  : const Icon(
                                                      Icons.favorite_border,
                                                      size: 20),
                                              tooltip:
                                                  'Maintenir pour choisir une réaction',
                                              onPressed: () => _react(
                                                  post['id'],
                                                  myReaction ?? 'like'),
                                            ),
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
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.share_outlined,
                                                size: 20),
                                            tooltip: 'Partager',
                                            onPressed: () => _sharePost(
                                                post, authorName),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount:
                                _posts.length + (_hasMore ? 1 : 0),
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
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await SupabaseConfig.client
          .from('products')
          .select('id, name, price_detail, image_url')
          .eq('visibility', true)
          .order('name')
          .limit(200);
      if (!mounted) return;
      setState(() => _products = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      // Repli silencieux : le sélecteur de produit restera vide, le champ
      // reste optionnel donc la publication n'est pas bloquée.
    }
  }

  Future<void> _pickProduct() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProductPickerSheet(products: _products),
    );
    if (selected != null) {
      setState(() => _selectedProduct = selected);
    }
  }

  /// Compression automatique (01/08, demande explicite après avoir
  /// remarqué une connexion très lente — 6 KB/s sur une capture) : les
  /// photos de la Communauté ne s'affichent jamais plus grand que la
  /// largeur de la carte du fil (~20.h de haut, largeur de l'écran) — pas
  /// besoin d'un fichier plus large que ça. `maxWidth`/`imageQuality`
  /// sont appliqués par `image_picker` lui-même (redimensionnement +
  /// réencodage JPEG) avant même l'upload, donc le gain s'applique aussi
  /// bien à l'envoi (le posteur) qu'au téléchargement (tous les lecteurs
  /// du fil) : un fichier plus petit à la source profite à tout le monde.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 60, maxWidth: 800);
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
        'mentioned_product_id': _selectedProduct?['id'],
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
          if (_selectedProduct != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Chip(
                avatar: const Icon(Icons.shopping_bag_outlined, size: 16),
                label: Text(_selectedProduct!['name'] ?? ''),
                onDeleted: () => setState(() => _selectedProduct = null),
              ),
            ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_outlined),
                label: const Text('Ajouter une photo'),
              ),
              TextButton.icon(
                onPressed: _products.isEmpty ? null : _pickProduct,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                    _selectedProduct == null ? 'Mentionner' : 'Changer'),
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
  Map<String, Map<String, dynamic>> _authorProfiles = {};
  bool _isLoading = true;
  final _controller = TextEditingController();
  final _inputFocus = FocusNode();

  /// Commentaire (obligatoirement de premier niveau) auquel la prochaine
  /// saisie répond — `null` pour un nouveau commentaire "racine" (01/08,
  /// demande explicite : "répondre un commentaire"). Volontairement
  /// limité à un seul niveau de profondeur (pas de "répondre à une
  /// réponse") pour garder l'affichage simple et lisible.
  Map<String, dynamic>? _replyingTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseConfig.client
          .from('post_comments')
          .select()
          .eq('post_id', widget.postId)
          .order('created_at');
      final list = List<Map<String, dynamic>>.from(data);
      final authorIds = list
          .map((c) => c['author_id'] as String?)
          .whereType<String>()
          .toSet();
      final profiles = await PublicProfilesRepo.fetchByIds(authorIds);
      setState(() {
        _comments = list;
        _authorProfiles = profiles;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _topLevelComments =>
      _comments.where((c) => c['parent_comment_id'] == null).toList();

  List<Map<String, dynamic>> _repliesTo(String commentId) => _comments
      .where((c) => c['parent_comment_id'] == commentId)
      .toList();

  void _startReply(Map<String, dynamic> comment) {
    setState(() => _replyingTo = comment);
    _inputFocus.requestFocus();
  }

  Future<void> _addComment() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || _controller.text.trim().isEmpty) return;
    final text = _controller.text.trim();
    final parentId = _replyingTo?['id'] as String?;
    _controller.clear();
    setState(() => _replyingTo = null);

    try {
      await SupabaseConfig.client.from('post_comments').insert({
        'post_id': widget.postId,
        'author_id': userId,
        'content': text,
        if (parentId != null) 'parent_comment_id': parentId,
      });
      widget.onCommentAdded();
      _load();
    } catch (_) {}
  }

  Widget _buildCommentTile(Map<String, dynamic> c, {bool isReply = false}) {
    final name =
        PublicProfilesRepo.displayName(_authorProfiles[c['author_id']]);
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 10.w : 0),
      child: ListTile(
        dense: true,
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(c['content'] ?? ''),
        trailing: isReply
            ? null
            : TextButton(
                onPressed: () => _startReply(c),
                child: const Text('Répondre'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topLevel = _topLevelComments;
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
                  : topLevel.isEmpty
                      ? const Center(child: Text('Aucun commentaire.'))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          itemCount: topLevel.length,
                          itemBuilder: (context, index) {
                            final c = topLevel[index];
                            final replies = _repliesTo(c['id']);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCommentTile(c),
                                ...replies.map((r) =>
                                    _buildCommentTile(r, isReply: true)),
                              ],
                            );
                          },
                        ),
            ),
            if (_replyingTo != null)
              Padding(
                padding: EdgeInsets.fromLTRB(3.w, 0, 3.w, 1.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Réponse à ${PublicProfilesRepo.displayName(_authorProfiles[_replyingTo!['author_id']])}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _replyingTo = null),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _inputFocus,
                      decoration: InputDecoration(
                        hintText: _replyingTo != null
                            ? 'Écrire une réponse...'
                            : 'Ajouter un commentaire...',
                        isDense: true,
                        border: const OutlineInputBorder(),
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

/// Sélecteur de produit à mentionner (tag) dans une publication du Mur —
/// recherche simple par nom sur la liste déjà chargée par _NewPostSheet.
class _ProductPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> products;

  const _ProductPickerSheet({required this.products});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _query = '';

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return widget.products;
    final q = _query.toLowerCase();
    return widget.products
        .where((p) => (p['name'] ?? '').toString().toLowerCase().contains(q))
        .toList();
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
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un produit...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('Aucun produit trouvé.'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final product = _filtered[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: product['image_url'] != null
                                ? NetworkImage(product['image_url'])
                                : null,
                            child: product['image_url'] == null
                                ? const Icon(Icons.shopping_bag_outlined)
                                : null,
                          ),
                          title: Text(product['name'] ?? ''),
                          onTap: () => Navigator.pop(context, product),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
