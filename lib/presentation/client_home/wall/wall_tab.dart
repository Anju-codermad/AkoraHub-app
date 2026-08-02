import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/community/community_moderation_repo.dart';
import '../../../core/community/friends_repo.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/utils/whatsapp_link.dart';
import '../product_detail_client.dart';
import '../community/friends_list_screen.dart';
import '../community/public_profile_screen.dart';
import '../community/public_profiles_repo.dart';
import '../community/realisations_gallery_screen.dart';
import '../community/saved_posts_screen.dart';

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
class WallTab extends ConsumerStatefulWidget {
  final bool initialOnlyMine;

  const WallTab({super.key, this.initialOnlyMine = false});

  @override
  ConsumerState<WallTab> createState() => _WallTabState();
}

class _WallTabState extends ConsumerState<WallTab> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _error;
  String _sectorFilter = 'tous';
  bool _onlyMine = false;
  bool _isTrending = false;
  List<Map<String, dynamic>> _businessUnits = [];
  String? _selectedUnitId;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  final Map<String, int> _likeCounts = {};
  final Map<String, String?> _myReactionByPost = {};
  final Map<String, int> _commentCounts = {};
  Map<String, Map<String, dynamic>> _authorProfiles = {};
  Map<String, Map<String, dynamic>> _mentionedProducts = {};
  Map<String, List<String>> _postImages = {};
  Set<String> _savedPostIds = {};
  Set<String> _verifiedPurchasePostIds = {};

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

  int _pendingFriendRequests = 0;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _onlyMine = widget.initialOnlyMine;
    _loadPosts();
    _loadPendingFriendRequests();
    _loadMyRole();
    _loadBusinessUnits();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadPendingFriendRequests() async {
    final received = await FriendsRepo.fetchPendingReceived();
    if (!mounted) return;
    setState(() => _pendingFriendRequests = received.length);
  }

  /// Piliers d'entreprise (Lot 4 Communauté, 02/08) — chargés une seule
  /// fois, la liste change rarement contrairement au fil.
  Future<void> _loadBusinessUnits() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final rows = await SupabaseConfig.client
          .from('business_units')
          .select()
          .eq('active', true)
          .order('name');
      if (!mounted) return;
      setState(() => _businessUnits = List<Map<String, dynamic>>.from(rows));
    } catch (_) {}
  }

  /// "Officiel" et "Épingler" (Lot 2 Communauté, 02/08) — la vraie
  /// protection est côté serveur (voir
  /// supabase/phase52_patch_official_badge_pinned_posts.sql), ceci ne
  /// sert qu'à savoir si le menu "Épingler" doit apparaître pour
  /// l'utilisateur connecté.
  Future<void> _loadMyRole() async {
    final uid = _myId;
    if (uid == null || !SupabaseConfig.isConfigured) return;
    try {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select('role')
          .eq('id', uid)
          .single();
      if (!mounted) return;
      setState(() => _isStaff = const [
            'admin',
            'commercial',
            'production',
            'comptable'
          ].contains(row['role']));
    } catch (_) {}
  }

  Future<void> _openFriendsList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendsListScreen()),
    );
    _loadPendingFriendRequests();
  }

  Future<void> _openSavedPosts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
    );
    if (!mounted) return;
    final savedIds = await CommunityModerationRepo.fetchSavedPostIds();
    if (!mounted) return;
    setState(() => _savedPostIds = savedIds);
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
      setState(() {
        _searchQuery = trimmed;
        _isTrending = false;
      });
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

  /// IDs des produits du pilier choisi (null si aucun pilier sélectionné),
  /// pour filtrer les posts par `mentioned_product_id` (Lot 4 Communauté,
  /// 02/08) — même principe que `_sectorAuthorIds`.
  Future<List<String>?> _pilierProductIds() async {
    if (_selectedUnitId == null) return null;
    try {
      final rows = await SupabaseConfig.client
          .from('products')
          .select('id')
          .eq('business_unit_id', _selectedUnitId!);
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
    final pilierProductIds = await _pilierProductIds();
    if (pilierProductIds != null) {
      if (pilierProductIds.isEmpty) return [];
      query = query.inFilter('mentioned_product_id', pilierProductIds);
    }
    final data = await query
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .range(page * _pageSize, page * _pageSize + _pageSize - 1);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Top publications des 30 derniers jours par engagement (réactions +
  /// commentaires, `post_engagement_scores`, Lot 4 Communauté, 02/08).
  /// La vue ne sert qu'à classer — le contenu repasse par `posts`, donc
  /// une publication qu'un client ne devrait pas voir (bloquée, masquée,
  /// privée) est naturellement absente du résultat final, sans logique
  /// dupliquée ici. Pas de pagination : liste fixe, courte.
  Future<List<Map<String, dynamic>>> _fetchTrendingPosts() async {
    try {
      final scores = await SupabaseConfig.client
          .from('post_engagement_scores')
          .select('post_id, score')
          .gte(
              'created_at',
              DateTime.now()
                  .subtract(const Duration(days: 30))
                  .toIso8601String())
          .gt('score', 0)
          .order('score', ascending: false)
          .limit(30);
      final rankedIds = List<Map<String, dynamic>>.from(scores)
          .map((r) => r['post_id'] as String)
          .toList();
      if (rankedIds.isEmpty) return [];
      final posts = await SupabaseConfig.client
          .from('posts')
          .select()
          .inFilter('id', rankedIds);
      final byId = {
        for (final p in List<Map<String, dynamic>>.from(posts))
          p['id'] as String: p,
      };
      return [
        for (final id in rankedIds)
          if (byId.containsKey(id)) byId[id]!,
      ];
    } catch (_) {
      return [];
    }
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
      final list =
          _isTrending ? await _fetchTrendingPosts() : await _fetchPostsPage(0);
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

      // Profils auteurs ET mentionnés : jointure PostgREST `profiles(...)`
      // impossible ici (RLS de `profiles` limite la lecture à sa propre
      // ligne — voir supabase/phase9_patch_public_profiles.sql), on passe
      // donc par la vue publique légère. `PublicProfilesRepo.fetchByIds`
      // accepte n'importe quel ensemble d'ids, donc regrouper auteurs et
      // mentions dans un seul appel suffit — même map réutilisée pour les
      // deux affichages (03/08, mentions @).
      final authorIds = {
        ...list.map((p) => p['author_id'] as String?).whereType<String>(),
        ...list.map((p) => p['mentioned_user_id'] as String?).whereType<String>(),
      };

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
              .select('id, name, price_detail, price_gros, gros_threshold_qty, image_url')
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

      // Photos multiples (carrousel, Lot 3) — vide pour les posts d'une
      // seule photo (ou aucune) : le rendu retombe alors sur `image_url`.
      Future<Map<String, List<String>>> loadPostImages() async {
        if (postIds.isEmpty) return {};
        try {
          final rows = await SupabaseConfig.client
              .from('post_images')
              .select('post_id, image_url, position')
              .inFilter('post_id', postIds)
              .order('position');
          final grouped = <String, List<String>>{};
          for (final row in List<Map<String, dynamic>>.from(rows)) {
            grouped
                .putIfAbsent(row['post_id'] as String, () => [])
                .add(row['image_url'] as String);
          }
          return grouped;
        } catch (_) {
          // Repli silencieux : migration phase53 pas encore exécutée, ou
          // hors-ligne — le rendu retombe sur `image_url` (1 seule photo).
          return {};
        }
      }

      // Achats vérifiés (Lot 5 Communauté, 02/08) — un appel groupé plutôt
      // qu'un appel par publication, voir
      // supabase/phase55_patch_verified_purchases_reviews.sql.
      Future<Set<String>> loadVerifiedPurchases() async {
        if (postIds.isEmpty) return {};
        try {
          final rows = await SupabaseConfig.client.rpc(
              'verified_purchase_post_ids', params: {'post_ids': postIds});
          return List<Map<String, dynamic>>.from(rows)
              .map((r) => r['post_id'] as String)
              .toSet();
        } catch (_) {
          return {};
        }
      }

      final results = await Future.wait<dynamic>([
        loadLikes(),
        loadComments(),
        PublicProfilesRepo.fetchByIds(authorIds),
        loadMentionedProducts(),
        CommunityModerationRepo.fetchSavedPostIds(),
        loadPostImages(),
        loadVerifiedPurchases(),
      ]);
      final likesRows = results[0] as List<Map<String, dynamic>>;
      final commentsRows = results[1] as List<Map<String, dynamic>>;
      final profiles = results[2] as Map<String, Map<String, dynamic>>;
      final mentionedProducts =
          results[3] as Map<String, Map<String, dynamic>>;
      final savedIds = results[4] as Set<String>;
      final postImages = results[5] as Map<String, List<String>>;
      final verifiedPurchaseIds = results[6] as Set<String>;

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
        _savedPostIds = savedIds;
        _postImages = postImages;
        _verifiedPurchasePostIds = verifiedPurchaseIds;
        _isLoading = false;
        // Le fil Tendances est une liste fixe (top 30), jamais paginée.
        _hasMore = !_isTrending && list.length == _pageSize;
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

      final authorIds = {
        ...list.map((p) => p['author_id'] as String?).whereType<String>(),
        ...list.map((p) => p['mentioned_user_id'] as String?).whereType<String>(),
      };
      final mentionedIds = list
          .map((p) => p['mentioned_product_id'] as String?)
          .whereType<String>()
          .toSet();

      Future<Map<String, Map<String, dynamic>>> loadMentionedProducts() async {
        if (mentionedIds.isEmpty) return {};
        try {
          final products = await SupabaseConfig.client
              .from('products')
              .select('id, name, price_detail, price_gros, gros_threshold_qty, image_url')
              .inFilter('id', mentionedIds.toList());
          return {
            for (final row in List<Map<String, dynamic>>.from(products))
              row['id'] as String: row,
          };
        } catch (_) {
          return {};
        }
      }

      Future<Map<String, List<String>>> loadPostImages() async {
        if (postIds.isEmpty) return {};
        try {
          final rows = await SupabaseConfig.client
              .from('post_images')
              .select('post_id, image_url, position')
              .inFilter('post_id', postIds)
              .order('position');
          final grouped = <String, List<String>>{};
          for (final row in List<Map<String, dynamic>>.from(rows)) {
            grouped
                .putIfAbsent(row['post_id'] as String, () => [])
                .add(row['image_url'] as String);
          }
          return grouped;
        } catch (_) {
          return {};
        }
      }

      Future<Set<String>> loadVerifiedPurchases() async {
        if (postIds.isEmpty) return {};
        try {
          final rows = await SupabaseConfig.client.rpc(
              'verified_purchase_post_ids', params: {'post_ids': postIds});
          return List<Map<String, dynamic>>.from(rows)
              .map((r) => r['post_id'] as String)
              .toSet();
        } catch (_) {
          return {};
        }
      }

      final results = await Future.wait<dynamic>([
        loadLikes(),
        loadComments(),
        PublicProfilesRepo.fetchByIds(authorIds),
        loadMentionedProducts(),
        loadPostImages(),
        loadVerifiedPurchases(),
      ]);
      final likesRows = results[0] as List<Map<String, dynamic>>;
      final commentsRows = results[1] as List<Map<String, dynamic>>;
      final profiles = results[2] as Map<String, Map<String, dynamic>>;
      final mentionedProducts =
          results[3] as Map<String, Map<String, dynamic>>;
      final postImages = results[4] as Map<String, List<String>>;
      final verifiedPurchaseIds = results[5] as Set<String>;

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
        _postImages = {..._postImages, ...postImages};
        _verifiedPurchasePostIds = {
          ..._verifiedPurchasePostIds,
          ...verifiedPurchaseIds
        };
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
      final updatedAt = DateTime.now().toIso8601String();
      await SupabaseConfig.client.from('posts').update(
          {'content': newContent, 'updated_at': updatedAt}).eq('id', post['id']);
      setState(() {
        final index = _posts.indexWhere((p) => p['id'] == post['id']);
        if (index != -1) {
          _posts[index]['content'] = newContent;
          _posts[index]['updated_at'] = updatedAt;
        }
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

  /// Signaler une publication d'un autre client (01/08, demande
  /// explicite) — jamais proposé sur ses propres publications (le menu
  /// contextuel affiche Modifier/Supprimer dans ce cas). Le staff est
  /// notifié automatiquement (voir
  /// supabase/phase47_patch_report_and_whatsapp_contact.sql), aucune
  /// action supplémentaire nécessaire ici.
  Future<void> _reportPost(Map<String, dynamic> post) async {
    final userId = _myId;
    if (userId == null) return;
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler cette publication'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Raison (optionnel)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await SupabaseConfig.client.from('post_reports').insert({
        'post_id': post['id'],
        'reporter_id': userId,
        'reason': reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Publication signalée — notre équipe va la vérifier.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de signaler pour le moment.')));
    }
  }

  /// Enregistrer/retirer une publication (Lot 1 Communauté, 02/08) — mise
  /// à jour optimiste avec repli si l'appel serveur échoue.
  Future<void> _toggleSave(Map<String, dynamic> post) async {
    final postId = post['id'] as String;
    final wasSaved = _savedPostIds.contains(postId);
    setState(() {
      if (wasSaved) {
        _savedPostIds.remove(postId);
      } else {
        _savedPostIds.add(postId);
      }
    });
    try {
      if (wasSaved) {
        await CommunityModerationRepo.unsavePost(postId);
      } else {
        await CommunityModerationRepo.savePost(postId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (wasSaved) {
          _savedPostIds.add(postId);
        } else {
          _savedPostIds.remove(postId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action impossible pour le moment.')));
    }
  }

  /// Masquer une publication (pour soi seulement, sans signaler — voir
  /// supabase/phase51_patch_block_hide_save_posts.sql).
  Future<void> _hidePost(Map<String, dynamic> post) async {
    try {
      await CommunityModerationRepo.hidePost(post['id']);
      if (!mounted) return;
      setState(() => _posts.removeWhere((p) => p['id'] == post['id']));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Publication masquée.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de masquer pour le moment.')));
    }
  }

  /// Bloquer l'auteur d'une publication — exclut immédiatement toutes
  /// ses publications du fil affiché (la RLS s'occupe des futurs
  /// rechargements, voir posts_select dans phase51).
  Future<void> _blockAuthor(Map<String, dynamic> post) async {
    final authorId = post['author_id'] as String?;
    if (authorId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquer ce client ?'),
        content: const Text(
            'Vous ne verrez plus ses publications, et il ne pourra plus vous envoyer de demande d\'ami ni de message.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await CommunityModerationRepo.block(authorId);
      if (!mounted) return;
      setState(() => _posts.removeWhere((p) => p['author_id'] == authorId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Client bloqué.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de bloquer pour le moment.')));
    }
  }

  /// Commander directement le produit taggé sans passer par sa fiche
  /// (Lot 2 Communauté, 02/08). Si le produit a des variantes
  /// (format/parfum, `product_variants`), impossible de deviner laquelle
  /// commander : on ouvre la fiche pour que le client choisisse — sinon
  /// ajout direct au panier, quantité 1.
  Future<void> _quickOrder(Map<String, dynamic> product) async {
    try {
      final variants = await SupabaseConfig.client
          .from('product_variants')
          .select('id')
          .eq('product_id', product['id'])
          .limit(1);
      if (!mounted) return;
      if (List.from(variants).isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailClient(product: product)),
        );
        return;
      }
      ref.read(cartProvider.notifier).addItem(CartItem(
            productId: product['id'],
            name: product['name'] ?? '',
            priceDetail: (product['price_detail'] as num?)?.toDouble() ?? 0,
            priceGros: (product['price_gros'] as num?)?.toDouble() ?? 0,
            grosThresholdQty: (product['gros_threshold_qty'] as int?) ?? 10,
            imageUrl: product['image_url'] as String?,
          ));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${product['name']} ajouté au panier'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible d\'ajouter au panier pour le moment.')));
    }
  }

  /// Épingler/désépingler une publication (staff uniquement — voir le
  /// trigger `protect_posts_pin_column` qui annule silencieusement toute
  /// tentative venant d'un compte non-staff, même si ce menu ne devrait
  /// jamais leur être proposé).
  Future<void> _togglePin(Map<String, dynamic> post) async {
    final newValue = !(post['is_pinned'] == true);
    try {
      await SupabaseConfig.client
          .from('posts')
          .update({'is_pinned': newValue}).eq('id', post['id']);
      if (!mounted) return;
      setState(() {
        final index = _posts.indexWhere((p) => p['id'] == post['id']);
        if (index != -1) _posts[index]['is_pinned'] = newValue;
        _posts.sort((a, b) {
          final pa = a['is_pinned'] == true ? 1 : 0;
          final pb = b['is_pinned'] == true ? 1 : 0;
          if (pa != pb) return pb - pa;
          return (b['created_at'] as String)
              .compareTo(a['created_at'] as String);
        });
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de modifier l\'épinglage.')));
    }
  }

  /// Hashtags cliquables (Lot 3 Communauté, 02/08) — analysés directement
  /// depuis `content`, aucune colonne dédiée : reconnaît `#mot` (lettres
  /// Unicode, chiffres, underscore) et le rend cliquable, coloré comme un
  /// lien. Le tap réutilise la recherche déjà en place (`content ilike`)
  /// plutôt que d'inventer un système de catégories séparé.
  Widget _buildPostContent(String content, ThemeData theme) {
    final regex = RegExp(r'#[\p{L}\p{N}_]+', unicode: true);
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in regex.allMatches(content)) {
      if (match.start > last) {
        spans.add(TextSpan(text: content.substring(last, match.start)));
      }
      final tag = match.group(0)!;
      spans.add(TextSpan(
        text: tag,
        style: TextStyle(
            color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
        recognizer: TapGestureRecognizer()..onTap = () => _searchByHashtag(tag),
      ));
      last = match.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last)));
    }
    return Text.rich(TextSpan(style: theme.textTheme.bodyMedium, children: spans));
  }

  void _searchByHashtag(String tag) {
    setState(() {
      _searchController.text = tag;
      _searchQuery = tag;
      _isTrending = false;
    });
    _loadPosts();
  }

  /// Contacter l'auteur via WhatsApp (01/08, demande explicite) —
  /// n'apparaît que si l'auteur a lui-même activé "Afficher mon numéro"
  /// dans ses réglages de confidentialité (voir
  /// security_settings_screen.dart) : le numéro est masqué par défaut
  /// pour tout le monde (voir public_profile_screen.dart).
  Future<void> _contactAuthorViaWhatsApp(String? phone) async {
    final link = buildWhatsAppLink(phone);
    if (link == null) return;
    try {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible d\'ouvrir WhatsApp.')));
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
        actions: [
          IconButton(
            tooltip: 'Réalisations clients',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RealisationsGalleryScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Sauvegardés',
            icon: const Icon(Icons.bookmark_border),
            onPressed: _openSavedPosts,
          ),
          IconButton(
            tooltip: 'Amis',
            icon: Badge(
              label: Text('$_pendingFriendRequests'),
              isLabelVisible: _pendingFriendRequests > 0,
              child: const Icon(Icons.people_outline),
            ),
            onPressed: _openFriendsList,
          ),
        ],
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
                                child: ChoiceChip(
                                  avatar: const Icon(
                                      Icons.local_fire_department_outlined,
                                      size: 16),
                                  label: const Text('Tendances'),
                                  selected: _isTrending,
                                  onSelected: (v) {
                                    setState(() => _isTrending = v);
                                    _onFilterChanged();
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  avatar: const Icon(Icons.person_outline,
                                      size: 16),
                                  label: const Text('Mes publications'),
                                  selected: _onlyMine,
                                  onSelected: (v) {
                                    setState(() {
                                      _onlyMine = v;
                                      _isTrending = false;
                                    });
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
                                    setState(() {
                                      _sectorFilter = 'tous';
                                      _isTrending = false;
                                    });
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
                                        setState(() {
                                          _sectorFilter = e.key;
                                          _isTrending = false;
                                        });
                                        _onFilterChanged();
                                      },
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      if (_businessUnits.isNotEmpty)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 5.h,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4.w, vertical: 1.h),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: const Text('Tous les piliers'),
                                    selected: _selectedUnitId == null,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedUnitId = null;
                                        _isTrending = false;
                                      });
                                      _onFilterChanged();
                                    },
                                  ),
                                ),
                                ..._businessUnits.map((u) => Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        label: Text(u['name'] ?? ''),
                                        selected:
                                            _selectedUnitId == u['id'],
                                        onSelected: (_) {
                                          setState(() {
                                            _selectedUnitId = u['id'];
                                            _isTrending = false;
                                          });
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
                              child: Text(_isTrending
                                  ? 'Aucune publication très active dans les 30 derniers jours.'
                                  : _searchQuery.isNotEmpty
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
                                      if (post['is_pinned'] == true) ...[
                                        Row(
                                          children: [
                                            Icon(Icons.push_pin,
                                                size: 14,
                                                color: theme
                                                    .colorScheme.primary),
                                            const SizedBox(width: 4),
                                            Text('Épinglé',
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                          ],
                                        ),
                                        SizedBox(height: 0.5.h),
                                      ],
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
                                                        Row(
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                  authorName,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  style: theme
                                                                      .textTheme
                                                                      .bodyMedium
                                                                      ?.copyWith(
                                                                          fontWeight:
                                                                              FontWeight.w600)),
                                                            ),
                                                            if (author?[
                                                                    'is_staff'] ==
                                                                true) ...[
                                                              const SizedBox(
                                                                  width: 4),
                                                              Icon(
                                                                  Icons
                                                                      .verified,
                                                                  size: 14,
                                                                  color: theme
                                                                      .colorScheme
                                                                      .primary),
                                                            ],
                                                          ],
                                                        ),
                                                        if (sector != null ||
                                                            post['updated_at'] !=
                                                                null)
                                                          Text(
                                                              [
                                                                if (sector !=
                                                                    null)
                                                                  sector,
                                                                if (post['updated_at'] !=
                                                                    null)
                                                                  'Modifié',
                                                              ].join(' · '),
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
                                                } else if (value == 'save') {
                                                  _toggleSave(post);
                                                } else if (value == 'pin') {
                                                  _togglePin(post);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'save',
                                                  child: Text(_savedPostIds
                                                          .contains(post['id'])
                                                      ? 'Retirer des enregistrés'
                                                      : 'Enregistrer'),
                                                ),
                                                if (_isStaff)
                                                  PopupMenuItem(
                                                    value: 'pin',
                                                    child: Text(post[
                                                                'is_pinned'] ==
                                                            true
                                                        ? 'Désépingler'
                                                        : 'Épingler'),
                                                  ),
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Modifier'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Supprimer',
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ],
                                            )
                                          else if (post['author_id'] != null)
                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                  Icons.more_vert,
                                                  size: 20),
                                              onSelected: (value) {
                                                if (value == 'report') {
                                                  _reportPost(post);
                                                } else if (value == 'save') {
                                                  _toggleSave(post);
                                                } else if (value == 'hide') {
                                                  _hidePost(post);
                                                } else if (value == 'block') {
                                                  _blockAuthor(post);
                                                } else if (value == 'pin') {
                                                  _togglePin(post);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'save',
                                                  child: Text(_savedPostIds
                                                          .contains(post['id'])
                                                      ? 'Retirer des enregistrés'
                                                      : 'Enregistrer'),
                                                ),
                                                if (_isStaff)
                                                  PopupMenuItem(
                                                    value: 'pin',
                                                    child: Text(post[
                                                                'is_pinned'] ==
                                                            true
                                                        ? 'Désépingler'
                                                        : 'Épingler'),
                                                  ),
                                                const PopupMenuItem(
                                                  value: 'hide',
                                                  child: Text('Masquer'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'report',
                                                  child: Text('Signaler'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'block',
                                                  child: Text('Bloquer ce client',
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
                                        _buildPostContent(
                                            post['content'], theme),
                                      if (post['mentioned_user_id'] !=
                                          null) ...[
                                        SizedBox(height: 0.5.h),
                                        InkWell(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PublicProfileScreen(
                                                userId: post[
                                                    'mentioned_user_id'],
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            'avec @${PublicProfilesRepo.displayName(_authorProfiles[post['mentioned_user_id']])}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                    color: theme.colorScheme
                                                        .primary,
                                                    fontWeight:
                                                        FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                      if ((_postImages[post['id']]?.length ??
                                              0) >
                                          1) ...[
                                        SizedBox(height: 1.h),
                                        _PostImageCarousel(
                                            imageUrls:
                                                _postImages[post['id']]!),
                                      ] else if (post['image_url'] !=
                                          null) ...[
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
                                                if (_verifiedPurchasePostIds
                                                    .contains(post['id']))
                                                  Tooltip(
                                                    message:
                                                        'Ce client a réellement commandé ce produit',
                                                    child: Icon(
                                                        Icons.verified,
                                                        size: 16,
                                                        color: theme
                                                            .colorScheme
                                                            .primary),
                                                  ),
                                                TextButton(
                                                  onPressed: () =>
                                                      _quickOrder(
                                                          mentionedProduct),
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets
                                                        .symmetric(
                                                            horizontal: 2.w),
                                                    minimumSize: Size.zero,
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                  child:
                                                      const Text('Commander'),
                                                ),
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
                                          if (buildWhatsAppLink(
                                                  author?['phone']
                                                      as String?) !=
                                              null)
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.chat_outlined,
                                                  size: 20,
                                                  color: Colors.green),
                                              tooltip:
                                                  'Contacter via WhatsApp',
                                              onPressed: () =>
                                                  _contactAuthorViaWhatsApp(
                                                      author?['phone']
                                                          as String?),
                                            ),
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
  List<File> _images = [];
  bool _isPosting = false;
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;
  Map<String, dynamic>? _selectedMentionedUser;

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
  /// Sélection multiple (Lot 3 Communauté, 02/08 — carrousel) : même
  /// compression qu'avant (maxWidth/imageQuality appliqués par
  /// `image_picker` avant l'upload), juste plusieurs fichiers à la fois.
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 60, maxWidth: 800);
    if (picked.isNotEmpty) {
      setState(() => _images = [..._images, ...picked.map((p) => File(p.path))]);
    }
  }

  Future<void> _pickMentionedUser() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _UserPickerSheet(),
    );
    if (selected != null) {
      setState(() => _selectedMentionedUser = selected);
    }
  }

  Future<void> _submit() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    if (_controller.text.trim().isEmpty && _images.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      // Chaque photo est uploadée séparément vers `wall-photos` (bucket
      // public, Phase 3) ; `posts.image_url` garde la 1ère pour rester
      // compatible avec les affichages qui ne connaissent pas encore
      // `post_images` (aperçu du profil public).
      final imageUrls = <String>[];
      for (var i = 0; i < _images.length; i++) {
        final fileName =
            '$userId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        await SupabaseConfig.client.storage
            .from('wall-photos')
            .upload(fileName, _images[i]);
        imageUrls.add(SupabaseConfig.client.storage
            .from('wall-photos')
            .getPublicUrl(fileName));
      }

      final inserted = await SupabaseConfig.client
          .from('posts')
          .insert({
            'author_id': userId,
            'content': _controller.text.trim(),
            'image_url': imageUrls.isEmpty ? null : imageUrls.first,
            'mentioned_product_id': _selectedProduct?['id'],
            'mentioned_user_id': _selectedMentionedUser?['id'],
          })
          .select('id')
          .single();

      if (imageUrls.isNotEmpty) {
        await SupabaseConfig.client.from('post_images').insert([
          for (var i = 0; i < imageUrls.length; i++)
            {
              'post_id': inserted['id'],
              'image_url': imageUrls[i],
              'position': i,
            },
        ]);
      }

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
          if (_images.isNotEmpty)
            SizedBox(
              height: 15.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => SizedBox(width: 2.w),
                itemBuilder: (context, index) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_images[index],
                          height: 15.h, width: 15.h, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => setState(
                            () => _images = [..._images]..removeAt(index)),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 8,
            children: [
              if (_selectedProduct != null)
                Chip(
                  avatar: const Icon(Icons.shopping_bag_outlined, size: 16),
                  label: Text(_selectedProduct!['name'] ?? ''),
                  onDeleted: () => setState(() => _selectedProduct = null),
                ),
              if (_selectedMentionedUser != null)
                Chip(
                  avatar: const Icon(Icons.person_outline, size: 16),
                  label: Text(
                      '@${PublicProfilesRepo.displayName(_selectedMentionedUser)}'),
                  onDeleted: () =>
                      setState(() => _selectedMentionedUser = null),
                ),
            ],
          ),
          if (_selectedProduct != null || _selectedMentionedUser != null)
            SizedBox(height: 1.h),
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_outlined),
                label: const Text('Photos'),
              ),
              TextButton.icon(
                onPressed: _products.isEmpty ? null : _pickProduct,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(
                    _selectedProduct == null ? 'Produit' : 'Changer'),
              ),
              TextButton.icon(
                onPressed: _pickMentionedUser,
                icon: const Icon(Icons.alternate_email),
                label: Text(
                    _selectedMentionedUser == null ? 'Mentionner' : 'Changer'),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _isPosting ? null : _submit,
              child: _isPosting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Publier'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recherche d'un autre client pour le mentionner dans une publication
/// (Lot 3 Communauté, 02/08) — remplit `posts.mentioned_user_id` (Phase
/// 3, colonne inutilisée jusqu'ici). Recherche côté serveur (pas de
/// préchargement comme `_ProductPickerSheet` : trop de clients pour tout
/// charger d'un coup) via `public_profiles`, débouncée.
class _UserPickerSheet extends StatefulWidget {
  const _UserPickerSheet();

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isLoading = true);
      try {
        final myId = SupabaseConfig.client.auth.currentUser?.id;
        final rows = await SupabaseConfig.client
            .from('public_profiles')
            .select()
            .or('full_name.ilike.%$query%,company_name.ilike.%$query%')
            .limit(20);
        if (!mounted) return;
        setState(() {
          _results = List<Map<String, dynamic>>.from(rows)
              .where((r) => r['id'] != myId)
              .toList();
          _isLoading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    });
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
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un client...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _onChanged,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _controller.text.trim().isEmpty
                                ? 'Tapez un nom pour rechercher.'
                                : 'Aucun client trouvé.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final profile = _results[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: profile['avatar_url'] != null
                                    ? NetworkImage(profile['avatar_url'])
                                    : null,
                                child: profile['avatar_url'] == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                  PublicProfilesRepo.displayName(profile)),
                              onTap: () => Navigator.pop(context, profile),
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

/// Carrousel de photos d'une publication (Lot 3 Communauté, 02/08) —
/// `post_images`, voir supabase/phase53_patch_post_images_carousel.sql.
/// Affiché seulement si la publication a 2 photos ou plus (sinon le fil
/// retombe sur `posts.image_url`, une seule image sans PageView).
class _PostImageCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const _PostImageCarousel({required this.imageUrls});

  @override
  State<_PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<_PostImageCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 20.h,
            width: double.infinity,
            child: PageView.builder(
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => Image.network(
                widget.imageUrls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                cacheWidth: 800,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.imageUrls.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                ),
              ),
          ],
        ),
      ],
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
