import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';
import '../customer_360/customer_360_screen.dart';

/// Liste réelle des clients (comptes créés via l'inscription), avec leur
/// type (Hôtel/Hôpital/Entreprise/Particulier) et coordonnées.
class CustomerManagementReal extends StatefulWidget {
  const CustomerManagementReal({super.key});

  @override
  State<CustomerManagementReal> createState() =>
      _CustomerManagementRealState();
}

class _CustomerManagementRealState extends State<CustomerManagementReal> {
  List<Map<String, dynamic>> _customers = [];
  Map<String, Map<String, dynamic>> _segments = {};
  bool _isLoading = true;
  bool _isSendingNotification = false;
  String? _error;
  String _typeFilter = 'tous';
  String _segmentFilter = 'tous';

  /// Seuil de valeur totale (lifetime value) au-dessus duquel un client
  /// est considéré "gros compte" — hypothèse de départ, ajustable si
  /// besoin (pas de règle métier communiquée par ailleurs).
  static const num _grosCompteThreshold = 1000000;
  static const int _inactifAfterDays = 90;

  final Map<String, String> _typeLabels = const {
    'hotel': 'Hôtel',
    'hopital': 'Hôpital',
    'entreprise': 'Entreprise',
    'particulier': 'Particulier',
  };
  final Map<String, String> _segmentLabels = const {
    'nouveau': 'Nouveaux',
    'recurrent': 'Récurrents',
    'inactif': 'Inactifs',
    'gros_compte': 'Gros comptes',
  };

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
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
            .from('profiles')
            .select()
            .eq('role', 'client')
            .order('created_at', ascending: false),
        SupabaseConfig.client.from('customer_segments').select(),
      ]);
      final segments = List<Map<String, dynamic>>.from(results[1]);
      setState(() {
        _customers = List<Map<String, dynamic>>.from(results[0]);
        _segments = {
          for (final s in segments) s['customer_id'] as String: s,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les clients.';
      });
    }
  }

  /// Segment d'activité (mutuellement exclusif) : null si le client n'a
  /// encore jamais commandé (pas assez de signal pour le classer).
  String? _activitySegment(String customerId) {
    final agg = _segments[customerId];
    final orderCount = (agg?['order_count'] as num?)?.toInt() ?? 0;
    if (orderCount == 0) return null;
    final lastOrderAt = agg?['last_order_at'] != null
        ? DateTime.tryParse(agg!['last_order_at'] as String)
        : null;
    if (lastOrderAt != null &&
        DateTime.now().difference(lastOrderAt).inDays > _inactifAfterDays) {
      return 'inactif';
    }
    return orderCount == 1 ? 'nouveau' : 'recurrent';
  }

  bool _isGrosCompte(String customerId) {
    final value = (_segments[customerId]?['lifetime_value'] as num?) ?? 0;
    return value >= _grosCompteThreshold;
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _customers;
    if (_typeFilter != 'tous') {
      list = list.where((c) => c['client_type'] == _typeFilter).toList();
    }
    if (_segmentFilter != 'tous') {
      list = list.where((c) {
        final id = c['id'] as String;
        return _segmentFilter == 'gros_compte'
            ? _isGrosCompte(id)
            : _activitySegment(id) == _segmentFilter;
      }).toList();
    }
    return list;
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'hotel':
        return Icons.hotel;
      case 'hopital':
        return Icons.local_hospital;
      case 'entreprise':
        return Icons.business_center;
      default:
        return Icons.person;
    }
  }

  Future<void> _sendTargetedNotification(
      String title, String body, List<String> customerIds) async {
    setState(() => _isSendingNotification = true);
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'send-targeted-notification',
        body: {
          'customerIds': customerIds,
          'title': title,
          'body': body,
        },
      );
      final data = response.data as Map?;
      if (!mounted) return;
      final sent = data?['sent'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification envoyée à $sent client(s).')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible d\'envoyer la notification.')));
    } finally {
      if (mounted) setState(() => _isSendingNotification = false);
    }
  }

  void _showNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final targetLabel = _segmentFilter == 'tous'
        ? 'tous les clients affichés'
        : _segmentLabels[_segmentFilter] ?? _segmentFilter;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notification ciblée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destinataires : $targetLabel (${_filtered.length})'),
            SizedBox(height: 2.h),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Message'),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isEmpty || body.isEmpty) return;
              Navigator.pop(dialogContext);
              _sendTargetedNotification(
                  title, body, _filtered.map((c) => c['id'] as String).toList());
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: _isSendingNotification
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.campaign_outlined),
            tooltip: 'Notification ciblée',
            onPressed:
                _isSendingNotification ? null : _showNotificationDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.h),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Tous'),
                            selected: _typeFilter == 'tous',
                            onSelected: (_) =>
                                setState(() => _typeFilter = 'tous'),
                          ),
                          SizedBox(width: 2.w),
                          ..._typeLabels.entries.map((entry) => Padding(
                                padding: EdgeInsets.only(right: 2.w),
                                child: ChoiceChip(
                                  label: Text(entry.value),
                                  selected: _typeFilter == entry.key,
                                  onSelected: (_) =>
                                      setState(() => _typeFilter = entry.key),
                                ),
                              )),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(
                          left: 4.w, right: 4.w, bottom: 1.h),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Tous segments'),
                            selected: _segmentFilter == 'tous',
                            onSelected: (_) =>
                                setState(() => _segmentFilter = 'tous'),
                          ),
                          SizedBox(width: 2.w),
                          ..._segmentLabels.entries.map((entry) => Padding(
                                padding: EdgeInsets.only(right: 2.w),
                                child: ChoiceChip(
                                  label: Text(entry.value),
                                  selected: _segmentFilter == entry.key,
                                  onSelected: (_) => setState(
                                      () => _segmentFilter = entry.key),
                                ),
                              )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: _filtered.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(height: 20.h),
                                  const Center(
                                      child: Text('Aucun client.')),
                                ],
                              )
                            : ListView.separated(
                                padding: EdgeInsets.all(4.w),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
                                  final c = _filtered[index];
                                  final id = c['id'] as String;
                                  final segment = _activitySegment(id);
                                  final grosCompte = _isGrosCompte(id);
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Icon(
                                            _iconForType(c['client_type'])),
                                      ),
                                      title: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              c['company_name'] ??
                                                  c['full_name'] ??
                                                  'Client',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (c['is_vip'] == true) ...[
                                            SizedBox(width: 1.w),
                                            const Icon(
                                                Icons.workspace_premium,
                                                size: 16,
                                                color: Colors.amber),
                                          ],
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            [
                                              _typeLabels[
                                                      c['client_type']] ??
                                                  '',
                                              if ((c['phone'] ?? '')
                                                  .toString()
                                                  .isNotEmpty)
                                                c['phone'],
                                            ]
                                                .where((s) => s != '')
                                                .join(' · '),
                                          ),
                                          if (segment != null ||
                                              grosCompte)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  top: 0.5.h),
                                              child: Wrap(
                                                spacing: 6,
                                                children: [
                                                  if (segment != null)
                                                    Chip(
                                                      label: Text(
                                                          _segmentLabels[
                                                                  segment] ??
                                                              segment),
                                                      visualDensity:
                                                          VisualDensity
                                                              .compact,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                  if (grosCompte)
                                                    const Chip(
                                                      label:
                                                          Text('Gros compte'),
                                                      visualDensity:
                                                          VisualDensity
                                                              .compact,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      isThreeLine: segment != null ||
                                          grosCompte,
                                      trailing:
                                          const Icon(Icons.chevron_right),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => Customer360Screen(
                                              customerId: c['id'] as String),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
