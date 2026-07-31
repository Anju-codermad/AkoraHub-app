import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/reference_data/reference_table_cache.dart';
import '../../core/supabase/supabase_config.dart';

/// Gestion des catégories (sous-catalogues) d'un pilier donné : activer /
/// désactiver (comme pour les piliers eux-mêmes dans
/// business_units_management.dart), renommer, ajouter. Une catégorie
/// désactivée disparaît du menu déroulant de sélection dans le formulaire
/// produit et du catalogue client, sans supprimer les produits qui la
/// portent déjà — pratique pour préparer une nouvelle gamme (ex:
/// Anti-Nuisibles) à l'avance et la "lancer" d'un coup plus tard.
class CategoryManagement extends ConsumerStatefulWidget {
  final String businessUnitId;
  final String businessUnitName;

  const CategoryManagement({
    super.key,
    required this.businessUnitId,
    required this.businessUnitName,
  });

  @override
  ConsumerState<CategoryManagement> createState() =>
      _CategoryManagementState();
}

class _CategoryManagementState extends ConsumerState<CategoryManagement> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
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
          .from('categories')
          .select()
          .eq('business_unit_id', widget.businessUnitId)
          .order('name');
      setState(() {
        _categories = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger les catégories. La migration phase9 (colonne `active`) a-t-elle été exécutée ?';
      });
    }
  }

  Future<void> _showEditDialog({Map<String, dynamic>? category}) async {
    final controller = TextEditingController(text: category?['name'] ?? '');
    final isEditing = category != null;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom de la catégorie',
            hintText: 'ex: Carrelage & Sols',
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
            .from('categories')
            .update({'name': result}).eq('id', category['id']);
      } else {
        await SupabaseConfig.client.from('categories').insert({
          'name': result,
          'business_unit_id': widget.businessUnitId,
        });
      }
      if (!mounted) return;
      _loadCategories();
      // Invalide le cache partagé (utilisé par le formulaire produit et le
      // catalogue client — voir lib/core/reference_data/reference_table_cache.dart)
      // pour que ce changement soit visible immédiatement ailleurs, sans
      // attendre jusqu'à 6h.
      ref.read(categoriesCacheProvider.notifier).refresh(force: true);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.message}')),
      );
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> category) async {
    try {
      await SupabaseConfig.client
          .from('categories')
          .update({'active': !(category['active'] as bool? ?? true)}).eq(
              'id', category['id']);
      _loadCategories();
      ref.read(categoriesCacheProvider.notifier).refresh(force: true);
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
        title: Text('Catégories — ${widget.businessUnitName}'),
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
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _categories.isEmpty
                  ? const Center(
                      child: Text(
                          'Aucune catégorie pour ce pilier. Ajoute-en une avec le bouton "+".'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final active = category['active'] as bool? ?? true;
                        return Card(
                          child: ListTile(
                            title: Text(category['name'] ?? ''),
                            subtitle: Text(active
                                ? 'Visible dans le catalogue'
                                : 'Masquée (préparation)'),
                            leading: CircleAvatar(
                              backgroundColor: active
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.category_outlined,
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
                                  onChanged: (_) => _toggleActive(category),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _showEditDialog(category: category),
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
