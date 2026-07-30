import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/offline/connectivity_provider.dart';
import '../../core/offline/offline_order_queue.dart';
import '../../core/payment/payment_method_settings_repo.dart';
import '../../core/payment/payment_methods.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'delivery_pricing.dart';
import 'recurring_orders/recurring_orders_screen.dart';

class CartTab extends ConsumerStatefulWidget {
  const CartTab({super.key});

  @override
  ConsumerState<CartTab> createState() => _CartTabState();
}

class _CartTabState extends ConsumerState<CartTab> {
  bool _isSubmitting = false;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  bool _isEstimatingDelivery = false;
  double? _deliveryFee;
  double? _deliveryDistanceKm;
  double? _deliveryLat;
  double? _deliveryLon;
  String? _deliveryError;

  PaymentMethod _paymentMethod = PaymentMethod.paiementLivraison;
  Set<PaymentMethod> _availableMethods = PaymentMethod.values.toSet();

  @override
  void initState() {
    super.initState();
    _estimateDelivery();
    _loadAvailablePaymentMethods();
  }

  /// Modes de paiement activés par l'Admin (voir
  /// `payment_methods_management.dart`) — repli sur tous les modes actifs
  /// tant que le chargement n'est pas terminé ou en cas d'échec, pour ne
  /// jamais bloquer le checkout.
  Future<void> _loadAvailablePaymentMethods() async {
    final available = await PaymentMethodSettingsRepo.fetchEnabled();
    if (!mounted) return;
    setState(() {
      _availableMethods = available;
      if (!available.contains(_paymentMethod) && available.isNotEmpty) {
        _paymentMethod = available.first;
      }
    });
  }

  Future<void> _estimateDelivery() async {
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
  }

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

    final total = ref.read(cartProvider.notifier).total;
    final online = await isCurrentlyOnline();

    // Hors-ligne : on ne tente même pas l'appel réseau, on met
    // directement en file d'attente locale pour un envoi automatique dès
    // que la connexion revient (voir OfflineOrderQueue.trySync, déclenché
    // par le listener de connectivité dans client_home.dart).
    if (!online) {
      try {
        if (asQuote) {
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
        } else {
          await OfflineOrderQueue.enqueue(
            type: 'order',
            payload: {
              'header': {
                'order_number': _generateNumber('CMD'),
                'customer_id': userId,
                'total_amount': total + (_deliveryFee ?? 0),
                'delivery_fee': _deliveryFee ?? 0,
                'delivery_zone': _deliveryDistanceKm != null
                    ? '≈ ${_deliveryDistanceKm!.toStringAsFixed(1)} km'
                    : null,
                'latitude': _deliveryLat,
                'longitude': _deliveryLon,
                'payment_method': _paymentMethod.id,
              },
              'items': cart
                  .map((item) => {
                        'product_id': item.productId,
                        'product_name': item.name,
                        'quantity': item.quantity,
                        'unit_price': item.unitPrice,
                        'is_gros_price': item.isGrosPrice,
                      })
                  .toList(),
            },
          );
        }

        ref.read(cartProvider.notifier).clear();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              asQuote
                  ? 'Pas de connexion — votre demande de devis sera envoyée automatiquement dès que le réseau revient.'
                  : 'Pas de connexion — votre commande sera envoyée automatiquement dès que le réseau revient.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }

    try {
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
              'total_amount': total + (_deliveryFee ?? 0),
              'delivery_fee': _deliveryFee ?? 0,
              'delivery_zone': _deliveryDistanceKm != null
                  ? '≈ ${_deliveryDistanceKm!.toStringAsFixed(1)} km'
                  : null,
              'latitude': _deliveryLat,
              'longitude': _deliveryLon,
              'payment_method': _paymentMethod.id,
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
              Text('Mode de paiement', style: theme.textTheme.labelLarge),
              SizedBox(height: 0.5.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: PaymentMethod.values
                    .where((m) => _availableMethods.contains(m))
                    .map((method) {
                  final selected = _paymentMethod == method;
                  return ChoiceChip(
                    avatar: Icon(method.icon,
                        size: 16,
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant),
                    label: Text(method.label),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _paymentMethod = method),
                  );
                }).toList(),
              ),
              if (_paymentMethod.instructions != null)
                Container(
                  margin: EdgeInsets.only(top: 1.h),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Effectuez ce paiement puis validez votre commande '
                        '— nous confirmons dès réception :',
                        style: theme.textTheme.bodySmall,
                      ),
                      SizedBox(height: 0.5.h),
                      SelectableText(
                        _paymentMethod.instructions!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
