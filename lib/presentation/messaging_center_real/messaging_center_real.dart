import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/calls/call_repo.dart';
import '../../core/chat/chat_attachment_bubble.dart';
import '../../core/chat/chat_attachment_service.dart';
import '../../core/chat/chat_bubble_style.dart';
import '../../core/chat/chat_composer.dart';
import '../../core/supabase/supabase_config.dart';
import '../calls/call_screen.dart';

/// Messagerie côté staff : liste de toutes les conversations clients,
/// triées par message le plus récent.
class MessagingCenterReal extends StatefulWidget {
  const MessagingCenterReal({super.key});

  @override
  State<MessagingCenterReal> createState() => _MessagingCenterRealState();
}

class _MessagingCenterRealState extends State<MessagingCenterReal> {
  List<Map<String, dynamic>> _conversations = [];
  Map<String, int> _unreadCounts = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
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
      final data = await SupabaseConfig.client
          .from('conversations')
          .select('*, profiles(full_name, company_name, client_type)')
          .order('last_message_at', ascending: false);

      // Badge de messages non lus par conversation (23/07) : un seul
      // aller-retour groupant tous les messages client non lus, plutôt
      // qu'une requête par conversation.
      Map<String, int> unread = {};
      try {
        final unreadMessages = await SupabaseConfig.client
            .from('messages')
            .select('conversation_id')
            .eq('sender_role', 'client')
            .eq('read_by_staff', false);
        for (final m in List<Map<String, dynamic>>.from(unreadMessages)) {
          final convId = m['conversation_id'] as String;
          unread[convId] = (unread[convId] ?? 0) + 1;
        }
      } catch (_) {
        // Repli silencieux : les badges restent à 0, la liste reste
        // utilisable.
      }

      setState(() {
        _conversations = List<Map<String, dynamic>>.from(data);
        _unreadCounts = unread;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les conversations.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Messagerie')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: _conversations.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                  child: Text(
                                      'Aucune conversation pour le moment.')),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: _conversations.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final c = _conversations[index];
                            final profile = c['profiles'];
                            final name = profile != null
                                ? (profile['company_name'] ??
                                    profile['full_name'] ??
                                    'Client')
                                : 'Client';
                            final unread = _unreadCounts[c['id']] ?? 0;
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  name.toString().isNotEmpty
                                      ? name.toString()[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(
                                name,
                                style: unread > 0
                                    ? const TextStyle(
                                        fontWeight: FontWeight.w700)
                                    : null,
                              ),
                              subtitle: Text(
                                'Dernier message : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(c['last_message_at']))}',
                              ),
                              trailing: unread > 0
                                  ? Badge(
                                      label: Text('$unread'),
                                    )
                                  : null,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _AdminConversationThread(
                                      conversationId: c['id'],
                                      customerName: name,
                                      customerId: c['customer_id'],
                                    ),
                                  ),
                                );
                                _loadConversations();
                              },
                            );
                          },
                        ),
                ),
    );
  }
}

class _AdminConversationThread extends ConsumerStatefulWidget {
  final String conversationId;
  final String customerName;
  final String customerId;

  const _AdminConversationThread({
    required this.conversationId,
    required this.customerName,
    required this.customerId,
  });

  @override
  ConsumerState<_AdminConversationThread> createState() =>
      _AdminConversationThreadState();
}

class _AdminConversationThreadState
    extends ConsumerState<_AdminConversationThread> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  String? get _myId =>
      SupabaseConfig.isConfigured ? SupabaseConfig.client.auth.currentUser?.id : null;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startCall(String callType) async {
    try {
      final invitation = await CallRepo.createInvitation(
        conversationId: widget.conversationId,
        calleeId: widget.customerId,
        callType: callType,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            channelName: invitation.channelName,
            callType: callType,
            peerName: widget.customerName,
            invitationId: invitation.id,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de démarrer l\'appel. Réessayez.'),
        ),
      );
    }
  }

  Future<void> _loadMessages() async {
    try {
      final data = await SupabaseConfig.client
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('created_at');
      setState(() {
        _messages = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController
              .jumpTo(_scrollController.position.maxScrollExtent);
        }
      });

      // Marque les messages du client comme lus à l'ouverture — sans quoi
      // le badge de la liste des conversations ne redescendrait jamais.
      try {
        await SupabaseConfig.client
            .from('messages')
            .update({'read_by_staff': true})
            .eq('conversation_id', widget.conversationId)
            .eq('sender_role', 'client')
            .eq('read_by_staff', false);
      } catch (_) {
        // Non bloquant.
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _myId == null) return;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _myId,
        'sender_role': 'staff',
        'content': text,
        'read_by_staff': true,
      });
      await _loadMessages();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendAttachment(File file, String type,
      {String? name, int? durationMs}) async {
    if (_myId == null) return;

    try {
      final upload = await ChatAttachmentService.upload(
        conversationId: widget.conversationId,
        file: file,
        type: type,
        name: name,
        durationMs: durationMs,
      );
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': _myId,
        'sender_role': 'staff',
        'attachment_url': upload.path,
        'attachment_type': upload.type,
        'attachment_name': upload.name,
        'attachment_duration_ms': upload.durationMs,
        'read_by_staff': true,
      });
      await _loadMessages();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Échec de l\'envoi de la pièce jointe.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleStyle = ref.watch(chatBubbleStyleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Appel audio',
            onPressed: () => _startCall('audio'),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Appel vidéo',
            onPressed: () => _startCall('video'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isMine = m['sender_id'] == _myId;
                      final isRequest = m['is_request'] == true;
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              vertical: bubbleStyle.bubbleSpacing / 2),
                          padding: bubbleStyle.bubblePadding,
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(bubbleStyle.borderRadius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isRequest)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: const Text('Demande'),
                                    labelStyle: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: isMine
                                          ? theme.colorScheme.primary
                                          : theme
                                              .colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    backgroundColor: isMine
                                        ? Colors.white
                                        : theme.colorScheme.surface,
                                    side: BorderSide.none,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              if (m['attachment_type'] != null)
                                ChatAttachmentBubble(
                                  path: m['attachment_url'],
                                  type: m['attachment_type'],
                                  name: m['attachment_name'],
                                  durationMs: m['attachment_duration_ms'],
                                  foregroundColor: isMine
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              if ((m['content'] as String?)?.isNotEmpty ==
                                  true)
                                Text(
                                  m['content'],
                                  style: TextStyle(
                                    fontSize: bubbleStyle.fontSize,
                                    color: isMine
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ChatComposer(
                      controller: _controller,
                      hintText: 'Répondre...',
                      onSendText: _isSending ? () {} : _sendMessage,
                      onSendAttachment: _sendAttachment,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
