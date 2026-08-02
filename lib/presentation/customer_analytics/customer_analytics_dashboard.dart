import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';
import '../customer_360/customer_360_screen.dart';

/// Tableau de bord CRM (Lot 5/5, dernier lot du chantier CRM) —
/// synthèse globale au-dessus de la fiche client 360° (Lot 1) et des
/// segments (Lot 4) : clients actifs, taux de rétention, top clients
/// par valeur, et clients à risque à relancer en priorité. Entièrement
/// dérivé de la vue `customer_segments` (Phase 63) déjà en place pour
/// le Lot 4 — aucune nouvelle table/vue nécessaire.
class CustomerAnalyticsDashboard extends StatefulWidget {
  const CustomerAnalyticsDashboard({super.key});

  @override
  State<CustomerAnalyticsDashboard> createState() =>
      _CustomerAnalyticsDashboardState();
}

class _CustomerAnalyticsDashboardState
    extends State<CustomerAnalyticsDashboard> {
  List<Map<String, dynamic>> _profiles = [];
  List<Map<String, dynamic>> _segments = [];
  bool _isLoading = true;
  String? _error;

  static const int _inactifAfterDays = 90;

  final _currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
            .select('id, company_name, full_name')
            .eq('role', 'client'),
        SupabaseConfig.client.from('customer_segments').select(),
      ]);
      if (!mounted) return;
      setState(() {
        _profiles = List<Map<String, dynamic>>.from(results[0]);
        _segments = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les statistiques.';
      });
    }
  }

  String _nameFor(String customerId) {
    final profile = _profiles.firstWhere(
      (p) => p['id'] == customerId,
      orElse: () => const {},
    );
    return (profile['company_name'] ?? profile['full_name'] ?? 'Client')
        as String;
  }

  bool _isInactif(Map<String, dynamic> s) {
    final lastOrderAt = s['last_order_at'] != null
        ? DateTime.tryParse(s['last_order_at'] as String)
        : null;
    return lastOrderAt != null &&
        DateTime.now().difference(lastOrderAt).inDays > _inactifAfterDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final withOrders =
        _segments.where((s) => ((s['order_count'] as num?) ?? 0) > 0).toList();
    final active = withOrders.where((s) => !_isInactif(s)).toList();
    final recurrent =
        withOrders.where((s) => ((s['order_count'] as num?) ?? 0) >= 2).toList();
    final retentionRate =
        withOrders.isEmpty ? 0.0 : recurrent.length / withOrders.length * 100;
    final atRisk = withOrders.where(_isInactif).toList()
      ..sort((a, b) => ((b['lifetime_value'] as num?) ?? 0)
          .compareTo((a['lifetime_value'] as num?) ?? 0));
    final topClients = [...withOrders]
      ..sort((a, b) => ((b['lifetime_value'] as num?) ?? 0)
          .compareTo((a['lifetime_value'] as num?) ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord CRM')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.all(4.w),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.people_outline,
                              label: 'Clients actifs',
                              value: '${active.length} / ${_profiles.length}',
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.autorenew,
                              label: 'Taux de rétention',
                              value: '${retentionRate.toStringAsFixed(0)}%',
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.warning_amber_outlined,
                              label: 'Clients à risque',
                              value: '${atRisk.length}',
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        child: Text(
                          'Rétention = part des clients ayant recommandé au '
                          'moins une fois. "À risque" = client ayant déjà '
                          'commandé mais silencieux depuis plus de '
                          '$_inactifAfterDays jours.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text('Top clients par valeur totale',
                          style: theme.textTheme.titleMedium),
                      SizedBox(height: 1.h),
                      if (topClients.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          child: Text('Aucun client avec commande pour l\'instant.',
                              style: theme.textTheme.bodyMedium),
                        )
                      else
                        Card(
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < topClients.length && i < 10;
                                  i++) ...[
                                ListTile(
                                  leading: CircleAvatar(
                                      child: Text('${i + 1}')),
                                  title: Text(_nameFor(
                                      topClients[i]['customer_id'] as String)),
                                  subtitle: Text(
                                      '${topClients[i]['order_count']} commande(s)'),
                                  trailing: Text(
                                    _currency.format(
                                        topClients[i]['lifetime_value'] ?? 0),
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Customer360Screen(
                                          customerId: topClients[i]
                                              ['customer_id'] as String),
                                    ),
                                  ),
                                ),
                                if (i != topClients.length - 1 && i != 9)
                                  const Divider(height: 1),
                              ],
                            ],
                          ),
                        ),
                      SizedBox(height: 2.h),
                      Text('Clients à relancer en priorité',
                          style: theme.textTheme.titleMedium),
                      SizedBox(height: 1.h),
                      if (atRisk.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          child: Text('Aucun client inactif pour l\'instant.',
                              style: theme.textTheme.bodyMedium),
                        )
                      else
                        Card(
                          child: Column(
                            children: [
                              for (var i = 0; i < atRisk.length && i < 10; i++) ...[
                                ListTile(
                                  leading: const Icon(Icons.person_off_outlined),
                                  title: Text(_nameFor(
                                      atRisk[i]['customer_id'] as String)),
                                  subtitle: Text(
                                    'Dernière commande le '
                                    '${_dateFormat.format(DateTime.parse(atRisk[i]['last_order_at']))}',
                                  ),
                                  trailing: Text(
                                    _currency.format(
                                        atRisk[i]['lifetime_value'] ?? 0),
                                    style: theme.textTheme.labelLarge,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Customer360Screen(
                                          customerId: atRisk[i]['customer_id']
                                              as String),
                                    ),
                                  ),
                                ),
                                if (i != atRisk.length - 1 && i != 9)
                                  const Divider(height: 1),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.5.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            SizedBox(height: 0.5.h),
            Text(value,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
