import 'package:flutter/material.dart';

import '../supabase/supabase_config.dart';

/// Sélecteur de conversation (29/09), pour "Transférer" un message —
/// staff uniquement (un client n'a qu'une seule conversation avec
/// l'équipe, transférer n'aurait pas de sens côté client). Retourne
/// l'id de la conversation choisie via `Navigator.pop`.
class ConversationPickerScreen extends StatefulWidget {
  final String excludeConversationId;

  const ConversationPickerScreen({
    super.key,
    required this.excludeConversationId,
  });

  @override
  State<ConversationPickerScreen> createState() =>
      _ConversationPickerScreenState();
}

class _ConversationPickerScreenState extends State<ConversationPickerScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseConfig.client
          .from('conversations')
          .select('id, profiles(full_name, company_name)')
          .neq('id', widget.excludeConversationId)
          .order('last_message_at', ascending: false);
      setState(() {
        _conversations = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transférer à...')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Aucune autre conversation.'),
                  ),
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
                      onTap: () => Navigator.pop(context, c['id'] as String),
                    );
                  },
                ),
    );
  }
}
