import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Gestion réelle des produits : tarification Gros/Détail par seuil de
/// quantité, stock, et lots de production (n° lot, fabrication, DLC).
/// Remplace progressivement l'ancien écran basé sur des données fictives.
class ProductManagementReal extends StatefulWidget {
  const ProductManagementReal({super.key});

  @override
  State<ProductManagementReal> createState() => _ProductManagementRealState();
}

class _ProductManagementRealState extends State<ProductManagementReal> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _businessUnits = [];
  bool _isLoading = true;
  String? _error;
  final _currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
      final products = await SupabaseConfig.client
          .from('products')
          .select()
          .order('created_at', ascending: false);
      final units =
          await SupabaseConfig.client.from('business_units').select();
      setState(() {
        _products = List<Map<String, dynamic>>.from(products);
        _businessUnits = List<Map<String, dynamic>>.from(units);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les produits.';
      });
    }
  }

  Future<void> _showProductDialog({Map<String, dynamic>? product}) async {
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final descCtrl =
        TextEditingController(text: product?['description'] ?? '');
    final categoryCtrl =
        TextEditingController(text: product?['category'] ?? '');
    final priceDetailCtrl = TextEditingController(
        text: (product?['price_detail'] ?? '').toString());
    final priceGrosCtrl =
        TextEditingController(text: (product?['price_gros'] ?? '').toString());
    final grosThresholdCtrl = TextEditingController(
        text: (product?['gros_threshold_qty'] ?? 10).toString());
    final stockCtrl =
        TextEditingController(text: (product?['stock_quantity'] ?? 0).toString());

    String? selectedUnitId = product?['business_unit_id'] ??
        (_businessUnits.isNotEmpty ? _businessUnits.first['id'] : null);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Modifier le produit' : 'Nouveau produit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom du produit'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                ),
                const SizedBox(height: 12),
                const Text('Pilier d\'entreprise'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: _businessUnits.map((u) {
                    return ChoiceChip(
                      label: Text(u['name']),
                      selected: selectedUnitId == u['id'],
                      onSelected: (_) {
                        setDialogState(() => selectedUnitId = u['id']);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceDetailCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Prix Détail (Ar)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priceGrosCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Prix Gros (Ar)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: grosThresholdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Seuil quantité pour prix Gros',
                    helperText:
                        'Au-delà de cette quantité commandée, le prix Gros s\'applique automatiquement',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock actuel'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;

                final payload = {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'category': categoryCtrl.text.trim(),
                  'business_unit_id': selectedUnitId,
                  'price_detail':
                      double.tryParse(priceDetailCtrl.text) ?? 0,
                  'price_gros': double.tryParse(priceGrosCtrl.text) ?? 0,
                  'gros_threshold_qty':
                      int.tryParse(grosThresholdCtrl.text) ?? 10,
                  'stock_quantity': double.tryParse(stockCtrl.text) ?? 0,
                };

                try {
                  if (isEditing) {
                    await SupabaseConfig.client
                        .from('products')
                        .update(payload)
                        .eq('id', product['id']);
                  } else {
                    await SupabaseConfig.client
                        .from('products')
                        .insert(payload);
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'enregistrement.')),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBatch(Map<String, dynamic> product) async {
    final batchNumberCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    DateTime manufactureDate = DateTime.now();
    DateTime? expiryDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Nouveau lot — ${product['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: batchNumberCtrl,
                decoration: const InputDecoration(labelText: 'Numéro de lot'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantité'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    'Fabrication : ${DateFormat('dd/MM/yyyy').format(manufactureDate)}'),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: manufactureDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => manufactureDate = picked);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(expiryDate == null
                    ? 'DLC (optionnel)'
                    : 'DLC : ${DateFormat('dd/MM/yyyy').format(expiryDate!)}'),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => expiryDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (batchNumberCtrl.text.trim().isEmpty) return;
                try {
                  await SupabaseConfig.client.from('production_batches').insert({
                    'product_id': product['id'],
                    'batch_number': batchNumberCtrl.text.trim(),
                    'manufacture_date':
                        manufactureDate.toIso8601String().split('T').first,
                    'expiry_date':
                        expiryDate?.toIso8601String().split('T').first,
                    'quantity': double.tryParse(quantityCtrl.text) ?? 0,
                  });
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lot enregistré.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'enregistrement du lot.')),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Produits (Gros / Détail)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Produit'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _products.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            Center(
                              child: Text(
                                'Aucun produit pour le moment.\nAppuyez sur "+" pour en créer un.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _products.length,
                          separatorBuilder: (_, __) => SizedBox(height: 1.h),
                          itemBuilder: (context, index) {
                            final p = _products[index];
                            final lowStock = (p['stock_quantity'] ?? 0) <=
                                (p['low_stock_threshold'] ?? 5);
                            return Card(
                              child: Padding(
                                padding: EdgeInsets.all(3.w),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p['name'] ?? '',
                                            style: theme.textTheme.titleMedium,
                                          ),
                                        ),
                                        if (lowStock)
                                          Chip(
                                            label: const Text('Stock bas'),
                                            backgroundColor:
                                                theme.colorScheme.errorContainer,
                                            labelStyle: TextStyle(
                                                color: theme
                                                    .colorScheme.onErrorContainer,
                                                fontSize: 11),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      'Détail : ${_currency.format(p['price_detail'] ?? 0)}  ·  '
                                      'Gros (≥${p['gros_threshold_qty']}) : ${_currency.format(p['price_gros'] ?? 0)}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      'Stock : ${p['stock_quantity']}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    SizedBox(height: 1.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _addBatch(p),
                                          icon: const Icon(Icons.inventory_2_outlined,
                                              size: 18),
                                          label: const Text('Lot'),
                                        ),
                                        TextButton.icon(
                                          onPressed: () =>
                                              _showProductDialog(product: p),
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 18),
                                          label: const Text('Modifier'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
