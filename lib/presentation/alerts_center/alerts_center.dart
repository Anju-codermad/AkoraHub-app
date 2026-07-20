import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Centre d'alertes : stock bas (produits) et DLC proche (lots de production).
/// Consulté par le staff Production/Admin.
class AlertsCenter extends StatefulWidget {
  const AlertsCenter({super.key});

  @override
  State<AlertsCenter> createState() => _AlertsCenterState();
}

class _AlertsCenterState extends State<AlertsCenter> {
  List<Map<String, dynamic>> _lowStockProducts = [];
  List<Map<String, dynamic>> _expiringBatches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
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
      // Stock bas : on récupère tous les produits et on filtre côté client,
      // car Supabase ne permet pas de comparer deux colonnes entre elles
      // directement dans un simple filtre .lte().
      final allProducts =
          await SupabaseConfig.client.from('products').select();
      final lowStock = List<Map<String, dynamic>>.from(allProducts)
          .where((p) =>
              (p['stock_quantity'] ?? 0) <= (p['low_stock_threshold'] ?? 5))
          .toList();

      // DLC proche : lots dont la date d'expiration est dans les 30 prochains
      // jours (ou déjà dépassée).
      final soon =
          DateTime.now().add(const Duration(days: 30)).toIso8601String();
      final batches = await SupabaseConfig.client
          .from('production_batches')
          .select('*, products(name)')
          .not('expiry_date', 'is', null)
          .lte('expiry_date', soon)
          .order('expiry_date');

      setState(() {
        _lowStockProducts = lowStock;
        _expiringBatches = List<Map<String, dynamic>>.from(batches);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les alertes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAlerts = _lowStockProducts.length + _expiringBatches.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Alertes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadAlerts,
                  child: totalAlerts == 0
                      ? ListView(
                          children: [
                            SizedBox(height: 15.h),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 48,
                                      color: theme.colorScheme.primary),
                                  SizedBox(height: 1.h),
                                  const Text('Aucune alerte pour le moment.'),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: EdgeInsets.all(4.w),
                          children: [
                            if (_lowStockProducts.isNotEmpty) ...[
                              Text('Stock bas (${_lowStockProducts.length})',
                                  style: theme.textTheme.titleMedium),
                              SizedBox(height: 1.h),
                              ..._lowStockProducts.map((p) => Card(
                                    color: theme.colorScheme.errorContainer
                                        .withValues(alpha: 0.4),
                                    child: ListTile(
                                      leading: Icon(Icons.inventory_2_outlined,
                                          color: theme.colorScheme.error),
                                      title: Text(p['name'] ?? ''),
                                      subtitle: Text(
                                          'Stock : ${p['stock_quantity']} (seuil : ${p['low_stock_threshold']})'),
                                    ),
                                  )),
                              SizedBox(height: 2.h),
                            ],
                            if (_expiringBatches.isNotEmpty) ...[
                              Text(
                                  'DLC proche ou dépassée (${_expiringBatches.length})',
                                  style: theme.textTheme.titleMedium),
                              SizedBox(height: 1.h),
                              ..._expiringBatches.map((b) {
                                final expiry =
                                    DateTime.tryParse(b['expiry_date'] ?? '');
                                final expired = expiry != null &&
                                    expiry.isBefore(DateTime.now());
                                final productName =
                                    b['products']?['name'] ?? 'Produit';
                                return Card(
                                  color: (expired
                                          ? theme.colorScheme.errorContainer
                                          : theme.colorScheme.tertiaryContainer)
                                      .withValues(alpha: 0.4),
                                  child: ListTile(
                                    leading: Icon(
                                      expired
                                          ? Icons.error_outline
                                          : Icons.schedule,
                                      color: expired
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.tertiary,
                                    ),
                                    title:
                                        Text('$productName — Lot ${b['batch_number']}'),
                                    subtitle: Text(
                                      expiry == null
                                          ? ''
                                          : (expired
                                              ? 'Expiré le ${DateFormat('dd/MM/yyyy').format(expiry)}'
                                              : 'DLC : ${DateFormat('dd/MM/yyyy').format(expiry)}'),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                ),
    );
  }
}
