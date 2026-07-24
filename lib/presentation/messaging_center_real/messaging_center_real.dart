import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/supabase/supabase_config.dart';

/// Messagerie côté staff : liste de toutes les conversations clients,
/// triées par message le plus récent.
class MessagingCenterReal extends StatefulWidget {
  const MessagingCenterReal({super.key});

  @override
  State<MessagingCenterReal> createState() => _MessagingCenterRealState();
}

class _MessagingCenterRealState extends State<MessagingCenterReal> {
  List<Map<String, dynamic>> _conversations = [];
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
      setState(() {
        _conversations = List<Map<String, dynamic>>.from(data);
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
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  name.toString().isNotEmpty
                                      ? name.toString()[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(name),
                              subtitle: Text(
                                'Dernier message : ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(c['last_message_at']))}',
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _AdminConversationThread(
                                      conversationId: c['id'],
                                      customerName: name,
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

class _AdminConversationThread extends StatefulWidget {
  final String conversationId;
  final String customerName;

  const _AdminConversationThread({
    required this.conversationId,
    required this.customerName,
  });

  @override
  State<_AdminConversationThread> createState() =>
      _AdminConversationThreadState();
}

class _AdminConversationThreadState extends State<_AdminConversationThread> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.customerName)),
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
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            m['content'] ?? '',
                            style: TextStyle(
                              color: isMine
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Répondre...',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(24)),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _isSending ? null : _sendMessage,
                          icon: const Icon(Icons.send),
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
