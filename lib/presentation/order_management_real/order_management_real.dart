import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/payment/payment_methods.dart';
import '../../core/supabase/supabase_config.dart';

/// Gestion réelle des commandes : suivi des 4 statuts (Reçue, En préparation,
/// Expédiée, Livrée), consultable/modifiable par le staff.
class OrderManagementReal extends StatefulWidget {
  const OrderManagementReal({super.key});

  @override
  State<OrderManagementReal> createState() => _OrderManagementRealState();
}

class _OrderManagementRealState extends State<OrderManagementReal> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'toutes';
  bool _onlyPaymentToVerify = false;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  // Pagination : la liste des commandes n'a plus de limite (toutes
  // chargées d'un coup) — remplacé par un chargement par pages de 20, la
  // suite arrivant automatiquement en scrollant vers le bas. Le filtre de
  // statut passe désormais côté serveur (une page = déjà le bon statut).
  // "Paiement à vérifier" reste un filtre côté client car sa logique
  // (valeurs nulles traitées comme 'paiement_livraison'/'en_attente') ne
  // se traduit pas proprement en filtre Postgrest — dans ce mode, on
  // charge donc tout (sans pagination) pour ne rater aucune commande à
  // vérifier, ce sous-ensemble restant nettement plus petit que la liste
  // complète en pratique.
  static const _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final _scrollController = ScrollController();

  final Map<String, String> _statusLabels = const {
    'recue': 'Reçue',
    'en_preparation': 'En préparation',
    'expediee': 'Expédiée',
    'livree': 'Livrée',
    'annulee': 'Annulée',
  };

  final Map<String, String> _paymentStatusLabels = const {
    'en_attente': 'En attente',
    'acompte_verse': 'Acompte versé',
    'paye': 'Payée',
    'facture_30j': 'Facturée (30j)',
    'echoue': 'Échouée',
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreOrders();
    }
  }

  Future<void> _loadOrders() async {
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
      _page = 0;
      _hasMore = true;
    });
    try {
      var query = SupabaseConfig.client
          .from('orders')
          .select('*, profiles(full_name, company_name)');
      if (_statusFilter != 'toutes') {
        query = query.eq('status', _statusFilter);
      }
      final builder = query.order('created_at', ascending: false);
      // "Paiement à vérifier" : filtre pas traduisible en Postgrest simple
      // (voir commentaire sur _onlyPaymentToVerify) — on charge tout d'un
      // coup dans ce mode, sans pagination.
      final data = _onlyPaymentToVerify
          ? await builder
          : await builder.range(0, _pageSize - 1);
      final rows = List<Map<String, dynamic>>.from(data);
      setState(() {
        _orders = rows;
        _isLoading = false;
        _hasMore = !_onlyPaymentToVerify && rows.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les commandes.';
      });
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMore || _onlyPaymentToVerify) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      var query = SupabaseConfig.client
          .from('orders')
          .select('*, profiles(full_name, company_name)');
      if (_statusFilter != 'toutes') {
        query = query.eq('status', _statusFilter);
      }
      final data = await query
          .order('created_at', ascending: false)
          .range(nextPage * _pageSize, nextPage * _pageSize + _pageSize - 1);
      final rows = List<Map<String, dynamic>>.from(data);
      if (!mounted) return;
      setState(() {
        _orders = [..._orders, ...rows];
        _page = nextPage;
        _hasMore = rows.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onFilterChanged() {
    _loadOrders();
  }

  Future<void> _updateStatus(Map<String, dynamic> order) async {
    String selectedStatus = order['status'] ?? 'recue';
    String selectedPayment = order['payment_status'] ?? 'en_attente';
    DateTime? driverPositionUpdatedAt = order['driver_position_updated_at'] !=
            null
        ? DateTime.tryParse(order['driver_position_updated_at'])
        : null;
    bool isUpdatingPosition = false;

    final isManualPayment =
        (order['payment_method'] ?? 'paiement_livraison') !=
            'paiement_livraison';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isPaymentConfirmed =
              selectedPayment == 'paye' || selectedPayment == 'facture_30j';
          final statusLocked = isManualPayment && !isPaymentConfirmed;

          return AlertDialog(
            title: Text('Commande ${order['order_number']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (statusLocked)
                    Container(
                      margin: EdgeInsets.only(bottom: 1.h),
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 18, color: theme.colorScheme.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Paiement non confirmé',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ],
                      ),
                    ),
                  Text('Mode de paiement choisi par le client',
                      style: theme.textTheme.labelLarge),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      Icon(
                          PaymentMethodX.fromId(
                                  order['payment_method'] as String?)
                              .icon,
                          size: 18),
                      const SizedBox(width: 6),
                      Text(
                        PaymentMethodX.fromId(
                                order['payment_method'] as String?)
                            .label,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if ((order['payment_reference'] as String?)
                          ?.isNotEmpty ==
                      true) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      'Référence : ${order['payment_reference']}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (order['payment_proof_path'] != null) ...[
                    SizedBox(height: 0.5.h),
                    TextButton.icon(
                      onPressed: () =>
                          _viewPaymentProof(order['payment_proof_path']),
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Voir la capture de paiement'),
                    ),
                  ],
                  if (isManualPayment && !isPaymentConfirmed) ...[
                    SizedBox(height: 1.h),
                    FilledButton.icon(
                      onPressed: () =>
                          setDialogState(() => selectedPayment = 'paye'),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Confirmer le paiement reçu'),
                    ),
                  ],
                  SizedBox(height: 1.h),
                  Text('Statut du paiement', style: theme.textTheme.labelLarge),
                  ..._paymentStatusLabels.entries.map((entry) {
                    return RadioListTile<String>(
                      value: entry.key,
                      groupValue: selectedPayment,
                      dense: true,
                      title: Text(entry.value),
                      onChanged: (v) =>
                          setDialogState(() => selectedPayment = v!),
                    );
                  }),
                  const Divider(),
                  Text('Statut de la commande',
                      style: theme.textTheme.labelLarge),
                  if (statusLocked)
                    Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Text(
                        'Débloqué une fois le paiement confirmé ci-dessus.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ..._statusLabels.entries.map((entry) {
                    final lockedForThisEntry = statusLocked &&
                        entry.key != 'recue' &&
                        entry.key != 'annulee';
                    return RadioListTile<String>(
                      value: entry.key,
                      groupValue: selectedStatus,
                      dense: true,
                      title: Text(entry.value),
                      onChanged: lockedForThisEntry
                          ? null
                          : (v) => setDialogState(() => selectedStatus = v!),
                    );
                  }),
                  const Divider(),
                  Text('Adresse de livraison indiquée par le client',
                      style: theme.textTheme.labelLarge),
                  SizedBox(height: 0.5.h),
                  Text(
                    (order['delivery_address'] as String?)
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? order['delivery_address'] as String
                        : 'Adresse non précisée — seules les coordonnées '
                            'GPS ci-dessous sont disponibles.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (order['latitude'] != null &&
                      order['longitude'] != null) ...[
                    SizedBox(height: 0.5.h),
                    TextButton.icon(
                      onPressed: () => _openInMaps(
                        (order['latitude'] as num).toDouble(),
                        (order['longitude'] as num).toDouble(),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Ouvrir dans Google Maps'),
                    ),
                  ],
                  const Divider(),
                  Text('Position du livreur (suivi de livraison)',
                      style: theme.textTheme.labelLarge),
                  SizedBox(height: 0.5.h),
                  Text(
                    driverPositionUpdatedAt != null
                        ? 'Dernière mise à jour : ${DateFormat('dd/MM HH:mm').format(driverPositionUpdatedAt!.toLocal())}'
                        : 'Position jamais renseignée pour cette commande.',
                    style: theme.textTheme.bodySmall,
                  ),
                  SizedBox(height: 1.h),
                  OutlinedButton.icon(
                    onPressed: isUpdatingPosition
                        ? null
                        : () async {
                            setDialogState(() => isUpdatingPosition = true);
                            final updatedAt =
                                await _captureAndSaveDriverPosition(
                                    order['id']);
                            setDialogState(() {
                              isUpdatingPosition = false;
                              if (updatedAt != null) {
                                driverPositionUpdatedAt = updatedAt;
                              }
                            });
                          },
                    icon: isUpdatingPosition
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('Mettre à jour ma position maintenant'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, {
                  'status': selectedStatus,
                  'payment_status': selectedPayment,
                }),
                child: const Text('Mettre à jour'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;

    try {
      await SupabaseConfig.client
          .from('orders')
          .update(result)
          .eq('id', order['id']);
      _loadOrders();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour.')),
      );
    }
  }

  Future<void> _openInMaps(double lat, double lon) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Capture la position GPS actuelle du staff (livreur) et la sauvegarde
  /// immédiatement sur la commande — indépendant du bouton "Mettre à
  /// jour" du dialogue (statut/paiement), pour que le client voie la
  /// nouvelle position tout de suite, même si le staff annule le reste
  /// du dialogue. Retourne l'horodatage de la mise à jour si réussie.
  Future<DateTime?> _captureAndSaveDriverPosition(String orderId) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Autorisation de localisation refusée — impossible de mettre à jour la position.')),
          );
        }
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final now = DateTime.now();
      await SupabaseConfig.client.from('orders').update({
        'driver_latitude': position.latitude,
        'driver_longitude': position.longitude,
        'driver_position_updated_at': now.toIso8601String(),
      }).eq('id', orderId);
      _loadOrders();
      return now;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Impossible de récupérer votre position.')),
        );
      }
      return null;
    }
  }

  // Le filtre de statut est désormais appliqué côté serveur (_loadOrders) —
  // _orders ne contient déjà que le bon statut. Seul "Paiement à
  // vérifier" reste filtré ici, côté client (voir commentaire plus haut).
  List<Map<String, dynamic>> get _filteredOrders {
    if (!_onlyPaymentToVerify) return _orders;
    return _orders
        .where((o) =>
            (o['payment_method'] ?? 'paiement_livraison') !=
                'paiement_livraison' &&
            (o['payment_status'] ?? 'en_attente') != 'paye')
        .toList();
  }

  /// Ouvre la capture de paiement jointe par le client (bucket privé
  /// `payment-proofs` — URL signée temporaire, pas d'URL publique
  /// puisque ce sont des documents financiers).
  Future<void> _viewPaymentProof(String path) async {
    try {
      final signedUrl = await SupabaseConfig.client.storage
          .from('payment-proofs')
          .createSignedUrl(path, 3600);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: InteractiveViewer(
            child: Image.network(signedUrl),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de charger la capture de paiement.')),
      );
    }
  }

  Color _statusColor(String status, ThemeData theme) {
    switch (status) {
      case 'livree':
        return Colors.green;
      case 'expediee':
        return Colors.blue;
      case 'en_preparation':
        return Colors.orange;
      case 'annulee':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  Color _paymentColor(String paymentStatus, ThemeData theme) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Commandes')),
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
                            label: const Text('Toutes'),
                            selected: _statusFilter == 'toutes',
                            onSelected: (_) {
                              setState(() => _statusFilter = 'toutes');
                              _onFilterChanged();
                            },
                          ),
                          SizedBox(width: 2.w),
                          ..._statusLabels.entries.map((entry) => Padding(
                                padding: EdgeInsets.only(right: 2.w),
                                child: ChoiceChip(
                                  label: Text(entry.value),
                                  selected: _statusFilter == entry.key,
                                  onSelected: (_) {
                                    setState(() => _statusFilter = entry.key);
                                    _onFilterChanged();
                                  },
                                ),
                              )),
                          FilterChip(
                            label: const Text('Paiement à vérifier'),
                            avatar: const Icon(Icons.receipt_long_outlined,
                                size: 16),
                            selected: _onlyPaymentToVerify,
                            onSelected: (v) {
                              setState(() => _onlyPaymentToVerify = v);
                              _onFilterChanged();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: _filteredOrders.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(height: 20.h),
                                  const Center(
                                      child: Text('Aucune commande.')),
                                ],
                              )
                            : ListView.separated(
                                controller: _scrollController,
                                padding: EdgeInsets.all(4.w),
                                itemCount: _filteredOrders.length +
                                    (_hasMore && !_onlyPaymentToVerify
                                        ? 1
                                        : 0),
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
                                  if (index >= _filteredOrders.length) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 2.h),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                    );
                                  }
                                  final order = _filteredOrders[index];
                                  final status = order['status'] ?? 'recue';
                                  final paymentStatus =
                                      order['payment_status'] ?? 'en_attente';
                                  final customer = order['profiles'];
                                  final customerName = customer != null
                                      ? (customer['company_name'] ??
                                          customer['full_name'] ??
                                          'Client')
                                      : 'Client';
                                  final hasPaymentProof =
                                      order['payment_proof_path'] != null ||
                                          (order['payment_reference']
                                                      as String?)
                                                  ?.isNotEmpty ==
                                              true;
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                          order['order_number'] ?? ''),
                                      subtitle: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '$customerName · ${_currency.format(order['total_amount'] ?? 0)} · '
                                              '${PaymentMethodX.fromId(order['payment_method'] as String?).label}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (hasPaymentProof) ...[
                                            const SizedBox(width: 4),
                                            Icon(Icons.attach_file,
                                                size: 14,
                                                color: theme
                                                    .colorScheme.primary),
                                          ],
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Chip(
                                            label: Text(
                                              _statusLabels[status] ?? status,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white),
                                            ),
                                            backgroundColor:
                                                _statusColor(status, theme),
                                            visualDensity:
                                                VisualDensity.compact,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          const SizedBox(height: 4),
                                          Chip(
                                            label: Text(
                                              _paymentStatusLabels[
                                                      paymentStatus] ??
                                                  paymentStatus,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white),
                                            ),
                                            backgroundColor: _paymentColor(
                                                paymentStatus, theme),
                                            visualDensity:
                                                VisualDensity.compact,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ],
                                      ),
                                      onTap: () => _updateStatus(order),
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
