import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/services/service_catalog_repo.dart';
import '../../core/services/service_request_repo.dart';

const serviceRequestStatusLabels = {
  'nouvelle': 'Nouvelle',
  'en_cours': 'En cours',
  'traitee': 'Traitée',
  'refusee': 'Refusée',
};

/// Un embed PostgREST à-un peut parfois revenir en `List` plutôt qu'en
/// `Map` (voir PROJECT_CONTEXT.md, fix Achats Formation) — évite un
/// TypeError sur un `as Map?` direct.
Map? _embedAsMap(dynamic value) {
  if (value is Map) return value;
  if (value is List && value.isNotEmpty && value.first is Map) {
    return value.first as Map;
  }
  return null;
}

Color serviceRequestStatusColor(String status, ThemeData theme) {
  switch (status) {
    case 'en_cours':
      return Colors.orange;
    case 'traitee':
      return theme.colorScheme.primary;
    case 'refusee':
      return theme.colorScheme.error;
    default:
      return theme.colorScheme.outline;
  }
}

/// Onglet "Services" côté client — demande de service (installation,
/// intervention, consultation...), distinct d'une commande de produit ou
/// d'un devis : le client décrit un besoin, le staff le traite
/// manuellement (voir supabase/phase65_patch_service_requests.sql).
class ServiceRequestsTab extends StatefulWidget {
  const ServiceRequestsTab({super.key});

  @override
  State<ServiceRequestsTab> createState() => _ServiceRequestsTabState();
}

class _ServiceRequestsTabState extends State<ServiceRequestsTab> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

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
      final requests = await ServiceRequestRepo.fetchMine();
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger vos demandes.';
      });
    }
  }

  Future<void> _openNewRequestSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewServiceRequestSheet(),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        SizedBox(height: 1.5.h),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : _requests.isEmpty
                    ? ListView(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        children: [
                          SizedBox(height: 12.h),
                          Icon(Icons.miscellaneous_services_outlined,
                              size: 48, color: theme.colorScheme.outline),
                          SizedBox(height: 2.h),
                          Text(
                            'Aucune demande de service pour le moment. '
                            'Besoin d\'une installation, d\'une intervention '
                            'ou d\'une consultation ? Faites votre demande.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => SizedBox(height: 2.h),
                        itemBuilder: (context, index) {
                          final r = _requests[index];
                          final status =
                              (r['status'] ?? 'nouvelle').toString();
                          final catalogItem =
                              _embedAsMap(r['service_catalog_items']);
                          final categoryMap = catalogItem != null
                              ? _embedAsMap(
                                  catalogItem['service_categories'])
                              : _embedAsMap(r['business_units']);
                          final unit = categoryMap?['name'] as String?;
                          final createdAt =
                              DateTime.tryParse(r['created_at'] ?? '');
                          return Card(
                            child: Padding(
                              padding: EdgeInsets.all(3.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          r['title'] ?? '',
                                          style: theme.textTheme.titleSmall,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          serviceRequestStatusLabels[
                                                  status] ??
                                              status,
                                          style: TextStyle(
                                            color: serviceRequestStatusColor(
                                                status, theme),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        backgroundColor:
                                            serviceRequestStatusColor(
                                                    status, theme)
                                                .withValues(alpha: 0.12),
                                        side: BorderSide.none,
                                      ),
                                    ],
                                  ),
                                  if (unit != null) ...[
                                    SizedBox(height: 0.3.h),
                                    Text(
                                      unit,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 0.8.h),
                                  Text(
                                    r['description'] ?? '',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (r['staff_notes'] != null &&
                                      (r['staff_notes'] as String)
                                          .isNotEmpty) ...[
                                    SizedBox(height: 0.8.h),
                                    Container(
                                      padding: EdgeInsets.all(2.w),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.surfaceContainerHighest,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.info_outline,
                                              size: 16,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              r['staff_notes'],
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (createdAt != null) ...[
                                    SizedBox(height: 0.8.h),
                                    Text(
                                      _dateFormat.format(createdAt),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewRequestSheet,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle demande'),
      ),
    );
  }
}

class _NewServiceRequestSheet extends StatefulWidget {
  const _NewServiceRequestSheet();

  @override
  State<_NewServiceRequestSheet> createState() =>
      _NewServiceRequestSheetState();
}

class _NewServiceRequestSheetState extends State<_NewServiceRequestSheet> {
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String? _selectedItemId;
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _preferredDate;
  bool _isLoadingCatalog = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final categories =
          await ServiceCatalogRepo.fetchCategoriesWithItems();
      setState(() {
        _categories = categories;
        _isLoadingCatalog = false;
      });
    } catch (_) {
      setState(() => _isLoadingCatalog = false);
    }
  }

  List<Map<String, dynamic>> get _itemsOfSelectedCategory {
    if (_selectedCategoryId == null) return [];
    final category = _categories
        .firstWhere((c) => c['id'] == _selectedCategoryId, orElse: () => {});
    return List<Map<String, dynamic>>.from(category['items'] ?? []);
  }

  Future<void> _submit() async {
    if (_selectedItemId == null ||
        _descriptionController.text.trim().isEmpty) {
      setState(() => _error = 'Merci de remplir les champs obligatoires.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final item = _itemsOfSelectedCategory
          .firstWhere((i) => i['id'] == _selectedItemId);
      await ServiceRequestRepo.submit(
        serviceCatalogItemId: _selectedItemId!,
        title: item['name'] as String,
        description: _descriptionController.text.trim(),
        preferredDate: _preferredDate,
        address: _addressController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() {
        _isSubmitting = false;
        _error = 'Impossible d\'envoyer la demande. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 4.w,
        right: 4.w,
        top: 3.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 3.h,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nouvelle demande de service',
                style: theme.textTheme.titleMedium),
            SizedBox(height: 2.h),
            if (_isLoadingCatalog)
              const Center(child: CircularProgressIndicator())
            else if (_categories.isEmpty)
              Text(
                'Aucun service disponible pour le moment — contactez le '
                'support pour votre demande.',
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Catégorie *',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Text(c['name'] ?? ''),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedCategoryId = v;
                  _selectedItemId = null;
                }),
              ),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedCategoryId),
                initialValue: _selectedItemId,
                decoration: const InputDecoration(
                  labelText: 'Service *',
                  border: OutlineInputBorder(),
                ),
                items: _itemsOfSelectedCategory
                    .map((i) => DropdownMenuItem(
                          value: i['id'] as String,
                          child: Text(i['name'] ?? ''),
                        ))
                    .toList(),
                onChanged: _selectedCategoryId == null
                    ? null
                    : (v) => setState(() => _selectedItemId = v),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 2.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  _preferredDate == null
                      ? 'Date souhaitée (optionnel)'
                      : DateFormat('d MMM yyyy', 'fr_FR')
                          .format(_preferredDate!),
                ),
                trailing: _preferredDate != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            setState(() => _preferredDate = null),
                      )
                    : null,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _preferredDate = picked);
                },
              ),
              if (_error != null) ...[
                SizedBox(height: 1.h),
                Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ],
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Envoyer la demande'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
