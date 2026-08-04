import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Commandes masquées par le client lui-même (voir `_hideOrder` dans
/// orders_tab.dart, phase69_patch_order_archiving.sql) — jamais
/// supprimées en base, juste retirées de la liste principale. Cet
/// écran permet de les retrouver et de les réafficher : aucune perte
/// de données, entièrement réversible.
class ArchivedOrdersScreen extends StatefulWidget {
  const ArchivedOrdersScreen({super.key});

  @override
  State<ArchivedOrdersScreen> createState() => _ArchivedOrdersScreenState();
}

class _ArchivedOrdersScreenState extends State<ArchivedOrdersScreen> {
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
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (!SupabaseConfig.isConfigured || userId == null) {
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
          .select()
          .eq('customer_id', userId)
          .eq('hidden_by_customer', true)
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
      await SupabaseConfig.client.rpc('set_order_hidden', params: {
        'p_order_id': order['id'],
        'p_hidden': false,
      });
      if (!mounted) return;
      setState(() => _orders.removeWhere((o) => o['id'] == order['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Commande réaffichée dans votre liste.')),
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
              ? Center(child: Text(_error!))
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
                          return Card(
                            child: ListTile(
                              title: Text(order['order_number'] ?? ''),
                              subtitle: Text(_currency
                                  .format(order['total_amount'] ?? 0)),
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
