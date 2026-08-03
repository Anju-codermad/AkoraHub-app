import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/services/service_catalog_repo.dart';

/// Gestion du catalogue de services (onglet "Services" côté client, voir
/// supabase/phase66_patch_service_catalog.sql) : catégories + services,
/// chacun activable/désactivable. Un service désactivé n'apparaît plus
/// dans le formulaire de demande côté client, sans supprimer les
/// demandes déjà envoyées qui le référencent — même logique que
/// `category_management.dart` pour les catégories produit.
class ServiceCatalogManagement extends StatefulWidget {
  const ServiceCatalogManagement({super.key});

  @override
  State<ServiceCatalogManagement> createState() =>
      _ServiceCatalogManagementState();
}

class _ServiceCatalogManagementState extends State<ServiceCatalogManagement> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories =
          await ServiceCatalogRepo.fetchCategoriesWithItems(onlyAvailable: false);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger le catalogue (migration phase66 exécutée ?).';
      });
    }
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom de la catégorie',
            hintText: 'ex: Nettoyage & Hygiène des espaces',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ServiceCatalogRepo.createCategory(name);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création.')));
    }
  }

  Future<void> _renameCategory(Map<String, dynamic> category) async {
    final controller = TextEditingController(text: category['name'] as String?);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la catégorie'),
        content: TextField(controller: controller, autofocus: true),
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
    if (name == null || name.isEmpty) return;
    try {
      await ServiceCatalogRepo.renameCategory(category['id'] as String, name);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')));
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text(
            'Tous les services de "${category['name']}" seront supprimés avec elle.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ServiceCatalogRepo.deleteCategory(category['id'] as String);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression.')));
    }
  }

  Future<void> _editItem(String categoryId, {Map<String, dynamic>? item}) async {
    final nameController = TextEditingController(text: item?['name'] as String?);
    final descController =
        TextEditingController(text: item?['description'] as String?);
    final isEditing = item != null;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Modifier le service' : 'Nouveau service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nom du service'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
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
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (saved != true || nameController.text.trim().isEmpty) return;
    try {
      if (isEditing) {
        await ServiceCatalogRepo.updateItem(
          id: item['id'] as String,
          name: nameController.text.trim(),
          description: descController.text.trim(),
        );
      } else {
        await ServiceCatalogRepo.createItem(
          categoryId: categoryId,
          name: nameController.text.trim(),
          description: descController.text.trim(),
        );
      }
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'enregistrement.')));
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce service ?'),
        content: Text('"${item['name']}" sera retiré du catalogue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ServiceCatalogRepo.deleteItem(item['id'] as String);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression.')));
    }
  }

  Future<void> _toggleAvailable(Map<String, dynamic> item) async {
    try {
      await ServiceCatalogRepo.setAvailable(
          item['id'] as String, !(item['available'] as bool? ?? false));
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de modifier le statut.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue de services')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        icon: const Icon(Icons.add),
        label: const Text('Catégorie'),
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
                          'Aucune catégorie. Ajoute-en une avec le bouton "+".'),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: EdgeInsets.all(3.w),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final items = List<Map<String, dynamic>>.from(
                              category['items'] ?? []);
                          final availableCount =
                              items.where((i) => i['available'] == true).length;
                          return Card(
                            margin: EdgeInsets.only(bottom: 2.h),
                            child: ExpansionTile(
                              title: Text(category['name'] ?? ''),
                              subtitle: Text(
                                  '$availableCount/${items.length} disponible(s)'),
                              children: [
                                for (final item in items)
                                  ListTile(
                                    title: Text(item['name'] ?? ''),
                                    subtitle: (item['description'] as String?)
                                                ?.isNotEmpty ==
                                            true
                                        ? Text(item['description'])
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value:
                                              item['available'] as bool? ??
                                                  false,
                                          onChanged: (_) =>
                                              _toggleAvailable(item),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit_outlined, size: 20),
                                          onPressed: () => _editItem(
                                              category['id'] as String,
                                              item: item),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline,
                                              size: 20,
                                              color: theme.colorScheme.error),
                                          onPressed: () => _deleteItem(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4.w, vertical: 1.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _editItem(
                                            category['id'] as String),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Service'),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18),
                                            onPressed: () =>
                                                _renameCategory(category),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline,
                                                size: 18,
                                                color:
                                                    theme.colorScheme.error),
                                            onPressed: () =>
                                                _deleteCategory(category),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
