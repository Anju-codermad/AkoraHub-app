import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/calls/call_repo.dart';
import '../../core/chat/chat_attachment_bubble.dart';
import '../../core/chat/chat_attachment_service.dart';
import '../../core/chat/chat_bubble_style.dart';
import '../../core/chat/chat_composer.dart';
import '../../core/chat/message_actions_sheet.dart';
import '../../core/chat/pinned_message_banner.dart';
import '../../core/chat/presence_helper.dart';
import '../../core/chat/read_receipt.dart';
import '../../core/chat/starred_messages_screen.dart';
import '../../core/chat/typing_dots.dart';
import '../../core/chat/typing_presence.dart';
import '../../core/supabase/supabase_config.dart';
import '../calls/call_screen.dart';

/// Messagerie privée client ↔ équipe commerciale — une conversation par
/// client. Une "Demande" (ex "Demandes & annonces") est un message envoyé
/// avec is_request=true : jamais visible par les autres clients,
/// uniquement par le staff (contrairement à un post du Mur).
///
/// Schéma : `supabase/phase8_patch_messaging.sql`. Compte tenu de son
/// périmètre, l'écran Admin correspondant (déjà présent mais 100% mock,
/// `lib/presentation/messaging_center/`) reste à brancher côté
/// Backend/Infra sur ce même schéma.
class ChatScreen extends ConsumerStatefulWidget {
  /// Pré-remplit le champ de saisie (ex : référence de commande depuis
  /// `OrderDetailScreen`) — le client garde la main pour l'éditer avant
  /// envoi, rien n'est envoyé automatiquement.
  final String? initialMessage;

  const ChatScreen({super.key, this.initialMessage});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String? _conversationId;
  bool _isLoading = true;
  String? _error;
  bool _isRequestMode = false;
  final _textController = TextEditingController();
  final _dateFormat = DateFormat('HH:mm');
  Stream<List<Map<String, dynamic>>>? _messagesStream;

  /// 'ia' (Akora AI répond automatiquement), 'humain_demande' (le client a
  /// demandé un humain, en attente) ou 'humain_actif' (le staff a repris la
  /// main) — voir supabase/phase176_patch_ai_assistant.sql. Suivi en direct
  /// via un flux Realtime dédié (indépendant de `_messagesStream`) pour que
  /// la bannière change sans que le client ait à rouvrir l'écran.
  String _mode = 'ia';
  Stream<List<Map<String, dynamic>>>? _conversationStream;
  StreamSubscription<List<Map<String, dynamic>>>? _conversationSub;
  bool _togglingMode = false;

  final _scrollController = ScrollController();
  int _lastMessageCount = 0;
  bool _showJumpToLatest = false;

  /// Indicateur "en train d'écrire" (05/08) — topic dérivé de l'id de
  /// conversation (stable, partagé avec le futur écran Admin une fois
  /// branché sur ce même schéma). Créé une fois `_conversationId` connu,
  /// voir `_init()`.
  TypingPresence? _typing;
  bool _remoteIsTyping = false;

  /// Présence "En ligne" / "Vu(e) pour la dernière fois" (29/09) —
  /// approxime la présence de "l'équipe" au sens large (pas un membre du
  /// staff précis, une conversation n'en a pas un seul assigné) via le
  /// membre du staff le plus récemment actif. Voir presence_helper.dart.
  Timer? _presenceTimer;
  String? _staffLastSeenAt;

  /// Recherche dans l'historique (29/09) — filtrage local sur `content`,
  /// aucun appel réseau supplémentaire.
  bool _searchMode = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  /// Clé par message (29/09) — permet de scroller jusqu'à un message
  /// précis (résultat de recherche, ou message épinglé) via
  /// `Scrollable.ensureVisible`, seule façon fiable de cibler un item
  /// dans une `ListView` à hauteurs variables sans extents connus.
  final Map<String, GlobalKey> _messageKeys = {};

  /// Messages enregistrés par CE client (29/09) — ids seulement, pour
  /// savoir quelle icône afficher dans le menu d'actions. Voir
  /// `starred_messages` (phase251).
  Set<String> _starredIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _textController.text = widget.initialMessage!;
    }
    _init();
    // Liste inversée (reverse: true) : offset 0 = tout en bas. Si le
    // client remonte dans l'historique, on masque la pastille "Nouveau
    // message" dès qu'il revient naturellement près du bas.
    _scrollController.addListener(() {
      if (_showJumpToLatest &&
          _scrollController.hasClients &&
          _scrollController.position.pixels <= 80) {
        setState(() => _showJumpToLatest = false);
      }
    });
    _textController.addListener(() {
      if (_textController.text.trim().isNotEmpty) _typing?.notifyTyping();
    });
  }

  @override
  void dispose() {
    _typing?.dispose();
    _presenceTimer?.cancel();
    _conversationSub?.cancel();
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Appelé à chaque nouvelle liste reçue du flux temps réel. Si le client
  /// est déjà en bas (ou vient d'ouvrir la conversation), on le fait
  /// défiler automatiquement vers le nouveau message. S'il est remonté
  /// dans l'historique, on affiche une petite pastille "Nouveau message"
  /// plutôt que de le faire défiler de force.
  void _handleIncomingMessages(int count) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (count > _lastMessageCount) {
        final atBottom = !_scrollController.hasClients ||
            _scrollController.position.pixels <= 80;
        if (atBottom) {
          _scrollToLatest();
        } else if (_lastMessageCount != 0) {
          setState(() => _showJumpToLatest = true);
        }
      }
      _lastMessageCount = count;
    });
  }

  Future<void> _init() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion indisponible.';
      });
      return;
    }
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Vous devez être connecté.';
      });
      return;
    }
    try {
      final existing = await SupabaseConfig.client
          .from('conversations')
          .select('id, mode')
          .eq('customer_id', userId)
          .maybeSingle();

      String conversationId;
      String initialMode;
      if (existing != null) {
        conversationId = existing['id'] as String;
        initialMode = (existing['mode'] as String?) ?? 'ia';
      } else {
        final created = await SupabaseConfig.client
            .from('conversations')
            .insert({'customer_id': userId})
            .select()
            .single();
        conversationId = created['id'] as String;
        initialMode = (created['mode'] as String?) ?? 'ia';
      }

      setState(() {
        _conversationId = conversationId;
        _mode = initialMode;
        _messagesStream = SupabaseConfig.client
            .from('messages')
            .stream(primaryKey: ['id'])
            .eq('conversation_id', conversationId)
            .order('created_at');
        _conversationStream = SupabaseConfig.client
            .from('conversations')
            .stream(primaryKey: ['id']).eq('id', conversationId);
        _isLoading = false;
      });
      _conversationSub = _conversationStream!.listen((rows) {
        if (!mounted || rows.isEmpty) return;
        final mode = rows.first['mode'] as String? ?? 'ia';
        if (mode != _mode) setState(() => _mode = mode);
      });
      _typing = TypingPresence(
        topic: 'conversation:$conversationId',
        selfId: userId,
        onRemoteTypingChanged: (isTyping) {
          if (mounted) setState(() => _remoteIsTyping = isTyping);
        },
      );

      await _markIncomingAsRead(conversationId);
      await _loadStarredIds(conversationId);

      // Présence (29/09) : signale que le client est actif maintenant,
      // répété toutes les 25s tant que l'écran reste ouvert, et récupère
      // en parallèle la dernière activité connue côté staff.
      PresenceHelper.touch();
      _refreshStaffPresence();
      _presenceTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        PresenceHelper.touch();
        _refreshStaffPresence();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Messagerie indisponible pour le moment. Réessayez plus tard.';
      });
    }
  }

  /// Marque comme lus les messages du staff/IA pas encore lus — appelé à
  /// l'ouverture de l'écran ET à chaque nouveau message reçu tant que
  /// l'écran reste ouvert (sinon les coches ✓✓ resteraient bloquées à
  /// "envoyé" côté staff pendant toute la durée de la conversation).
  Future<void> _markIncomingAsRead(String conversationId) async {
    try {
      await SupabaseConfig.client
          .from('messages')
          .update({
            'read_by_client': true,
            'read_by_client_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .inFilter('sender_role', ['staff', 'ai'])
          .eq('read_by_client', false);
    } catch (_) {
      // Non bloquant : la conversation reste utilisable même si le
      // marquage échoue.
    }
  }

  Future<void> _loadStarredIds(String conversationId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;
      final rows = await SupabaseConfig.client
          .from('starred_messages')
          .select('message_id')
          .eq('user_id', userId)
          .eq('conversation_id', conversationId);
      if (mounted) {
        setState(() {
          _starredIds = List<Map<String, dynamic>>.from(rows)
              .map((r) => r['message_id'] as String)
              .toSet();
        });
      }
    } catch (_) {}
  }

  /// Épingle/désépingle un message (29/09) — un seul message épinglé à
  /// la fois par conversation : on désépingle d'abord l'éventuel autre
  /// message épinglé avant d'épingler le nouveau.
  Future<void> _togglePin(Map<String, dynamic> message) async {
    if (_conversationId == null) return;
    final isPinned = message['pinned'] == true;
    try {
      if (!isPinned) {
        await SupabaseConfig.client
            .from('messages')
            .update({'pinned': false, 'pinned_at': null})
            .eq('conversation_id', _conversationId as Object)
            .eq('pinned', true);
      }
      await SupabaseConfig.client.from('messages').update({
        'pinned': !isPinned,
        'pinned_at': isPinned ? null : DateTime.now().toIso8601String(),
      }).eq('id', message['id']);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible. Réessayez.')),
      );
    }
  }

  Future<void> _toggleStar(Map<String, dynamic> message) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || _conversationId == null) return;
    final messageId = message['id'] as String;
    final isStarred = _starredIds.contains(messageId);
    try {
      if (isStarred) {
        await SupabaseConfig.client
            .from('starred_messages')
            .delete()
            .eq('user_id', userId)
            .eq('message_id', messageId);
        if (mounted) setState(() => _starredIds.remove(messageId));
      } else {
        await SupabaseConfig.client.from('starred_messages').insert({
          'user_id': userId,
          'message_id': messageId,
          'conversation_id': _conversationId,
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

  Future<void> _refreshStaffPresence() async {
    try {
      final row = await SupabaseConfig.client
          .from('public_profiles')
          .select('last_seen_at')
          .eq('is_staff', true)
          .not('last_seen_at', 'is', null)
          .order('last_seen_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (mounted) {
        setState(() => _staffLastSeenAt = row?['last_seen_at'] as String?);
      }
    } catch (_) {}
  }

  /// Une conversation n'a pas de membre du staff assigné (voir
  /// `conversations`, phase8) — appelle en priorité le dernier membre du
  /// staff ayant répondu ici, sinon n'importe quel Admin/Commercial.
  Future<String?> _resolveCalleeStaffId() async {
    if (_conversationId == null) return null;
    final lastStaffMessage = await SupabaseConfig.client
        .from('messages')
        .select('sender_id')
        .eq('conversation_id', _conversationId!)
        .eq('sender_role', 'staff')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (lastStaffMessage != null) {
      return lastStaffMessage['sender_id'] as String;
    }
    // La RLS de `profiles` ne laisse un client voir que sa propre ligne
    // (phase1_schema.sql) — on passe par la vue publique légère
    // `public_profiles` (phase9, étendue en phase162 pour exposer
    // `role`), sinon cette recherche ne trouve jamais personne.
    final anyStaff = await SupabaseConfig.client
        .from('public_profiles')
        .select('id')
        .inFilter('role', ['admin', 'commercial'])
        .limit(1)
        .maybeSingle();
    return anyStaff?['id'] as String?;
  }

  Future<void> _startCall(String callType) async {
    if (_conversationId == null) return;
    try {
      final calleeId = await _resolveCalleeStaffId();
      if (calleeId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aucun membre de l\'équipe disponible.')),
        );
        return;
      }
      final invitation = await CallRepo.createInvitation(
        conversationId: _conversationId!,
        calleeId: calleeId,
        callType: callType,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            channelName: invitation.channelName,
            callType: callType,
            peerName: 'AkoraHub',
            invitationId: invitation.id,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de démarrer l\'appel. Réessayez.')),
      );
    }
  }

  /// Choix client IA <-> humain (voir supabase/phase176_patch_ai_assistant.sql).
  /// Demander un humain notifie le staff par WhatsApp côté backend (webhook
  /// Database Webhook sur `conversations` UPDATE, akora-fb-assistant).
  /// Revenir à l'IA est toujours possible, y compris pendant que le staff
  /// est déjà intervenu (mode 'humain_actif').
  Future<void> _toggleHumanMode() async {
    if (_conversationId == null || _togglingMode) return;
    final requestingHuman = _mode == 'ia';
    final nextMode = requestingHuman ? 'humain_demande' : 'ia';
    setState(() => _togglingMode = true);
    try {
      await SupabaseConfig.client
          .from('conversations')
          .update({'mode': nextMode}).eq('id', _conversationId as Object);
      if (requestingHuman) {
        await SupabaseConfig.client.from('messages').insert({
          'conversation_id': _conversationId,
          'sender_id': null,
          'sender_role': 'ai',
          'content':
              'Un membre de notre équipe va vous répondre sous peu 🙏',
          'read_by_client': true,
          'read_by_staff': true,
        });
      }
      if (mounted) setState(() => _mode = nextMode);
    } catch (e) {
      debugPrint('Échec changement de mode chat : $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible. Réessayez.')),
      );
    } finally {
      if (mounted) setState(() => _togglingMode = false);
    }
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _conversationId == null) return;
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    final wasRequest = _isRequestMode;
    setState(() => _isRequestMode = false);

    try {
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': _conversationId,
        'sender_id': userId,
        'sender_role': 'client',
        'content': text,
        'is_request': wasRequest,
        'read_by_client': true,
        'read_by_staff': false,
      });
      await SupabaseConfig.client
          .from('conversations')
          .update({'last_message_at': DateTime.now().toIso8601String()}).eq(
              'id', _conversationId as Object);
      // On ne vide le champ qu'une fois l'envoi confirmé — sinon, en cas
      // d'échec, le client perdait son message tapé et devait tout
      // retaper à chaque tentative.
      if (mounted) _textController.clear();
    } catch (e) {
      // Log technique pour diagnostiquer une éventuelle récidive (RLS,
      // migration manquante...) — jamais montré au client.
      debugPrint('Échec envoi message chat : $e');
      if (!mounted) return;
      setState(() => _isRequestMode = wasRequest);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Message non envoyé — vérifie ta connexion et réessaie.'),
          action: SnackBarAction(
            label: 'Réessayer',
            onPressed: _send,
          ),
        ),
      );
    }
  }

  Future<void> _sendAttachment(File file, String type,
      {String? name, int? durationMs}) async {
    if (_conversationId == null) return;
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final upload = await ChatAttachmentService.upload(
        conversationId: _conversationId!,
        file: file,
        type: type,
        name: name,
        durationMs: durationMs,
      );
      await SupabaseConfig.client.from('messages').insert({
        'conversation_id': _conversationId,
        'sender_id': userId,
        'sender_role': 'client',
        'attachment_url': upload.path,
        'attachment_type': upload.type,
        'attachment_name': upload.name,
        'attachment_duration_ms': upload.durationMs,
        'read_by_client': true,
        'read_by_staff': false,
      });
      await SupabaseConfig.client
          .from('conversations')
          .update({'last_message_at': DateTime.now().toIso8601String()}).eq(
              'id', _conversationId as Object);
    } catch (e) {
      debugPrint('Échec envoi pièce jointe chat : $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Échec de l\'envoi de la pièce jointe.')),
      );
    }
  }

  Widget _buildModeBanner(ThemeData theme) {
    final isPending = _mode == 'humain_demande';
    final color = isPending ? theme.colorScheme.tertiary : theme.colorScheme.primary;
    return Material(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              isPending ? Icons.hourglass_top : Icons.support_agent,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isPending
                    ? 'Un membre de l\'équipe va vous répondre.'
                    : 'Vous discutez avec un membre de l\'équipe.',
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
            TextButton(
              onPressed: _togglingMode ? null : _toggleHumanMode,
              child: const Text('Assistant IA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(
      ThemeData theme, List<Map<String, dynamic>> results) {
    return Container(
      constraints: BoxConstraints(maxHeight: 30.h),
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
            const Text('Messagerie'),
            if (PresenceHelper.label(_staffLastSeenAt).isNotEmpty)
              Text(
                PresenceHelper.label(_staffLastSeenAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: PresenceHelper.isOnline(_staffLastSeenAt)
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
            icon: _mode == 'ia'
                ? const Icon(Icons.support_agent_outlined)
                : ClipOval(
                    child: Image.asset(
                      'assets/images/akora_ai_logo.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
            tooltip: _mode == 'ia'
                ? 'Parler à une vraie personne'
                : 'Revenir à l\'assistant IA',
            onPressed: _togglingMode ? null : _toggleHumanMode,
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
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : Column(
                  children: [
                    if (_mode != 'ia') _buildModeBanner(theme),
                    Expanded(
                      child: Stack(
                        children: [
                          StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _messagesStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final messages = snapshot.data!;
                          _handleIncomingMessages(messages.length);
                          if (_conversationId != null) {
                            _markIncomingAsRead(_conversationId!);
                          }
                          Map<String, dynamic>? pinnedMessage;
                          for (final m in messages) {
                            if (m['pinned'] == true) {
                              pinnedMessage = m;
                              break;
                            }
                          }
                          final searchResults = _searchQuery.isEmpty
                              ? <Map<String, dynamic>>[]
                              : messages
                                  .where((m) =>
                                      (m['content'] as String? ?? '')
                                          .toLowerCase()
                                          .contains(_searchQuery.toLowerCase()))
                                  .toList();
                          Widget messageArea;
                          if (messages.isEmpty) {
                            messageArea = Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Text(
                                  'Écrivez à notre équipe pour toute '
                                  'question, ou faites une demande '
                                  '(ex: besoin d\'un produit en gros '
                                  'volume) — visible uniquement par '
                                  'nous, jamais par les autres clients.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            );
                          } else {
                          messageArea = ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: EdgeInsets.all(4.w),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              // reverse: true ancre la liste en bas de
                              // l'écran (comme WhatsApp/Messenger) au lieu
                              // de laisser les messages "flotter" en haut
                              // avec un grand vide en dessous quand il y en
                              // a peu — index 0 = message le plus récent.
                              final msgIndex = messages.length - 1 - index;
                              final m = messages[msgIndex];
                              final isClient = m['sender_role'] == 'client';
                              final isAi = m['sender_role'] == 'ai';
                              final isRequest = m['is_request'] == true;
                              final createdAt =
                                  DateTime.tryParse(m['created_at'] ?? '');

                              // N'affiche l'horodatage que sur la dernière
                              // bulle d'une série consécutive du même
                              // expéditeur — évite de répéter l'heure sur
                              // chaque message envoyé coup sur coup.
                              final nextMsg = msgIndex + 1 < messages.length
                                  ? messages[msgIndex + 1]
                                  : null;
                              final isLastOfGroup = nextMsg == null ||
                                  nextMsg['sender_role'] != m['sender_role'];
                              final messageId = m['id'] as String;
                              final messageKey = _messageKeys.putIfAbsent(
                                  messageId, () => GlobalKey());

                              return Align(
                                key: messageKey,
                                alignment: isClient
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: GestureDetector(
                                  onLongPress: () => showMessageActionsSheet(
                                    context,
                                    isPinned: m['pinned'] == true,
                                    isStarred: _starredIds.contains(messageId),
                                    onTogglePin: () => _togglePin(m),
                                    onToggleStar: () => _toggleStar(m),
                                  ),
                                  child: Container(
                                  margin: EdgeInsets.only(
                                      bottom: bubbleStyle.bubbleSpacing),
                                  padding: bubbleStyle.bubblePadding,
                                  constraints: BoxConstraints(
                                      maxWidth: 75.w),
                                  decoration: BoxDecoration(
                                    color: isClient
                                        ? theme.colorScheme.primary
                                        : theme
                                            .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                        bubbleStyle.borderRadius),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (isAi)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4),
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
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (isRequest)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4),
                                          child: Chip(
                                            visualDensity:
                                                VisualDensity.compact,
                                            label: const Text('Demande'),
                                            labelStyle: theme
                                                .textTheme.labelSmall
                                                ?.copyWith(
                                              color: isClient
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme
                                                      .onSurfaceVariant,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            backgroundColor: isClient
                                                ? Colors.white
                                                : theme.colorScheme.surface,
                                            side: BorderSide.none,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                      if (m['attachment_type'] != null)
                                        ChatAttachmentBubble(
                                          path: m['attachment_url'],
                                          type: m['attachment_type'],
                                          name: m['attachment_name'],
                                          durationMs:
                                              m['attachment_duration_ms'],
                                          foregroundColor: isClient
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                        ),
                                      if ((m['content'] as String?)
                                              ?.isNotEmpty ==
                                          true)
                                        Text(
                                          m['content'],
                                          style: TextStyle(
                                            fontSize: bubbleStyle.fontSize,
                                            color: isClient
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      if (createdAt != null && isLastOfGroup)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _dateFormat.format(
                                                    createdAt.toLocal()),
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: (isClient
                                                          ? theme.colorScheme
                                                              .onPrimary
                                                          : theme.colorScheme
                                                              .onSurfaceVariant)
                                                      .withValues(alpha: 0.75),
                                                ),
                                              ),
                                              // Coches ✓/✓✓ (29/09) : seulement
                                              // sur SES PROPRES messages
                                              // envoyés (isClient ici =
                                              // "envoyé par ce client"), jamais
                                              // sur ceux reçus du staff/IA.
                                              if (isClient) ...[
                                                const SizedBox(width: 4),
                                                ReadReceiptTicks(
                                                  isRead:
                                                      m['read_by_staff'] ==
                                                          true,
                                                  color: theme
                                                      .colorScheme.onPrimary
                                                      .withValues(alpha: 0.75),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      if (isClient &&
                                          msgIndex == messages.length - 1 &&
                                          m['read_by_staff'] == true &&
                                          m['read_by_staff_at'] != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Vu à ${_dateFormat.format(DateTime.parse(m['read_by_staff_at']).toLocal())}',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              fontSize: 10,
                                              color: theme.colorScheme
                                                  .onPrimary
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
                          );
                          }
                          return Column(
                            children: [
                              if (pinnedMessage != null)
                                PinnedMessageBanner(
                                  content: pinnedMessage['content']
                                          as String? ??
                                      '',
                                  onTap: () => _scrollToMessage(
                                      pinnedMessage!['id'] as String),
                                  onUnpin: () => _togglePin(pinnedMessage!),
                                ),
                              if (_searchMode)
                                _buildSearchResults(theme, searchResults),
                              Expanded(child: messageArea),
                            ],
                          );
                        },
                          ),
                          if (_showJumpToLatest)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Material(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  elevation: 2,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      _scrollToLatest();
                                      setState(
                                          () => _showJumpToLatest = false);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.arrow_downward,
                                              size: 16,
                                              color:
                                                  theme.colorScheme.onPrimary),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Nouveau message',
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_remoteIsTyping)
                      Padding(
                        padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 1.h),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TypingDots(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(3.w, 1.h, 3.w, 1.h),
                        child: ChatComposer(
                          controller: _textController,
                          hintText: _isRequestMode
                              ? 'Décrivez votre besoin...'
                              : 'Écrire un message...',
                          onSendText: _send,
                          onSendAttachment: _sendAttachment,
                          topBar: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 6, left: 4),
                            child: FilterChip(
                              label: const Text('Envoyer comme demande'),
                              avatar: Icon(
                                Icons.request_page_outlined,
                                size: 16,
                                color: _isRequestMode
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.outline,
                              ),
                              selected: _isRequestMode,
                              onSelected: (v) =>
                                  setState(() => _isRequestMode = v),
                              selectedColor: theme.colorScheme.primary,
                              labelStyle: TextStyle(
                                color: _isRequestMode
                                    ? theme.colorScheme.onPrimary
                                    : null,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
