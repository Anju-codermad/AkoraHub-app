import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/offline/connectivity_provider.dart';
import '../../core/offline/offline_order_queue.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'delivery_pricing.dart';
import 'payment_screen.dart';
import 'recurring_orders/recurring_orders_screen.dart';

class CartTab extends ConsumerStatefulWidget {
  const CartTab({super.key});

  @override
  ConsumerState<CartTab> createState() => _CartTabState();
}

class _CartTabState extends ConsumerState<CartTab> {
  bool _isSubmittingQuote = false;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  bool _isEstimatingDelivery = false;
  double? _deliveryFee;
  double? _deliveryDistanceKm;
  double? _deliveryLat;
  double? _deliveryLon;
  String? _deliveryError;

  final _deliveryAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _estimateDelivery();
  }

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    super.dispose();
  }

  /// Géocodage inverse best-effort (aucune erreur ne doit bloquer le
  /// checkout — l'adresse reste modifiable/saisissable à la main si ça
  /// échoue).
  Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = {
        if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
        if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
        if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
      }.toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  /// [overwriteAddress] : true quand l'utilisateur appuie explicitement sur
  /// "Utiliser ma position actuelle" (on remplace alors le texte déjà
  /// saisi) ; false lors de l'estimation automatique au chargement, où l'on
  /// ne pré-remplit que si le champ est encore vide, pour ne jamais écraser
  /// une adresse déjà tapée par le client.
  Future<void> _estimateDelivery({bool overwriteAddress = false}) async {
    setState(() {
      _isEstimatingDelivery = true;
      _deliveryError = null;
      _deliveryLat = null;
      _deliveryLon = null;
    });

    double? lat;
    double? lon;

    // 1) Position GPS actuelle (la plus précise).
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled &&
          permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        lat = position.latitude;
        lon = position.longitude;
      }
    } catch (_) {
      // On tente le repli ci-dessous.
    }

    // 2) Repli : coordonnées précises déjà enregistrées dans le profil
    // (Localisation Niveau 2 — plus fiable qu'un géocodage d'adresse texte).
    if (lat == null && SupabaseConfig.isConfigured) {
      try {
        final userId = SupabaseConfig.client.auth.currentUser?.id;
        if (userId != null) {
          final profile = await SupabaseConfig.client
              .from('profiles')
              .select('latitude, longitude, location')
              .eq('id', userId)
              .single();
          final savedLat = (profile['latitude'] as num?)?.toDouble();
          final savedLon = (profile['longitude'] as num?)?.toDouble();
          if (savedLat != null && savedLon != null) {
            lat = savedLat;
            lon = savedLon;
          } else {
            // 3) Dernier repli : géocoder l'adresse texte du profil.
            final locationText = (profile['location'] ?? '').toString();
            if (locationText.trim().isNotEmpty) {
              final locations = await locationFromAddress(locationText);
              if (locations.isNotEmpty) {
                lat = locations.first.latitude;
                lon = locations.first.longitude;
              }
            }
          }
        }
      } catch (_) {
        // Rien à faire de plus, on affichera l'erreur ci-dessous.
      }
    }

    if (!mounted) return;

    if (lat == null || lon == null) {
      setState(() {
        _isEstimatingDelivery = false;
        _deliveryError =
            'Estimation indisponible (position introuvable). Les frais de livraison seront confirmés par notre équipe.';
        _deliveryFee = null;
        _deliveryDistanceKm = null;
      });
      return;
    }

    final correctedKm = DeliveryPricing.correctedDistanceKm(lat, lon);
    final fee = DeliveryPricing.feeForDistance(correctedKm);
    setState(() {
      _isEstimatingDelivery = false;
      _deliveryDistanceKm = correctedKm;
      _deliveryFee = fee;
      _deliveryLat = lat;
      _deliveryLon = lon;
    });

    final address = await _reverseGeocode(lat, lon);
    if (!mounted || address == null) return;
    if (overwriteAddress || _deliveryAddressController.text.trim().isEmpty) {
      setState(() => _deliveryAddressController.text = address);
    }
  }

  /// Choisir une adresse enregistrée (Profil → Adresses de livraison,
  /// Lot 4 du Profil, 03/08) plutôt que de taper/géolocaliser à chaque
  /// commande. N'écrase les frais de livraison que si l'adresse a une
  /// position enregistrée (`latitude`/`longitude`) — une adresse créée
  /// avant l'ajout de la géolocalisation dans ce carnet retombe sur le
  /// même repli "à confirmer par l'équipe" que l'estimation GPS.
  Future<void> _pickSavedAddress() async {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null || !SupabaseConfig.isConfigured) return;

    List<Map<String, dynamic>> addresses;
    try {
      final rows = await SupabaseConfig.client
          .from('delivery_addresses')
          .select()
          .eq('customer_id', uid)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      addresses = List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      addresses = [];
    }
    if (!mounted) return;
    if (addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Aucune adresse enregistrée — ajoutez-en une depuis votre profil (Mes achats > Adresses de livraison).'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choisir une adresse',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            ...addresses.map((a) => ListTile(
                  leading: Icon(a['is_default'] == true
                      ? Icons.push_pin
                      : Icons.location_on_outlined),
                  title: Text(a['label'] ?? ''),
                  subtitle: Text(a['address'] ?? ''),
                  onTap: () => Navigator.pop(context, a),
                )),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;

    final lat = (selected['latitude'] as num?)?.toDouble();
    final lon = (selected['longitude'] as num?)?.toDouble();
    if (lat != null && lon != null) {
      final correctedKm = DeliveryPricing.correctedDistanceKm(lat, lon);
      final fee = DeliveryPricing.feeForDistance(correctedKm);
      setState(() {
        _deliveryAddressController.text = selected['address'] ?? '';
        _deliveryLat = lat;
        _deliveryLon = lon;
        _deliveryDistanceKm = correctedKm;
        _deliveryFee = fee;
        _deliveryError = null;
      });
    } else {
      setState(() {
        _deliveryAddressController.text = selected['address'] ?? '';
        _deliveryLat = null;
        _deliveryLon = null;
        _deliveryDistanceKm = null;
        _deliveryFee = null;
        _deliveryError =
            'Frais de livraison à confirmer par notre équipe (adresse sans position enregistrée).';
      });
    }
  }

  String _generateNumber(String prefix) {
    final now = DateTime.now();
    final ms = now.millisecondsSinceEpoch.toString().substring(7);
    return '$prefix-${DateFormat('yyyyMM').format(now)}-$ms';
  }

  /// Un devis n'a besoin ni d'adresse de livraison ni de mode de paiement
  /// — soumission directe depuis le panier, pas de passage par la page de
  /// paiement.
  Future<void> _submitQuote() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté.')),
      );
      return;
    }

    setState(() => _isSubmittingQuote = true);

    final total = ref.read(cartProvider.notifier).total;
    final online = await isCurrentlyOnline();

    if (!online) {
      try {
        await OfflineOrderQueue.enqueue(
          type: 'quote',
          payload: {
            'header': {
              'quote_number': _generateNumber('DEV'),
              'customer_id': userId,
              'total_amount': total,
            },
            'items': cart
                .map((item) => {
                      'product_id': item.productId,
                      'product_name': item.name,
                      'quantity': item.quantity,
                      'unit_price': item.unitPrice,
                    })
                .toList(),
          },
        );
        ref.read(cartProvider.notifier).clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Pas de connexion — votre demande de devis sera envoyée automatiquement dès que le réseau revient.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      } finally {
        if (mounted) setState(() => _isSubmittingQuote = false);
      }
      return;
    }

    try {
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

      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande de devis envoyée !'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi. Réessayez.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmittingQuote = false);
    }
  }

  Future<void> _goToPayment() async {
    if (_deliveryAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Indiquez l\'adresse de livraison (ou utilisez votre position actuelle).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final total = ref.read(cartProvider.notifier).total;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          subtotal: total,
          deliveryFee: _deliveryFee,
          deliveryDistanceKm: _deliveryDistanceKm,
          deliveryLat: _deliveryLat,
          deliveryLon: _deliveryLon,
          deliveryAddress: _deliveryAddressController.text.trim(),
        ),
      ),
    );

    if (result != null && mounted) {
      _deliveryAddressController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                  Text('Sous-total', style: theme.textTheme.bodyMedium),
                  Text(_currency.format(total)),
                ],
              ),
              SizedBox(height: 0.5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Frais de livraison',
                          style: theme.textTheme.bodyMedium),
                      if (_deliveryDistanceKm != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(≈ ${_deliveryDistanceKm!.toStringAsFixed(1)} km)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_isEstimatingDelivery)
                    const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_deliveryFee != null)
                    Text(_currency.format(_deliveryFee))
                  else
                    TextButton(
                      onPressed: _estimateDelivery,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0)),
                      child: const Text('Réessayer'),
                    ),
                ],
              ),
              if (_deliveryError != null)
                Padding(
                  padding: EdgeInsets.only(top: 0.5.h),
                  child: Text(
                    _deliveryError!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              SizedBox(height: 1.5.h),
              Text('Adresse de livraison', style: theme.textTheme.labelLarge),
              SizedBox(height: 0.5.h),
              TextField(
                controller: _deliveryAddressController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ex : Lot II M 12 Ter Ankorondrano, près de la '
                      'pharmacie...',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bookmark_border, size: 20),
                        tooltip: 'Choisir une adresse enregistrée',
                        onPressed: _pickSavedAddress,
                      ),
                      IconButton(
                        icon: _isEstimatingDelivery
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, size: 20),
                        tooltip: 'Utiliser ma position actuelle',
                        onPressed: _isEstimatingDelivery
                            ? null
                            : () => _estimateDelivery(overwriteAddress: true),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: theme.textTheme.titleMedium),
                  Text(
                    _currency.format(total + (_deliveryFee ?? 0)),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecurringOrdersScreen(
                          cartItemsForNew: cart,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.autorenew, size: 18),
                  label: const Text('Configurer comme commande récurrente'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmittingQuote ? null : _submitQuote,
                      child: _isSubmittingQuote
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Demander un devis'),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _goToPayment,
                      icon: const Icon(Icons.lock_outline, size: 18),
                      label: const Text('Payer'),
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
