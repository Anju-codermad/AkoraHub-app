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
  List<Map<String, dynamic>> _lowStockVariants = [];
  List<Map<String, dynamic>> _expiringBatches = [];
  List<Map<String, dynamic>> _predictedStockouts = [];
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

      // Stock bas par VARIANTE (conditionnement) — ajouté 14/08 : chaque
      // format (ex. "Sac 25 kg") a son propre stock indépendant depuis les
      // conditionnements industriels, mais n'était surveillé nulle part —
      // un conditionnement précis pouvait tomber à zéro sans que personne
      // ne soit prévenu, même si le produit "parent" semblait en stock.
      List<Map<String, dynamic>> lowStockVariants = [];
      try {
        final allVariants = await SupabaseConfig.client
            .from('product_variants')
            .select('*, products(name), formats(name), parfums(name)');
        lowStockVariants = List<Map<String, dynamic>>.from(allVariants)
            .where((v) =>
                (v['stock_quantity'] ?? 0) <=
                (v['low_stock_threshold'] ?? 5))
            .toList();
      } catch (_) {
        // Repli silencieux : reste vide si la table n'est pas accessible.
      }

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

      // Rupture prévue : vitesse de vente réelle des 30 derniers jours
      // (quantité vendue / produit) comparée au stock actuel. Estimation
      // simple (moyenne linéaire) — pas une vraie prévision statistique,
      // mais largement suffisante pour donner une alerte utile à l'Admin.
      final since =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      final recentItems = await SupabaseConfig.client
          .from('order_items')
          .select('product_id, quantity, orders!inner(created_at)')
          .gte('orders.created_at', since);

      final Map<String, num> soldByProduct = {};
      for (final item in List<Map<String, dynamic>>.from(recentItems)) {
        final productId = item['product_id'] as String?;
        if (productId == null) continue;
        final qty = (item['quantity'] ?? 0) as num;
        soldByProduct[productId] = (soldByProduct[productId] ?? 0) + qty;
      }

      final predictedStockouts = <Map<String, dynamic>>[];
      for (final p in List<Map<String, dynamic>>.from(allProducts)) {
        final sold = soldByProduct[p['id']];
        if (sold == null || sold <= 0) continue;
        final dailyRate = sold / 30;
        final stock = (p['stock_quantity'] ?? 0) as num;
        final daysLeft = stock / dailyRate;
        if (daysLeft <= 14) {
          predictedStockouts.add({
            ...p,
            'days_left': daysLeft.round(),
          });
        }
      }
      predictedStockouts
          .sort((a, b) => (a['days_left'] as int).compareTo(b['days_left'] as int));

      setState(() {
        _lowStockProducts = lowStock;
        _lowStockVariants = lowStockVariants;
        _expiringBatches = List<Map<String, dynamic>>.from(batches);
        _predictedStockouts = predictedStockouts;
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
    final totalAlerts = _lowStockProducts.length +
        _lowStockVariants.length +
        _expiringBatches.length +
        _predictedStockouts.length;

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
                            if (_predictedStockouts.isNotEmpty) ...[
                              Text(
                                  'Rupture prévue (${_predictedStockouts.length})',
                                  style: theme.textTheme.titleMedium),
                              SizedBox(height: 0.5.h),
                              Text(
                                'Basé sur le rythme de vente des 30 derniers jours.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant),
                              ),
                              SizedBox(height: 1.h),
                              ..._predictedStockouts.map((p) {
                                final daysLeft = p['days_left'] as int;
                                return Card(
                                  color: theme.colorScheme.tertiaryContainer
                                      .withValues(alpha: 0.4),
                                  child: ListTile(
                                    leading: Icon(Icons.trending_down,
                                        color: theme.colorScheme.tertiary),
                                    title: Text(p['name'] ?? ''),
                                    subtitle: Text(
                                      daysLeft <= 0
                                          ? 'Rupture imminente au rythme actuel'
                                          : 'Stock épuisé dans environ $daysLeft jour${daysLeft > 1 ? 's' : ''} au rythme actuel',
                                    ),
                                  ),
                                );
                              }),
                              SizedBox(height: 2.h),
                            ],
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
                            if (_lowStockVariants.isNotEmpty) ...[
                              Text(
                                  'Conditionnements en stock bas (${_lowStockVariants.length})',
                                  style: theme.textTheme.titleMedium),
                              SizedBox(height: 0.5.h),
                              Text(
                                'Le stock du produit peut sembler correct '
                                'alors qu\'un format précis est bas.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant),
                              ),
                              SizedBox(height: 1.h),
                              ..._lowStockVariants.map((v) {
                                final productName =
                                    v['products']?['name'] ?? 'Produit';
                                final formatName = v['formats']?['name'];
                                final parfumName = v['parfums']?['name'];
                                final variantLabel = [formatName, parfumName]
                                    .whereType<String>()
                                    .join(' · ');
                                return Card(
                                  color: theme.colorScheme.errorContainer
                                      .withValues(alpha: 0.4),
                                  child: ListTile(
                                    leading: Icon(Icons.inventory_2_outlined,
                                        color: theme.colorScheme.error),
                                    title: Text(
                                      variantLabel.isNotEmpty
                                          ? '$productName — $variantLabel'
                                          : productName,
                                    ),
                                    subtitle: Text(
                                        'Stock : ${v['stock_quantity']} (seuil : ${v['low_stock_threshold']})'),
                                  ),
                                );
                              }),
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
