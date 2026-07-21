import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';

class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});

  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
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
          .select('*, order_items(*)')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(orders);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger vos commandes.';
      });
    }
  }

  int _statusStep(String status) {
    const order = ['recue', 'en_preparation', 'expediee', 'livree'];
    final i = order.indexOf(status);
    return i < 0 ? 0 : i;
  }

  void _reorder(Map<String, dynamic> order) {
    final items = List<Map<String, dynamic>>.from(order['order_items'] ?? []);
    for (final item in items) {
      ref.read(cartProvider.notifier).addItem(CartItem(
            productId: item['product_id'] ?? '',
            name: item['product_name'] ?? '',
            priceDetail: (item['unit_price'] ?? 0).toDouble(),
            priceGros: (item['unit_price'] ?? 0).toDouble(),
            grosThresholdQty: 999999,
            quantity: (item['quantity'] ?? 1).toInt(),
          ));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Articles ajoutés au panier.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('Aucune commande pour le moment.'));
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: EdgeInsets.all(4.w),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => SizedBox(height: 2.h),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final status = order['status'] ?? 'recue';
          final step = _statusStep(status);
          final cancelled = status == 'annulee';

          return Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order['order_number'] ?? '',
                          style: theme.textTheme.titleSmall),
                      Text(_currency.format(order['total_amount'] ?? 0)),
                    ],
                  ),
                  SizedBox(height: 1.5.h),
                  if (!cancelled)
                    Row(
                      children: List.generate(4, (i) {
                        final done = i <= step;
                        return Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 4,
                                color: done
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                _statusLabels.values.elementAt(i),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: done
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline,
                                  fontWeight: done
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }),
                    )
                  else
                    Chip(
                      label: const Text('Annulée'),
                      backgroundColor: theme.colorScheme.errorContainer,
                    ),
                  SizedBox(height: 1.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _reorder(order),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Recommander'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
