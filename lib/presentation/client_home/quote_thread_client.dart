import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Fil de négociation d'un devis, côté client : voir les propositions de
/// l'équipe commerciale, accepter/refuser, ou reproposer un montant/message
/// si le prix ne convient pas.
class QuoteThreadClient extends StatefulWidget {
  final Map<String, dynamic> quote;

  const QuoteThreadClient({super.key, required this.quote});

  @override
  State<QuoteThreadClient> createState() => _QuoteThreadClientState();
}

class _QuoteThreadClientState extends State<QuoteThreadClient> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _thread = [];
  bool _isLoading = true;
  final _controller = TextEditingController();
  final _amountController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  final Map<String, String> _statusLabels = const {
    'en_attente': 'En attente',
    'envoye': 'Proposition reçue',
    'accepte': 'Accepté',
    'refuse': 'Refusé',
    'expire': 'Expiré',
  };

  String? get _myId =>
      SupabaseConfig.isConfigured ? SupabaseConfig.client.auth.currentUser?.id : null;

  @override
  void initState() {
    super.initState();
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
          .order('created_at');
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

  /// Le client répond avec un message et/ou un montant qu'il propose à la
  /// place — repasse automatiquement le devis en "En attente" pour que le
  /// staff sache qu'il doit revoir sa proposition.
  Future<void> _sendCounterProposal() async {
    if (_myId == null) return;
    final text = _controller.text.trim();
    final proposedAmount = double.tryParse(_amountController.text);
    if (text.isEmpty && proposedAmount == null) return;

    setState(() => _isSending = true);

    try {
      await SupabaseConfig.client.from('quote_messages').insert({
        'quote_id': widget.quote['id'],
        'sender_id': _myId,
        'sender_role': 'client',
        'content': text,
        'proposed_amount': proposedAmount,
      });

      await SupabaseConfig.client
          .from('quotes')
          .update({'status': 'en_attente'}).eq('id', widget.quote['id']);

      _controller.clear();
      _amountController.clear();
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

  Future<void> _respond(String status) async {
    try {
      await SupabaseConfig.client
          .from('quotes')
          .update({'status': status}).eq('id', widget.quote['id']);
      await SupabaseConfig.client.from('quote_messages').insert({
        'quote_id': widget.quote['id'],
        'sender_id': _myId,
        'sender_role': 'client',
        'content': status == 'accepte'
            ? 'Devis accepté par le client.'
            : 'Devis refusé par le client.',
      });
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la réponse.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.quote['status'] ?? 'en_attente';
    final canRespond = status == 'envoye';

    return Scaffold(
      appBar: AppBar(title: Text(widget.quote['quote_number'] ?? '')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Chip(label: Text(_statusLabels[status] ?? status)),
                          Text(
                            _currency.format(widget.quote['total_amount'] ?? 0),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
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
                            'Votre demande a été envoyée. Notre équipe va vous répondre ici.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _thread.length,
                          itemBuilder: (context, index) {
                            final m = _thread[index];
                            final isMine = m['sender_role'] == 'client';
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
                if (canRespond)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _respond('refuse'),
                            child: const Text('Refuser'),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _respond('accepte'),
                            child: const Text('Accepter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Le prix ne vous convient pas ? Proposez un autre montant :',
                        style: theme.textTheme.bodySmall,
                      ),
                      SizedBox(height: 1.h),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Votre proposition (Ar, optionnel)',
                          isDense: true,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Votre message...',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed:
                                _isSending ? null : _sendCounterProposal,
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
