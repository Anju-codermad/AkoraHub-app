import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/offline/connectivity_provider.dart';
import '../../core/offline/offline_order_queue.dart';
import '../../core/payment/mvola_withdrawal_fee.dart';
import '../../core/payment/papi_payment_repo.dart';
import '../../core/payment/payment_method_selector.dart';
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
  final _paymentReferenceController = TextEditingController();
  File? _paymentProofFile;

  // Réglage Admin (voir payment_methods_management.dart) : secours
  // d'urgence (ex: Papi indisponible) — quand activé, force TOUS les
  // clients en manuel pour Mvola/Orange Money/Airtel Money, sans leur
  // laisser le choix. Cas normal (false) : les deux options coexistent,
  // voir `_payAutomatically` ci-dessous.
  bool _manualFallback = false;

  /// Choix du client (pas de l'Admin) entre paiement automatique (Papi)
  /// et manuel (référence + preuve), pour les méthodes qui supportent les
  /// deux — demande explicite de l'utilisatrice (01/08) : les deux modes
  /// doivent être disponibles en même temps, au client de choisir.
  bool _payAutomatically = true;

  /// Le flux manuel (encadré coordonnées + référence + photo) s'affiche
  /// pour les méthodes sans confirmation automatique (virement bancaire),
  /// ou pour Mvola/Orange/Airtel si le secours manuel est forcé par
  /// l'Admin, ou si le client a lui-même choisi le paiement manuel.
  bool get _showManualPaymentFields =>
      _paymentMethod.instructions != null &&
      (!_paymentMethod.isPapiCapable || _manualFallback || !_payAutomatically);

  final _deliveryAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _estimateDelivery();
    _loadAvailablePaymentMethods();
  }

  @override
  void dispose() {
    _paymentReferenceController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickPaymentProof() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _paymentProofFile = File(picked.path));
  }

  /// Modes de paiement activés par l'Admin (voir
  /// `payment_methods_management.dart`) — repli sur tous les modes actifs
  /// tant que le chargement n'est pas terminé ou en cas d'échec, pour ne
  /// jamais bloquer le checkout.
  Future<void> _loadAvailablePaymentMethods() async {
    final available = await PaymentMethodSettingsRepo.fetchEnabled();
    final manualFallback =
        await PaymentMethodSettingsRepo.isManualFallbackEnabled();
    if (!mounted) return;
    setState(() {
      _availableMethods = available;
      _manualFallback = manualFallback;
      if (!available.contains(_paymentMethod) && available.isNotEmpty) {
        _paymentMethod = available.first;
      }
    });
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

    if (!asQuote && _deliveryAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Indiquez l\'adresse de livraison (ou utilisez votre position actuelle).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!asQuote &&
        _showManualPaymentFields &&
        _paymentReferenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Indiquez la référence du paiement ou le nom du kiosque.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final total = ref.read(cartProvider.notifier).total;
    final online = await isCurrentlyOnline();
    final usesPapi = !asQuote &&
        _paymentMethod.isPapiCapable &&
        !_manualFallback &&
        _payAutomatically;

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
                'delivery_address': _deliveryAddressController.text.trim(),
                'payment_method': _paymentMethod.id,
                'payment_reference':
                    _paymentReferenceController.text.trim().isEmpty
                        ? null
                        : _paymentReferenceController.text.trim(),
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
              [
                asQuote
                    ? 'Pas de connexion — votre demande de devis sera envoyée automatiquement dès que le réseau revient.'
                    : 'Pas de connexion — votre commande sera envoyée automatiquement dès que le réseau revient.',
                if (!asQuote && _paymentProofFile != null)
                  ' La capture de paiement n\'a pas pu être jointe (nécessite une connexion) — vous pourrez l\'envoyer par message.',
              ].join(),
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

        String? proofPath;
        if (!usesPapi && _paymentProofFile != null) {
          try {
            proofPath = '$userId/$orderNumber.jpg';
            await SupabaseConfig.client.storage
                .from('payment-proofs')
                .upload(proofPath, _paymentProofFile!);
          } catch (_) {
            // Repli tolérant : la commande part quand même sans preuve
            // jointe (ex: migration phase29 pas encore exécutée) — le
            // staff pourra la demander par message si besoin.
            proofPath = null;
          }
        }

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
              'delivery_address': _deliveryAddressController.text.trim(),
              'payment_method': _paymentMethod.id,
              'payment_reference': (!usesPapi &&
                      _paymentReferenceController.text.trim().isNotEmpty)
                  ? _paymentReferenceController.text.trim()
                  : null,
              'payment_proof_path': proofPath,
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

        // Paiement en ligne automatique via Papi (voir
        // supabase/phase38_patch_papi_payment.sql) : la commande existe
        // déjà (payment_status reste "en_attente" tant que Papi n'a pas
        // confirmé par webhook) — on récupère un lien de paiement et on
        // l'ouvre dans le navigateur. Un échec ici n'annule pas la
        // commande : elle reste consultable, le client pourra réessayer
        // depuis le suivi de commande.
        if (usesPapi) {
          try {
            final paymentLink =
                await PapiPaymentRepo.createPaymentLink(order['id'] as String);
            final uri = Uri.parse(paymentLink);
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Commande créée, mais le paiement en ligne n\'a pas pu '
                      'démarrer. Réessayez depuis le suivi de commande.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }

      ref.read(cartProvider.notifier).clear();
      _paymentReferenceController.clear();
      _deliveryAddressController.clear();
      _paymentProofFile = null;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(asQuote
              ? 'Demande de devis envoyée !'
              : usesPapi
                  ? 'Commande créée ! Finalisez le paiement dans la page '
                      'qui vient de s\'ouvrir.'
                  : _showManualPaymentFields
                      ? 'Commande passée avec succès ! Nous vérifions votre '
                          'paiement sous 24h ouvrées et vous notifierons '
                          'dès confirmation.'
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
                  suffixIcon: IconButton(
                    icon: _isEstimatingDelivery
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 20),
                    tooltip: 'Utiliser ma position actuelle',
                    onPressed: _isEstimatingDelivery
                        ? null
                        : () => _estimateDelivery(overwriteAddress: true),
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
              Text('Mode de paiement', style: theme.textTheme.labelLarge),
              SizedBox(height: 1.h),
              PaymentMethodSelector(
                methods: PaymentMethod.values
                    .where((m) => _availableMethods.contains(m))
                    .toList(),
                selected: _paymentMethod,
                onSelected: (method) =>
                    setState(() => _paymentMethod = method),
              ),
              if (_paymentMethod.isPapiCapable && !_manualFallback) ...[
                SizedBox(height: 1.h),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      avatar: const Icon(Icons.bolt_outlined, size: 18),
                      label: const Text('Paiement automatique en ligne'),
                      selected: _payAutomatically,
                      onSelected: (_) =>
                          setState(() => _payAutomatically = true),
                    ),
                    ChoiceChip(
                      avatar: const Icon(Icons.edit_note_outlined, size: 18),
                      label: const Text('Paiement manuel (référence)'),
                      selected: !_payAutomatically,
                      onSelected: (_) =>
                          setState(() => _payAutomatically = false),
                    ),
                  ],
                ),
                if (_payAutomatically)
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
                        Row(
                          children: [
                            Icon(Icons.lock_outline,
                                size: 18, color: theme.colorScheme.primary),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                'Vous serez redirigé vers une page de paiement '
                                'sécurisée après validation de la commande. '
                                'Montant demandé : ${_currency.format(total + (_deliveryFee ?? 0))} '
                                '(produits + livraison), sans frais supplémentaire.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                        if (_paymentMethod == PaymentMethod.mvola) ...[
                          SizedBox(height: 0.8.h),
                          Text(
                            'Frais de retrait Mvola estimés pour ce montant : '
                            '~${_currency.format(MvolaWithdrawalFee.estimate(total + (_deliveryFee ?? 0)))} '
                            '(à titre indicatif, dépend du montant total '
                            'retiré en une fois).',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
              if (_showManualPaymentFields) ...[
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Effectuez ce paiement puis validez votre '
                              'commande — nous confirmons dès réception :',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_outlined, size: 18),
                            tooltip: 'Copier les coordonnées',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: _paymentMethod.instructions!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coordonnées copiées.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SelectableText(
                        _paymentMethod.instructions!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_paymentMethod == PaymentMethod.mvola) ...[
                        SizedBox(height: 0.8.h),
                        Text(
                          'Frais de retrait Mvola estimés pour ce montant : '
                          '~${_currency.format(MvolaWithdrawalFee.estimate(total + (_deliveryFee ?? 0)))} '
                          '(à titre indicatif, dépend du montant total '
                          'retiré en une fois).',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _paymentReferenceController,
                  decoration: const InputDecoration(
                    labelText: 'Référence de paiement ou nom du kiosque *',
                    hintText: 'Ex : numéro de transaction reçu par SMS, ou '
                        'nom du kiosque si payé via un agent',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                SizedBox(height: 1.h),
                if (_paymentProofFile != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _paymentProofFile!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                            padding: EdgeInsets.zero,
                            onPressed: () =>
                                setState(() => _paymentProofFile = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickPaymentProof,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label:
                        const Text('Joindre une capture du paiement (facultatif)'),
                  ),
              ],
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
