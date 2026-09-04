import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import 'category_management.dart';

/// Gestion des piliers d'entreprise (Akora Pro, Akora Home, Akora Protect,
/// Akora Soins, Akora Coatings, Akora Paints, AkoraFormation, Akor'Eau, et
/// tout pilier futur — noms modifiables ici même, voir _showEditDialog).
/// Réservé au staff (RLS côté serveur).
class BusinessUnitsManagement extends StatefulWidget {
  const BusinessUnitsManagement({super.key});

  @override
  State<BusinessUnitsManagement> createState() =>
      _BusinessUnitsManagementState();
}

class _BusinessUnitsManagementState extends State<BusinessUnitsManagement> {
  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;
  String? _error;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
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
      final data = await SupabaseConfig.client
          .from('business_units')
          .select()
          .order('created_at');
      setState(() {
        _units = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les piliers.';
      });
    }
  }

  /// Génère un identifiant technique propre à partir d'un nom, en gérant
  /// correctement les accents français/malgaches (ex: "Matières Premières"
  /// -> "matieres-premieres", pas "mati-res-premi-res"). Sans cette
  /// translittération, deux piliers créés avec le même nom accentué à des
  /// moments différents pouvaient obtenir des slugs différents et donc
  /// échapper à la protection anti-doublon (unique sur `slug`).
  String _slugify(String name) {
    const accents = 'àâäáãåèéêëìíîïòóôöõùúûüçñÀÂÄÁÃÅÈÉÊËÌÍÎÏÒÓÔÖÕÙÚÛÜÇÑ';
    const plain = 'aaaaaaeeeeiiiiooooouuuucnAAAAAAEEEEIIIIOOOOOUUUUCN';
    var result = name;
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], plain[i]);
    }
    return result
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _showEditDialog({Map<String, dynamic>? unit}) async {
    final controller = TextEditingController(text: unit?['name'] ?? '');
    final isEditing = unit != null;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier le pilier' : 'Nouveau pilier'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom du pilier',
            hintText: 'ex: Akora Pro',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      if (isEditing) {
        await SupabaseConfig.client
            .from('business_units')
            .update({'name': result}).eq('id', unit['id']);
      } else {
        await SupabaseConfig.client.from('business_units').insert({
          'name': result,
          'slug': _slugify(result),
        });
      }
      if (!mounted) return;
      _loadUnits();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.message}')),
      );
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> unit) async {
    try {
      await SupabaseConfig.client
          .from('business_units')
          .update({'active': !(unit['active'] as bool)}).eq(
              'id', unit['id']);
      _loadUnits();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de modifier le statut.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Piliers d\'entreprise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list_outlined),
            tooltip: 'Vue liste',
            color: _isGridView
                ? theme.colorScheme.outline
                : theme.colorScheme.primary,
            onPressed: () => setState(() => _isGridView = false),
          ),
          IconButton(
            icon: const Icon(Icons.grid_view_outlined),
            tooltip: 'Vue grille',
            color: _isGridView
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            onPressed: () => setState(() => _isGridView = true),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        SizedBox(height: 2.h),
                        OutlinedButton(
                          onPressed: _loadUnits,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUnits,
                  child: _units.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            Center(
                              child: Text(
                                'Aucun pilier pour le moment.\nAppuyez sur "+" pour en créer un.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        )
                      : _isGridView
                          ? GridView.builder(
                              padding: EdgeInsets.all(4.w),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 3.w,
                                crossAxisSpacing: 3.w,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _units.length,
                              itemBuilder: (context, index) =>
                                  _buildUnitGridCard(theme, _units[index]),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.all(4.w),
                              itemCount: _units.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 1.h),
                              itemBuilder: (context, index) =>
                                  _buildUnitListTile(theme, _units[index]),
                            ),
                ),
    );
  }

  Widget _buildUnitListTile(ThemeData theme, Map<String, dynamic> unit) {
    final active = unit['active'] as bool? ?? true;
    return Card(
      child: ListTile(
        title: Text(unit['name'] ?? ''),
        subtitle: Text(unit['slug'] ?? ''),
        leading: CircleAvatar(
          backgroundColor: active
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.business,
            color: active
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.outline,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Gérer les catégories',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryManagement(
                    businessUnitId: unit['id'],
                    businessUnitName: unit['name'] ?? '',
                  ),
                ),
              ),
            ),
            Switch(
              value: active,
              onChanged: (_) => _toggleActive(unit),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditDialog(unit: unit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitGridCard(ThemeData theme, Map<String, dynamic> unit) {
    final active = unit['active'] as bool? ?? true;
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryManagement(
              businessUnitId: unit['id'],
              businessUnitName: unit['name'] ?? '',
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 6.w,
                backgroundColor: active
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.business,
                  color: active
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.outline,
                ),
              ),
              SizedBox(height: 1.5.h),
              Text(
                unit['name'] ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                unit['slug'] ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Switch(
                    value: active,
                    onChanged: (_) => _toggleActive(unit),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showEditDialog(unit: unit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
