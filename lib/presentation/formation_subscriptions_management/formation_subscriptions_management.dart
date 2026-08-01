import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Validation des demandes d'abonnement Formation (accès payant aux fiches
/// détaillées de matières premières — voir supabase/phase40_schema.sql).
/// Même logique que la vérification manuelle des paiements de commande :
/// le client transfère et indique une référence/preuve, le staff active.
class FormationSubscriptionsManagement extends StatefulWidget {
  const FormationSubscriptionsManagement({super.key});

  @override
  State<FormationSubscriptionsManagement> createState() =>
      _FormationSubscriptionsManagementState();
}

class _FormationSubscriptionsManagementState
    extends State<FormationSubscriptionsManagement> {
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'en_attente';
  final _currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

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
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('formation_subscriptions')
            .select('*, profiles(full_name, company_name)')
            .order('created_at', ascending: false),
        SupabaseConfig.client.from('formation_plan_pricing').select().order('price'),
      ]);
      setState(() {
        _subscriptions = List<Map<String, dynamic>>.from(results[0]);
        _plans = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les abonnements (migration phase40 exécutée ?).';
      });
    }
  }

  Future<void> _editPlanPrice(Map<String, dynamic> plan) async {
    final ctrl = TextEditingController(text: (plan['price'] ?? '').toString());
    final newPrice = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tarif — ${plan['label']}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Prix (Ar)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, double.tryParse(ctrl.text)),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (newPrice == null) return;
    try {
      await SupabaseConfig.client
          .from('formation_plan_pricing')
          .update({'price': newPrice, 'updated_at': DateTime.now().toIso8601String()})
          .eq('plan', plan['plan']);
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur lors de la mise à jour du tarif.')));
    }
  }

  Future<void> _activate(Map<String, dynamic> sub) async {
    final isAnnual = sub['plan'] == 'annuel';
    final now = DateTime.now();
    final expiresAt = isAnnual
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);
    try {
      await SupabaseConfig.client.from('formation_subscriptions').update({
        'status': 'actif',
        'started_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'updated_at': now.toIso8601String(),
      }).eq('id', sub['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Abonnement activé.')));
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur lors de l\'activation.')));
    }
  }

  Future<void> _refuse(Map<String, dynamic> sub) async {
    try {
      await SupabaseConfig.client.from('formation_subscriptions').update({
        'status': 'refuse',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', sub['id']);
      if (!mounted) return;
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur lors du refus.')));
    }
  }

  Future<void> _viewProof(Map<String, dynamic> sub) async {
    final path = sub['payment_proof_path'] as String?;
    if (path == null) return;
    try {
      final url = await SupabaseConfig.client.storage
          .from('payment-proofs')
          .createSignedUrl(path, 300);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Image.network(url, errorBuilder: (_, __, ___) =>
              const Padding(padding: EdgeInsets.all(24), child: Text('Impossible d\'afficher l\'image.'))),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Impossible de charger la preuve de paiement.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _subscriptions
        .where((s) => _statusFilter == 'tous' || s['status'] == _statusFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Abonnements Formation')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: EdgeInsets.all(4.w),
                    children: [
                      if (_plans.isNotEmpty) ...[
                        Text('Tarifs', style: theme.textTheme.titleMedium),
                        SizedBox(height: 1.h),
                        ..._plans.map((p) => Card(
                              child: ListTile(
                                title: Text(p['label'] ?? ''),
                                subtitle: Text(_currency.format(p['price'])),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _editPlanPrice(p),
                                ),
                              ),
                            )),
                        SizedBox(height: 2.h),
                      ],
                      Text('Demandes d\'abonnement',
                          style: theme.textTheme.titleMedium),
                      SizedBox(height: 1.h),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final status in [
                            'en_attente',
                            'actif',
                            'refuse',
                            'expire',
                            'tous'
                          ])
                            ChoiceChip(
                              label: Text(status == 'tous'
                                  ? 'Tous'
                                  : status == 'en_attente'
                                      ? 'En attente'
                                      : status == 'actif'
                                          ? 'Actifs'
                                          : status == 'refuse'
                                              ? 'Refusés'
                                              : 'Expirés'),
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
                        ...filtered.map((sub) {
                          final profile = sub['profiles'] as Map?;
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
                                          profile?['company_name'] ??
                                              profile?['full_name'] ??
                                              'Client',
                                          style: theme.textTheme.titleSmall,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(sub['status'],
                                            style:
                                                const TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  Text(
                                      'Plan ${sub['plan']} · ${_currency.format(sub['amount'])}'),
                                  if (sub['payment_reference'] != null)
                                    Text('Référence : ${sub['payment_reference']}'),
                                  if (sub['expires_at'] != null)
                                    Text(
                                        'Expire le ${_dateFormat.format(DateTime.parse(sub['expires_at']))}'),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (sub['payment_proof_path'] != null)
                                        TextButton.icon(
                                          onPressed: () => _viewProof(sub),
                                          icon: const Icon(Icons.image_outlined,
                                              size: 18),
                                          label: const Text('Preuve'),
                                        ),
                                      if (sub['status'] == 'en_attente') ...[
                                        TextButton(
                                          onPressed: () => _refuse(sub),
                                          child: const Text('Refuser'),
                                        ),
                                        FilledButton(
                                          onPressed: () => _activate(sub),
                                          child: const Text('Activer'),
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
