import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/supabase/supabase_config.dart';

/// Demandes de contact laissées par un visiteur anonyme depuis le
/// formulaire "Demander un devis / être rappelé" du site web (voir
/// supabase/phase186_patch_website_leads.sql et SITE_APP_SYNC.md —
/// le site n'a pas de compte client, donc pas de lien avec `profiles`
/// comme pour service_requests).
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

class _WebsiteLeadsManagementState extends State<WebsiteLeadsManagement> {
  List<Map<String, dynamic>> _leads = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'nouveau';
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
          .from('website_leads')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _leads = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger les demandes (migration phase186 exécutée ?).';
      });
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> lead, String status) async {
    try {
      await SupabaseConfig.client
          .from('website_leads')
          .update({'status': status}).eq('id', lead['id']);
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
    final filtered = _leads
        .where((l) => _statusFilter == 'tous' || l['status'] == _statusFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Demandes du site web')),
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
                            'nouveau',
                            'contacte',
                            'traite',
                            'tous',
                          ])
                            ChoiceChip(
                              label: Text(status == 'tous'
                                  ? 'Toutes'
                                  : _statusLabels[status] ?? status),
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
                        ...filtered.map((l) {
                          final status = (l['status'] ?? 'nouveau').toString();
                          final createdAt = DateTime.tryParse(
                              l['created_at']?.toString() ?? '');
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
                                        child: Text(
                                          l['name'] ?? '',
                                          style: theme.textTheme.titleSmall,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          _statusLabels[status] ?? status,
                                          style: TextStyle(
                                            color:
                                                _statusColor(status, theme),
                                            fontSize: 11,
                                          ),
                                        ),
                                        backgroundColor:
                                            _statusColor(status, theme)
                                                .withValues(alpha: 0.12),
                                        visualDensity: VisualDensity.compact,
                                        side: BorderSide.none,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 0.3.h),
                                  Row(
                                    children: [
                                      Icon(Icons.phone_outlined,
                                          size: 14,
                                          color: theme.colorScheme.primary),
                                      SizedBox(width: 1.w),
                                      InkWell(
                                        onTap: phone.isEmpty
                                            ? null
                                            : () => launchUrl(
                                                Uri.parse('tel:$phone')),
                                        child: Text(
                                          phone,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
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
                                      (l['message'] as String)
                                          .isNotEmpty) ...[
                                    const Divider(height: 20),
                                    Text(l['message']),
                                  ],
                                  if (l['source_page'] != null) ...[
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      'Page : ${l['source_page']}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (status == 'nouveau')
                                        FilledButton(
                                          onPressed: () =>
                                              _updateStatus(l, 'contacte'),
                                          child: const Text('Marquer contacté'),
                                        )
                                      else if (status == 'contacte')
                                        FilledButton(
                                          onPressed: () =>
                                              _updateStatus(l, 'traite'),
                                          child: const Text('Marquer traité'),
                                        ),
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
