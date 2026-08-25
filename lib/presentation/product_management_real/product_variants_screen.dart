import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
      // Formats/parfums/concentrations passent par le cache partagé
      // (rarement modifiés — voir
      // lib/core/reference_data/reference_table_cache.dart) plutôt qu'une
      // requête dédiée à chaque ouverture de cet écran.
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('product_variants')
            .select('*, formats(name), parfums(name), concentrations(name)')
            .eq('product_id', widget.product['id'])
            .order('created_at'),
        ref.read(formatsCacheProvider.notifier).refresh(),
        ref.read(parfumsCacheProvider.notifier).refresh(),
        ref.read(concentrationsCacheProvider.notifier).refresh(),
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
      // format/parfum/concentration fraîchement créé(e) apparaisse
      // immédiatement dans le menu déroulant, plutôt que d'attendre 6h.
      final notifier = switch (table) {
        'formats' => ref.read(formatsCacheProvider.notifier),
        'parfums' => ref.read(parfumsCacheProvider.notifier),
        _ => ref.read(concentrationsCacheProvider.notifier),
      };
      await notifier.refresh(force: true);
      return result['id'] as String;
    } catch (e) {
      return null;
    }
  }

  /// Multiplicateur du format sélectionné (`formats.base_unit_quantity`,
  /// voir phase172) — null si le format n'en a pas (formats existants
  /// avant cette fonctionnalité, ex. "100 ml"), auquel cas le calcul
  /// automatique n'est simplement pas proposé pour ce format.
  num? _baseUnitQuantityFor(String? formatId) {
    if (formatId == null) return null;
    final format = ref.read(formatsCacheProvider).firstWhere(
          (f) => f['id'] == formatId,
          orElse: () => <String, dynamic>{},
        );
    return format['base_unit_quantity'] as num?;
  }

  Future<void> _showVariantDialog({Map<String, dynamic>? variant}) async {
    final isEditing = variant != null;
    String? selectedFormatId = variant?['format_id'];
    String? selectedParfumId = variant?['parfum_id'];
    String? selectedConcentrationId = variant?['concentration_id'];
    final priceDetailCtrl = TextEditingController(
        text: (variant?['price_detail'] ?? '').toString());
    final priceGrosCtrl =
        TextEditingController(text: (variant?['price_gros'] ?? '').toString());
    final grosThresholdCtrl = TextEditingController(
        text: (variant?['gros_threshold_qty'] ?? 10).toString());
    final stockCtrl = TextEditingController(
        text: (variant?['stock_quantity'] ?? 0).toString());
    // Photo propre à la variante (25/08, demande explicite : étiquette
    // différente par degré/concentration, ex. Eau de Javel 9°/12°/18°) —
    // distincte des photos du produit lui-même (product_images). `pickedPhoto`
    // = fraîchement sélectionnée, pas encore uploadée ; `currentImageUrl` =
    // celle qui sera effectivement enregistrée (existante, remplacée, ou
    // effacée par l'utilisateur) — toujours envoyée telle quelle dans le
    // payload, ce qui gère uniformément création, édition sans changement,
    // remplacement et suppression.
    XFile? pickedPhoto;
    String? currentImageUrl = variant?['image_url'] as String?;

    // Prix de base du produit (ses propres price_detail/price_gros, pas
    // ceux d'une variante) — sert de référence au calcul automatique
    // ci-dessous : "prix de base x multiplicateur du format".
    final basePriceDetail =
        (widget.product['price_detail'] as num?)?.toDouble() ?? 0;
    final basePriceGros =
        (widget.product['price_gros'] as num?)?.toDouble() ?? 0;

    void applyAutoCalc(void Function(void Function()) setDialogState) {
      final multiplier = _baseUnitQuantityFor(selectedFormatId);
      if (multiplier == null) return;
      setDialogState(() {
        priceDetailCtrl.text = (basePriceDetail * multiplier).toString();
        priceGrosCtrl.text = (basePriceGros * multiplier).toString();
      });
    }

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
                        onChanged: (v) {
                          setDialogState(() => selectedFormatId = v);
                          // Pré-remplissage automatique uniquement à la
                          // création (jamais en édition, pour ne jamais
                          // écraser un prix déjà ajusté manuellement) et
                          // seulement si le format a un multiplicateur
                          // connu (voir _baseUnitQuantityFor).
                          if (!isEditing) applyAutoCalc(setDialogState);
                        },
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
                        decoration:
                            const InputDecoration(labelText: 'Parfum (optionnel)'),
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
                // Axe dédié (25/08) : distinct de Parfum pour ne jamais
                // mélanger senteurs (Liquide Vaisselle, Lave-sol...) et
                // concentrations/degrés (Eau de Javel, Peroxyde
                // d'hydrogène) dans le même menu déroulant.
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedConcentrationId,
                        decoration: const InputDecoration(
                            labelText: 'Concentration (optionnel)'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Aucune'),
                          ),
                          ...ref.read(concentrationsCacheProvider).map((c) =>
                              DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(c['name']),
                              )),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => selectedConcentrationId = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Ajouter une concentration',
                      onPressed: () async {
                        final id = await _addNewReference(
                            'concentrations', 'Concentration');
                        if (id != null) {
                          setDialogState(() => selectedConcentrationId = id);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text('Photo de la variante (optionnel)',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  Future<void> pick() async {
                    try {
                      final picked =
                          await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setDialogState(() => pickedPhoto = picked);
                      }
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Impossible d\'ouvrir la galerie photo.')),
                      );
                    }
                  }

                  final hasPhoto = pickedPhoto != null || currentImageUrl != null;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: pick,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: hasPhoto
                              ? (pickedPhoto != null
                                  ? Image.file(File(pickedPhoto!.path),
                                      width: 72, height: 72, fit: BoxFit.cover)
                                  : Image.network(currentImageUrl!,
                                      width: 72, height: 72, fit: BoxFit.cover))
                              : Container(
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
                        if (hasPhoto)
                          Positioned(
                            top: -8,
                            right: -8,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, size: 20),
                              onPressed: () => setDialogState(() {
                                pickedPhoto = null;
                                currentImageUrl = null;
                              }),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
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
                // Recalcul manuel (14/08) — au cas où l'auto-remplissage à
                // la sélection du format ne suffit pas (variante déjà
                // existante, ou prix modifié entre-temps sur le produit).
                // Masqué si le format choisi n'a pas de multiplicateur
                // connu (formats.base_unit_quantity, voir phase172).
                if (_baseUnitQuantityFor(selectedFormatId) != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => applyAutoCalc(setDialogState),
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: const Text(
                          'Calculer depuis le prix de base du produit'),
                    ),
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
                if (selectedFormatId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Choisissez un format avant d\'enregistrer.')),
                  );
                  return;
                }
                try {
                  // Upload de la photo AVANT de construire le payload (elle
                  // doit être terminée pour connaître l'URL finale à
                  // enregistrer) — même bucket `products` que les photos du
                  // produit lui-même, sous-dossier dédié pour ne jamais
                  // entrer en conflit de nom de fichier.
                  if (pickedPhoto != null) {
                    final file = File(pickedPhoto!.path);
                    final fileName =
                        '${widget.product['id']}/variants/${DateTime.now().millisecondsSinceEpoch}.jpg';
                    await SupabaseConfig.client.storage
                        .from('products')
                        .upload(fileName, file);
                    currentImageUrl = SupabaseConfig.client.storage
                        .from('products')
                        .getPublicUrl(fileName);
                  }
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Erreur lors de l\'envoi de la photo.')),
                  );
                  return;
                }
                final payload = {
                  'product_id': widget.product['id'],
                  'format_id': selectedFormatId,
                  'parfum_id': selectedParfumId,
                  'concentration_id': selectedConcentrationId,
                  'price_detail': double.tryParse(priceDetailCtrl.text) ?? 0,
                  'price_gros': double.tryParse(priceGrosCtrl.text) ?? 0,
                  'gros_threshold_qty':
                      int.tryParse(grosThresholdCtrl.text) ?? 10,
                  'stock_quantity': double.tryParse(stockCtrl.text) ?? 0,
                  'image_url': currentImageUrl,
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
                            'Erreur (cette combinaison Format+Parfum+Concentration existe peut-être déjà).')),
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
                    final concentrationName = v['concentrations']?['name'];
                    final imageUrl = v['image_url'] as String?;
                    return Card(
                      child: ListTile(
                        leading: imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  imageUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : null,
                        title: Text(
                          [formatName, parfumName, concentrationName]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(' · '),
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
