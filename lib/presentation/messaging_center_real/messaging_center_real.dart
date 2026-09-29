import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/calls/call_repo.dart';
import '../../core/chat/chat_attachment_bubble.dart';
import '../../core/chat/chat_attachment_service.dart';
import '../../core/chat/chat_bubble_style.dart';
import '../../core/chat/chat_composer.dart';
import '../../core/chat/conversation_picker_screen.dart';
import '../../core/chat/message_actions_sheet.dart';
import '../../core/chat/message_reactions_bar.dart';
import '../../core/chat/pinned_message_banner.dart';
import '../../core/chat/presence_helper.dart';
import '../../core/chat/read_receipt.dart';
import '../../core/chat/reply_preview.dart';
import '../../core/chat/starred_messages_screen.dart';
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

  /// Filtres de la liste (29/09) : 'all' | 'unread' | 'attachment' |
  /// 'request' — voir `_buildFilterChips`.
  String _filter = 'all';
  Set<String> _attachmentConvIds = {};
  Set<String> _requestConvIds = {};

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

      // Filtres "Avec pièce jointe" / "Demandes" (29/09) : même principe
      // que les badges non lus, un aller-retour groupé par filtre plutôt
      // qu'une requête par conversation.
      Set<String> attachmentConvIds = {};
      try {
        final rows = await SupabaseConfig.client
            .from('messages')
            .select('conversation_id')
            .not('attachment_type', 'is', null);
        attachmentConvIds = List<Map<String, dynamic>>.from(rows)
            .map((r) => r['conversation_id'] as String)
            .toSet();
      } catch (_) {}

      Set<String> requestConvIds = {};
      try {
        final rows = await SupabaseConfig.client
            .from('messages')
            .select('conversation_id')
            .eq('is_request', true);
        requestConvIds = List<Map<String, dynamic>>.from(rows)
            .map((r) => r['conversation_id'] as String)
            .toSet();
      } catch (_) {}

      setState(() {
        _conversations = List<Map<String, dynamic>>.from(data);
        _unreadCounts = unread;
        _attachmentConvIds = attachmentConvIds;
        _requestConvIds = requestConvIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les conversations.';
      });
    }
  }

  Widget _buildFilterChips(ThemeData theme) {
    final options = const [
      ('all', 'Toutes'),
      ('unread', 'Non lues'),
      ('attachment', 'Pièce jointe'),
      ('request', 'Demandes'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option.$2),
                  selected: _filter == option.$1,
                  onSelected: (_) => setState(() => _filter = option.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _conversations.where((c) {
      final id = c['id'] as String;
      switch (_filter) {
        case 'unread':
          return (_unreadCounts[id] ?? 0) > 0;
        case 'attachment':
          return _attachmentConvIds.contains(id);
        case 'request':
          return _requestConvIds.contains(id);
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messagerie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border),
            tooltip: 'Messages enregistrés',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StarredMessagesScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    if (_conversations.isNotEmpty) _buildFilterChips(theme),
                    Expanded(
                      child: RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: filtered.isEmpty
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                  child: Text(
                                      _conversations.isEmpty
                                          ? 'Aucune conversation pour le moment.'
                                          : 'Aucune conversation ne correspond à ce filtre.')),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final c = filtered[index];
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
                    ),
                  ],
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

  /// Recherche dans l'historique (29/09) — filtrage local sur `content`.
  bool _searchMode = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  /// Clé par message (29/09), pour scroller jusqu'à un résultat de
  /// recherche ou jusqu'au message épinglé.
  final Map<String, GlobalKey> _messageKeys = {};

  /// Messages enregistrés par CE membre du staff (29/09). Voir
  /// `starred_messages` (phase251).
  Set<String> _starredIds = {};

  /// Réactions emoji (29/09), groupées par message — voir
  /// `message_reactions` (phase252). Pas de flux temps réel ici (cet
  /// écran n'en a pas non plus pour les messages) : rechargé après
  /// chaque action.
  Map<String, List<Map<String, dynamic>>> _reactionsByMessage = {};

  /// Message auquel ce membre du staff est en train de répondre (29/09).
  Map<String, dynamic>? _replyTarget;

  /// Messages supprimés "pour moi" uniquement (29/09), voir
  /// `message_hidden_for` (phase252).
  Set<String> _hiddenIds = {};

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
    _loadStarredIds();
    _loadReactions();
    _loadHiddenIds();
    _presenceTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      PresenceHelper.touch();
      _refreshCustomerPresence();
    });
  }

  Future<void> _loadReactions() async {
    try {
      final rows = await SupabaseConfig.client
          .from('message_reactions')
          .select()
          .eq('conversation_id', widget.conversationId);
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final r in List<Map<String, dynamic>>.from(rows)) {
        final mid = r['message_id'] as String;
        grouped.putIfAbsent(mid, () => []).add(r);
      }
      if (mounted) setState(() => _reactionsByMessage = grouped);
    } catch (_) {}
  }

  Future<void> _loadHiddenIds() async {
    final myId = _myId;
    if (myId == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('message_hidden_for')
          .select('message_id')
          .eq('user_id', myId);
      if (mounted) {
        setState(() {
          _hiddenIds = List<Map<String, dynamic>>.from(rows)
              .map((r) => r['message_id'] as String)
              .toSet();
        });
      }
    } catch (_) {}
  }

  String? _myReactionFor(String messageId) {
    final myId = _myId;
    final list = _reactionsByMessage[messageId];
    if (list == null || myId == null) return null;
    for (final r in list) {
      if (r['user_id'] == myId) return r['emoji'] as String?;
    }
    return null;
  }

  Future<void> _toggleReaction(Map<String, dynamic> message, String emoji) async {
    final myId = _myId;
    if (myId == null) return;
    final messageId = message['id'] as String;
    final current = _myReactionFor(messageId);
    try {
      if (current == emoji) {
        await SupabaseConfig.client
            .from('message_reactions')
            .delete()
            .eq('message_id', messageId)
            .eq('user_id', myId);
      } else {
        await SupabaseConfig.client.from('message_reactions').upsert({
          'message_id': messageId,
          'conversation_id': widget.conversationId,
          'user_id': myId,
          'emoji': emoji,
        }, onConflict: 'message_id,user_id');
      }
      await _loadReactions();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible. Réessayez.')),
      );
    }
  }

  void _setReplyTarget(Map<String, dynamic> message) {
    setState(() => _replyTarget = message);
  }

  void _cancelReply() {
    setState(() => _replyTarget = null);
  }

  void _copyMessageText(Map<String, dynamic> message) {
    final text = message['content'] as String?;
    if (text == null || text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Texte copié.')),
    );
  }

  Future<void> _editMessage(Map<String, dynamic> message) async {
    final controller =
        TextEditingController(text: message['content'] as String? ?? '');
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (newText == null || newText.isEmpty || newText == message['content']) {
      return;
    }
    try {
      await SupabaseConfig.client.from('messages').update({
        'content': newText,
        'edited_at': DateTime.now().toIso8601String(),
      }).eq('id', message['id']);
      await _loadMessages();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible. Réessayez.')),
      );
    }
  }

  Future<void> _deleteForMe(Map<String, dynamic> message) async {
    final myId = _myId;
    if (myId == null) return;
    final messageId = message['id'] as String;
    try {
      await SupabaseConfig.client.from('message_hidden_for').insert({
        'user_id': myId,
        'message_id': messageId,
      });
      if (mounted) setState(() => _hiddenIds.add(messageId));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible. Réessayez.')),
      );
    }
  }

  Future<void> _deleteForEveryone(Map<String, dynamic> message) async {
    try {
      await SupabaseConfig.client.from('messages').update({
        'content': null,
        'attachment_url': null,
        'attachment_type': null,
        'attachment_name': null,
        'attachment_duration_ms': null,
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', message['id']);
      await _loadMessages();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible. Réessayez.')),
      );
    }
  }

  Future<void> _forwardMessage(Map<String, dynamic> message) async {
    final myId = _myId;
    if (myId == null) return;
    final targetConversationId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationPickerScreen(
          excludeConversationId: widget.conversationId,
        ),
      ),
    );
    if (targetConversationId == null || !mounted) return;
    try {
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': targetConversationId,
        'sender_id': myId,
        'sender_role': 'staff',
        'content': message['content'],
        'attachment_url': message['attachment_url'],
        'attachment_type': message['attachment_type'],
        'attachment_name': message['attachment_name'],
        'attachment_duration_ms': message['attachment_duration_ms'],
        'forwarded': true,
        'read_by_staff': true,
      });
      await SupabaseConfig.client
          .from('conversations')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', targetConversationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message transféré.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du transfert. Réessayez.')),
      );
    }
  }

  Map<String, dynamic>? _findMessageById(
      List<Map<String, dynamic>> messages, String? id) {
    if (id == null) return null;
    for (final m in messages) {
      if (m['id'] == id) return m;
    }
    return null;
  }

  Future<void> _loadStarredIds() async {
    final myId = _myId;
    if (myId == null) return;
    try {
      final rows = await SupabaseConfig.client
          .from('starred_messages')
          .select('message_id')
          .eq('user_id', myId)
          .eq('conversation_id', widget.conversationId);
      if (mounted) {
        setState(() {
          _starredIds = List<Map<String, dynamic>>.from(rows)
              .map((r) => r['message_id'] as String)
              .toSet();
        });
      }
    } catch (_) {}
  }

  /// Épingle/désépingle un message (29/09) — un seul message épinglé à la
  /// fois par conversation.
  Future<void> _togglePin(Map<String, dynamic> message) async {
    final isPinned = message['pinned'] == true;
    try {
      if (!isPinned) {
        await SupabaseConfig.client
            .from('messages')
            .update({'pinned': false, 'pinned_at': null})
            .eq('conversation_id', widget.conversationId)
            .eq('pinned', true);
      }
      await SupabaseConfig.client.from('messages').update({
        'pinned': !isPinned,
        'pinned_at': isPinned ? null : DateTime.now().toIso8601String(),
      }).eq('id', message['id']);
      await _loadMessages();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible. Réessayez.')),
      );
    }
  }

  Future<void> _toggleStar(Map<String, dynamic> message) async {
    final myId = _myId;
    if (myId == null) return;
    final messageId = message['id'] as String;
    final isStarred = _starredIds.contains(messageId);
    try {
      if (isStarred) {
        await SupabaseConfig.client
            .from('starred_messages')
            .delete()
            .eq('user_id', myId)
            .eq('message_id', messageId);
        if (mounted) setState(() => _starredIds.remove(messageId));
      } else {
        await SupabaseConfig.client.from('starred_messages').insert({
          'user_id': myId,
          'message_id': messageId,
          'conversation_id': widget.conversationId,
        });
        if (mounted) setState(() => _starredIds.add(messageId));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible. Réessayez.')),
      );
    }
  }

  void _scrollToMessage(String messageId) {
    final ctx = _messageKeys[messageId]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.5,
      );
    }
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
    _searchController.dispose();
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
        'reply_to_message_id': _replyTarget?['id'],
        'read_by_staff': true,
      });
      if (mounted) setState(() => _replyTarget = null);
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
        'reply_to_message_id': _replyTarget?['id'],
        'read_by_staff': true,
      });
      if (mounted) setState(() => _replyTarget = null);
      await _loadMessages();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Échec de l\'envoi de la pièce jointe.')),
      );
    }
  }

  Widget _buildSearchResults(
      ThemeData theme, List<Map<String, dynamic>> results) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      color: theme.colorScheme.surfaceContainerHighest,
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _searchQuery.isEmpty
                    ? 'Tapez pour rechercher dans cette conversation.'
                    : 'Aucun résultat.',
                style: theme.textTheme.bodySmall,
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final m = results[index];
                final createdAt = m['created_at'] != null
                    ? DateTime.tryParse(m['created_at'])
                    : null;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.search, size: 18),
                  title: Text(
                    m['content'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: createdAt != null
                      ? Text(_dateFormat.format(createdAt.toLocal()))
                      : null,
                  onTap: () {
                    final messageId = m['id'] as String;
                    setState(() {
                      _searchMode = false;
                      _searchController.clear();
                      _searchQuery = '';
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToMessage(messageId);
                    });
                  },
                );
              },
            ),
    );
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
        bottom: _searchMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Rechercher dans la conversation...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(_searchMode ? Icons.close : Icons.search),
            tooltip: _searchMode ? 'Fermer la recherche' : 'Rechercher',
            onPressed: () {
              setState(() {
                _searchMode = !_searchMode;
                if (!_searchMode) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.star_border),
            tooltip: 'Messages enregistrés',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StarredMessagesScreen(),
              ),
            ),
          ),
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
          : Builder(builder: (context) {
              final visibleMessages = _messages
                  .where((m) => !_hiddenIds.contains(m['id']))
                  .toList();
              Map<String, dynamic>? pinnedMessage;
              for (final m in visibleMessages) {
                if (m['pinned'] == true) {
                  pinnedMessage = m;
                  break;
                }
              }
              final searchResults = _searchQuery.isEmpty
                  ? <Map<String, dynamic>>[]
                  : visibleMessages
                      .where((m) => (m['content'] as String? ?? '')
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
              return Column(
              children: [
                if (pinnedMessage != null)
                  PinnedMessageBanner(
                    content: pinnedMessage['content'] as String? ?? '',
                    onTap: () =>
                        _scrollToMessage(pinnedMessage!['id'] as String),
                    onUnpin: () => _togglePin(pinnedMessage!),
                  ),
                if (_searchMode) _buildSearchResults(theme, searchResults),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: visibleMessages.length,
                    itemBuilder: (context, index) {
                      final m = visibleMessages[index];
                      final isMine = m['sender_id'] == _myId;
                      final isAi = m['sender_role'] == 'ai';
                      final isRequest = m['is_request'] == true;
                      final isDeleted = m['deleted_at'] != null;
                      final messageId = m['id'] as String;
                      final messageKey = _messageKeys.putIfAbsent(
                          messageId, () => GlobalKey());
                      final replyTo = _findMessageById(
                          _messages, m['reply_to_message_id'] as String?);
                      return Align(
                        key: messageKey,
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () => showMessageActionsSheet(
                            context,
                            isPinned: m['pinned'] == true,
                            isStarred: _starredIds.contains(messageId),
                            myReaction: _myReactionFor(messageId),
                            onReact: (emoji) => _toggleReaction(m, emoji),
                            onTogglePin: () => _togglePin(m),
                            onToggleStar: () => _toggleStar(m),
                            onReply: () => _setReplyTarget(m),
                            onCopy: () => _copyMessageText(m),
                            onDeleteForMe: () => _deleteForMe(m),
                            onForward: !isDeleted
                                ? () => _forwardMessage(m)
                                : null,
                            onEdit: (isMine &&
                                    !isDeleted &&
                                    (m['content'] as String?)?.isNotEmpty ==
                                        true)
                                ? () => _editMessage(m)
                                : null,
                            onDeleteForEveryone: (isMine && !isDeleted)
                                ? () => _deleteForEveryone(m)
                                : null,
                          ),
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
                              if (replyTo != null)
                                QuotedMessagePreview(
                                  senderLabel: replyTo['sender_role'] ==
                                          'client'
                                      ? widget.customerName
                                      : (replyTo['sender_role'] == 'ai'
                                          ? 'Akora AI'
                                          : 'Équipe'),
                                  snippet: (replyTo['content'] as String?)
                                              ?.isNotEmpty ==
                                          true
                                      ? replyTo['content'] as String
                                      : 'Pièce jointe',
                                  foregroundColor: isMine
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  onTap: () => _scrollToMessage(
                                      replyTo['id'] as String),
                                ),
                              if (m['forwarded'] == true)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Transféré',
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: (isMine
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface)
                                          .withValues(alpha: 0.65),
                                    ),
                                  ),
                                ),
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
                              if (!isDeleted && m['attachment_type'] != null)
                                ChatAttachmentBubble(
                                  path: m['attachment_url'],
                                  type: m['attachment_type'],
                                  name: m['attachment_name'],
                                  durationMs: m['attachment_duration_ms'],
                                  foregroundColor: isMine
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              if (isDeleted)
                                Text(
                                  'Message supprimé',
                                  style: TextStyle(
                                    fontSize: bubbleStyle.fontSize,
                                    fontStyle: FontStyle.italic,
                                    color: (isMine
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface)
                                        .withValues(alpha: 0.65),
                                  ),
                                )
                              else if ((m['content'] as String?)
                                      ?.isNotEmpty ==
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
                              if (!isDeleted)
                                MessageReactionsBar(
                                  reactions:
                                      _reactionsByMessage[messageId] ??
                                          const [],
                                  myUserId: _myId,
                                  onTapEmoji: (emoji) =>
                                      _toggleReaction(m, emoji),
                                ),
                              if (m['created_at'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        m['edited_at'] != null && !isDeleted
                                            ? '${_dateFormat.format(DateTime.parse(m['created_at']).toLocal())} · modifié'
                                            : _dateFormat.format(
                                                DateTime.parse(
                                                        m['created_at'])
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
                                  index == visibleMessages.length - 1 &&
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
                      topBar: _replyTarget != null
                          ? ReplyPreviewBar(
                              senderLabel:
                                  _replyTarget!['sender_role'] == 'client'
                                      ? widget.customerName
                                      : (_replyTarget!['sender_role'] ==
                                              'ai'
                                          ? 'Akora AI'
                                          : 'Équipe'),
                              snippet: (_replyTarget!['content']
                                              as String?)
                                          ?.isNotEmpty ==
                                      true
                                  ? _replyTarget!['content'] as String
                                  : 'Pièce jointe',
                              onCancel: _cancelReply,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            );
            }),
    );
  }
}
