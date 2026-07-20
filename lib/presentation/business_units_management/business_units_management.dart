import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';

/// Gestion des piliers d'entreprise (Akora Fanadiovana, ARCA PAINTS,
/// AkoraFormation, et tout pilier futur). Réservé au staff (RLS côté serveur).
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

  String _slugify(String name) {
    return name
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
            hintText: 'ex: Akora Fanadiovana',
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
      appBar: AppBar(title: const Text('Piliers d\'entreprise')),
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
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _units.length,
                          separatorBuilder: (_, __) => SizedBox(height: 1.h),
                          itemBuilder: (context, index) {
                            final unit = _units[index];
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
                                    Switch(
                                      value: active,
                                      onChanged: (_) => _toggleActive(unit),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () =>
                                          _showEditDialog(unit: unit),
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
