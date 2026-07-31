import '../supabase/supabase_config.dart';

/// Signalisation des appels audio/vidéo (voir
/// supabase/phase37_patch_calls.sql) — cette table ne transporte aucun
/// flux audio/vidéo, seulement "qui appelle qui, sur quel canal Agora".
class CallRepo {
  CallRepo._();

  static String _newChannelName(String conversationId) =>
      'call_${conversationId}_${DateTime.now().millisecondsSinceEpoch}';

  /// Crée l'invitation et retourne (id, channel_name) pour que
  /// l'appelant puisse rejoindre immédiatement le canal Agora.
  static Future<({String id, String channelName})> createInvitation({
    required String conversationId,
    required String calleeId,
    required String callType,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser!.id;
    final channelName = _newChannelName(conversationId);
    final row = await SupabaseConfig.client
        .from('call_invitations')
        .insert({
          'conversation_id': conversationId,
          'caller_id': userId,
          'callee_id': calleeId,
          'call_type': callType,
          'channel_name': channelName,
        })
        .select('id, channel_name')
        .single();
    return (id: row['id'] as String, channelName: row['channel_name'] as String);
  }

  static Future<void> updateStatus(String invitationId, String status) async {
    await SupabaseConfig.client
        .from('call_invitations')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', invitationId);
  }
}
