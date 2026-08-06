import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';
import 'raw_material_editor_screen.dart';
import 'raw_material_style.dart';

/// Gestion Admin de la base de matières premières/ingrédients ("Formation",
/// voir supabase/phase40_schema.sql) — distincte du catalogue de vente
/// (`products`) : ces fiches ne sont jamais commandables, seulement
/// consultables par le staff et par les clients avec un abonnement
/// Formation actif.
///
/// Depuis le 06/08 : sans Scaffold propre d'AppBar (juste body + FAB) —
/// utilisé comme onglet "Fiches" de FormationHub (fusion avec "Achats
/// Formation"), voir formation_hub.dart.
class RawMaterialsManagement extends StatefulWidget {
  const RawMaterialsManagement({super.key});

  @override
  State<RawMaterialsManagement> createState() =>
      _RawMaterialsManagementState();
}

class _RawMaterialsManagementState extends State<RawMaterialsManagement> {
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _businessUnits = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedUnitId;
  String _search = '';
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
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('raw_materials')
            .select()
            .order('name'),
        SupabaseConfig.client.from('business_units').select(),
      ]);
      setState(() {
        _materials = List<Map<String, dynamic>>.from(results[0]);
        _businessUnits = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les matières premières.';
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _materials.where((m) {
      final matchesUnit =
          _selectedUnitId == null || m['business_unit_id'] == _selectedUnitId;
      final matchesSearch = _search.isEmpty ||
          (m['name'] as String? ?? '')
              .toLowerCase()
              .contains(_search.toLowerCase()) ||
          (m['category_name'] as String? ?? '')
              .toLowerCase()
              .contains(_search.toLowerCase());
      return matchesUnit && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const RawMaterialEditorScreen(),
            ),
          );
          if (created == true) _loadData();
        },
        icon: const Icon(Icons.add),
        label: const Text('Matière première'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Rechercher un nom ou une catégorie…',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      if (_businessUnits.isNotEmpty)
                        SizedBox(
                          height: 5.h,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: const Text('Tous les piliers'),
                                  selected: _selectedUnitId == null,
                                  onSelected: (_) =>
                                      setState(() => _selectedUnitId = null),
                                ),
                              ),
                              ..._businessUnits.map((u) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(u['name'] ?? ''),
                                      selected: _selectedUnitId == u['id'],
                                      onSelected: (_) => setState(
                                          () => _selectedUnitId = u['id']),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      SizedBox(height: 1.h),
                      Expanded(
                        child: filtered.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(height: 20.h),
                                  Center(
                                    child: Text(
                                      _materials.isEmpty
                                          ? 'Aucune matière première pour le moment.\nAppuyez sur "+" pour créer la première fiche.'
                                          : 'Aucun résultat.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
                                  final m = filtered[index];
                                  final stockStatus =
                                      m['stock_status'] as String? ??
                                          'en_stock';
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: rawMaterialStatusColor(
                                                stockStatus)
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
                                                    stockStatus),
                                              ),
                                      ),
                                      title: Text(m['name'] ?? ''),
                                      subtitle: Text(
                                        [
                                          m['category_name'],
                                          if (m['current_price'] != null)
                                            _currency
                                                .format(m['current_price']),
                                        ].where((e) => e != null).join(' · '),
                                      ),
                                      trailing: Chip(
                                        label: Text(
                                            rawMaterialStatusLabel(
                                                stockStatus),
                                            style:
                                                const TextStyle(fontSize: 11)),
                                        backgroundColor:
                                            rawMaterialStatusColor(
                                                    stockStatus)
                                                .withValues(alpha: 0.15),
                                        labelStyle: TextStyle(
                                            color: rawMaterialStatusColor(
                                                stockStatus)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onTap: () async {
                                        final changed =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                RawMaterialEditorScreen(
                                                    material: m),
                                          ),
                                        );
                                        if (changed == true) _loadData();
                                      },
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
