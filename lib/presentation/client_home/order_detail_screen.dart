import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:sizer/sizer.dart';

import '../../core/pdf/document_pdf_generator.dart';
import '../../core/payment/payment_methods.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'chat_screen.dart';
import 'delivery_tracking_screen.dart';
import 'orders_tab.dart';

/// Détail d'une commande (CRM/Commandes Lot 1, 03/08) — jusqu'ici une
/// commande n'était pas cliquable dans `_OrdersList` (contrairement aux
/// devis, qui ouvrent déjà `QuoteThreadClient`). Toutes les données
/// nécessaires (articles, adresse de livraison) sont déjà chargées par
/// `_OrdersList` via `select('*, order_items(*))` — aucune nouvelle
/// requête nécessaire, l'`order` complet est simplement passé en
/// paramètre.
class OrderDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({super.key, required this.order});

  Future<void> _downloadInvoice(BuildContext context) async {
    try {
      final customer = SupabaseConfig.client.auth.currentUser;
      Map<String, dynamic>? profile;
      if (customer != null) {
        profile = await SupabaseConfig.client
            .from('profiles')
            .select()
            .eq('id', customer.id)
            .maybeSingle();
      }
      final items =
          List<Map<String, dynamic>>.from(order['order_items'] ?? []);
      final bytes = await DocumentPdfGenerator.build(
        documentType: 'Facture',
        documentNumber: order['order_number'] ?? '',
        date: DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now(),
        customer: profile,
        items: items,
        totalAmount: (order['total_amount'] ?? 0).toDouble(),
      );
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la génération du PDF.')),
      );
    }
  }

  void _contactSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          initialMessage:
              'Bonjour, j\'ai une question concernant ma commande '
              '${order['order_number'] ?? ''}.',
        ),
      ),
    );
  }

  /// Réservé aux commandes encore "reçue" — voir la policy RLS dédiée
  /// `orders_update_own_cancel_if_recue` (Phase 64) : un client ne peut
  /// annuler que depuis ce statut précis, jamais une commande déjà en
  /// préparation/expédiée.
  Future<void> _cancelOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: Text(
            'Voulez-vous vraiment annuler la commande ${order['order_number'] ?? ''} ? Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Annuler la commande'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseConfig.client
          .from('orders')
          .update({'status': 'annulee'})
          .eq('id', order['id'])
          .eq('status', 'recue');
      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible d\'annuler cette commande.')));
    }
  }

  void _reorder(BuildContext context, WidgetRef ref) {
    final items = List<Map<String, dynamic>>.from(order['order_items'] ?? []);
    for (final item in items) {
      ref.read(cartProvider.notifier).addItem(CartItem(
            productId: item['product_id'] ?? '',
            name: item['product_name'] ?? '',
            priceDetail: (item['unit_price'] ?? 0).toDouble(),
            priceGros: (item['unit_price'] ?? 0).toDouble(),
            grosThresholdQty: 999999,
            quantity: (item['quantity'] ?? 1).toInt(),
          ));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Articles ajoutés au panier.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);
    final dateFormat = DateFormat('d MMM yyyy', 'fr_FR');
    final status = (order['status'] ?? 'recue') as String;
    final cancelled = status == 'annulee';
    final paymentStatus = (order['payment_status'] ?? 'en_attente') as String;
    final paymentMethod =
        PaymentMethodX.fromId(order['payment_method'] as String?);
    final items = List<Map<String, dynamic>>.from(order['order_items'] ?? []);
    final deliveryAddress = (order['delivery_address'] as String?) ?? '';
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');

    return Scaffold(
      appBar: AppBar(title: Text(order['order_number'] ?? 'Commande')),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order['order_number'] ?? '',
                          style: theme.textTheme.titleMedium),
                      Text(
                        currency.format(order['total_amount'] ?? 0),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  if (createdAt != null) ...[
                    SizedBox(height: 0.3.h),
                    Text(
                      'Commandée le ${dateFormat.format(createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  SizedBox(height: 0.8.h),
                  Row(
                    children: [
                      Icon(paymentMethod.icon,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        paymentMethod.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (!cancelled) ...[
                    SizedBox(height: 0.8.h),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                orderPaymentStatusColor(paymentStatus, theme),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          orderPaymentStatusLabels[paymentStatus] ??
                              paymentStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: orderPaymentStatusColor(
                                paymentStatus, theme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 2.h),
                  if (!cancelled)
                    OrderProgressBar(status: status)
                  else
                    Chip(
                      label: const Text('Annulée'),
                      backgroundColor: theme.colorScheme.errorContainer,
                    ),
                ],
              ),
            ),
          ),
          if (deliveryAddress.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text('Adresse de livraison', style: theme.textTheme.titleSmall),
            SizedBox(height: 1.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    SizedBox(width: 2.w),
                    Expanded(child: Text(deliveryAddress)),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 2.h),
          Text('Articles', style: theme.textTheme.titleSmall),
          SizedBox(height: 1.h),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  ListTile(
                    title: Text(items[i]['product_name'] ?? ''),
                    subtitle: Text(
                        '${items[i]['quantity']} x ${currency.format(items[i]['unit_price'] ?? 0)}'),
                    trailing: Text(
                      currency.format(
                          ((items[i]['quantity'] as num?) ?? 0) *
                              ((items[i]['unit_price'] as num?) ?? 0)),
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  if (i != items.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: theme.textTheme.titleSmall),
              Text(
                currency.format(order['total_amount'] ?? 0),
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (status == 'expediee')
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeliveryTrackingScreen(order: order),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Suivre sur la carte'),
                ),
              OutlinedButton.icon(
                onPressed: () => _downloadInvoice(context),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Facture PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () => _contactSupport(context),
                icon: const Icon(Icons.support_agent_outlined, size: 18),
                label: const Text('Contacter le support'),
              ),
              if (status == 'recue')
                OutlinedButton.icon(
                  onPressed: () => _cancelOrder(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Annuler la commande'),
                ),
              FilledButton.icon(
                onPressed: () => _reorder(context, ref),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Recommander'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
