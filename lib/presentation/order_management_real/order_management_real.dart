import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

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
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
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
    });
    try {
      final data = await SupabaseConfig.client
          .from('orders')
          .select('*, profiles(full_name, company_name)')
          .order('created_at', ascending: false);
      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les commandes.';
      });
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> order) async {
    String selectedStatus = order['status'] ?? 'recue';
    String selectedPayment = order['payment_status'] ?? 'en_attente';
    DateTime? driverPositionUpdatedAt = order['driver_position_updated_at'] !=
            null
        ? DateTime.tryParse(order['driver_position_updated_at'])
        : null;
    bool isUpdatingPosition = false;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Commande ${order['order_number']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statut de la commande',
                    style: Theme.of(context).textTheme.labelLarge),
                ..._statusLabels.entries.map((entry) {
                  return RadioListTile<String>(
                    value: entry.key,
                    groupValue: selectedStatus,
                    dense: true,
                    title: Text(entry.value),
                    onChanged: (v) =>
                        setDialogState(() => selectedStatus = v!),
                  );
                }),
                const Divider(),
                Text('Mode de paiement choisi par le client',
                    style: Theme.of(context).textTheme.labelLarge),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Icon(
                        PaymentMethodX.fromId(order['payment_method'] as String?)
                            .icon,
                        size: 18),
                    const SizedBox(width: 6),
                    Text(
                      PaymentMethodX.fromId(order['payment_method'] as String?)
                          .label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                if ((order['payment_reference'] as String?)
                        ?.isNotEmpty ==
                    true) ...[
                  SizedBox(height: 0.5.h),
                  Text(
                    'Référence : ${order['payment_reference']}',
                    style: Theme.of(context).textTheme.bodySmall,
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
                SizedBox(height: 1.h),
                Text('Statut du paiement',
                    style: Theme.of(context).textTheme.labelLarge),
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
                Text('Position du livreur (suivi de livraison)',
                    style: Theme.of(context).textTheme.labelLarge),
                SizedBox(height: 0.5.h),
                Text(
                  driverPositionUpdatedAt != null
                      ? 'Dernière mise à jour : ${DateFormat('dd/MM HH:mm').format(driverPositionUpdatedAt!.toLocal())}'
                      : 'Position jamais renseignée pour cette commande.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: 1.h),
                OutlinedButton.icon(
                  onPressed: isUpdatingPosition
                      ? null
                      : () async {
                          setDialogState(() => isUpdatingPosition = true);
                          final updatedAt = await _captureAndSaveDriverPosition(
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
        ),
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

  List<Map<String, dynamic>> get _filteredOrders {
    var orders = _statusFilter == 'toutes'
        ? _orders
        : _orders.where((o) => o['status'] == _statusFilter).toList();
    if (_onlyPaymentToVerify) {
      orders = orders
          .where((o) =>
              (o['payment_method'] ?? 'paiement_livraison') !=
                  'paiement_livraison' &&
              (o['payment_status'] ?? 'en_attente') != 'paye')
          .toList();
    }
    return orders;
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
                            onSelected: (_) =>
                                setState(() => _statusFilter = 'toutes'),
                          ),
                          SizedBox(width: 2.w),
                          ..._statusLabels.entries.map((entry) => Padding(
                                padding: EdgeInsets.only(right: 2.w),
                                child: ChoiceChip(
                                  label: Text(entry.value),
                                  selected: _statusFilter == entry.key,
                                  onSelected: (_) => setState(
                                      () => _statusFilter = entry.key),
                                ),
                              )),
                          FilterChip(
                            label: const Text('Paiement à vérifier'),
                            avatar: const Icon(Icons.receipt_long_outlined,
                                size: 16),
                            selected: _onlyPaymentToVerify,
                            onSelected: (v) =>
                                setState(() => _onlyPaymentToVerify = v),
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
                                padding: EdgeInsets.all(4.w),
                                itemCount: _filteredOrders.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
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
