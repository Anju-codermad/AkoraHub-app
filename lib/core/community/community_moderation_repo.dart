import '../supabase/supabase_config.dart';

/// Blocage, masquage et enregistrement de publications (Communauté) —
/// voir supabase/phase51_patch_block_hide_save_posts.sql. Chaque table
/// est strictement personnelle (RLS : select/insert/delete uniquement
/// sur ses propres lignes) — le blocage exclut aussi automatiquement les
/// publications concernées du fil (RLS sur `posts`, pas un filtre
/// côté app).
class CommunityModerationRepo {
  CommunityModerationRepo._();

  static String? get _myId => SupabaseConfig.client.auth.currentUser?.id;

  // ------------------------------------------------------------
  // Blocage
  // ------------------------------------------------------------

  /// IDs des clients bloqués par l'utilisateur connecté (jamais qui l'a
  /// bloqué lui — voir le script SQL, même principe que post_reports).
  static Future<Set<String>> fetchBlockedIds() async {
    final uid = _myId;
    if (uid == null) return {};
    try {
      final rows = await SupabaseConfig.client
          .from('user_blocks')
          .select('blocked_id')
          .eq('blocker_id', uid);
      return List<Map<String, dynamic>>.from(rows)
          .map((r) => r['blocked_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// Lignes `user_blocks` brutes (id du compte bloqué + date), triées du
  /// plus récent au plus ancien — pour l'écran "Comptes bloqués". Le
  /// profil de chaque compte se résout séparément via
  /// `PublicProfilesRepo.fetchByIds` (même pattern que `friends_repo.dart`
  /// — `user_blocks` a deux colonnes vers `profiles`, une jointure
  /// imbriquée demanderait de deviner le nom de la contrainte FK).
  static Future<List<Map<String, dynamic>>> fetchBlocked() async {
    final uid = _myId;
    if (uid == null) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('user_blocks')
          .select('blocked_id, created_at')
          .eq('blocker_id', uid)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  static Future<void> block(String userId) async {
    final uid = _myId;
    if (uid == null) throw Exception('Non connecté.');
    await SupabaseConfig.client
        .from('user_blocks')
        .upsert({'blocker_id': uid, 'blocked_id': userId},
            onConflict: 'blocker_id,blocked_id');
  }

  static Future<void> unblock(String userId) async {
    final uid = _myId;
    if (uid == null) return;
    await SupabaseConfig.client
        .from('user_blocks')
        .delete()
        .eq('blocker_id', uid)
        .eq('blocked_id', userId);
  }

  // ------------------------------------------------------------
  // Masquer une publication
  // ------------------------------------------------------------

  static Future<void> hidePost(String postId) async {
    final uid = _myId;
    if (uid == null) throw Exception('Non connecté.');
    await SupabaseConfig.client
        .from('hidden_posts')
        .upsert({'user_id': uid, 'post_id': postId},
            onConflict: 'user_id,post_id');
  }

  // ------------------------------------------------------------
  // Enregistrer une publication
  // ------------------------------------------------------------

  /// IDs des publications enregistrées par l'utilisateur connecté.
  static Future<Set<String>> fetchSavedPostIds() async {
    final uid = _myId;
    if (uid == null) return {};
    try {
      final rows = await SupabaseConfig.client
          .from('saved_posts')
          .select('post_id')
          .eq('user_id', uid);
      return List<Map<String, dynamic>>.from(rows)
          .map((r) => r['post_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> savePost(String postId) async {
    final uid = _myId;
    if (uid == null) throw Exception('Non connecté.');
    await SupabaseConfig.client
        .from('saved_posts')
        .upsert({'user_id': uid, 'post_id': postId},
            onConflict: 'user_id,post_id');
  }

  static Future<void> unsavePost(String postId) async {
    final uid = _myId;
    if (uid == null) return;
    await SupabaseConfig.client
        .from('saved_posts')
        .delete()
        .eq('user_id', uid)
        .eq('post_id', postId);
  }

  /// Publications enregistrées, les plus récentes en premier — pour
  /// l'écran "Sauvegardés". Deux requêtes séparées plutôt qu'une
  /// jointure imbriquée (même pattern que `wall_tab.dart` : `posts` a
  /// deux colonnes vers `profiles` — author_id et mentioned_user_id —
  /// une jointure `profiles(...)` serait ambiguë pour PostgREST).
  /// `posts` reste soumis à sa propre RLS : une publication supprimée ou
  /// d'un compte désormais bloqué disparaît naturellement du résultat.
  static Future<List<Map<String, dynamic>>> fetchSavedPosts() async {
    final uid = _myId;
    if (uid == null) return [];
    try {
      final savedRows = await SupabaseConfig.client
          .from('saved_posts')
          .select('post_id, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      final saved = List<Map<String, dynamic>>.from(savedRows);
      if (saved.isEmpty) return [];
      final postIds = saved.map((r) => r['post_id'] as String).toList();
      final postRows = await SupabaseConfig.client
          .from('posts')
          .select()
          .inFilter('id', postIds);
      final postsById = {
        for (final p in List<Map<String, dynamic>>.from(postRows))
          p['id'] as String: p,
      };
      return saved
          .where((r) => postsById.containsKey(r['post_id']))
          .map((r) => postsById[r['post_id']]!)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
