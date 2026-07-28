import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Messagerie privée client ↔ équipe commerciale — une conversation par
/// client. Une "Demande" (ex "Demandes & annonces") est un message envoyé
/// avec is_request=true : jamais visible par les autres clients,
/// uniquement par le staff (contrairement à un post du Mur).
///
/// Schéma : `supabase/phase8_patch_messaging.sql`. Compte tenu de son
/// périmètre, l'écran Admin correspondant (déjà présent mais 100% mock,
/// `lib/presentation/messaging_center/`) reste à brancher côté
/// Backend/Infra sur ce même schéma.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? _conversationId;
  bool _isLoading = true;
  String? _error;
  bool _isRequestMode = false;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _dateFormat = DateFormat('HH:mm');
  Stream<List<Map<String, dynamic>>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          .select('id')
          .eq('customer_id', userId)
          .maybeSingle();

      String conversationId;
      if (existing != null) {
        conversationId = existing['id'] as String;
      } else {
        final created = await SupabaseConfig.client
            .from('conversations')
            .insert({'customer_id': userId})
            .select()
            .single();
        conversationId = created['id'] as String;
      }

      setState(() {
        _conversationId = conversationId;
        _messagesStream = SupabaseConfig.client
            .from('messages')
            .stream(primaryKey: ['id'])
            .eq('conversation_id', conversationId)
            .order('created_at');
        _isLoading = false;
      });

      // Marque les messages du staff comme lus à l'ouverture — sans quoi le
      // badge de notification de l'Accueil (voir catalog_tab.dart,
      // _unreadMessagesCount) ne redescendrait jamais à zéro.
      try {
        await SupabaseConfig.client
            .from('messages')
            .update({'read_by_client': true})
            .eq('conversation_id', conversationId)
            .eq('sender_role', 'staff')
            .eq('read_by_client', false);
      } catch (_) {
        // Non bloquant : la conversation reste utilisable même si le
        // marquage échoue.
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Messagerie indisponible pour le moment. Réessayez plus tard.';
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Messagerie')),
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
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _messagesStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final messages = snapshot.data!;
                          if (messages.isEmpty) {
                            return Center(
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
                          }
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              _scrollController.jumpTo(
                                  _scrollController.position.maxScrollExtent);
                            }
                          });
                          return ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(4.w),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final m = messages[index];
                              final isClient = m['sender_role'] == 'client';
                              final isRequest = m['is_request'] == true;
                              final createdAt =
                                  DateTime.tryParse(m['created_at'] ?? '');

                              return Align(
                                alignment: isClient
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(
                                      maxWidth: 75.w),
                                  decoration: BoxDecoration(
                                    color: isClient
                                        ? theme.colorScheme.primary
                                        : theme
                                            .colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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
                                      Text(
                                        m['content'] ?? '',
                                        style: TextStyle(
                                          color: isClient
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      if (createdAt != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            _dateFormat.format(
                                                createdAt.toLocal()),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: (isClient
                                                      ? theme.colorScheme
                                                          .onPrimary
                                                      : theme.colorScheme
                                                          .onSurfaceVariant)
                                                  .withValues(alpha: 0.75),
                                            ),
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
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(3.w, 1.h, 3.w, 1.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
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
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    minLines: 1,
                                    maxLines: 4,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: InputDecoration(
                                      hintText: _isRequestMode
                                          ? 'Décrivez votre besoin...'
                                          : 'Écrire un message...',
                                      filled: true,
                                      fillColor: theme
                                          .colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.5),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(24),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Material(
                                  color: theme.colorScheme.primary,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(Icons.send),
                                    color: theme.colorScheme.onPrimary,
                                    onPressed: _send,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
