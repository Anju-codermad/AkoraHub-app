import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/chat/typing_dots.dart';
import '../../../core/chat/typing_presence.dart';
import '../../../core/community/friends_repo.dart';
import '../../../core/supabase/supabase_config.dart';

/// Conversation privée 1:1 entre deux clients devenus amis (voir
/// supabase/phase48_patch_friends_and_private_chat.sql) — texte
/// uniquement pour cette première version (pas de photo/audio, à la
/// différence de la messagerie client/staff — ChatComposer n'est pas
/// réutilisé ici pour ne pas coupler les deux systèmes de messagerie).
/// Mise à jour en direct via Supabase Realtime, même principe que
/// chat_screen.dart. Indicateur "en train d'écrire" (05/08) via
/// `TypingPresence` — topic dérivé de la paire d'ids triée, identique
/// des deux côtés de la conversation.
class FriendChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const FriendChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends State<FriendChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  final _timeFormat = DateFormat('HH:mm');

  TypingPresence? _typing;
  bool _remoteIsTyping = false;

  String? get _myId => SupabaseConfig.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    FriendsRepo.markRead(widget.otherUserId);
    final myId = _myId;
    if (myId != null) {
      // Paire d'ids triée : même topic quel que soit le côté qui ouvre
      // la conversation en premier.
      final ids = [myId, widget.otherUserId]..sort();
      _typing = TypingPresence(
        topic: 'friend:${ids.join('_')}',
        selfId: myId,
        onRemoteTypingChanged: (isTyping) {
          if (mounted) setState(() => _remoteIsTyping = isTyping);
        },
      );
    }
    _controller.addListener(() {
      if (_controller.text.trim().isNotEmpty) _typing?.notifyTyping();
    });
  }

  @override
  void dispose() {
    _typing?.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _controller.clear();
    try {
      await FriendsRepo.sendMessage(widget.otherUserId, text);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message non envoyé. Réessayez.')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FriendsRepo.messagesStream(widget.otherUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Text('Aucun message. Dites bonjour !',
                        style: theme.textTheme.bodyMedium),
                  );
                }
                // Marque comme lu à chaque nouveau lot reçu pendant que
                // l'écran est ouvert — best-effort, sans setState, donc
                // sans risque de boucle de reconstruction.
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => FriendsRepo.markRead(widget.otherUserId));
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(4.w),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMine = message['sender_id'] == _myId;
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        constraints: BoxConstraints(maxWidth: 75.w),
                        decoration: BoxDecoration(
                          color: isMine
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message['content'] ?? '',
                              style: TextStyle(
                                color: isMine
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _timeFormat.format(
                                  DateTime.parse(message['created_at'])
                                      .toLocal()),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: (isMine
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface)
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_remoteIsTyping)
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TypingDots(color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Écrire un message...',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
