import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:sizer/sizer.dart';

import '../../core/pdf/document_pdf_generator.dart';
import '../../core/payment/payment_methods.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'delivery_tracking_screen.dart';
import 'quote_thread_client.dart';

/// Écran "Commandes" du client, avec deux sous-onglets : Commandes et Devis
/// ("Mes devis" — les devis existaient déjà en base, mais n'étaient
/// visibles nulle part côté client avant cet ajout).
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Commandes'),
              Tab(text: 'Devis'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _OrdersList(),
                _QuotesList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends ConsumerStatefulWidget {
  const _OrdersList();

  @override
  ConsumerState<_OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends ConsumerState<_OrdersList> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  final Map<String, String> _statusLabels = const {
    'recue': 'Reçue',
    'en_preparation': 'En préparation',
    'expediee': 'Expédiée',
    'livree': 'Livrée',
    'annulee': 'Annulée',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (!SupabaseConfig.isConfigured || userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final orders = await SupabaseConfig.client
          .from('orders')
          .select('*, order_items(*)')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(orders);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger vos commandes.';
      });
    }
  }

  int _statusStep(String status) {
    const order = ['recue', 'en_preparation', 'expediee', 'livree'];
    final i = order.indexOf(status);
    return i < 0 ? 0 : i;
  }

  static const _paymentStatusLabels = {
    'en_attente': 'Paiement en attente',
    'acompte_verse': 'Acompte versé',
    'paye': 'Paiement confirmé',
    'facture_30j': 'Facturée (30j)',
    'echoue': 'Paiement échoué',
  };

  Color _paymentStatusColor(String paymentStatus, ThemeData theme) {
    switch (paymentStatus) {
      case 'paye':
        return Colors.green;
      case 'acompte_verse':
        return Colors.orange;
      case 'facture_30j':
        return Colors.blue;
      case 'echoue':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  Future<void> _downloadInvoice(Map<String, dynamic> order) async {
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la génération du PDF.')),
      );
    }
  }

  void _reorder(Map<String, dynamic> order) {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('Aucune commande pour le moment.'));
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: EdgeInsets.all(4.w),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => SizedBox(height: 2.h),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final status = order['status'] ?? 'recue';
          final step = _statusStep(status);
          final cancelled = status == 'annulee';
          final paymentStatus =
              (order['payment_status'] ?? 'en_attente') as String;
          final paymentMethod =
              PaymentMethodX.fromId(order['payment_method'] as String?);

          return Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(order['order_number'] ?? '',
                          style: theme.textTheme.titleSmall),
                      Text(_currency.format(order['total_amount'] ?? 0)),
                    ],
                  ),
                  SizedBox(height: 0.3.h),
                  Row(
                    children: [
                      Icon(
                        paymentMethod.icon,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        paymentMethod.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
                            color: _paymentStatusColor(paymentStatus, theme),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _paymentStatusLabels[paymentStatus] ??
                              paymentStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _paymentStatusColor(paymentStatus, theme),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (paymentStatus == 'en_attente' &&
                            !paymentMethod.isPapiCapable) ...[
                          const SizedBox(width: 4),
                          Text(
                            '· vérification sous 24h ouvrées',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  SizedBox(height: 1.5.h),
                  if (!cancelled)
                    Row(
                      children: List.generate(4, (i) {
                        final done = i <= step;
                        return Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 4,
                                color: done
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant,
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                _statusLabels.values.elementAt(i),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: done
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline,
                                  fontWeight: done
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }),
                    )
                  else
                    Chip(
                      label: const Text('Annulée'),
                      backgroundColor: theme.colorScheme.errorContainer,
                    ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (status == 'expediee')
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DeliveryTrackingScreen(order: order),
                            ),
                          ),
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Suivre sur la carte'),
                        ),
                      TextButton.icon(
                        onPressed: () => _downloadInvoice(order),
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            size: 18),
                        label: const Text('Facture PDF'),
                      ),
                      TextButton.icon(
                        onPressed: () => _reorder(order),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Recommander'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuotesList extends ConsumerStatefulWidget {
  const _QuotesList();

  @override
  ConsumerState<_QuotesList> createState() => _QuotesListState();
}

class _QuotesListState extends ConsumerState<_QuotesList> {
  List<Map<String, dynamic>> _quotes = [];
  bool _isLoading = true;
  String? _error;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  final Map<String, String> _statusLabels = const {
    'en_attente': 'En attente',
    'envoye': 'Envoyé',
    'accepte': 'Accepté',
    'refuse': 'Refusé',
    'expire': 'Expiré',
  };

  Color _statusColor(ThemeData theme, String status) {
    switch (status) {
      case 'accepte':
        return theme.colorScheme.primary;
      case 'refuse':
      case 'expire':
        return theme.colorScheme.error;
      case 'envoye':
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (!SupabaseConfig.isConfigured || userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final quotes = await SupabaseConfig.client
          .from('quotes')
          .select('*, quote_items(*)')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);
      setState(() {
        _quotes = List<Map<String, dynamic>>.from(quotes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger vos devis.';
      });
    }
  }

  Future<void> _downloadQuotePdf(Map<String, dynamic> quote) async {
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
          List<Map<String, dynamic>>.from(quote['quote_items'] ?? []);
      final bytes = await DocumentPdfGenerator.build(
        documentType: 'Devis',
        documentNumber: quote['quote_number'] ?? '',
        date: DateTime.tryParse(quote['created_at'] ?? '') ?? DateTime.now(),
        customer: profile,
        items: items,
        totalAmount: (quote['total_amount'] ?? 0).toDouble(),
      );
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la génération du PDF.')),
      );
    }
  }

  void _reorder(Map<String, dynamic> quote) {
    final items = List<Map<String, dynamic>>.from(quote['quote_items'] ?? []);
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
        content: Text('Articles du devis ajoutés au panier.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_quotes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            'Aucun devis pour le moment. Depuis votre panier, utilisez '
            '"Demander un devis" pour en créer un.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuotes,
      child: ListView.separated(
        padding: EdgeInsets.all(4.w),
        itemCount: _quotes.length,
        separatorBuilder: (_, __) => SizedBox(height: 2.h),
        itemBuilder: (context, index) {
          final quote = _quotes[index];
          final status = (quote['status'] ?? 'en_attente').toString();
          final items =
              List<Map<String, dynamic>>.from(quote['quote_items'] ?? []);
          final canReorder = items.isNotEmpty &&
              (status == 'accepte' || status == 'envoye');

          return Card(
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuoteThreadClient(quote: quote),
                  ),
                );
                _loadQuotes();
              },
              child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(quote['quote_number'] ?? '',
                            style: theme.textTheme.titleSmall),
                      ),
                      Chip(
                        label: Text(
                          _statusLabels[status] ?? status,
                          style: TextStyle(
                            color: _statusColor(theme, status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor:
                            _statusColor(theme, status).withValues(alpha: 0.12),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${items.length} article${items.length > 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.bodyMedium),
                      Text(
                        _currency.format(quote['total_amount'] ?? 0),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _downloadQuotePdf(quote),
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            size: 18),
                        label: const Text('Devis PDF'),
                      ),
                      if (canReorder)
                        TextButton.icon(
                          onPressed: () => _reorder(quote),
                          icon: const Icon(Icons.shopping_cart_outlined,
                              size: 18),
                          label: const Text('Commander'),
                        ),
                    ],
                  ),
                ],
              ),
              ),
            ),
          );
        },
      ),
    );
  }
}
