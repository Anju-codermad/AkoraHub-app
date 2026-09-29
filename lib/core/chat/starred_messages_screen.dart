import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../supabase/supabase_config.dart';

/// Messages enregistrés (29/09) — équivalent "Messages relayés à
/// moi-même" de WhatsApp : liste, tous fils confondus, des messages que
/// CET utilisateur (client ou membre du staff) a marqués comme favoris.
/// Voir `starred_messages` (phase251) — RLS limite chacun à ses propres
/// lignes, donc cet écran est le même pour le client et pour le staff.
class StarredMessagesScreen extends StatefulWidget {
  const StarredMessagesScreen({super.key});

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Vous devez être connecté.';
        });
        return;
      }
      final data = await SupabaseConfig.client
          .from('starred_messages')
          .select(
              'id, created_at, messages(content, attachment_type, created_at)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      setState(() {
        _items = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les messages enregistrés.';
      });
    }
  }

  Future<void> _unstar(String starredId) async {
    try {
      await SupabaseConfig.client
          .from('starred_messages')
          .delete()
          .eq('id', starredId);
      if (mounted) {
        setState(() => _items.removeWhere((i) => i['id'] == starredId));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action impossible. Réessayez.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(title: const Text('Messages enregistrés')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Aucun message enregistré pour le moment.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final message =
                            item['messages'] as Map<String, dynamic>?;
                        final content = message?['content'] as String?;
                        final createdAt = message?['created_at'] != null
                            ? DateTime.tryParse(message!['created_at'])
                            : null;
                        return ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: Text(
                            (content?.isNotEmpty ?? false)
                                ? content!
                                : 'Pièce jointe',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: createdAt != null
                              ? Text(dateFormat.format(createdAt.toLocal()))
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.star, color: Colors.amber),
                            tooltip: 'Retirer des favoris',
                            onPressed: () => _unstar(item['id'] as String),
                          ),
                        );
                      },
                    ),
    );
  }
}
