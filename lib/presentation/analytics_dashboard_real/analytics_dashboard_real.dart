import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Tableau de bord Analytics — statistiques réelles calculées à partir
/// des vraies commandes, clients et produits de Supabase.
class AnalyticsDashboardReal extends StatefulWidget {
  const AnalyticsDashboardReal({super.key});

  @override
  State<AnalyticsDashboardReal> createState() =>
      _AnalyticsDashboardRealState();
}

class _AnalyticsDashboardRealState extends State<AnalyticsDashboardReal> {
  bool _isLoading = true;
  String? _error;
  int _daysRange = 7;

  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _newCustomers = 0;
  List<Map<String, dynamic>> _topProducts = [];

  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
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
      final since = DateTime.now()
          .subtract(Duration(days: _daysRange))
          .toIso8601String();

      // Les 3 requêtes sont indépendantes (même filtre "since") — lancées
      // en parallèle plutôt qu'à la suite pour ne pas cumuler leurs temps
      // de réseau.
      final results = await Future.wait([
        SupabaseConfig.client
            .from('orders')
            .select('total_amount, created_at')
            .gte('created_at', since),
        SupabaseConfig.client
            .from('profiles')
            .select('id')
            .eq('role', 'client')
            .gte('created_at', since),
        SupabaseConfig.client
            .from('order_items')
            .select('product_name, quantity, orders!inner(created_at)')
            .gte('orders.created_at', since),
      ]);
      final ordersList = List<Map<String, dynamic>>.from(results[0]);
      final customers = results[1];
      final orderItems = results[2];

      final Map<String, int> productCounts = {};
      for (final item in List<Map<String, dynamic>>.from(orderItems)) {
        final name = item['product_name'] ?? '';
        final qty = (item['quantity'] ?? 0) as num;
        productCounts[name] = (productCounts[name] ?? 0) + qty.toInt();
      }
      final topProducts = productCounts.entries
          .map((e) => {'name': e.key, 'quantity': e.value})
          .toList()
        ..sort((a, b) =>
            (b['quantity'] as int).compareTo(a['quantity'] as int));

      setState(() {
        _totalRevenue = ordersList.fold(
            0.0, (sum, o) => sum + ((o['total_amount'] ?? 0) as num));
        _totalOrders = ordersList.length;
        _newCustomers =
            List<Map<String, dynamic>>.from(customers).length;
        _topProducts = topProducts.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les statistiques.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView(
                    padding: EdgeInsets.all(4.w),
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [7, 30, 90].map((d) {
                            final selected = _daysRange == d;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('$d derniers jours'),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() => _daysRange = d);
                                  _loadStats();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 3.w,
                        mainAxisSpacing: 2.h,
                        childAspectRatio: 1.4,
                        children: [
                          _StatCard(
                            icon: Icons.payments_outlined,
                            label: 'Chiffre d\'affaires',
                            value: _currency.format(_totalRevenue),
                          ),
                          _StatCard(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Commandes',
                            value: '$_totalOrders',
                          ),
                          _StatCard(
                            icon: Icons.person_add_outlined,
                            label: 'Nouveaux clients',
                            value: '$_newCustomers',
                          ),
                          _StatCard(
                            icon: Icons.trending_up,
                            label: 'Panier moyen',
                            value: _totalOrders > 0
                                ? _currency
                                    .format(_totalRevenue / _totalOrders)
                                : _currency.format(0),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text('Produits les plus vendus',
                          style: theme.textTheme.titleMedium),
                      SizedBox(height: 1.h),
                      if (_topProducts.isEmpty)
                        const Text('Aucune vente sur cette période.')
                      else
                        ..._topProducts.map((p) => Card(
                              child: ListTile(
                                title: Text(p['name']),
                                trailing: Text('${p['quantity']} vendus'),
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
