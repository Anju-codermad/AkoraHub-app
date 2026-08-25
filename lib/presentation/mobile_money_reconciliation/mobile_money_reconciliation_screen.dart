import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/payment/payment_methods.dart';
import '../../core/supabase/supabase_config.dart';

/// Rapprochement manuel des paiements Mobile Money confirmés par SMS.
///
/// Contexte (25/08) : les API marchandes Papi.mg/FiveOne Pay confirment
/// automatiquement les paiements en ligne, mais leurs tarifs restent
/// élevés pour tout le volume. En complément, un téléphone Android dédié
/// (SIM marchande + appli SMS-vers-webhook) relaie chaque SMS de
/// confirmation Mvola/Orange Money/Airtel Money vers la fonction Edge
/// `mobile-money-sms-webhook`, qui tente un rapprochement automatique
/// (voir supabase/phase180_patch_mobile_money_sms_reconciliation.sql).
/// Cet écran ne montre que les SMS que l'automatisation n'a PAS réussi à
/// rapprocher seule (montant ambigu entre plusieurs commandes, ou
/// commande introuvable) — le staff choisit alors la bonne commande, ou
/// ignore le SMS s'il ne correspond à aucune vente AkoraHub.
class MobileMoneyReconciliationScreen extends StatefulWidget {
  const MobileMoneyReconciliationScreen({super.key});

  @override
  State<MobileMoneyReconciliationScreen> createState() =>
      _MobileMoneyReconciliationScreenState();
}

class _MobileMoneyReconciliationScreenState
    extends State<MobileMoneyReconciliationScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);
  final _dateFormat = DateFormat('dd/MM HH:mm');

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
      final rows = await SupabaseConfig.client
          .from('mobile_money_sms_events')
          .select('*')
          .eq('match_status', 'unmatched')
          .order('sms_received_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _events = List<Map<String, dynamic>>.from(rows as List);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les paiements à rapprocher.';
      });
    }
  }

  PaymentMethod? _operatorOf(Map<String, dynamic> event) {
    switch (event['operator']) {
      case 'mvola':
        return PaymentMethod.mvola;
      case 'orange_money':
        return PaymentMethod.orangeMoney;
      case 'airtel_money':
        return PaymentMethod.airtelMoney;
    }
    return null;
  }

  Future<void> _ignore(Map<String, dynamic> event) async {
    try {
      await SupabaseConfig.client.rpc(
        'ignore_mobile_money_sms_event',
        params: {'p_event_id': event['id']},
      );
      if (!mounted) return;
      setState(() => _events.removeWhere((e) => e['id'] == event['id']));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ignorer ce SMS.')),
      );
    }
  }

  Future<void> _pickOrderAndMatch(Map<String, dynamic> event) async {
    final operator = _operatorOf(event);
    if (operator == null) return;

    List<Map<String, dynamic>> candidates = [];
    try {
      final rows = await SupabaseConfig.client
          .from('orders')
          .select('id, order_number, total_amount, created_at, '
              'profiles(full_name, company_name)')
          .eq('payment_status', 'en_attente')
          .eq('payment_method', operator.id)
          .order('created_at', ascending: false)
          .limit(50);
      candidates = List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger les commandes.')),
      );
      return;
    }
    if (!mounted) return;

    final parsedAmount = (event['parsed_amount'] as num?)?.toDouble();
    candidates.sort((a, b) {
      final aMatch = (a['total_amount'] as num?)?.toDouble() == parsedAmount;
      final bMatch = (b['total_amount'] as num?)?.toDouble() == parsedAmount;
      if (aMatch == bMatch) return 0;
      return aMatch ? -1 : 1;
    });

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => candidates.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Aucune commande en attente pour cet opérateur.'),
                ),
              )
            : ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.all(4.w),
                itemCount: candidates.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final order = candidates[i];
                  final amount = (order['total_amount'] as num?)?.toDouble();
                  final profile =
                      order['profiles'] as Map<String, dynamic>?;
                  final name = profile?['company_name'] ??
                      profile?['full_name'] ??
                      'Client';
                  return ListTile(
                    title: Text('${order['order_number']} — $name'),
                    subtitle: Text(amount != null
                        ? _currency.format(amount)
                        : 'Montant inconnu'),
                    trailing: amount == parsedAmount
                        ? Icon(Icons.check_circle,
                            color: Colors.green.shade600)
                        : null,
                    onTap: () => Navigator.pop(context, order),
                  );
                },
              ),
      ),
    );
    if (selected == null || !mounted) return;

    try {
      await SupabaseConfig.client.rpc(
        'manually_match_mobile_money_payment',
        params: {'p_event_id': event['id'], 'p_order_id': selected['id']},
      );
      if (!mounted) return;
      setState(() => _events.removeWhere((e) => e['id'] == event['id']));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commande ${selected['order_number']} marquée payée.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de rapprocher ce paiement.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Paiements Mobile Money à rapprocher')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _events.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            Icon(Icons.check_circle_outline,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant),
                            SizedBox(height: 1.h),
                            const Center(
                              child: Text('Aucun paiement en attente de '
                                  'rapprochement.'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _events.length,
                          separatorBuilder: (_, __) => SizedBox(height: 1.h),
                          itemBuilder: (context, i) {
                            final event = _events[i];
                            final operator = _operatorOf(event);
                            final amount =
                                (event['parsed_amount'] as num?)?.toDouble();
                            final receivedAt =
                                DateTime.tryParse(
                                    event['sms_received_at'] ?? '');
                            return Card(
                              child: Padding(
                                padding: EdgeInsets.all(3.w),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          operator?.icon ??
                                              Icons.phone_android_outlined,
                                          size: 20,
                                        ),
                                        SizedBox(width: 2.w),
                                        Text(
                                          operator?.label ??
                                              (event['operator'] ?? ''),
                                          style: theme.textTheme.titleSmall,
                                        ),
                                        const Spacer(),
                                        if (receivedAt != null)
                                          Text(
                                            _dateFormat.format(receivedAt),
                                            style: theme.textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      amount != null
                                          ? _currency.format(amount)
                                          : 'Montant non détecté',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    if (event['parsed_sender_phone'] != null)
                                      Text(
                                        'De : ${event['parsed_sender_phone']}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      event['raw_text'] ?? '',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 1.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _ignore(event),
                                          child: const Text('Ignorer'),
                                        ),
                                        SizedBox(width: 2.w),
                                        FilledButton(
                                          onPressed: operator == null
                                              ? null
                                              : () => _pickOrderAndMatch(event),
                                          child: const Text('Rapprocher'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
