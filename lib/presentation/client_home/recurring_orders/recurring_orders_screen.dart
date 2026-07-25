import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/providers/cart_provider.dart';
import '../../../core/supabase/supabase_config.dart';

/// Gestion des commandes récurrentes du client : voir celles déjà
/// configurées, les mettre en pause/reprendre, les supprimer, ou en créer
/// une nouvelle à partir du panier actuel.
class RecurringOrdersScreen extends StatefulWidget {
  final List<CartItem> cartItemsForNew;

  const RecurringOrdersScreen({super.key, this.cartItemsForNew = const []});

  @override
  State<RecurringOrdersScreen> createState() => _RecurringOrdersScreenState();
}

class _RecurringOrdersScreenState extends State<RecurringOrdersScreen> {
  List<Map<String, dynamic>> _recurringOrders = [];
  bool _isLoading = true;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  String? get _myId =>
      SupabaseConfig.isConfigured ? SupabaseConfig.client.auth.currentUser?.id : null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_myId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await SupabaseConfig.client
          .from('recurring_orders')
          .select('*, recurring_order_items(*)')
          .eq('customer_id', _myId!)
          .order('created_at', ascending: false);
      setState(() {
        _recurringOrders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createFromCart() async {
    if (widget.cartItemsForNew.isEmpty || _myId == null) return;

    int frequency = 30;
    final confirmed = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle commande récurrente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${widget.cartItemsForNew.length} article(s) de votre panier actuel seront recommandés automatiquement.'),
              const SizedBox(height: 16),
              const Text('Fréquence'),
              Wrap(
                spacing: 8,
                children: [7, 14, 30, 60].map((d) {
                  return ChoiceChip(
                    label: Text(d == 7
                        ? 'Chaque semaine'
                        : d == 14
                            ? 'Toutes les 2 semaines'
                            : d == 30
                                ? 'Chaque mois'
                                : 'Tous les 2 mois'),
                    selected: frequency == d,
                    onSelected: (_) => setDialogState(() => frequency = d),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, frequency),
              child: const Text('Activer'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null) return;

    try {
      final created = await SupabaseConfig.client
          .from('recurring_orders')
          .insert({
            'customer_id': _myId,
            'frequency_days': confirmed,
            'next_run_date':
                DateTime.now().add(Duration(days: confirmed)).toIso8601String().split('T').first,
          })
          .select()
          .single();

      await SupabaseConfig.client.from('recurring_order_items').insert(
            widget.cartItemsForNew
                .map((item) => {
                      'recurring_order_id': created['id'],
                      'product_id': item.productId,
                      'product_name': item.name,
                      'quantity': item.quantity,
                      'unit_price': item.unitPrice,
                    })
                .toList(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande récurrente activée !')),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création.')),
      );
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> ro) async {
    try {
      await SupabaseConfig.client
          .from('recurring_orders')
          .update({'active': !(ro['active'] as bool)}).eq('id', ro['id']);
      _load();
    } catch (_) {}
  }

  Future<void> _delete(Map<String, dynamic> ro) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette commande récurrente ?'),
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
      await SupabaseConfig.client
          .from('recurring_orders')
          .delete()
          .eq('id', ro['id']);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Commandes récurrentes')),
      floatingActionButton: widget.cartItemsForNew.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createFromCart,
              icon: const Icon(Icons.autorenew),
              label: const Text('Depuis mon panier'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recurringOrders.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Text(
                      widget.cartItemsForNew.isNotEmpty
                          ? 'Aucune commande récurrente pour le moment.\nUtilisez le bouton ci-dessous pour en créer une à partir de votre panier actuel.'
                          : 'Aucune commande récurrente pour le moment.\nAjoutez des articles à votre panier, puis revenez ici pour en configurer une.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _recurringOrders.length,
                    separatorBuilder: (_, __) => SizedBox(height: 1.h),
                    itemBuilder: (context, index) {
                      final ro = _recurringOrders[index];
                      final items = List<Map<String, dynamic>>.from(
                          ro['recurring_order_items'] ?? []);
                      final active = ro['active'] as bool? ?? true;
                      final freq = ro['frequency_days'] as int;
                      final nextRun = DateTime.tryParse(ro['next_run_date'] ?? '');

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
                                  Text(
                                    freq == 7
                                        ? 'Chaque semaine'
                                        : freq == 14
                                            ? 'Toutes les 2 semaines'
                                            : freq == 30
                                                ? 'Chaque mois'
                                                : 'Tous les $freq jours',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  Switch(
                                    value: active,
                                    onChanged: (_) => _toggleActive(ro),
                                  ),
                                ],
                              ),
                              ...items.map((item) => Text(
                                  '• ${item['product_name']} × ${item['quantity']}',
                                  style: theme.textTheme.bodySmall)),
                              if (nextRun != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 0.5.h),
                                  child: Text(
                                    'Prochaine commande : ${DateFormat('dd/MM/yyyy').format(nextRun)}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: theme
                                                .colorScheme.primary),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _delete(ro),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18),
                                  label: const Text('Supprimer'),
                                ),
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
