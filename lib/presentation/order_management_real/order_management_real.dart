import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Gestion réelle des commandes : suivi des 4 statuts (Reçue, En préparation,
/// Expédiée, Livrée), consultable/modifiable par le staff.
class OrderManagementReal extends StatefulWidget {
  const OrderManagementReal({super.key});

  @override
  State<OrderManagementReal> createState() => _OrderManagementRealState();
}

class _OrderManagementRealState extends State<OrderManagementReal> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'toutes';
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  final Map<String, String> _statusLabels = const {
    'recue': 'Reçue',
    'en_preparation': 'En préparation',
    'expediee': 'Expédiée',
    'livree': 'Livrée',
    'annulee': 'Annulée',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
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
          .from('orders')
          .select('*, profiles(full_name, company_name)')
          .order('created_at', ascending: false);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les commandes.';
      });
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> order) async {
    String selected = order['status'] ?? 'recue';

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Commande ${order['order_number']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _statusLabels.entries.map((entry) {
              return RadioListTile<String>(
                value: entry.key,
                groupValue: selected,
                title: Text(entry.value),
                onChanged: (v) => setDialogState(() => selected = v!),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      await SupabaseConfig.client
          .from('orders')
          .update({'status': result}).eq('id', order['id']);
      _loadOrders();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour.')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_statusFilter == 'toutes') return _orders;
    return _orders.where((o) => o['status'] == _statusFilter).toList();
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'livree':
        return Colors.green;
      case 'expediee':
        return Colors.blue;
      case 'en_preparation':
        return Colors.orange;
      case 'annulee':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Commandes')),
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
                            label: const Text('Toutes'),
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
                        onRefresh: _loadOrders,
                        child: _filteredOrders.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(height: 20.h),
                                  const Center(
                                      child: Text('Aucune commande.')),
                                ],
                              )
                            : ListView.separated(
                                padding: EdgeInsets.all(4.w),
                                itemCount: _filteredOrders.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
                                  final order = _filteredOrders[index];
                                  final status = order['status'] ?? 'recue';
                                  final customer = order['profiles'];
                                  final customerName = customer != null
                                      ? (customer['company_name'] ??
                                          customer['full_name'] ??
                                          'Client')
                                      : 'Client';
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                          order['order_number'] ?? ''),
                                      subtitle: Text(
                                        '$customerName · ${_currency.format(order['total_amount'] ?? 0)}',
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
                                      onTap: () => _updateStatus(order),
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
