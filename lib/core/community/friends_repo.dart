import '../supabase/supabase_config.dart';

/// Demandes d'ami + messagerie privée entre clients (Communauté), voir
/// supabase/phase48_patch_friends_and_private_chat.sql — réservé aux
/// clients ayant déjà fait au moins un achat (RLS côté serveur,
/// `has_made_purchase`), pas seulement une vérification côté app.
class FriendsRepo {
  FriendsRepo._();

  static String? get _myId => SupabaseConfig.client.auth.currentUser?.id;

  static Future<bool> hasMadePurchase() async {
    final uid = _myId;
    if (uid == null) return false;
    try {
      final result = await SupabaseConfig.client
          .rpc('has_made_purchase', params: {'uid': uid});
      return result as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Ligne `friendships` entre l'utilisateur connecté et [otherUserId],
  /// quel que soit qui a envoyé la demande — `null` si aucune relation.
  static Future<Map<String, dynamic>?> fetchFriendshipStatus(
      String otherUserId) async {
    final uid = _myId;
    if (uid == null) return null;
    try {
      final rows = await SupabaseConfig.client
          .from('friendships')
          .select()
          .or('and(requester_id.eq.$uid,addressee_id.eq.$otherUserId),'
              'and(requester_id.eq.$otherUserId,addressee_id.eq.$uid)')
          .limit(1);
      final list = List<Map<String, dynamic>>.from(rows);
      return list.isEmpty ? null : list.first;
    } catch (_) {
      return null;
    }
  }

  static Future<void> sendRequest(String otherUserId) async {
    final uid = _myId;
    if (uid == null) throw Exception('Non connecté.');
    await SupabaseConfig.client.from('friendships').insert({
      'requester_id': uid,
      'addressee_id': otherUserId,
    });
  }

  static Future<void> acceptRequest(String friendshipId) async {
    await SupabaseConfig.client.from('friendships').update({
      'status': 'acceptee',
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', friendshipId);
  }

  static Future<void> refuseRequest(String friendshipId) async {
    await SupabaseConfig.client.from('friendships').update({
      'status': 'refusee',
      'responded_at': DateTime.now().toIso8601String(),
    }).eq('id', friendshipId);
  }

  /// Annuler une demande envoyée, ou retirer un ami — simple suppression
  /// de la ligne (les deux côtés y sont autorisés par la policy RLS).
  static Future<void> removeFriendship(String friendshipId) async {
    await SupabaseConfig.client
        .from('friendships')
        .delete()
        .eq('id', friendshipId);
  }

  static Future<List<Map<String, dynamic>>> fetchFriends() async {
    final uid = _myId;
    if (uid == null) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('friendships')
          .select()
          .eq('status', 'acceptee')
          .or('requester_id.eq.$uid,addressee_id.eq.$uid');
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPendingReceived() async {
    final uid = _myId;
    if (uid == null) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('friendships')
          .select()
          .eq('status', 'en_attente')
          .eq('addressee_id', uid)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPendingSent() async {
    final uid = _myId;
    if (uid == null) return [];
    try {
      final rows = await SupabaseConfig.client
          .from('friendships')
          .select()
          .eq('status', 'en_attente')
          .eq('requester_id', uid)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return [];
    }
  }

  /// Le "correspondant" d'une ligne friendships du point de vue de
  /// l'utilisateur connecté — l'autre id, quel que soit qui a envoyé la
  /// demande.
  static String otherUserId(Map<String, dynamic> friendship) {
    final uid = _myId;
    return friendship['requester_id'] == uid
        ? friendship['addressee_id'] as String
        : friendship['requester_id'] as String;
  }

  /// `.stream()` ne supporte pas de filtre `or` — on reçoit donc TOUS
  /// les messages privés visibles par l'utilisateur connecté (déjà
  /// limités par la RLS à ses propres conversations) et on filtre côté
  /// app sur la paire précise affichée à l'écran.
  static Stream<List<Map<String, dynamic>>> messagesStream(
      String otherUserId) {
    final uid = _myId ?? '';
    return SupabaseConfig.client
        .from('friend_messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((rows) => rows
            .where((r) =>
                (r['sender_id'] == uid && r['recipient_id'] == otherUserId) ||
                (r['sender_id'] == otherUserId && r['recipient_id'] == uid))
            .toList());
  }

  static Future<void> sendMessage(String recipientId, String content) async {
    final uid = _myId;
    if (uid == null) throw Exception('Non connecté.');
    await SupabaseConfig.client.from('friend_messages').insert({
      'sender_id': uid,
      'recipient_id': recipientId,
      'content': content,
    });
  }

  static Future<void> markRead(String otherUserId) async {
    final uid = _myId;
    if (uid == null) return;
    try {
      await SupabaseConfig.client
          .from('friend_messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('sender_id', otherUserId)
          .eq('recipient_id', uid)
          .filter('read_at', 'is', null);
    } catch (_) {}
  }
}
