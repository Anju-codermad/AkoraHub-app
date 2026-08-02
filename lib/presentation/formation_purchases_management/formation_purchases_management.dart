import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Validation des demandes d'achat Formation, produit par produit (voir
/// supabase/phase45_patch_formation_per_product_pricing.sql) — remplace
/// l'ancienne gestion des abonnements (formation_subscriptions_management,
/// supprimé le 01/08). Même logique que la vérification manuelle des
/// paiements de commande : le client transfère et indique une
/// référence/preuve, le staff valide. Les lignes d'un même achat
/// (plusieurs produits à la fois) partagent un `batch_id` — regroupées
/// ici pour être validées/refusées ensemble en un clic.
///
/// Depuis le 02/08 : contenu sans Scaffold propre, utilisé comme onglet
/// de FormationPurchasesHub (fusion avec CoursePurchasesManagement) —
/// voir formation_purchases_hub.dart.
class FormationPurchasesManagement extends StatefulWidget {
  const FormationPurchasesManagement({super.key});

  @override
  State<FormationPurchasesManagement> createState() =>
      _FormationPurchasesManagementState();
}

class _FormationPurchasesManagementState
    extends State<FormationPurchasesManagement> {
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _tiers = [];
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
            .from('formation_purchases')
            .select(
                '*, profiles(full_name, company_name), raw_materials(name)')
            .order('requested_at', ascending: false),
        SupabaseConfig.client
            .from('formation_pricing_tiers')
            .select()
            .order('min_quantity'),
      ]);
      setState(() {
        _purchases = List<Map<String, dynamic>>.from(results[0]);
        _tiers = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger les achats (migration phase45 exécutée ?).';
      });
    }
  }

  Future<void> _editTierPrice(Map<String, dynamic> tier) async {
    final ctrl = TextEditingController(text: (tier['price'] ?? '').toString());
    final newPrice = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Palier — à partir de ${tier['min_quantity']} produit(s)'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Prix par produit (Ar)'),
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
          .from('formation_pricing_tiers')
          .update({
            'price': newPrice,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('min_quantity', tier['min_quantity']);
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour du tarif.')));
    }
  }

  /// Regroupe les lignes par `batch_id` — un même achat (plusieurs
  /// produits en une fois) se valide/refuse en bloc.
  List<List<Map<String, dynamic>>> _groupByBatch(
      List<Map<String, dynamic>> purchases) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final p in purchases) {
      groups.putIfAbsent(p['batch_id'] as String, () => []).add(p);
    }
    final result = groups.values.toList();
    result.sort((a, b) => (b.first['requested_at'] as String)
        .compareTo(a.first['requested_at'] as String));
    return result;
  }

  Future<void> _validateBatch(List<Map<String, dynamic>> batch) async {
    try {
      await SupabaseConfig.client
          .from('formation_purchases')
          .update({
            'status': 'validee',
            'validated_at': DateTime.now().toIso8601String(),
          })
          .eq('batch_id', batch.first['batch_id'])
          .eq('status', 'en_attente');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Achat validé.')));
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la validation.')));
    }
  }

  Future<void> _refuseBatch(List<Map<String, dynamic>> batch) async {
    try {
      await SupabaseConfig.client
          .from('formation_purchases')
          .update({'status': 'refusee'})
          .eq('batch_id', batch.first['batch_id'])
          .eq('status', 'en_attente');
      if (!mounted) return;
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur lors du refus.')));
    }
  }

  Future<void> _viewProof(Map<String, dynamic> purchase) async {
    final path = purchase['payment_proof_path'] as String?;
    if (path == null) return;
    try {
      final url = await SupabaseConfig.client.storage
          .from('payment-proofs')
          .createSignedUrl(path, 300);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Image.network(url,
              errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Impossible d\'afficher l\'image.'))),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de charger la preuve de paiement.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _purchases
        .where((p) => _statusFilter == 'tous' || p['status'] == _statusFilter)
        .toList();
    final batches = _groupByBatch(filtered);

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                    padding: EdgeInsets.all(4.w),
                    children: [
                      if (_tiers.isNotEmpty) ...[
                        Text('Paliers de prix', style: theme.textTheme.titleMedium),
                        SizedBox(height: 1.h),
                        ..._tiers.map((t) => Card(
                              child: ListTile(
                                title: Text(
                                    'À partir de ${t['min_quantity']} produit(s)'),
                                subtitle:
                                    Text('${_currency.format(t['price'])} / produit'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _editTierPrice(t),
                                ),
                              ),
                            )),
                        SizedBox(height: 2.h),
                      ],
                      Text('Demandes d\'achat', style: theme.textTheme.titleMedium),
                      SizedBox(height: 1.h),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final status in [
                            'en_attente',
                            'validee',
                            'refusee',
                            'tous'
                          ])
                            ChoiceChip(
                              label: Text(status == 'tous'
                                  ? 'Tous'
                                  : status == 'en_attente'
                                      ? 'En attente'
                                      : status == 'validee'
                                          ? 'Validés'
                                          : 'Refusés'),
                              selected: _statusFilter == status,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = status),
                            ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      if (batches.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Center(
                            child: Text('Aucune demande.',
                                style: theme.textTheme.bodyMedium),
                          ),
                        )
                      else
                        ...batches.map((batch) {
                          final first = batch.first;
                          final profile = first['profiles'] as Map?;
                          final status = first['status'] as String;
                          final total = batch.fold<num>(
                              0, (sum, p) => sum + (p['amount'] as num));
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
                                        label: Text(status,
                                            style:
                                                const TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(batch
                                      .map((p) =>
                                          (p['raw_materials'] as Map?)?['name'] ??
                                          '')
                                      .join(', ')),
                                  Text(
                                      '${batch.length} produit(s) · ${_currency.format(total)}'),
                                  if (first['payment_reference'] != null)
                                    Text('Référence : ${first['payment_reference']}'),
                                  Text(
                                      'Demandé le ${_dateFormat.format(DateTime.parse(first['requested_at']))}'),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (first['payment_proof_path'] != null)
                                        TextButton.icon(
                                          onPressed: () => _viewProof(first),
                                          icon: const Icon(Icons.image_outlined,
                                              size: 18),
                                          label: const Text('Preuve'),
                                        ),
                                      if (status == 'en_attente') ...[
                                        TextButton(
                                          onPressed: () => _refuseBatch(batch),
                                          child: const Text('Refuser'),
                                        ),
                                        FilledButton(
                                          onPressed: () => _validateBatch(batch),
                                          child: const Text('Valider'),
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
                );
  }
}
