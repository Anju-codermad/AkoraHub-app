import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/reference_data/reference_table_cache.dart';
import '../../core/supabase/supabase_config.dart';
import 'raw_material_style.dart';

/// Fiche complète d'une matière première (Formation) — description,
/// dosages d'usage par domaine, conditionnement, historique de prix et
/// galerie photo. Voir supabase/phase40_schema.sql pour le schéma complet.
class RawMaterialEditorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? material;

  const RawMaterialEditorScreen({super.key, this.material});

  @override
  ConsumerState<RawMaterialEditorScreen> createState() =>
      _RawMaterialEditorScreenState();
}

class _RawMaterialEditorScreenState
    extends ConsumerState<RawMaterialEditorScreen> {
  final _currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _safetyCtrl;
  late final TextEditingController _priceCtrl;

  List<Map<String, dynamic>> _businessUnits = [];
  List<Map<String, dynamic>> _nameSuggestions = [];
  List<Map<String, dynamic>> _products = [];
  String? _selectedUnitId;
  String? _selectedCategoryName;
  String _stockStatus = 'en_stock';
  String? _suggestionNote;

  List<Map<String, dynamic>> _usages = [];
  List<Map<String, dynamic>> _packaging = [];
  List<Map<String, dynamic>> _priceHistory = [];

  List<Map<String, dynamic>> _existingPhotos = [];
  final List<XFile> _newPhotos = [];
  final Set<String> _removedExistingPhotoIds = {};

  num? _originalPrice;
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditing => widget.material != null;

  @override
  void initState() {
    super.initState();
    final m = widget.material;
    _nameCtrl = TextEditingController(text: m?['name'] ?? '');
    _descCtrl = TextEditingController(text: m?['description'] ?? '');
    _safetyCtrl = TextEditingController(text: m?['safety_note'] ?? '');
    _priceCtrl =
        TextEditingController(text: (m?['current_price'] ?? '').toString());
    _selectedUnitId = m?['business_unit_id'];
    _selectedCategoryName = m?['category_name'];
    _stockStatus = m?['stock_status'] ?? 'en_stock';
    _originalPrice = m?['current_price'] as num?;
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _safetyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client.from('business_units').select(),
        SupabaseConfig.client
            .from('raw_material_name_suggestions')
            .select()
            .order('name'),
        SupabaseConfig.client.from('products').select('id, name').order('name'),
      ]);
      await ref.read(categoriesCacheProvider.notifier).refresh();

      _businessUnits = List<Map<String, dynamic>>.from(results[0] as List);
      _nameSuggestions = List<Map<String, dynamic>>.from(results[1] as List);
      _products = List<Map<String, dynamic>>.from(results[2] as List);
      _selectedUnitId ??=
          _businessUnits.isNotEmpty ? _businessUnits.first['id'] : null;

      if (_isEditing) {
        final id = widget.material!['id'];
        final childResults = await Future.wait<dynamic>([
          SupabaseConfig.client
              .from('raw_material_images')
              .select()
              .eq('raw_material_id', id)
              .order('position'),
          SupabaseConfig.client
              .from('raw_material_usages')
              .select('*, products(name)')
              .eq('raw_material_id', id)
              .order('sort_order'),
          SupabaseConfig.client
              .from('raw_material_packaging')
              .select()
              .eq('raw_material_id', id)
              .order('sort_order'),
          SupabaseConfig.client
              .from('raw_material_price_history')
              .select()
              .eq('raw_material_id', id)
              .order('recorded_at', ascending: false),
        ]);
        _existingPhotos = List<Map<String, dynamic>>.from(childResults[0]);
        _usages = List<Map<String, dynamic>>.from(childResults[1]);
        _packaging = List<Map<String, dynamic>>.from(childResults[2]);
        _priceHistory = List<Map<String, dynamic>>.from(childResults[3]);
      }
    } catch (_) {
      // Repli tolérant : la fiche reste éditable même si une des tables
      // enfant (phase40 pas encore exécutée) ne répond pas.
    }
    if (mounted) setState(() => _isLoading = false);
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
      await SupabaseConfig.client
          .from('categories')
          .insert({'business_unit_id': businessUnitId, 'name': name});
      await ref.read(categoriesCacheProvider.notifier).refresh(force: true);
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

  void _addUsageRow() {
    setState(() {
      _usages.add({
        'domain': rawMaterialUsageDomains.first,
        'product_id': null,
        'usage_label': '',
        'dosage': '',
      });
    });
  }

  void _addPackagingRow() {
    setState(() {
      _packaging.add({'label': '', 'price': null});
    });
  }

  Future<void> _addPriceHistoryEntry() async {
    if (!_isEditing) return;
    final priceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime date = DateTime.now();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter un ancien prix'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Prix (Ar)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Note (optionnel)'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(_dateFormat.format(date))),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2015),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => date = picked);
                      }
                    },
                    child: const Text('Changer la date'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    final price = double.tryParse(priceCtrl.text);
    if (price == null) return;
    try {
      final inserted = await SupabaseConfig.client
          .from('raw_material_price_history')
          .insert({
            'raw_material_id': widget.material!['id'],
            'price': price,
            'recorded_at': date.toIso8601String().split('T').first,
            'note': noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
          })
          .select()
          .single();
      if (!mounted) return;
      setState(() {
        _priceHistory = [inserted, ..._priceHistory]
          ..sort((a, b) =>
              (b['recorded_at'] as String).compareTo(a['recorded_at'] as String));
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Impossible d\'ajouter cette entrée (migration phase40 pas encore exécutée ?).')));
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Le nom et le pilier sont obligatoires.')));
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final newPrice = double.tryParse(_priceCtrl.text);
    final payload = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      'safety_note':
          _safetyCtrl.text.trim().isEmpty ? null : _safetyCtrl.text.trim(),
      'category_name': _selectedCategoryName ?? '',
      'business_unit_id': _selectedUnitId,
      'stock_status': _stockStatus,
      'current_price': newPrice,
    };

    try {
      String materialId;
      if (_isEditing) {
        materialId = widget.material!['id'] as String;
        await SupabaseConfig.client
            .from('raw_materials')
            .update(payload)
            .eq('id', materialId);
      } else {
        final inserted = await SupabaseConfig.client
            .from('raw_materials')
            .insert(payload)
            .select()
            .single();
        materialId = inserted['id'] as String;
      }

      // Historique de prix automatique : si le prix a changé depuis
      // l'ouverture de la fiche, on garde une trace datée du jour — en
      // plus des entrées manuelles ajoutées via "Ajouter un ancien prix".
      if (newPrice != null && newPrice != _originalPrice) {
        try {
          await SupabaseConfig.client.from('raw_material_price_history').insert({
            'raw_material_id': materialId,
            'price': newPrice,
            'recorded_at': DateTime.now().toIso8601String().split('T').first,
          });
        } catch (_) {}
      }

      // Photos : même mécanique que product_images (phase8) — réécriture
      // complète de la galerie, bucket dédié `raw-materials`.
      var photosFailed = false;
      if (_newPhotos.isNotEmpty || _removedExistingPhotoIds.isNotEmpty) {
        try {
          final uploadedUrls = <String>[];
          for (var i = 0; i < _newPhotos.length; i++) {
            final file = File(_newPhotos[i].path);
            final fileName =
                '$materialId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            await SupabaseConfig.client.storage
                .from('raw-materials')
                .upload(fileName, file);
            uploadedUrls.add(SupabaseConfig.client.storage
                .from('raw-materials')
                .getPublicUrl(fileName));
          }
          for (final photo in _existingPhotos) {
            if (!_removedExistingPhotoIds.contains(photo['id'])) continue;
            try {
              final url = photo['image_url'] as String;
              final path = url.split('/raw-materials/').last;
              await SupabaseConfig.client.storage
                  .from('raw-materials')
                  .remove([path]);
            } catch (_) {}
          }
          await SupabaseConfig.client
              .from('raw_material_images')
              .delete()
              .eq('raw_material_id', materialId);
          final keptUrls = _existingPhotos
              .where((p) => !_removedExistingPhotoIds.contains(p['id']))
              .map((p) => p['image_url'] as String)
              .toList();
          final finalUrls = [...keptUrls, ...uploadedUrls];
          if (finalUrls.isNotEmpty) {
            await SupabaseConfig.client.from('raw_material_images').insert([
              for (var i = 0; i < finalUrls.length; i++)
                {
                  'raw_material_id': materialId,
                  'image_url': finalUrls[i],
                  'position': i,
                },
            ]);
          }
          await SupabaseConfig.client.from('raw_materials').update({
            'image_url': finalUrls.isNotEmpty ? finalUrls.first : null,
          }).eq('id', materialId);
        } catch (_) {
          photosFailed = true;
        }
      }

      // Usages et conditionnement : réécriture complète (petit nombre de
      // lignes par fiche), plus simple qu'un diff ligne à ligne.
      await SupabaseConfig.client
          .from('raw_material_usages')
          .delete()
          .eq('raw_material_id', materialId);
      final validUsages = _usages
          .where((u) =>
              u['product_id'] != null ||
              (u['usage_label'] as String? ?? '').trim().isNotEmpty)
          .toList();
      if (validUsages.isNotEmpty) {
        await SupabaseConfig.client.from('raw_material_usages').insert([
          for (var i = 0; i < validUsages.length; i++)
            {
              'raw_material_id': materialId,
              'domain': validUsages[i]['domain'],
              'product_id': validUsages[i]['product_id'],
              'usage_label': validUsages[i]['product_id'] != null
                  ? null
                  : (validUsages[i]['usage_label'] as String).trim(),
              'dosage': (validUsages[i]['dosage'] as String? ?? '').trim().isEmpty
                  ? null
                  : (validUsages[i]['dosage'] as String).trim(),
              'sort_order': i,
            },
        ]);
      }

      await SupabaseConfig.client
          .from('raw_material_packaging')
          .delete()
          .eq('raw_material_id', materialId);
      final validPackaging = _packaging
          .where((p) => (p['label'] as String? ?? '').trim().isNotEmpty)
          .toList();
      if (validPackaging.isNotEmpty) {
        await SupabaseConfig.client.from('raw_material_packaging').insert([
          for (var i = 0; i < validPackaging.length; i++)
            {
              'raw_material_id': materialId,
              'label': (validPackaging[i]['label'] as String).trim(),
              'price': validPackaging[i]['price'],
              'sort_order': i,
            },
        ]);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      if (photosFailed) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Fiche enregistrée, mais les photos n\'ont pas pu être sauvegardées.')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Erreur lors de l\'enregistrement (migration phase40 exécutée ?).')));
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette fiche ?'),
        content: Text(
            '"${widget.material!['name']}" sera définitivement supprimée, avec ses photos, usages, conditionnements et historique de prix. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseConfig.client
          .from('raw_materials')
          .delete()
          .eq('id', widget.material!['id']);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Matière première')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final categoriesForUnit = ref
        .watch(categoriesCacheProvider)
        .where((c) =>
            c['business_unit_id'] == _selectedUnitId && c['active'] != false)
        .toList();
    final categoryItems = <String>{
      ...categoriesForUnit.map((c) => c['name'] as String),
      if (_selectedCategoryName != null && _selectedCategoryName!.isNotEmpty)
        _selectedCategoryName!,
    }.toList();

    final selectedSlug = _businessUnits.firstWhere(
      (u) => u['id'] == _selectedUnitId,
      orElse: () => <String, dynamic>{},
    )['slug'];
    final suggestionsForUnit = selectedSlug == null
        ? const <Map<String, dynamic>>[]
        : _nameSuggestions
            .where((s) => s['business_unit_slug'] == selectedSlug)
            .toList();

    final keptPhotos = _existingPhotos
        .where((p) => !_removedExistingPhotoIds.contains(p['id']))
        .toList();
    final totalPhotoCount = keptPhotos.length + _newPhotos.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la fiche' : 'Nouvelle matière première'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Text('Photos (jusqu\'à 10, optionnel)',
              style: theme.textTheme.labelLarge),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final photo in keptPhotos)
                _PhotoThumb(
                  image: NetworkImage(photo['image_url'] as String),
                  onRemove: () => setState(
                      () => _removedExistingPhotoIds.add(photo['id'])),
                ),
              for (var i = 0; i < _newPhotos.length; i++)
                _PhotoThumb(
                  image: FileImage(File(_newPhotos[i].path)),
                  onRemove: () => setState(() => _newPhotos.removeAt(i)),
                ),
              if (totalPhotoCount < 10)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final remaining = 10 - totalPhotoCount;
                    try {
                      final picked =
                          await ImagePicker().pickMultiImage(limit: remaining);
                      if (picked.isEmpty) return;
                      setState(() =>
                          _newPhotos.addAll(picked.take(remaining).toList()));
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Impossible d\'ouvrir la galerie photo.')));
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.trim().isEmpty) {
                return const Iterable<String>.empty();
              }
              final query = textEditingValue.text.toLowerCase();
              return suggestionsForUnit
                  .map((s) => s['name'] as String)
                  .where((n) => n.toLowerCase().contains(query));
            },
            onSelected: (selection) {
              _nameCtrl.text = selection;
              final match = suggestionsForUnit.firstWhere(
                (s) => s['name'] == selection,
                orElse: () => <String, dynamic>{},
              );
              setState(() {
                final matchedCategory = match['category_name'] as String?;
                if (matchedCategory != null &&
                    (_selectedCategoryName == null ||
                        _selectedCategoryName!.isEmpty)) {
                  _selectedCategoryName = matchedCategory;
                }
                _suggestionNote = match['note'] as String?;
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              controller.text = _nameCtrl.text;
              controller.selection =
                  TextSelection.collapsed(offset: controller.text.length);
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(labelText: 'Nom'),
                onChanged: (v) => _nameCtrl.text = v,
              );
            },
          ),
          if (_suggestionNote != null) ...[
            SizedBox(height: 0.5.h),
            Text('Repère (INS) : $_suggestionNote',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ],
          SizedBox(height: 2.h),
          Text('Pilier d\'entreprise', style: theme.textTheme.labelLarge),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 8,
            children: _businessUnits.map((u) {
              return ChoiceChip(
                label: Text(u['name'] ?? ''),
                selected: _selectedUnitId == u['id'],
                onSelected: (_) => setState(() {
                  _selectedUnitId = u['id'];
                  _selectedCategoryName = null;
                }),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryName,
                  decoration:
                      const InputDecoration(labelText: 'Catégorie chimique'),
                  items: categoryItems
                      .map((name) =>
                          DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryName = v),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Ajouter une catégorie',
                onPressed: _selectedUnitId == null
                    ? null
                    : () async {
                        final name = await _addNewCategory(_selectedUnitId!);
                        if (name != null) {
                          setState(() => _selectedCategoryName = name);
                        }
                      },
              ),
            ],
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              helperText:
                  'Rédigée à partir de votre recherche — pas un copier-coller de fiche technique tierce.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _safetyCtrl,
            decoration: const InputDecoration(
              labelText: 'Danger / précaution (optionnel)',
              prefixIcon: Icon(Icons.warning_amber_outlined),
            ),
          ),
          SizedBox(height: 2.h),
          Text('Statut de stock', style: theme.textTheme.labelLarge),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 8,
            children: rawMaterialStockStatuses.map((status) {
              final color = rawMaterialStatusColor(status);
              return ChoiceChip(
                label: Text(rawMaterialStatusLabel(status)),
                selected: _stockStatus == status,
                selectedColor: color.withValues(alpha: 0.25),
                onSelected: (_) => setState(() => _stockStatus = status),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Prix actuel (Ar)'),
          ),
          SizedBox(height: 3.h),
          _SectionHeader(
            title: 'Utilise dans la fabrication de',
            onAdd: _addUsageRow,
          ),
          for (var i = 0; i < _usages.length; i++)
            _UsageRow(
              key: ValueKey('usage-$i-${_usages[i]['id'] ?? ''}'),
              data: _usages[i],
              products: _products,
              onChanged: (v) => setState(() => _usages[i] = v),
              onRemove: () => setState(() => _usages.removeAt(i)),
            ),
          SizedBox(height: 3.h),
          _SectionHeader(
            title: 'Conditionnement',
            onAdd: _addPackagingRow,
          ),
          for (var i = 0; i < _packaging.length; i++)
            _PackagingRow(
              key: ValueKey('pack-$i-${_packaging[i]['id'] ?? ''}'),
              data: _packaging[i],
              onChanged: (v) => setState(() => _packaging[i] = v),
              onRemove: () => setState(() => _packaging.removeAt(i)),
            ),
          SizedBox(height: 3.h),
          _SectionHeader(
            title: 'Historique de prix',
            onAdd: _isEditing ? _addPriceHistoryEntry : null,
          ),
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Enregistrez d\'abord la fiche pour ajouter un historique.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (_priceHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Aucun historique pour le moment.',
                  style: theme.textTheme.bodySmall),
            )
          else
            ..._priceHistory.map((entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timeline_outlined),
                  title: Text(_currency.format(entry['price'])),
                  subtitle: Text([
                    _dateFormat.format(DateTime.parse(entry['recorded_at'])),
                    if (entry['note'] != null) entry['note'],
                  ].join(' · ')),
                )),
          SizedBox(height: 4.h),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;

  const _SectionHeader({required this.title, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (onAdd != null)
          IconButton(
              icon: const Icon(Icons.add_circle_outline), onPressed: onAdd),
      ],
    );
  }
}

class _UsageRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> products;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  const _UsageRow(
      {super.key,
      required this.data,
      required this.products,
      required this.onChanged,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final domain = data['domain'] as String? ?? rawMaterialUsageDomains.first;
    final productId = data['product_id'] as String?;
    // `products(name)` vient de la jointure au chargement d'une fiche
    // existante ; pour une ligne fraîchement ajoutée, le nom est déjà
    // connu localement (choisi via l'Autocomplete ci-dessous).
    final productName = data['_product_name'] as String? ??
        (data['products'] is Map ? data['products']['name'] as String? : null);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Icon(iconForUsageDomain(domain),
                    color: colorForUsageDomain(domain), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: domain,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Domaine'),
                    items: rawMaterialUsageDomains
                        .map((d) =>
                            DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) =>
                        onChanged({...data, 'domain': v ?? domain}),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close), onPressed: onRemove),
              ],
            ),
            if (productId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(productName ?? 'Produit sélectionné')),
                    TextButton(
                      onPressed: () => onChanged({
                        ...data,
                        'product_id': null,
                        '_product_name': null,
                      }),
                      child: const Text('Changer'),
                    ),
                  ],
                ),
              )
            else
              Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (p) => p['name'] as String,
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.trim().isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  final query = textEditingValue.text.toLowerCase();
                  return products.where(
                      (p) => (p['name'] as String).toLowerCase().contains(query));
                },
                onSelected: (selection) => onChanged({
                  ...data,
                  'product_id': selection['id'],
                  '_product_name': selection['name'],
                  'usage_label': null,
                }),
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Produit du catalogue (recommandé)',
                      helperText: 'Recherchez un produit existant à lier',
                    ),
                  );
                },
              ),
            Row(
              children: [
                if (productId == null)
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: data['usage_label'] as String? ?? '',
                      decoration: const InputDecoration(
                          labelText:
                              'Ou texte libre (formule pas encore un produit)'),
                      onChanged: (v) => onChanged({...data, 'usage_label': v}),
                    ),
                  ),
                if (productId == null) const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: data['dosage'] as String? ?? '',
                    decoration:
                        const InputDecoration(labelText: 'Dosage (ex: 10-15%)'),
                    onChanged: (v) => onChanged({...data, 'dosage': v}),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackagingRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  const _PackagingRow(
      {super.key,
      required this.data,
      required this.onChanged,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: data['label'] as String? ?? '',
              decoration: const InputDecoration(
                  labelText: 'Format (ex: 250g, 1kg, Sur demande)'),
              onChanged: (v) => onChanged({...data, 'label': v}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: (data['price'] ?? '').toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Prix (optionnel)'),
              onChanged: (v) =>
                  onChanged({...data, 'price': double.tryParse(v)}),
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
        ],
      ),
    );
  }
}

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
