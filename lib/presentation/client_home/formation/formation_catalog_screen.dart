import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/formation/formation_repo.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/utils/formation_web_link.dart';
import '../../raw_materials_management/raw_material_style.dart';
import 'raw_material_detail_client.dart';

/// Catalogue Formation côté client : liste toujours visible (nom,
/// catégorie, stock, photo) des matières premières — voir
/// supabase/phase40_schema.sql, vue `raw_materials_preview`. Les fiches
/// complètes (description, dosages, conditionnement, prix) s'achètent
/// désormais produit par produit, à vie (voir
/// supabase/phase45_patch_formation_per_product_pricing.sql) ; sinon, un
/// cadenas invite à acheter l'accès.
///
/// Point d'accès unique, indépendant des piliers "Produits" (voir
/// profile_tab.dart) — regroupe les matières premières de tous les
/// piliers (Akora Pro, Peinture Pro, Akora Protect...) au même endroit,
/// plutôt que d'accrocher cette base à un pilier "Produits" détourné de
/// son rôle (décision du 01/08, voir PROJECT_CONTEXT.md).
class FormationCatalogScreen extends StatefulWidget {
  const FormationCatalogScreen({super.key});

  @override
  State<FormationCatalogScreen> createState() => _FormationCatalogScreenState();
}

class _FormationCatalogScreenState extends State<FormationCatalogScreen> {
  List<Map<String, dynamic>> _materials = [];
  Map<String, String> _unitNames = {};
  bool _isLoading = true;
  String? _error;
  String _search = '';
  String _selectedUnitId = 'tous';
  String _selectedCategory = 'toutes';
  Set<String> _ownedIds = {};
  Set<String> _pendingIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client.from('raw_materials_preview').select().order('name'),
        SupabaseConfig.client.from('business_units').select('id, name'),
        FormationRepo.fetchMyPurchasedIds(),
        FormationRepo.fetchMyPendingIds(),
      ]);
      final units = List<Map<String, dynamic>>.from(results[1] as List);
      setState(() {
        _materials = List<Map<String, dynamic>>.from(results[0] as List);
        _unitNames = {
          for (final u in units) u['id'] as String: u['name'] as String? ?? ''
        };
        _ownedIds = results[2] as Set<String>;
        _pendingIds = results[3] as Set<String>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger la base Formation (migration phase40 exécutée ?).';
      });
    }
  }

  List<Map<String, String>> get _units {
    final ids = _materials.map((m) => m['business_unit_id'] as String).toSet();
    final list = ids
        .map((id) => {'id': id, 'name': _unitNames[id] ?? ''})
        .toList();
    list.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    return list;
  }

  List<String> get _categories => _materials
      .where((m) =>
          (_selectedUnitId == 'tous' ||
              _selectedUnitId == 'debloques' ||
              m['business_unit_id'] == _selectedUnitId) &&
          (_selectedUnitId != 'debloques' || _ownedIds.contains(m['id'])))
      .map((m) => m['category_name'] as String? ?? '')
      .toSet()
      .toList()
    ..sort();

  List<Map<String, dynamic>> get _filtered {
    // Vue "Débloqués" : remonte au même niveau que le filtre par pilier
    // plutôt que d'ajouter une rangée de filtres supplémentaire (retour
    // explicite de l'utilisatrice — trop de rangées de puces rend
    // l'écran désorganisé).
    final list = _materials.where((m) {
      final matchesUnit = _selectedUnitId == 'tous' ||
          _selectedUnitId == 'debloques' ||
          m['business_unit_id'] == _selectedUnitId;
      final matchesAccess =
          _selectedUnitId != 'debloques' || _ownedIds.contains(m['id']);
      final matchesCategory = _selectedCategory == 'toutes' ||
          m['category_name'] == _selectedCategory;
      final matchesSearch = _search.isEmpty ||
          (m['name'] as String? ?? '')
              .toLowerCase()
              .contains(_search.toLowerCase());
      return matchesUnit && matchesAccess && matchesCategory && matchesSearch;
    }).toList();
    if (_selectedUnitId == 'tous') {
      // Dans la vue par défaut, les produits déjà débloqués remontent en
      // tête plutôt que d'être noyés par ordre alphabétique.
      list.sort((a, b) {
        final aOwned = _ownedIds.contains(a['id']) ? 0 : 1;
        final bOwned = _ownedIds.contains(b['id']) ? 0 : 1;
        if (aOwned != bOwned) return aOwned.compareTo(bOwned);
        return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
      });
    }
    return list;
  }

  void _openMaterial(Map<String, dynamic> material) {
    final id = material['id'] as String;
    if (_ownedIds.contains(id)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RawMaterialDetailClient(materialId: id),
        ),
      );
      return;
    }
    if (_pendingIds.contains(id)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Cet achat est en attente de vérification par notre équipe.')));
      return;
    }
    openFormationPurchaseWeb(context);
  }

  /// Onglets soulignés (façon capture d'écran fournie par l'utilisatrice)
  /// plutôt que des puces : remplace la rangée "piliers" existante sans
  /// ajouter de rangée, et intègre "Débloqués" comme un onglet de plus au
  /// même niveau que les piliers pour retrouver facilement ce qu'on a
  /// déjà acheté.
  Widget _buildAccessTabsRow(ThemeData theme) {
    final tabs = <Map<String, String>>[
      {'id': 'tous', 'name': 'Tous'},
      {'id': 'debloques', 'name': 'Débloqués'},
      ..._units,
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SizedBox(
        height: 6.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          children: [
            for (final t in tabs)
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() {
                    _selectedUnitId = t['id']!;
                    _selectedCategory = 'toutes';
                  }),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t['name'] ?? '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: _selectedUnitId == t['id']
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: _selectedUnitId == t['id']
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Container(
                          height: 2,
                          color: _selectedUnitId == t['id']
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Formation')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      if (_ownedIds.length < _materials.length)
                        Container(
                          margin: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  color: theme.colorScheme.onPrimaryContainer),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  'Achetez l\'accès (à vie, tarif dégressif) pour débloquer les fiches complètes : description, dosages, conditionnement et historique de prix.',
                                  style: TextStyle(
                                      color:
                                          theme.colorScheme.onPrimaryContainer),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    openFormationPurchaseWeb(context),
                                child: const Text('Acheter'),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Rechercher une matière première…',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      if (_materials.isNotEmpty) _buildAccessTabsRow(theme),
                      if (_categories.isNotEmpty)
                        SizedBox(
                          height: 5.h,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: const Text('Toutes les catégories'),
                                  selected: _selectedCategory == 'toutes',
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = 'toutes'),
                                ),
                              ),
                              ..._categories.map((c) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      avatar:
                                          Icon(iconForChemicalCategory(c), size: 18),
                                      label: Text(c),
                                      selected: _selectedCategory == c,
                                      onSelected: (_) =>
                                          setState(() => _selectedCategory = c),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      SizedBox(height: 1.h),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  _materials.isEmpty
                                      ? 'Aucune matière première pour le moment.'
                                      : 'Aucun résultat.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
                                  final m = filtered[index];
                                  final status =
                                      m['stock_status'] as String? ?? 'en_stock';
                                  final unitName =
                                      _unitNames[m['business_unit_id']] ?? '';
                                  return Card(
                                    child: ListTile(
                                      leading: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor:
                                                rawMaterialStatusColor(status)
                                                    .withValues(alpha: 0.15),
                                            backgroundImage:
                                                (m['image_url'] as String?)
                                                            ?.isNotEmpty ==
                                                        true
                                                    ? NetworkImage(
                                                        m['image_url'] as String)
                                                    : null,
                                            child: (m['image_url'] as String?)
                                                        ?.isNotEmpty ==
                                                    true
                                                ? null
                                                : Icon(
                                                    iconForChemicalCategory(
                                                        m['category_name']
                                                                as String? ??
                                                            ''),
                                                    color: rawMaterialStatusColor(
                                                        status),
                                                  ),
                                          ),
                                          if (!_ownedIds.contains(m['id']))
                                            Positioned(
                                              right: -2,
                                              bottom: -2,
                                              child: Container(
                                                padding: const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.surface,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color:
                                                          theme.colorScheme.outline),
                                                ),
                                                child: Icon(
                                                    _pendingIds
                                                            .contains(m['id'])
                                                        ? Icons
                                                            .hourglass_top_outlined
                                                        : Icons.lock,
                                                    size: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Text(rawMaterialShortName(m['name'])),
                                      subtitle: Text([
                                        m['category_name'],
                                        if (unitName.isNotEmpty) unitName,
                                      ].where((e) => e != null && e != '').join(' · ')),
                                      trailing: Chip(
                                        label: Text(
                                            rawMaterialStatusLabel(status),
                                            style: const TextStyle(fontSize: 11)),
                                        backgroundColor:
                                            rawMaterialStatusColor(status)
                                                .withValues(alpha: 0.15),
                                        labelStyle: TextStyle(
                                            color: rawMaterialStatusColor(status)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onTap: () => _openMaterial(m),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
