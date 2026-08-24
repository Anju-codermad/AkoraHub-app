import '../supabase/supabase_config.dart';

/// Nombre de messages du staff non encore lus par le client, dans sa
/// conversation support (une par client — voir `phase8_patch_messaging.sql`).
/// Même requête que `loadUnreadCount()` dans `catalog_tab.dart`, extraite
/// ici pour être réutilisée par la bulle de chat flottante
/// (`floating_chat_bubble.dart`), affichée sur tout l'espace client et
/// pas seulement l'accueil.
Future<int> fetchUnreadSupportMessagesCount() async {
  final userId = SupabaseConfig.client.auth.currentUser?.id;
  if (userId == null || !SupabaseConfig.isConfigured) return 0;
  try {
    final convo = await SupabaseConfig.client
        .from('conversations')
        .select('id')
        .eq('customer_id', userId)
        .maybeSingle();
    if (convo == null) return 0;
    final unread = await SupabaseConfig.client
        .from('messages')
        .select('id')
        .eq('conversation_id', convo['id'])
        .inFilter('sender_role', ['staff', 'ai'])
        .eq('read_by_client', false);
    return List.from(unread).length;
  } catch (_) {
    return 0;
  }
}
