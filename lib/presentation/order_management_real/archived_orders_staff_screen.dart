import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Commandes masquées par un membre du staff (voir `_hideOrder` dans
/// order_management_real.dart, phase265_patch_order_staff_hide_delete.sql)
/// — jamais supprimées en base, juste retirées de la liste principale de
/// gestion. Distinct de `ArchivedOrdersScreen` (côté client,
/// `hidden_by_customer`) : masquer une commande ici ne la masque pas
/// pour le client, et inversement.
class ArchivedOrdersStaffScreen extends StatefulWidget {
  const ArchivedOrdersStaffScreen({super.key});

  @override
  State<ArchivedOrdersStaffScreen> createState() =>
      _ArchivedOrdersStaffScreenState();
}

class _ArchivedOrdersStaffScreenState
    extends State<ArchivedOrdersStaffScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
      final orders = await SupabaseConfig.client
          .from('orders')
          .select('*, profiles(full_name, company_name)')
          .eq('hidden_by_staff', true)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _orders = List<Map<String, dynamic>>.from(orders);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les commandes archivées.';
      });
    }
  }

  Future<void> _restore(Map<String, dynamic> order) async {
    try {
      await SupabaseConfig.client
          .from('orders')
          .update({'hidden_by_staff': false}).eq('id', order['id']);
      if (!mounted) return;
      setState(() => _orders.removeWhere((o) => o['id'] == order['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande réaffichée.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de réafficher cette commande.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes archivées')),
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
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? const Center(child: Text('Aucune commande archivée.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final customer = order['profiles'];
                          final customerName = customer != null
                              ? (customer['company_name'] ??
                                  customer['full_name'] ??
                                  'Client')
                              : 'Client';
                          return Card(
                            child: ListTile(
                              title: Text(order['order_number'] ?? ''),
                              subtitle: Text(
                                  '$customerName · ${_currency.format(order['total_amount'] ?? 0)}'),
                              trailing: TextButton.icon(
                                onPressed: () => _restore(order),
                                icon: const Icon(Icons.unarchive_outlined,
                                    size: 18),
                                label: const Text('Réafficher'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
