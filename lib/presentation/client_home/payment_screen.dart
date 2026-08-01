import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/offline/connectivity_provider.dart';
import '../../core/offline/offline_order_queue.dart';
import '../../core/payment/mobile_money_withdrawal_fee.dart';
import '../../core/payment/papi_payment_repo.dart';
import '../../core/payment/payment_method_selector.dart';
import '../../core/payment/payment_method_settings_repo.dart';
import '../../core/payment/payment_methods.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';

/// Page de paiement dédiée, séparée du panier — demande explicite de
/// l'utilisatrice (01/08) : donner plus de poids visuel à la sécurité du
/// paiement plutôt que de tout entasser dans l'écran panier. Reçoit les
/// informations de livraison déjà validées côté panier (adresse, frais) ;
/// relit le panier lui-même via `cartProvider` (état global, pas besoin
/// de le faire transiter en paramètre).
///
/// ⚠️ Aucune donnée bancaire sensible n'est saisie ici : Papi gère le
/// paiement en ligne sur sa propre page externe, et le mode manuel ne
/// demande qu'une référence de transaction + une photo facultative — la
/// "sécurité" de cette page est donc surtout une question de présentation
/// rassurante (cadenas, bandeau, logos officiels), pas une nouvelle
/// protection technique.
class PaymentScreen extends ConsumerStatefulWidget {
  final double subtotal;
  final double? deliveryFee;
  final double? deliveryDistanceKm;
  final double? deliveryLat;
  final double? deliveryLon;
  final String deliveryAddress;

  const PaymentScreen({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.deliveryDistanceKm,
    required this.deliveryLat,
    required this.deliveryLon,
    required this.deliveryAddress,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isSubmitting = false;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

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
  /// deux.
  bool _payAutomatically = true;

  bool get _showManualPaymentFields =>
      _paymentMethod.instructions != null &&
      (!_paymentMethod.isPapiCapable || _manualFallback || !_payAutomatically);

  @override
  void initState() {
    super.initState();
    _loadAvailablePaymentMethods();
  }

  @override
  void dispose() {
    _paymentReferenceController.dispose();
    super.dispose();
  }

  Future<void> _pickPaymentProof() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _paymentProofFile = File(picked.path));
  }

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

  String _generateNumber(String prefix) {
    final now = DateTime.now();
    final ms = now.millisecondsSinceEpoch.toString().substring(7);
    return '$prefix-${DateFormat('yyyyMM').format(now)}-$ms';
  }

  Future<void> _submitOrder() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté.')),
      );
      return;
    }

    if (_showManualPaymentFields &&
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

    final total = widget.subtotal + (widget.deliveryFee ?? 0);
    final online = await isCurrentlyOnline();
    final usesPapi =
        _paymentMethod.isPapiCapable && !_manualFallback && _payAutomatically;

    // Hors-ligne : mise en file d'attente locale (voir OfflineOrderQueue,
    // même mécanisme que pour les devis).
    if (!online) {
      try {
        await OfflineOrderQueue.enqueue(
          type: 'order',
          payload: {
            'header': {
              'order_number': _generateNumber('CMD'),
              'customer_id': userId,
              'total_amount': total,
              'delivery_fee': widget.deliveryFee ?? 0,
              'delivery_zone': widget.deliveryDistanceKm != null
                  ? '≈ ${widget.deliveryDistanceKm!.toStringAsFixed(1)} km'
                  : null,
              'latitude': widget.deliveryLat,
              'longitude': widget.deliveryLon,
              'delivery_address': widget.deliveryAddress,
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

        ref.read(cartProvider.notifier).clear();

        if (!mounted) return;
        Navigator.pop(context, {
          'message': [
            'Pas de connexion — votre commande sera envoyée automatiquement dès que le réseau revient.',
            if (_paymentProofFile != null)
              ' La capture de paiement n\'a pas pu être jointe (nécessite une connexion) — vous pourrez l\'envoyer par message.',
          ].join(),
        });
      } catch (_) {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }

    try {
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
          // jointe — le staff pourra la demander par message si besoin.
          proofPath = null;
        }
      }

      final order = await SupabaseConfig.client
          .from('orders')
          .insert({
            'order_number': orderNumber,
            'customer_id': userId,
            'total_amount': total,
            'delivery_fee': widget.deliveryFee ?? 0,
            'delivery_zone': widget.deliveryDistanceKm != null
                ? '≈ ${widget.deliveryDistanceKm!.toStringAsFixed(1)} km'
                : null,
            'latitude': widget.deliveryLat,
            'longitude': widget.deliveryLon,
            'delivery_address': widget.deliveryAddress,
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
      // supabase/phase38_patch_papi_payment.sql) : la commande existe déjà
      // (payment_status reste "en_attente" tant que Papi n'a pas confirmé
      // par webhook) — on récupère un lien de paiement et on l'ouvre dans
      // le navigateur. Un échec ici n'annule pas la commande.
      var papiFailed = false;
      if (usesPapi) {
        try {
          final paymentLink =
              await PapiPaymentRepo.createPaymentLink(order['id'] as String);
          final uri = Uri.parse(paymentLink);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          papiFailed = true;
        }
      }

      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;
      Navigator.pop(context, {
        'message': papiFailed
            ? 'Commande créée, mais le paiement en ligne n\'a pas pu '
                'démarrer. Réessayez depuis le suivi de commande.'
            : usesPapi
                ? 'Commande créée ! Finalisez le paiement dans la page '
                    'qui vient de s\'ouvrir.'
                : _showManualPaymentFields
                    ? 'Commande passée avec succès ! Nous vérifions votre '
                        'paiement sous 24h ouvrées et vous notifierons dès '
                        'confirmation.'
                    : 'Commande passée avec succès !',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi. Réessayez.')),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.subtotal + (widget.deliveryFee ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, size: 20),
            SizedBox(width: 8),
            Text('Paiement sécurisé'),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: Colors.green, size: 20),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Connexion sécurisée. Vos informations de paiement ne '
                    'sont jamais stockées en clair et ne transitent que vers '
                    'des opérateurs officiels.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.green.shade800),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Récapitulatif', style: theme.textTheme.titleSmall),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sous-total', style: theme.textTheme.bodyMedium),
                      Text(_currency.format(widget.subtotal)),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Frais de livraison',
                          style: theme.textTheme.bodyMedium),
                      Text(_currency.format(widget.deliveryFee ?? 0)),
                    ],
                  ),
                  const Divider(height: 20),
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
                  SizedBox(height: 0.5.h),
                  Text(
                    'Livraison : ${widget.deliveryAddress}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text('Mode de paiement', style: theme.textTheme.labelLarge),
          SizedBox(height: 1.h),
          PaymentMethodSelector(
            methods: PaymentMethod.values
                .where((m) => _availableMethods.contains(m))
                .toList(),
            selected: _paymentMethod,
            onSelected: (method) => setState(() => _paymentMethod = method),
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
                  onSelected: (_) => setState(() => _payAutomatically = true),
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
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
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
                            'Montant demandé : ${_currency.format(total)} '
                            '(produits + livraison), sans frais supplémentaire.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    if (_paymentMethod == PaymentMethod.mvola ||
                        _paymentMethod == PaymentMethod.orangeMoney) ...[
                      SizedBox(height: 0.8.h),
                      Text(
                        'Frais de retrait ${_paymentMethod.label} estimés pour ce montant : '
                        '~${_currency.format(MobileMoneyWithdrawalFee.estimate(total))} '
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
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
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
                          Clipboard.setData(
                              ClipboardData(text: _paymentMethod.instructions!));
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
                    style:
                        theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (_paymentMethod == PaymentMethod.mvola ||
                      _paymentMethod == PaymentMethod.orangeMoney) ...[
                    SizedBox(height: 0.8.h),
                    Text(
                      'Frais de retrait ${_paymentMethod.label} estimés pour ce montant : '
                      '~${_currency.format(MobileMoneyWithdrawalFee.estimate(total))} '
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
                hintText: 'Ex : numéro de transaction reçu par SMS, ou nom '
                    'du kiosque si payé via un agent',
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
                label: const Text('Joindre une capture du paiement (facultatif)'),
              ),
          ],
          SizedBox(height: 3.h),
          FilledButton(
            onPressed: _isSubmitting ? null : _submitOrder,
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Confirmer et payer — ${_currency.format(total)}'),
          ),
          SizedBox(height: 1.h),
          Center(
            child: Text(
              '🔒 Paiement chiffré · Opérateurs officiels Papi, Mvola, Orange Money, Airtel Money',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
