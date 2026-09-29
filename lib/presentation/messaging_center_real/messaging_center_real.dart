import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/calls/call_repo.dart';
import '../../core/chat/chat_attachment_bubble.dart';
import '../../core/chat/chat_attachment_service.dart';
import '../../core/chat/chat_bubble_style.dart';
import '../../core/chat/chat_composer.dart';
import '../../core/chat/presence_helper.dart';
import '../../core/chat/read_receipt.dart';
import '../../core/chat/typing_dots.dart';
import '../../core/chat/typing_presence.dart';
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
                                    builder: (_) => AdminConversationThread(
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

/// Fil de conversation admin ↔ client — extrait de la liste "Messagerie"
/// (nom public) pour être réutilisable depuis la fiche client 360°
/// (`customer_360_screen.dart`), qui permet de démarrer/reprendre une
/// conversation directement depuis le profil du client.
class AdminConversationThread extends ConsumerStatefulWidget {
  final String conversationId;
  final String customerName;
  final String customerId;

  const AdminConversationThread({
    super.key,
    required this.conversationId,
    required this.customerName,
    required this.customerId,
  });

  @override
  ConsumerState<AdminConversationThread> createState() =>
      _AdminConversationThreadState();
}

class _AdminConversationThreadState
    extends ConsumerState<AdminConversationThread> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _dateFormat = DateFormat('HH:mm');
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  /// "En train d'écrire" + présence (29/09) — même topic que côté client
  /// (`chat_screen.dart`), dérivé de l'id de conversation, pour qu'ils se
  /// voient mutuellement.
  TypingPresence? _typing;
  bool _remoteIsTyping = false;
  Timer? _presenceTimer;
  String? _customerLastSeenAt;

  String? get _myId =>
      SupabaseConfig.isConfigured ? SupabaseConfig.client.auth.currentUser?.id : null;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    final myId = _myId;
    if (myId != null) {
      _typing = TypingPresence(
        topic: 'conversation:${widget.conversationId}',
        selfId: myId,
        onRemoteTypingChanged: (isTyping) {
          if (mounted) setState(() => _remoteIsTyping = isTyping);
        },
      );
    }
    _controller.addListener(() {
      if (_controller.text.trim().isNotEmpty) _typing?.notifyTyping();
    });
    PresenceHelper.touch();
    _refreshCustomerPresence();
    _presenceTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      PresenceHelper.touch();
      _refreshCustomerPresence();
    });
  }

  Future<void> _refreshCustomerPresence() async {
    try {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select('last_seen_at')
          .eq('id', widget.customerId)
          .maybeSingle();
      if (mounted) {
        setState(() => _customerLastSeenAt = row?['last_seen_at'] as String?);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _typing?.dispose();
    _presenceTimer?.cancel();
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
            .update({
              'read_by_staff': true,
              'read_by_staff_at': DateTime.now().toIso8601String(),
            })
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customerName),
            if (PresenceHelper.label(_customerLastSeenAt).isNotEmpty)
              Text(
                PresenceHelper.label(_customerLastSeenAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: PresenceHelper.isOnline(_customerLastSeenAt)
                      ? Colors.lightGreenAccent.shade400
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
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
                      final isAi = m['sender_role'] == 'ai';
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
                              if (isAi)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipOval(
                                        child: Image.asset(
                                          'assets/images/akora_ai_logo.png',
                                          width: 12,
                                          height: 12,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Akora AI',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                              if (m['created_at'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _dateFormat.format(
                                            DateTime.parse(m['created_at'])
                                                .toLocal()),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: (isMine
                                                  ? theme.colorScheme
                                                      .onPrimary
                                                  : theme.colorScheme
                                                      .onSurfaceVariant)
                                              .withValues(alpha: 0.75),
                                        ),
                                      ),
                                      // Coches ✓/✓✓ : uniquement sur les
                                      // messages envoyés PAR ce membre du
                                      // staff (isMine), jamais sur ceux
                                      // reçus du client/IA.
                                      if (isMine) ...[
                                        const SizedBox(width: 4),
                                        ReadReceiptTicks(
                                          isRead:
                                              m['read_by_client'] == true,
                                          color: theme.colorScheme.onPrimary
                                              .withValues(alpha: 0.75),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              if (isMine &&
                                  index == _messages.length - 1 &&
                                  m['read_by_client'] == true &&
                                  m['read_by_client_at'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Vu à ${_dateFormat.format(DateTime.parse(m['read_by_client_at']).toLocal())}',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      fontSize: 10,
                                      color: theme.colorScheme.onPrimary
                                          .withValues(alpha: 0.65),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_remoteIsTyping)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:
                            TypingDots(color: theme.colorScheme.onSurface),
                      ),
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
