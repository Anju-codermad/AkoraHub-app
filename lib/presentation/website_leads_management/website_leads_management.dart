import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/supabase/supabase_config.dart';

/// Demandes laissées par un visiteur anonyme depuis le site web — deux
/// tables distinctes réunies dans un même écran par onglets :
///   - `website_leads` (Phase 186) : contact générique "Demander un devis
///     / être rappelé".
///   - `website_service_requests` (Phase 214/215) : demande structurée
///     propre à un service précis, pour l'instant uniquement le
///     diagnostic qualité de l'eau (`service_slug = 'diagnostic-eau'`).
/// Le site n'a pas de compte client, donc aucun lien avec `profiles`
/// comme pour service_requests (natif à l'apk). Voir aussi
/// supabase/phase216_patch_notif_demandes_site_web.sql (notification push
/// au staff dès qu'une ligne arrive dans l'une ou l'autre table).
class WebsiteLeadsManagement extends StatefulWidget {
  const WebsiteLeadsManagement({super.key});

  @override
  State<WebsiteLeadsManagement> createState() =>
      _WebsiteLeadsManagementState();
}

const _statusLabels = {
  'nouveau': 'Nouveau',
  'contacte': 'Contacté',
  'traite': 'Traité',
};

const _waterTypeLabels = {
  'puits': 'Puits',
  'forage': 'Forage',
  'reseau': 'Réseau',
};

const _samplingLabels = {
  'descente': 'Descente chez le client',
  'apport': 'Apport en point de vente',
};

const _clientTypeLabels = {
  'particulier': 'Particulier',
  'entreprise': 'Entreprise',
  'organisation': 'Organisation',
};

const _packLabels = {
  'eau_de_boisson': 'Pack Eau de boisson',
  'forage_complet': 'Pack Forage complet',
  'ong_communaute': 'Pack ONG / Communauté',
};

const _serviceSlugLabels = {
  'diagnostic-eau': "Diagnostic qualité de l'eau",
};

final _amountFormat = NumberFormat('#,##0', 'fr_FR');

String _amount(dynamic value) {
  if (value == null) return 'Sur devis';
  final n = value is num ? value : num.tryParse(value.toString());
  if (n == null) return 'Sur devis';
  return '${_amountFormat.format(n)} Ar';
}

Color _statusColor(String status, ThemeData theme) {
  switch (status) {
    case 'contacte':
      return Colors.orange;
    case 'traite':
      return Colors.green;
    case 'nouveau':
    default:
      return theme.colorScheme.primary;
  }
}

class _WebsiteLeadsManagementState extends State<WebsiteLeadsManagement>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Map<String, dynamic>> _leads = [];
  bool _leadsLoading = true;
  String? _leadsError;
  String _leadsStatusFilter = 'nouveau';

  List<Map<String, dynamic>> _requests = [];
  bool _requestsLoading = true;
  String? _requestsError;
  String _requestsStatusFilter = 'nouveau';

  final _dateFormat = DateFormat('d MMM yyyy à HH:mm', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeads();
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeads() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _leadsLoading = false;
        _leadsError = 'Connexion au serveur indisponible.';
      });
      return;
    }
    setState(() {
      _leadsLoading = true;
      _leadsError = null;
    });
    try {
      final data = await SupabaseConfig.client
          .from('website_leads')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _leads = List<Map<String, dynamic>>.from(data);
        _leadsLoading = false;
      });
    } catch (e) {
      setState(() {
        _leadsLoading = false;
        _leadsError =
            'Impossible de charger les demandes (migration phase186 exécutée ?).';
      });
    }
  }

  Future<void> _loadRequests() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _requestsLoading = false;
        _requestsError = 'Connexion au serveur indisponible.';
      });
      return;
    }
    setState(() {
      _requestsLoading = true;
      _requestsError = null;
    });
    try {
      final data = await SupabaseConfig.client
          .from('website_service_requests')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _requests = List<Map<String, dynamic>>.from(data);
        _requestsLoading = false;
      });
    } catch (e) {
      setState(() {
        _requestsLoading = false;
        _requestsError =
            'Impossible de charger les demandes (migration phase214/215 exécutée ?).';
      });
    }
  }

  Future<void> _updateLeadStatus(
      Map<String, dynamic> lead, String status) async {
    try {
      await SupabaseConfig.client
          .from('website_leads')
          .update({'status': status}).eq('id', lead['id']);
      _loadLeads();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')));
    }
  }

  Future<void> _updateRequestStatus(
      Map<String, dynamic> request, String status) async {
    try {
      await SupabaseConfig.client
          .from('website_service_requests')
          .update({'status': status}).eq('id', request['id']);
      _loadRequests();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')));
    }
  }

  Widget _statusFilterRow(String current, ValueChanged<String> onChanged) {
    return Wrap(
      spacing: 8,
      children: [
        for (final status in ['nouveau', 'contacte', 'traite', 'tous'])
          ChoiceChip(
            label:
                Text(status == 'tous' ? 'Toutes' : _statusLabels[status] ?? status),
            selected: current == status,
            onSelected: (_) => onChanged(status),
          ),
      ],
    );
  }

  Widget _statusChip(String status, ThemeData theme) {
    return Chip(
      label: Text(
        _statusLabels[status] ?? status,
        style: TextStyle(color: _statusColor(status, theme), fontSize: 11),
      ),
      backgroundColor: _statusColor(status, theme).withValues(alpha: 0.12),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }

  Widget _statusActionRow(String status, VoidCallback onContacte,
      VoidCallback onTraite) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (status == 'nouveau')
          FilledButton(onPressed: onContacte, child: const Text('Marquer contacté'))
        else if (status == 'contacte')
          FilledButton(onPressed: onTraite, child: const Text('Marquer traité')),
      ],
    );
  }

  Widget _buildLeadsTab(ThemeData theme) {
    final filtered = _leads
        .where((l) => _leadsStatusFilter == 'tous' || l['status'] == _leadsStatusFilter)
        .toList();
    if (_leadsLoading) return const Center(child: CircularProgressIndicator());
    if (_leadsError != null) return Center(child: Text(_leadsError!));
    return RefreshIndicator(
      onRefresh: _loadLeads,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _statusFilterRow(
              _leadsStatusFilter, (s) => setState(() => _leadsStatusFilter = s)),
          SizedBox(height: 1.h),
          if (filtered.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Center(
                  child:
                      Text('Aucune demande.', style: theme.textTheme.bodyMedium)),
            )
          else
            ...filtered.map((l) {
              final status = (l['status'] ?? 'nouveau').toString();
              final createdAt =
                  DateTime.tryParse(l['created_at']?.toString() ?? '');
              final phone = l['phone'] as String? ?? '';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(l['name'] ?? '',
                                style: theme.textTheme.titleSmall),
                          ),
                          _statusChip(status, theme),
                        ],
                      ),
                      SizedBox(height: 0.3.h),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 14, color: theme.colorScheme.primary),
                          SizedBox(width: 1.w),
                          InkWell(
                            onTap: phone.isEmpty
                                ? null
                                : () => launchUrl(Uri.parse('tel:$phone')),
                            child: Text(
                              phone,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (createdAt != null)
                        Text(_dateFormat.format(createdAt),
                            style: theme.textTheme.bodySmall),
                      if (l['message'] != null &&
                          (l['message'] as String).isNotEmpty) ...[
                        const Divider(height: 20),
                        Text(l['message']),
                      ],
                      if (l['source_page'] != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          'Page : ${l['source_page']}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _statusActionRow(
                        status,
                        () => _updateLeadStatus(l, 'contacte'),
                        () => _updateLeadStatus(l, 'traite'),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(ThemeData theme) {
    final filtered = _requests
        .where((r) =>
            _requestsStatusFilter == 'tous' || r['status'] == _requestsStatusFilter)
        .toList();
    if (_requestsLoading) return const Center(child: CircularProgressIndicator());
    if (_requestsError != null) return Center(child: Text(_requestsError!));
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _statusFilterRow(_requestsStatusFilter,
              (s) => setState(() => _requestsStatusFilter = s)),
          SizedBox(height: 1.h),
          if (filtered.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Center(
                  child:
                      Text('Aucune demande.', style: theme.textTheme.bodyMedium)),
            )
          else
            ...filtered.map((r) => _requestCard(r, theme)),
        ],
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> r, ThemeData theme) {
    final status = (r['status'] ?? 'nouveau').toString();
    final createdAt = DateTime.tryParse(r['created_at']?.toString() ?? '');
    final phone = r['phone'] as String? ?? '';
    final serviceSlug = r['service_slug'] as String? ?? 'Service';
    final serviceLabel = _serviceSlugLabels[serviceSlug] ?? serviceSlug;
    final waterType = r['water_type'] as String?;
    final samplingMethod = r['sampling_method'] as String?;
    final selectedPack = r['selected_pack'] as String?;
    final requestedAnalyses = (r['requested_analyses'] as List?)?.cast<String>();
    final clientType = r['client_type'] as String?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(serviceLabel, style: theme.textTheme.titleSmall),
                ),
                _statusChip(status, theme),
              ],
            ),
            Text(r['name'] ?? '', style: theme.textTheme.bodyMedium),
            SizedBox(height: 0.3.h),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: theme.colorScheme.primary),
                SizedBox(width: 1.w),
                InkWell(
                  onTap:
                      phone.isEmpty ? null : () => launchUrl(Uri.parse('tel:$phone')),
                  child: Text(
                    phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (r['email'] != null) ...[
                  SizedBox(width: 3.w),
                  Icon(Icons.email_outlined, size: 14, color: theme.colorScheme.primary),
                  SizedBox(width: 1.w),
                  Flexible(
                      child: Text(r['email'], style: theme.textTheme.bodySmall)),
                ],
              ],
            ),
            if (createdAt != null)
              Text(_dateFormat.format(createdAt), style: theme.textTheme.bodySmall),
            const Divider(height: 20),
            if (waterType != null)
              Text("Type d'eau : ${_waterTypeLabels[waterType] ?? waterType}"),
            if (samplingMethod != null)
              Text(
                  'Prélèvement : ${_samplingLabels[samplingMethod] ?? samplingMethod}'),
            if (r['preferred_day'] != null)
              Text('Jour souhaité : ${r['preferred_day']}'),
            if (r['address'] != null) Text('Adresse : ${r['address']}'),
            if (selectedPack != null)
              Text('Forfait : ${_packLabels[selectedPack] ?? selectedPack}')
            else if (requestedAnalyses != null && requestedAnalyses.isNotEmpty)
              Text('Analyses demandées : ${requestedAnalyses.join(", ")}'),
            SizedBox(height: 0.5.h),
            Text('Total estimé : ${_amount(r['estimated_total'])}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (r['deposit_amount'] != null)
              Text('Acompte : ${_amount(r['deposit_amount'])}'),
            if (clientType != null && clientType != 'particulier') ...[
              const Divider(height: 20),
              Text('${_clientTypeLabels[clientType] ?? clientType} : ${r['company_name'] ?? ''}'),
              if (r['nif'] != null) Text('NIF : ${r['nif']}'),
              if (r['stat'] != null) Text('STAT : ${r['stat']}'),
              if (r['contact_person'] != null)
                Text('Contact : ${r['contact_person']}'),
            ],
            if (r['source_page'] != null) ...[
              SizedBox(height: 0.5.h),
              Text(
                'Page : ${r['source_page']}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 8),
            _statusActionRow(
              status,
              () => _updateRequestStatus(r, 'contacte'),
              () => _updateRequestStatus(r, 'traite'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes du site web'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Devis'),
            Tab(text: 'Diagnostic eau'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeadsTab(theme),
          _buildRequestsTab(theme),
        ],
      ),
    );
  }
}
