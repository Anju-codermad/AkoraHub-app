import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/reference_data/reference_table_cache.dart';
import '../../core/supabase/supabase_config.dart';

/// Gestion des variantes d'un produit (combinaisons Format x Parfum),
/// chacune avec son propre prix Gros/Détail et son propre stock.
class ProductVariantsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;

  const ProductVariantsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductVariantsScreen> createState() =>
      _ProductVariantsScreenState();
}

class _ProductVariantsScreenState
    extends ConsumerState<ProductVariantsScreen> {
  List<Map<String, dynamic>> _variants = [];
  bool _isLoading = true;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      // Formats/parfums passent par le cache partagé (rarement modifiés —
      // voir lib/core/reference_data/reference_table_cache.dart) plutôt
      // qu'une requête dédiée à chaque ouverture de cet écran.
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('product_variants')
            .select('*, formats(name), parfums(name)')
            .eq('product_id', widget.product['id'])
            .order('created_at'),
        ref.read(formatsCacheProvider.notifier).refresh(),
        ref.read(parfumsCacheProvider.notifier).refresh(),
      ]);
      setState(() {
        _variants = List<Map<String, dynamic>>.from(results[0]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du chargement.')),
      );
    }
  }

  Future<String?> _addNewReference(String table, String label) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nouveau $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return null;

    try {
      final result = await SupabaseConfig.client
          .from(table)
          .insert({'name': name})
          .select()
          .single();
      // Invalide le cache partagé (force: true, ignore le TTL) pour que ce
      // format/parfum fraîchement créé apparaisse immédiatement dans le
      // menu déroulant, plutôt que d'attendre jusqu'à 6h.
      final notifier = table == 'formats'
          ? ref.read(formatsCacheProvider.notifier)
          : ref.read(parfumsCacheProvider.notifier);
      await notifier.refresh(force: true);
      return result['id'] as String;
    } catch (e) {
      return null;
    }
  }

  Future<void> _showVariantDialog({Map<String, dynamic>? variant}) async {
    final isEditing = variant != null;
    String? selectedFormatId = variant?['format_id'];
    String? selectedParfumId = variant?['parfum_id'];
    final priceDetailCtrl = TextEditingController(
        text: (variant?['price_detail'] ?? '').toString());
    final priceGrosCtrl =
        TextEditingController(text: (variant?['price_gros'] ?? '').toString());
    final grosThresholdCtrl = TextEditingController(
        text: (variant?['gros_threshold_qty'] ?? 10).toString());
    final stockCtrl = TextEditingController(
        text: (variant?['stock_quantity'] ?? 0).toString());

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Modifier la variante' : 'Nouvelle variante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedFormatId,
                        decoration: const InputDecoration(labelText: 'Format'),
                        items: ref
                            .read(formatsCacheProvider)
                            .map((f) => DropdownMenuItem(
                                  value: f['id'] as String,
                                  child: Text(f['name']),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedFormatId = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Ajouter un format',
                      onPressed: () async {
                        final id = await _addNewReference('formats', 'Format');
                        if (id != null) {
                          setDialogState(() => selectedFormatId = id);
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedParfumId,
                        decoration: const InputDecoration(
                            labelText: 'Parfum (optionnel)'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Aucun'),
                          ),
                          ...ref.read(parfumsCacheProvider).map((p) =>
                              DropdownMenuItem(
                                value: p['id'] as String,
                                child: Text(p['name']),
                              )),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedParfumId = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Ajouter un parfum',
                      onPressed: () async {
                        final id = await _addNewReference('parfums', 'Parfum');
                        if (id != null) {
                          setDialogState(() => selectedParfumId = id);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceDetailCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Prix Détail'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priceGrosCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Prix Gros'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: grosThresholdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Seuil quantité pour prix Gros'),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
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
                if (selectedFormatId == null) return;
                final payload = {
                  'product_id': widget.product['id'],
                  'format_id': selectedFormatId,
                  'parfum_id': selectedParfumId,
                  'price_detail': double.tryParse(priceDetailCtrl.text) ?? 0,
                  'price_gros': double.tryParse(priceGrosCtrl.text) ?? 0,
                  'gros_threshold_qty':
                      int.tryParse(grosThresholdCtrl.text) ?? 10,
                  'stock_quantity': double.tryParse(stockCtrl.text) ?? 0,
                };
                try {
                  if (isEditing) {
                    await SupabaseConfig.client
                        .from('product_variants')
                        .update(payload)
                        .eq('id', variant['id']);
                  } else {
                    await SupabaseConfig.client
                        .from('product_variants')
                        .insert(payload);
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadAll();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Erreur (cette combinaison Format+Parfum existe peut-être déjà).')),
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

  Future<void> _deleteVariant(String id) async {
    try {
      await SupabaseConfig.client
          .from('product_variants')
          .delete()
          .eq('id', id);
      _loadAll();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Variantes — ${widget.product['name']}'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVariantDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Variante'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _variants.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Text(
                      'Aucune variante pour le moment.\nAjoutez un format (et un parfum si besoin) avec son propre prix.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _variants.length,
                  separatorBuilder: (_, __) => SizedBox(height: 1.h),
                  itemBuilder: (context, index) {
                    final v = _variants[index];
                    final formatName = v['formats']?['name'] ?? '';
                    final parfumName = v['parfums']?['name'];
                    return Card(
                      child: ListTile(
                        title: Text(
                          parfumName != null
                              ? '$formatName · $parfumName'
                              : formatName,
                        ),
                        subtitle: Text(
                          'Détail ${_currency.format(v['price_detail'] ?? 0)} · '
                          'Gros ${_currency.format(v['price_gros'] ?? 0)} · '
                          'Stock ${v['stock_quantity']}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () =>
                                  _showVariantDialog(variant: v),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _deleteVariant(v['id']),
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
