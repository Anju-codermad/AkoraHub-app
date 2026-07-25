import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

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
    List<Map<String, dynamic>> items = [];
    try {
      final data = await SupabaseConfig.client
          .from('quote_items')
          .select()
          .eq('quote_id', quote['id']);
      items = List<Map<String, dynamic>>.from(data);
    } catch (_) {}

    if (!mounted) return;

    final amountController = TextEditingController(
        text: (quote['total_amount'] ?? 0).toString());
    String selectedStatus = quote['status'] ?? 'en_attente';
    final customer = quote['profiles'];
    final customerName = customer != null
        ? (customer['company_name'] ?? customer['full_name'] ?? 'Client')
        : 'Client';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 4.w,
            right: 4.w,
            top: 2.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(quote['quote_number'] ?? '',
                    style: Theme.of(context).textTheme.titleLarge),
                Text(customerName,
                    style: Theme.of(context).textTheme.bodyMedium),
                if ((customer?['phone'] ?? '').toString().isNotEmpty)
                  Text('Tél : ${customer!['phone']}',
                      style: Theme.of(context).textTheme.bodySmall),
                SizedBox(height: 2.h),
                Text('Articles demandés',
                    style: Theme.of(context).textTheme.titleSmall),
                SizedBox(height: 1.h),
                if (items.isEmpty)
                  const Text('Aucun article détaillé.')
                else
                  ...items.map((item) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 0.5.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(
                                    '${item['product_name']} × ${item['quantity']}')),
                            Text(_currency.format(item['unit_price'] ?? 0)),
                          ],
                        ),
                      )),
                const Divider(height: 32),
                Text('Montant proposé au client',
                    style: Theme.of(context).textTheme.titleSmall),
                SizedBox(height: 1.h),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixText: 'Ar',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 2.h),
                Text('Statut', style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 8,
                  children: _statusLabels.entries.map((entry) {
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: selectedStatus == entry.key,
                      onSelected: (_) =>
                          setSheetState(() => selectedStatus = entry.key),
                    );
                  }).toList(),
                ),
                SizedBox(height: 3.h),
                FilledButton(
                  onPressed: () async {
                    try {
                      await SupabaseConfig.client.from('quotes').update({
                        'status': selectedStatus,
                        'total_amount':
                            double.tryParse(amountController.text) ??
                                quote['total_amount'],
                      }).eq('id', quote['id']);
                      if (!mounted) return;
                      Navigator.pop(context);
                      _loadQuotes();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Devis mis à jour.')),
                      );
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Erreur lors de la mise à jour.')),
                      );
                    }
                  },
                  child: const Text('Enregistrer et répondre au client'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Devis')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
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
                                      title: Text(q['quote_number'] ?? ''),
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
