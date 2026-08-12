import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';
import '../client_home/service_requests_tab.dart'
    show serviceRequestStatusLabels, serviceRequestStatusColor;

/// Traitement des demandes de service envoyées par les clients depuis le
/// nouvel onglet "Services" (voir supabase/phase65_patch_service_requests.sql).
/// Le staff fait passer chaque demande de "nouvelle" à "en_cours" puis
/// "traitee" (ou "refusee"), avec une note interne optionnelle visible par
/// le client.
class ServiceRequestsManagement extends StatefulWidget {
  const ServiceRequestsManagement({super.key});

  @override
  State<ServiceRequestsManagement> createState() =>
      _ServiceRequestsManagementState();
}

/// Un embed PostgREST à-un (ex: `profiles(...)`) peut parfois revenir en
/// `List` plutôt qu'en `Map` (cache de schéma, ambiguïté de relation) —
/// un `as Map?` direct planterait alors avec un TypeError au lieu de
/// simplement retourner null (déjà rencontré sur les achats Formation,
/// voir PROJECT_CONTEXT.md).
Map? _embedAsMap(dynamic value) {
  if (value is Map) return value;
  if (value is List && value.isNotEmpty && value.first is Map) {
    return value.first as Map;
  }
  return null;
}

class _ServiceRequestsManagementState
    extends State<ServiceRequestsManagement> {
  List<Map<String, dynamic>> _requests = [];
  Map<String, Map<String, dynamic>> _contactsById = {};
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'nouvelle';
  final _dateFormat = DateFormat('d MMM yyyy à HH:mm', 'fr_FR');

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
      final data = await SupabaseConfig.client
          .from('service_requests')
          .select(
              '*, business_units(name), profiles(full_name, company_name, phone), '
              'service_catalog_items(name, service_categories(name))')
          .order('created_at', ascending: false);
      final requests = List<Map<String, dynamic>>.from(data);

      // Rôle Services (Phase 167, 12/08) : pas d'accès à `profiles` (RLS),
      // l'embed ci-dessus revient donc vide pour ce rôle — on récupère le
      // contact via la vue allégée `logistics_contacts` à la place.
      final customerIds = requests
          .map((r) => r['customer_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      var contacts = <String, Map<String, dynamic>>{};
      if (customerIds.isNotEmpty) {
        try {
          final contactsData = await SupabaseConfig.client
              .from('logistics_contacts')
              .select('id, full_name, company_name, phone, region, location')
              .inFilter('id', customerIds);
          for (final c in List<Map<String, dynamic>>.from(contactsData)) {
            contacts[c['id'] as String] = c;
          }
        } catch (_) {}
      }

      setState(() {
        _requests = requests;
        _contactsById = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger les demandes (migration phase65 exécutée ?).';
      });
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> request, String status) async {
    try {
      await SupabaseConfig.client
          .from('service_requests')
          .update({'status': status}).eq('id', request['id']);
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')));
    }
  }

  Future<void> _editNotes(Map<String, dynamic> request) async {
    final controller =
        TextEditingController(text: request['staff_notes'] as String?);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Note interne'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Visible par le client sur sa demande...',
            border: OutlineInputBorder(),
          ),
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
    if (saved != true) return;
    try {
      await SupabaseConfig.client
          .from('service_requests')
          .update({'staff_notes': controller.text.trim()}).eq(
              'id', request['id']);
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _requests
        .where((r) => _statusFilter == 'tous' || r['status'] == _statusFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de service')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: EdgeInsets.all(4.w),
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final status in [
                            'nouvelle',
                            'en_cours',
                            'traitee',
                            'refusee',
                            'tous'
                          ])
                            ChoiceChip(
                              label: Text(status == 'tous'
                                  ? 'Toutes'
                                  : serviceRequestStatusLabels[status] ??
                                      status),
                              selected: _statusFilter == status,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = status),
                            ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      if (filtered.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Center(
                            child: Text('Aucune demande.',
                                style: theme.textTheme.bodyMedium),
                          ),
                        )
                      else
                        ...filtered.map((r) {
                          final status = (r['status'] ?? 'nouvelle').toString();
                          final customer = _embedAsMap(r['profiles']) ??
                              _contactsById[r['customer_id']];
                          final catalogItem =
                              _embedAsMap(r['service_catalog_items']);
                          final unit = catalogItem != null
                              ? _embedAsMap(
                                  catalogItem['service_categories'])
                              : _embedAsMap(r['business_units']);
                          final customerName = customer?['company_name'] ??
                              customer?['full_name'] ??
                              'Client';
                          final createdAt = DateTime.tryParse(
                              r['created_at']?.toString() ?? '');
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(r['title'] ?? '',
                                            style: theme.textTheme.titleSmall),
                                      ),
                                      Chip(
                                        label: Text(
                                          serviceRequestStatusLabels[status] ??
                                              status,
                                          style: TextStyle(
                                            color: serviceRequestStatusColor(
                                                status, theme),
                                            fontSize: 11,
                                          ),
                                        ),
                                        backgroundColor:
                                            serviceRequestStatusColor(
                                                    status, theme)
                                                .withValues(alpha: 0.12),
                                        visualDensity: VisualDensity.compact,
                                        side: BorderSide.none,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 0.3.h),
                                  Text(
                                    '$customerName'
                                    '${unit != null ? " · ${unit['name']}" : ""}'
                                    '${customer?['phone'] != null ? " · ${customer!['phone']}" : ""}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (createdAt != null)
                                    Text(_dateFormat.format(createdAt),
                                        style: theme.textTheme.bodySmall),
                                  const Divider(height: 20),
                                  Text(r['description'] ?? ''),
                                  if (r['address'] != null &&
                                      (r['address'] as String).isNotEmpty) ...[
                                    SizedBox(height: 0.5.h),
                                    Text('Adresse : ${r['address']}',
                                        style: theme.textTheme.bodySmall),
                                  ],
                                  if (r['preferred_date'] != null) ...[
                                    SizedBox(height: 0.5.h),
                                    Text(
                                        'Date souhaitée : ${r['preferred_date']}',
                                        style: theme.textTheme.bodySmall),
                                  ],
                                  if (r['staff_notes'] != null &&
                                      (r['staff_notes'] as String)
                                          .isNotEmpty) ...[
                                    SizedBox(height: 0.5.h),
                                    Text('Note interne : ${r['staff_notes']}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                fontStyle: FontStyle.italic)),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => _editNotes(r),
                                        child: const Text('Note'),
                                      ),
                                      if (status == 'nouvelle') ...[
                                        TextButton(
                                          onPressed: () =>
                                              _updateStatus(r, 'refusee'),
                                          style: TextButton.styleFrom(
                                              foregroundColor:
                                                  theme.colorScheme.error),
                                          child: const Text('Refuser'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              _updateStatus(r, 'en_cours'),
                                          child: const Text('Prendre en charge'),
                                        ),
                                      ] else if (status == 'en_cours') ...[
                                        TextButton(
                                          onPressed: () =>
                                              _updateStatus(r, 'refusee'),
                                          style: TextButton.styleFrom(
                                              foregroundColor:
                                                  theme.colorScheme.error),
                                          child: const Text('Refuser'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              _updateStatus(r, 'traitee'),
                                          child: const Text('Marquer traitée'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
