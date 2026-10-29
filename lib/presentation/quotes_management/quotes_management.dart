import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';
import 'archived_quotes_staff_screen.dart';

/// Gestion des devis côté staff : liste des demandes reçues, détail des
/// articles demandés, réponse (prix proposé) et mise à jour du statut.
class QuotesManagement extends StatefulWidget {
  const QuotesManagement({super.key});

  @override
  State<QuotesManagement> createState() => _QuotesManagementState();
}

class _QuotesManagementState extends State<QuotesManagement> {
  List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'toutes';
  bool _isAdmin = false;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  final Map<String, String> _statusLabels = const {
    'en_attente': 'En attente',
    'envoye': 'Envoyé',
    'accepte': 'Accepté',
    'refuse': 'Refusé',
    'expire': 'Expiré',
  };

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _loadMyRole();
  }

  /// Détermine si le membre du staff connecté est Admin (seul rôle
  /// autorisé à supprimer définitivement un devis) — même pattern que
  /// order_management_real.dart.
  Future<void> _loadMyRole() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) return;
    try {
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      if (!mounted) return;
      setState(() => _isAdmin = profile['role'] == 'admin');
    } catch (_) {
      // Pas grave : reste simplement non-Admin (pas d'option Supprimer).
    }
  }

  Future<void> _loadQuotes() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion au serveur indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseConfig.client
          .from('quotes')
          .select('*, profiles(full_name, company_name, phone)')
          .eq('hidden_by_staff', false)
          .order('created_at', ascending: false);
      setState(() {
        _quotes = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les devis.';
      });
    }
  }

  /// Masque un devis de cette liste de gestion (jamais une suppression —
  /// distinct du masquage côté client, `hidden_by_customer`) —
  /// accessible à tout le staff, voir
  /// phase271_patch_quote_staff_hide_delete.sql.
  Future<void> _hideQuote(Map<String, dynamic> quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masquer ce devis'),
        content: Text(
            'Le devis ${quote['quote_number'] ?? ''} sera retiré de cette '
            'liste. Vous pourrez le retrouver dans "Devis archivés" (menu '
            '⋮ en haut). Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Masquer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseConfig.client
          .from('quotes')
          .update({'hidden_by_staff': true}).eq('id', quote['id']);
      if (!mounted) return;
      setState(() => _quotes.removeWhere((q) => q['id'] == quote['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devis masqué.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de masquer ce devis.')),
      );
    }
  }

  /// Suppression définitive (Admin uniquement) — irréversible, efface
  /// aussi les lignes/messages du devis (cascade, phase1/phase271).
  Future<void> _deleteQuotePermanently(Map<String, dynamic> quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer définitivement ce devis ?'),
        content: Text(
            'Le devis ${quote['quote_number'] ?? ''} et tout son historique '
            'd\'échanges seront effacés définitivement. Cette action est '
            'irréversible. ⚠️ Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseConfig.client.from('quotes').delete().eq('id', quote['id']);
      if (!mounted) return;
      setState(() => _quotes.removeWhere((q) => q['id'] == quote['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devis supprimé définitivement.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer ce devis.')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredQuotes {
    if (_statusFilter == 'toutes') return _quotes;
    return _quotes.where((q) => q['status'] == _statusFilter).toList();
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'accepte':
        return Colors.green;
      case 'envoye':
        return Colors.blue;
      case 'refuse':
      case 'expire':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  Future<void> _openQuote(Map<String, dynamic> quote) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QuoteThreadScreen(quote: quote),
      ),
    );
    _loadQuotes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devis'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'archived') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ArchivedQuotesStaffScreen()),
                ).then((_) => _loadQuotes());
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: 'archived', child: Text('Devis archivés')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  // Bouton "Réessayer" (27/10, demande explicite).
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        SizedBox(height: 2.h),
                        OutlinedButton.icon(
                          onPressed: _loadQuotes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.h),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Tous'),
                            selected: _statusFilter == 'toutes',
                            onSelected: (_) =>
                                setState(() => _statusFilter = 'toutes'),
                          ),
                          SizedBox(width: 2.w),
                          ..._statusLabels.entries.map((entry) => Padding(
                                padding: EdgeInsets.only(right: 2.w),
                                child: ChoiceChip(
                                  label: Text(entry.value),
                                  selected: _statusFilter == entry.key,
                                  onSelected: (_) => setState(
                                      () => _statusFilter = entry.key),
                                ),
                              )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadQuotes,
                        child: _filteredQuotes.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(height: 20.h),
                                  const Center(
                                      child: Text('Aucun devis.')),
                                ],
                              )
                            : ListView.separated(
                                padding: EdgeInsets.all(4.w),
                                itemCount: _filteredQuotes.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
                                  final q = _filteredQuotes[index];
                                  final status = q['status'] ?? 'en_attente';
                                  final customer = q['profiles'];
                                  final customerName = customer != null
                                      ? (customer['company_name'] ??
                                          customer['full_name'] ??
                                          'Client')
                                      : 'Client';
                                  return Card(
                                    child: ListTile(
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                                q['quote_number'] ?? ''),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert,
                                                size: 18),
                                            padding: EdgeInsets.zero,
                                            onSelected: (value) {
                                              if (value == 'hide') {
                                                _hideQuote(q);
                                              } else if (value == 'delete') {
                                                _deleteQuotePermanently(q);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'hide',
                                                child:
                                                    Text('Masquer ce devis'),
                                              ),
                                              if (_isAdmin)
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text(
                                                      'Supprimer définitivement'),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '$customerName · ${_currency.format(q['total_amount'] ?? 0)}',
                                      ),
                                      trailing: Chip(
                                        label: Text(
                                          _statusLabels[status] ?? status,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white),
                                        ),
                                        backgroundColor:
                                            _statusColor(status, theme),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onTap: () => _openQuote(q),
                                    ),
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

/// Fil de négociation d'un devis : historique complet des propositions
/// (client ↔ staff), avec possibilité de proposer un nouveau montant et de
/// changer le statut. Réutilisé tel quel côté Admin ; le client a son
/// propre écran équivalent dans `client_home/quote_thread_client.dart`.
class _QuoteThreadScreen extends StatefulWidget {
  final Map<String, dynamic> quote;

  const _QuoteThreadScreen({required this.quote});

  @override
  State<_QuoteThreadScreen> createState() => _QuoteThreadScreenState();
}

class _QuoteThreadScreenState extends State<_QuoteThreadScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _thread = [];
  bool _isLoading = true;
  final _controller = TextEditingController();
  final _amountController = TextEditingController();
  final _scrollController = ScrollController();
  String _status = 'en_attente';
  bool _isSending = false;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  final Map<String, String> _statusLabels = const {
    'en_attente': 'En attente',
    'envoye': 'Envoyé',
    'accepte': 'Accepté',
    'refuse': 'Refusé',
    'expire': 'Expiré',
  };

  String? get _myId =>
      SupabaseConfig.isConfigured ? SupabaseConfig.client.auth.currentUser?.id : null;

  @override
  void initState() {
    super.initState();
    _status = widget.quote['status'] ?? 'en_attente';
    _amountController.text = (widget.quote['total_amount'] ?? 0).toString();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _amountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await SupabaseConfig.client
          .from('quote_items')
          .select()
          .eq('quote_id', widget.quote['id']);
      final thread = await SupabaseConfig.client
          .from('quote_messages')
          .select()
          .eq('quote_id', widget.quote['id'])
          .order('created_at', ascending: true);
      setState(() {
        _items = List<Map<String, dynamic>>.from(items);
        _thread = List<Map<String, dynamic>>.from(thread);
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

  Future<void> _send({bool updateStatus = false}) async {
    if (_myId == null) return;
    final text = _controller.text.trim();
    final proposedAmount = double.tryParse(_amountController.text);
    if (text.isEmpty && !updateStatus) return;

    setState(() => _isSending = true);

    try {
      if (text.isNotEmpty || proposedAmount != null) {
        await SupabaseConfig.client.from('quote_messages').insert({
          'quote_id': widget.quote['id'],
          'sender_id': _myId,
          'sender_role': 'staff',
          'content': text.isEmpty ? 'Nouvelle proposition de prix' : text,
          'proposed_amount': proposedAmount,
        });
      }

      final updatePayload = <String, dynamic>{'status': _status};
      if (proposedAmount != null) {
        updatePayload['total_amount'] = proposedAmount;
      }
      await SupabaseConfig.client
          .from('quotes')
          .update(updatePayload)
          .eq('id', widget.quote['id']);

      _controller.clear();
      await _load();
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
    final customer = widget.quote['profiles'];
    final customerName = customer != null
        ? (customer['company_name'] ?? customer['full_name'] ?? 'Client')
        : 'Client';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quote['quote_number'] ?? ''),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerName, style: theme.textTheme.titleSmall),
                      if ((customer?['phone'] ?? '').toString().isNotEmpty)
                        Text('Tél : ${customer!['phone']}',
                            style: theme.textTheme.bodySmall),
                      SizedBox(height: 1.h),
                      ..._items.map((item) => Text(
                          '• ${item['product_name']} × ${item['quantity']}',
                          style: theme.textTheme.bodySmall)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _thread.isEmpty
                      ? Center(
                          child: Text(
                            'Demande initiale — proposez un montant ci-dessous.',
                            style: theme.textTheme.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _thread.length,
                          itemBuilder: (context, index) {
                            final m = _thread[index];
                            final isMine = m['sender_role'] == 'staff';
                            return Align(
                              alignment: isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme
                                          .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (m['proposed_amount'] != null)
                                      Text(
                                        'Proposition : ${_currency.format(m['proposed_amount'])}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isMine
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    if ((m['content'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text(
                                        m['content'],
                                        style: TextStyle(
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
                const Divider(height: 1),
                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: _statusLabels.entries.map((entry) {
                          return ChoiceChip(
                            label: Text(entry.value),
                            selected: _status == entry.key,
                            onSelected: (_) =>
                                setState(() => _status = entry.key),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Montant proposé (Ar)',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Message (optionnel)...',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed:
                                _isSending ? null : () => _send(),
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
