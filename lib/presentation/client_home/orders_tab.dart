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
import 'order_detail_screen.dart';
import 'quote_thread_client.dart';

const orderStatusLabels = {
  'recue': 'Reçue',
  'en_preparation': 'En préparation',
  'expediee': 'Expédiée',
  'livree': 'Livrée',
};
const orderStatusIcons = {
  'recue': Icons.receipt_long_outlined,
  'en_preparation': Icons.inventory_2_outlined,
  'expediee': Icons.local_shipping_outlined,
  'livree': Icons.home_outlined,
};

int orderStatusStep(String status) {
  const order = ['recue', 'en_preparation', 'expediee', 'livree'];
  final i = order.indexOf(status);
  return i < 0 ? 0 : i;
}

/// Étiquette de période (Lot 5) : "Aujourd'hui"/"Hier"/"Cette semaine" pour
/// le plus récent, sinon un libellé mois/année ("Juillet 2026") — pour
/// aider un client avec beaucoup d'historique à repérer une commande sans
/// scroller ligne par ligne.
String periodGroupLabel(DateTime date) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfYesterday = startOfToday.subtract(const Duration(days: 1));
  final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));
  if (!date.isBefore(startOfToday)) return "Aujourd'hui";
  if (!date.isBefore(startOfYesterday)) return 'Hier';
  if (!date.isBefore(startOfWeek)) return 'Cette semaine';
  if (date.year == now.year && date.month == now.month) return 'Ce mois-ci';
  final label = DateFormat('MMMM yyyy', 'fr_FR').format(date);
  return label[0].toUpperCase() + label.substring(1);
}

/// Aplatit une liste triée par `created_at` décroissant en une suite de
/// `String` (en-tête de période) et `Map` (l'élément lui-même), prête pour
/// un `ListView.builder` sans sous-widgets dédiés à la section.
List<dynamic> groupRowsByPeriod(List<Map<String, dynamic>> items) {
  final rows = <dynamic>[];
  String? currentLabel;
  for (final item in items) {
    final date = DateTime.tryParse(item['created_at'] ?? '');
    final label = date != null ? periodGroupLabel(date) : 'Date inconnue';
    if (label != currentLabel) {
      rows.add(label);
      currentLabel = label;
    }
    rows.add(item);
  }
  return rows;
}

const orderPaymentStatusLabels = {
  'en_attente': 'Paiement en attente',
  'acompte_verse': 'Acompte versé',
  'paye': 'Paiement confirmé',
  'facture_30j': 'Facturée (30j)',
  'echoue': 'Paiement échoué',
};

Color orderPaymentStatusColor(String paymentStatus, ThemeData theme) {
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

/// Barre de progression d'une commande (4 étapes), utilisée à la fois
/// dans la liste (`_OrdersList`) et dans `OrderDetailScreen` — icône +
/// barre colorée par étape, plutôt qu'un simple texte.
class OrderProgressBar extends StatelessWidget {
  final String status;

  const OrderProgressBar({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = orderStatusStep(status);
    return Row(
      children: List.generate(4, (i) {
        final done = i <= step;
        final key = orderStatusLabels.keys.elementAt(i);
        return Expanded(
          child: Column(
            children: [
              Icon(
                orderStatusIcons[key],
                size: 16,
                color: done
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(height: 2),
              Container(
                height: 4,
                color: done
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
              SizedBox(height: 0.5.h),
              Text(
                orderStatusLabels[key]!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: done
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Écran "Commandes" du client, avec deux sous-onglets : Commandes et Devis
/// ("Mes devis" — les devis existaient déjà en base, mais n'étaient
/// visibles nulle part côté client avant cet ajout).
class OrdersTab extends StatelessWidget {
  /// Onglet ouvert au départ (0 = Commandes, 1 = Devis) — utilisé par le
  /// raccourci "en attente" de l'accueil (catalog_tab.dart, Lot 4) pour
  /// amener directement sur le bon onglet selon ce qui nécessite une
  /// action du client.
  final int initialTabIndex;

  const OrdersTab({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
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

  // Filtres (Lot 2, client-side — le nombre de commandes d'un client reste
  // modeste, pas besoin d'aller-retour serveur par filtre).
  String _statusFilter = 'tous';
  String _periodFilter = 'tous';
  final _searchController = TextEditingController();

  static const _periodFilterDays = {
    '30j': 30,
    '90j': 90,
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    final days = _periodFilterDays[_periodFilter];
    final cutoff =
        days != null ? DateTime.now().subtract(Duration(days: days)) : null;
    return _orders.where((o) {
      if (_statusFilter != 'tous' && (o['status'] ?? 'recue') != _statusFilter) {
        return false;
      }
      if (query.isNotEmpty &&
          !((o['order_number'] as String? ?? '')
              .toLowerCase()
              .contains(query))) {
        return false;
      }
      if (cutoff != null) {
        final createdAt = DateTime.tryParse(o['created_at'] ?? '');
        if (createdAt == null || createdAt.isBefore(cutoff)) return false;
      }
      return true;
    }).toList();
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
      return const _OrdersSkeleton();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            SizedBox(height: 1.5.h),
            FilledButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('Aucune commande pour le moment.'));
    }

    final filtered = _filteredOrders;
    final rows = groupRowsByPeriod(filtered);

    return Column(
      children: [
        _buildFilters(theme),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text('Aucune commande ne correspond à ces filtres.',
                      style: theme.textTheme.bodyMedium),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is String) {
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 1.5.h, bottom: 1.h),
              child: Text(
                row,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final order = row as Map<String, dynamic>;
          final status = order['status'] ?? 'recue';
          final cancelled = status == 'annulee';
          final paymentStatus =
              (order['payment_status'] ?? 'en_attente') as String;
          final paymentMethod =
              PaymentMethodX.fromId(order['payment_method'] as String?);

          return Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Card(
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(order: order),
                  ),
                );
                _loadOrders();
              },
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
                            color:
                                orderPaymentStatusColor(paymentStatus, theme),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          orderPaymentStatusLabels[paymentStatus] ??
                              paymentStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                orderPaymentStatusColor(paymentStatus, theme),
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
                    OrderProgressBar(status: status)
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
            ),
            ),
          );
        },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 0.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par numéro de commande',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              isDense: true,
              filled: true,
              fillColor:
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in {
                  'tous': 'Tous',
                  'recue': 'Reçue',
                  'en_preparation': 'En préparation',
                  'expediee': 'Expédiée',
                  'livree': 'Livrée',
                  'annulee': 'Annulée',
                }.entries)
                  Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _statusFilter == entry.key,
                      onSelected: (_) =>
                          setState(() => _statusFilter = entry.key),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in {
                  'tous': 'Toute période',
                  '30j': '30 derniers jours',
                  '90j': '90 derniers jours',
                }.entries)
                  Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _periodFilter == entry.key,
                      onSelected: (_) =>
                          setState(() => _periodFilter = entry.key),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
      return const _OrdersSkeleton();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            SizedBox(height: 1.5.h),
            FilledButton.icon(
              onPressed: _loadQuotes,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
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

    final rows = groupRowsByPeriod(_quotes);

    return RefreshIndicator(
      onRefresh: _loadQuotes,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          if (row is String) {
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : 1.5.h, bottom: 1.h),
              child: Text(
                row,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final quote = row as Map<String, dynamic>;
          final status = (quote['status'] ?? 'en_attente').toString();
          final items =
              List<Map<String, dynamic>>.from(quote['quote_items'] ?? []);
          final canReorder = items.isNotEmpty &&
              (status == 'accepte' || status == 'envoye');

          return Padding(
            padding: EdgeInsets.only(bottom: 2.h),
            child: Card(
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
            ),
          );
        },
      ),
    );
  }
}

/// Rectangle qui pulse doucement — même principe que `_ShimmerBox` dans
/// catalog_tab.dart (Lot 5), dupliqué ici car privé à son fichier.
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const _ShimmerBox({
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final highlight = theme.colorScheme.surface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// Aperçu skeleton pendant le premier chargement des listes Commandes/Devis
/// (Lot 5) — remplace le spinner plein écran par 3 cartes fantômes, comme
/// `_CatalogSkeleton` côté accueil.
class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: 3,
      separatorBuilder: (_, __) => SizedBox(height: 2.h),
      itemBuilder: (context, __) => Card(
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ShimmerBox(width: 30.w, height: 16),
                  _ShimmerBox(width: 20.w, height: 16),
                ],
              ),
              SizedBox(height: 1.h),
              _ShimmerBox(width: 40.w, height: 12),
              SizedBox(height: 1.5.h),
              _ShimmerBox(width: double.infinity, height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
