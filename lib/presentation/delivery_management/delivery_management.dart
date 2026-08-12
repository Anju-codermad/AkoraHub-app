import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/supabase/supabase_config.dart';

/// Écran dédié au rôle Livraison (Étape 2/2 du chantier rôles, 12/08) —
/// version allégée de `order_management_real.dart` : uniquement ce dont un
/// livreur a besoin (statut, adresse, contact client, position GPS), sans
/// jamais afficher ni permettre de modifier prix/paiement (voir
/// phase167_patch_roles_services_livraison_access.sql).
///
/// Ne peut pas embarquer `profiles(...)` via PostgREST comme le fait l'écran
/// admin : ce rôle n'a pas accès à `profiles` (RLS), seulement à la vue
/// allégée `logistics_contacts` — le contact client est donc récupéré par
/// une requête séparée et fusionné côté client.
class DeliveryManagement extends StatefulWidget {
  const DeliveryManagement({super.key});

  @override
  State<DeliveryManagement> createState() => _DeliveryManagementState();
}

class _DeliveryManagementState extends State<DeliveryManagement> {
  List<Map<String, dynamic>> _orders = [];
  Map<String, Map<String, dynamic>> _contactsById = {};
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'toutes';

  final Map<String, String> _statusLabels = const {
    'recue': 'Reçue',
    'en_preparation': 'En préparation',
    'expediee': 'Expédiée',
    'livree': 'Livrée',
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
      var query = SupabaseConfig.client.from('orders').select(
          'id, order_number, status, customer_id, delivery_address, '
          'latitude, longitude, driver_latitude, driver_longitude, '
          'driver_position_updated_at, created_at');
      if (_statusFilter != 'toutes') {
        query = query.eq('status', _statusFilter);
      } else {
        query = query.neq('status', 'annulee');
      }
      final data = await query.order('created_at', ascending: false);
      final orders = List<Map<String, dynamic>>.from(data);

      final customerIds = orders
          .map((o) => o['customer_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      var contacts = <String, Map<String, dynamic>>{};
      if (customerIds.isNotEmpty) {
        final contactsData = await SupabaseConfig.client
            .from('logistics_contacts')
            .select('id, full_name, company_name, phone, region, location')
            .inFilter('id', customerIds);
        for (final c in List<Map<String, dynamic>>.from(contactsData)) {
          contacts[c['id'] as String] = c;
        }
      }

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _contactsById = contacts;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les livraisons.';
      });
    }
  }

  Future<void> _openInMaps(double lat, double lon) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callPhone(String phone) async {
    await launchUrl(Uri.parse('tel:$phone'));
  }

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
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final now = DateTime.now();
      await SupabaseConfig.client.from('orders').update({
        'driver_latitude': position.latitude,
        'driver_longitude': position.longitude,
        'driver_position_updated_at': now.toIso8601String(),
      }).eq('id', orderId);
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

  Future<void> _openOrderDialog(Map<String, dynamic> order) async {
    String selectedStatus = order['status'] ?? 'recue';
    bool isUpdatingPosition = false;
    DateTime? driverPositionUpdatedAt =
        order['driver_position_updated_at'] != null
            ? DateTime.tryParse(order['driver_position_updated_at'])
            : null;
    final contact = _contactsById[order['customer_id']];
    final customerName =
        contact?['company_name'] ?? contact?['full_name'] ?? 'Client';
    final phone = contact?['phone'] as String?;

    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text('Commande ${order['order_number'] ?? ''}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customerName, style: theme.textTheme.titleSmall),
                  if (contact?['region'] != null || contact?['location'] != null)
                    Text(
                      [contact?['location'], contact?['region']]
                          .whereType<String>()
                          .where((s) => s.trim().isNotEmpty)
                          .join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  if (phone != null && phone.trim().isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    TextButton.icon(
                      onPressed: () => _callPhone(phone),
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: Text(phone),
                    ),
                  ],
                  const Divider(),
                  Text('Adresse de livraison',
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
                  Text('Statut de la livraison',
                      style: theme.textTheme.labelLarge),
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
                  Text('Ma position (suivi de livraison)',
                      style: theme.textTheme.labelLarge),
                  SizedBox(height: 0.5.h),
                  Text(
                    driverPositionUpdatedAt != null
                        ? 'Dernière mise à jour : ${driverPositionUpdatedAt!.toLocal().hour.toString().padLeft(2, '0')}:${driverPositionUpdatedAt!.toLocal().minute.toString().padLeft(2, '0')}'
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
                child: const Text('Fermer'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, selectedStatus),
                child: const Text('Mettre à jour le statut'),
              ),
            ],
          );
        },
      ),
    );

    if (newStatus == null || newStatus == order['status']) return;
    try {
      await SupabaseConfig.client
          .from('orders')
          .update({'status': newStatus}).eq('id', order['id']);
      _loadOrders();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la mise à jour.')),
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
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Livraisons')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Toutes'),
                            selected: _statusFilter == 'toutes',
                            onSelected: (_) {
                              setState(() => _statusFilter = 'toutes');
                              _loadOrders();
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
                                    _loadOrders();
                                  },
                                ),
                              )),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: _orders.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(height: 20.h),
                                  const Center(
                                      child: Text('Aucune livraison.')),
                                ],
                              )
                            : ListView.separated(
                                padding: EdgeInsets.all(4.w),
                                itemCount: _orders.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  final status = order['status'] ?? 'recue';
                                  final contact =
                                      _contactsById[order['customer_id']];
                                  final customerName =
                                      contact?['company_name'] ??
                                          contact?['full_name'] ??
                                          'Client';
                                  final locationText = [
                                    contact?['location'],
                                    contact?['region']
                                  ]
                                      .whereType<String>()
                                      .where((s) => s.trim().isNotEmpty)
                                      .join(' · ');
                                  return Card(
                                    child: ListTile(
                                      title:
                                          Text(order['order_number'] ?? ''),
                                      subtitle: Text(
                                        locationText.isNotEmpty
                                            ? '$customerName · $locationText'
                                            : customerName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Chip(
                                        label: Text(
                                          _statusLabels[status] ?? status,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white),
                                        ),
                                        backgroundColor:
                                            _statusColor(status, theme),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onTap: () => _openOrderDialog(order),
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
