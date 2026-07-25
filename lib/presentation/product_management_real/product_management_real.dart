import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';
import 'product_variants_screen.dart';

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
  List<Map<String, dynamic>> _categories = [];
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
      List<Map<String, dynamic>> categories = [];
      try {
        final result = await SupabaseConfig.client
            .from('categories')
            .select()
            .order('name');
        categories = List<Map<String, dynamic>>.from(result);
      } catch (_) {
        // Table `categories` pas encore créée (migration phase6 non
        // exécutée) : on continue sans bloquer le reste de l'écran.
      }
      setState(() {
        _products = List<Map<String, dynamic>>.from(products);
        _businessUnits = List<Map<String, dynamic>>.from(units);
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les produits.';
      });
    }
  }

  Future<String?> _addNewCategory(String businessUnitId) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
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
          .from('categories')
          .insert({'business_unit_id': businessUnitId, 'name': name})
          .select()
          .single();
      setState(() {
        _categories = [..._categories, Map<String, dynamic>.from(result)];
      });
      return name;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Erreur — cette catégorie existe peut-être déjà pour ce pilier.')),
      );
      return null;
    }
  }

  Future<void> _showProductDialog({Map<String, dynamic>? product}) async {
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final descCtrl =
        TextEditingController(text: product?['description'] ?? '');
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

    // La catégorie est stockée en texte sur `products.category` (compatible
    // avec les anciens produits créés avant la table `categories`), mais on
    // la choisit désormais dans un menu déroulant scopé au pilier plutôt que
    // de la retaper à la main (évite les fautes de frappe qui cassent le
    // regroupement des filtres côté client).
    String? selectedCategoryName = product?['category'];

    // Galerie photo (jusqu'à 10). `existingPhotos` = déjà en base (si
    // édition) ; `newPhotos` = fraîchement sélectionnées, pas encore
    // uploadées ; `removedExistingIds` = existantes marquées à supprimer.
    List<Map<String, dynamic>> existingPhotos = [];
    if (isEditing) {
      try {
        final result = await SupabaseConfig.client
            .from('product_images')
            .select()
            .eq('product_id', product['id'])
            .order('position');
        existingPhotos = List<Map<String, dynamic>>.from(result);
      } catch (_) {
        // Table `product_images` pas encore créée (migration phase8 non
        // exécutée) : on continue sans bloquer l'édition du produit.
      }
    }
    final List<XFile> newPhotos = [];
    final removedExistingIds = <String>{};
    bool isSaving = false;

    if (!mounted) return;
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
                const SizedBox(height: 12),
                Text('Photos (jusqu\'à 10, optionnel)',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final keptExisting = existingPhotos
                      .where((p) => !removedExistingIds.contains(p['id']))
                      .toList();
                  final totalCount = keptExisting.length + newPhotos.length;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final photo in keptExisting)
                        _PhotoThumb(
                          image: NetworkImage(photo['image_url'] as String),
                          onRemove: () => setDialogState(
                              () => removedExistingIds.add(photo['id'])),
                        ),
                      for (var i = 0; i < newPhotos.length; i++)
                        _PhotoThumb(
                          image: FileImage(File(newPhotos[i].path)),
                          onRemove: () =>
                              setDialogState(() => newPhotos.removeAt(i)),
                        ),
                      if (totalCount < 10)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final remaining = 10 - totalCount;
                            try {
                              final picked = await ImagePicker()
                                  .pickMultiImage(limit: remaining);
                              if (picked.isEmpty) return;
                              setDialogState(() {
                                newPhotos.addAll(
                                    picked.take(remaining).toList());
                              });
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Impossible d\'ouvrir la galerie photo.')),
                              );
                            }
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final categoriesForUnit = _categories
                      .where((c) =>
                          c['business_unit_id'] == selectedUnitId &&
                          c['active'] != false)
                      .toList();
                  // Si la catégorie du produit édité n'existe plus dans la
                  // liste (pilier changé, catégorie supprimée...), on évite
                  // de planter le Dropdown en la proposant quand même.
                  final items = <String>{
                    ...categoriesForUnit.map((c) => c['name'] as String),
                    if (selectedCategoryName != null &&
                        selectedCategoryName!.isNotEmpty)
                      selectedCategoryName!,
                  }.toList();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCategoryName,
                          decoration: const InputDecoration(
                              labelText: 'Catégorie (optionnel)'),
                          items: items
                              .map((name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedCategoryName = v),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Ajouter une catégorie',
                        onPressed: selectedUnitId == null
                            ? null
                            : () async {
                                final name =
                                    await _addNewCategory(selectedUnitId!);
                                if (name != null) {
                                  setDialogState(
                                      () => selectedCategoryName = name);
                                }
                              },
                      ),
                    ],
                  );
                }),
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
                        setDialogState(() {
                          selectedUnitId = u['id'];
                          selectedCategoryName = null;
                        });
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
              onPressed: isSaving
                  ? null
                  : () async {
                if (nameCtrl.text.trim().isEmpty) return;
                // Verrou anti-double-clic : sans ça, un appui multiple
                // pendant l'upload des photos (qui peut prendre plusieurs
                // secondes) créait plusieurs produits identiques.
                if (isSaving) return;
                setDialogState(() => isSaving = true);

                final payload = {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'category': selectedCategoryName ?? '',
                  'business_unit_id': selectedUnitId,
                  'price_detail':
                      double.tryParse(priceDetailCtrl.text) ?? 0,
                  'price_gros': double.tryParse(priceGrosCtrl.text) ?? 0,
                  'gros_threshold_qty':
                      int.tryParse(grosThresholdCtrl.text) ?? 10,
                  'stock_quantity': double.tryParse(stockCtrl.text) ?? 0,
                };

                try {
                  String productId;
                  if (isEditing) {
                    productId = product['id'] as String;
                    await SupabaseConfig.client
                        .from('products')
                        .update(payload)
                        .eq('id', productId);
                  } else {
                    final inserted = await SupabaseConfig.client
                        .from('products')
                        .insert(payload)
                        .select()
                        .single();
                    productId = inserted['id'] as String;
                  }

                  // La galerie photo est gérée dans un try/catch séparé :
                  // si la migration `phase8_patch_product_images.sql` n'a
                  // pas encore été exécutée (table/bucket absents), le
                  // produit lui-même doit quand même s'enregistrer plutôt
                  // que d'afficher une fausse erreur globale.
                  var photosFailed = false;
                  if (newPhotos.isNotEmpty || removedExistingIds.isNotEmpty) {
                    try {
                      // Upload des nouvelles photos vers le bucket `products`.
                      final uploadedUrls = <String>[];
                      for (var i = 0; i < newPhotos.length; i++) {
                        final file = File(newPhotos[i].path);
                        final fileName =
                            '$productId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
                        await SupabaseConfig.client.storage
                            .from('products')
                            .upload(fileName, file);
                        uploadedUrls.add(SupabaseConfig.client.storage
                            .from('products')
                            .getPublicUrl(fileName));
                      }

                      // Suppression des fichiers retirés (best-effort).
                      for (final photo in existingPhotos) {
                        if (!removedExistingIds.contains(photo['id'])) {
                          continue;
                        }
                        try {
                          final url = photo['image_url'] as String;
                          final path = url.split('/products/').last;
                          await SupabaseConfig.client.storage
                              .from('products')
                              .remove([path]);
                        } catch (_) {}
                      }

                      // On réécrit la galerie au complet (existantes
                      // conservées + nouvelles) avec des positions propres
                      // 0..n-1 — plus simple qu'un update partiel vu le
                      // petit nombre de lignes (≤10).
                      await SupabaseConfig.client
                          .from('product_images')
                          .delete()
                          .eq('product_id', productId);
                      final keptUrls = existingPhotos
                          .where(
                              (p) => !removedExistingIds.contains(p['id']))
                          .map((p) => p['image_url'] as String)
                          .toList();
                      final finalUrls = [...keptUrls, ...uploadedUrls];
                      if (finalUrls.isNotEmpty) {
                        await SupabaseConfig.client
                            .from('product_images')
                            .insert([
                          for (var i = 0; i < finalUrls.length; i++)
                            {
                              'product_id': productId,
                              'image_url': finalUrls[i],
                              'position': i,
                            },
                        ]);
                      }
                      // La 1ère photo sert de couverture pour les vignettes
                      // catalogue (products.image_url).
                      await SupabaseConfig.client.from('products').update({
                        'image_url':
                            finalUrls.isNotEmpty ? finalUrls.first : null,
                      }).eq('id', productId);
                    } catch (_) {
                      photosFailed = true;
                    }
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                  if (photosFailed) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Produit enregistré, mais les photos n\'ont pas pu être sauvegardées.')));
                  }
                } catch (e) {
                  if (!mounted) return;
                  setDialogState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'enregistrement.')),
                  );
                }
              },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text(
          '"${product['name']}" sera définitivement supprimé, ainsi que ses variantes, lots et photos associés. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseConfig.client
          .from('products')
          .delete()
          .eq('id', product['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit supprimé.')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Erreur lors de la suppression (le produit a peut-être déjà des commandes liées).')),
      );
    }
  }

  Future<void> _addBatch(Map<String, dynamic> product) async {
    final batchNumberCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    DateTime manufactureDate = DateTime.now();
    DateTime? expiryDate;
    bool isSavingBatch = false;

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
              onPressed: isSavingBatch
                  ? null
                  : () async {
                if (batchNumberCtrl.text.trim().isEmpty) return;
                if (isSavingBatch) return;
                setDialogState(() => isSavingBatch = true);
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
                  setDialogState(() => isSavingBatch = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'enregistrement du lot.')),
                  );
                }
              },
              child: isSavingBatch
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
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
                                        FilledButton.tonalIcon(
                                          onPressed: () =>
                                              _showProductDialog(product: p),
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 18),
                                          label: const Text('Modifier'),
                                        ),
                                        SizedBox(width: 2.w),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (value) {
                                            if (value == 'variantes') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ProductVariantsScreen(
                                                          product: p),
                                                ),
                                              );
                                            } else if (value == 'lot') {
                                              _addBatch(p);
                                            } else if (value == 'supprimer') {
                                              _deleteProduct(p);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'variantes',
                                              child: Row(children: [
                                                Icon(Icons.tune, size: 18),
                                                SizedBox(width: 8),
                                                Text('Variantes'),
                                              ]),
                                            ),
                                            const PopupMenuItem(
                                              value: 'lot',
                                              child: Row(children: [
                                                Icon(
                                                    Icons
                                                        .inventory_2_outlined,
                                                    size: 18),
                                                SizedBox(width: 8),
                                                Text('Ajouter un lot'),
                                              ]),
                                            ),
                                            const PopupMenuDivider(),
                                            PopupMenuItem(
                                              value: 'supprimer',
                                              child: Row(children: [
                                                Icon(Icons.delete_outline,
                                                    size: 18,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error),
                                                const SizedBox(width: 8),
                                                Text('Supprimer',
                                                    style: TextStyle(
                                                        color: Theme.of(
                                                                context)
                                                            .colorScheme
                                                            .error)),
                                              ]),
                                            ),
                                          ],
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

/// Miniature de photo produit avec bouton de suppression, utilisée dans le
/// formulaire d'ajout/édition (aussi bien pour les photos déjà en base que
/// pour celles fraîchement sélectionnées, pas encore uploadées).
class _PhotoThumb extends StatelessWidget {
  final ImageProvider image;
  final VoidCallback onRemove;

  const _PhotoThumb({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: image, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: Colors.black87,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
