import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';

class CartTab extends ConsumerStatefulWidget {
  const CartTab({super.key});

  @override
  ConsumerState<CartTab> createState() => _CartTabState();
}

class _CartTabState extends ConsumerState<CartTab> {
  bool _isSubmitting = false;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  String _generateNumber(String prefix) {
    final now = DateTime.now();
    final ms = now.millisecondsSinceEpoch.toString().substring(7);
    return '$prefix-${DateFormat('yyyyMM').format(now)}-$ms';
  }

  Future<void> _submit({required bool asQuote}) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final total = ref.read(cartProvider.notifier).total;

      if (asQuote) {
        final quoteNumber = _generateNumber('DEV');
        final quote = await SupabaseConfig.client
            .from('quotes')
            .insert({
              'quote_number': quoteNumber,
              'customer_id': userId,
              'total_amount': total,
            })
            .select()
            .single();

        await SupabaseConfig.client.from('quote_items').insert(
              cart
                  .map((item) => {
                        'quote_id': quote['id'],
                        'product_id': item.productId,
                        'product_name': item.name,
                        'quantity': item.quantity,
                        'unit_price': item.unitPrice,
                      })
                  .toList(),
            );
      } else {
        final orderNumber = _generateNumber('CMD');
        final order = await SupabaseConfig.client
            .from('orders')
            .insert({
              'order_number': orderNumber,
              'customer_id': userId,
              'total_amount': total,
            })
            .select()
            .single();

        await SupabaseConfig.client.from('order_items').insert(
              cart
                  .map((item) => {
                        'order_id': order['id'],
                        'product_id': item.productId,
                        'product_name': item.name,
                        'quantity': item.quantity,
                        'unit_price': item.unitPrice,
                        'is_gros_price': item.isGrosPrice,
                      })
                  .toList(),
            );
      }

      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(asQuote
              ? 'Demande de devis envoyée !'
              : 'Commande passée avec succès !'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi. Réessayez.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).total;

    if (cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 56, color: theme.colorScheme.outline),
            SizedBox(height: 2.h),
            const Text('Votre panier est vide.'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: cart.length,
            separatorBuilder: (_, __) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              final item = cart[index];
              return Card(
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              '${_currency.format(item.unitPrice)} / unité'
                              '${item.isGrosPrice ? " (Gros)" : ""}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(
                                item.productId, item.quantity - 1),
                      ),
                      Text('${item.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(
                                item.productId, item.quantity + 1),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: theme.textTheme.titleMedium),
                  Text(
                    _currency.format(total),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => _submit(asQuote: true),
                      child: const Text('Demander un devis'),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submit(asQuote: false),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Commander'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
