import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/payment/payment_method_settings_repo.dart';
import '../../core/payment/payment_methods.dart';

/// Permet à l'Admin d'activer/désactiver chaque mode de paiement proposé
/// au checkout client (paiement à la livraison, virement bancaire, Orange
/// Money, Mvola, Airtel Money) — utile par exemple si un numéro Mobile
/// Money personnel devient temporairement indisponible, ou pour retirer
/// les modes manuels une fois un vrai paiement en ligne en place.
///
/// Depuis le 02/08 (intégration FiveOne Pay, Lot 4) : les 3 opérateurs
/// Mobile Money sont regroupés visuellement par PLATEFORME qui les
/// traite (Papi.mg / FiveOne Pay / Manuel), demande explicite de
/// l'utilisateur pour que ce soit clair. Chaque opérateur reste une
/// seule ligne en base (`payment_method_settings.provider`) — activer
/// son interrupteur sous une plateforme met `enabled = true` et
/// `provider` sur cette plateforme ; le désactiver le désactive
/// entièrement (pas de bascule automatique vers l'autre fournisseur,
/// pour éviter un changement de routage surprise).
class PaymentMethodsManagement extends StatefulWidget {
  const PaymentMethodsManagement({super.key});

  @override
  State<PaymentMethodsManagement> createState() =>
      _PaymentMethodsManagementState();
}

// Les 3 opérateurs Mobile Money, dans cet ordre, réutilisé pour les
// sections Papi.mg et FiveOne Pay.
const _onlineCapableMethods = [
  PaymentMethod.mvola,
  PaymentMethod.orangeMoney,
  PaymentMethod.airtelMoney,
];

class _PaymentMethodsManagementState extends State<PaymentMethodsManagement> {
  Set<PaymentMethod> _enabled = PaymentMethod.values.toSet();
  Map<PaymentMethod, String> _providers = {};
  bool _isLoading = true;
  final Set<PaymentMethod> _pending = {};

  bool _manualFallback = false;
  bool _manualFallbackPending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await PaymentMethodSettingsRepo.fetchEnabled();
    final manualFallback =
        await PaymentMethodSettingsRepo.isManualFallbackEnabled();
    final providers = await PaymentMethodSettingsRepo.fetchProviders();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _manualFallback = manualFallback;
      _providers = providers;
      _isLoading = false;
    });
  }

  Future<void> _toggleManualFallback(bool value) async {
    setState(() {
      _manualFallbackPending = true;
      _manualFallback = value;
    });
    try {
      await PaymentMethodSettingsRepo.setManualFallbackEnabled(value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _manualFallback = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de modifier ce réglage.')),
      );
    } finally {
      if (mounted) setState(() => _manualFallbackPending = false);
    }
  }

  Future<void> _toggle(PaymentMethod method, bool value) async {
    if (!value && _enabled.length == 1 && _enabled.contains(method)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Au moins un mode de paiement doit rester actif.')),
      );
      return;
    }

    setState(() {
      _pending.add(method);
      if (value) {
        _enabled.add(method);
      } else {
        _enabled.remove(method);
      }
    });
    try {
      await PaymentMethodSettingsRepo.setEnabled(method, value);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        // Repli visuel si la sauvegarde a échoué.
        if (value) {
          _enabled.remove(method);
        } else {
          _enabled.add(method);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de modifier ce mode de paiement.')),
      );
    } finally {
      if (mounted) setState(() => _pending.remove(method));
    }
  }

  /// Active un opérateur Mobile Money sous une plateforme donnée
  /// (`enabled = true` + `provider` sur cette plateforme), ou le
  /// désactive entièrement — jamais de bascule silencieuse vers l'autre
  /// fournisseur.
  Future<void> _toggleUnderProvider(
      PaymentMethod method, String provider, bool value) async {
    if (!value && _enabled.length == 1 && _enabled.contains(method)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Au moins un mode de paiement doit rester actif.')),
      );
      return;
    }

    final previousEnabled = _enabled.contains(method);
    final previousProvider = _providers[method];
    setState(() {
      _pending.add(method);
      if (value) {
        _enabled.add(method);
        _providers[method] = provider;
      } else {
        _enabled.remove(method);
      }
    });
    try {
      if (value) {
        await PaymentMethodSettingsRepo.setProvider(method, provider);
      }
      await PaymentMethodSettingsRepo.setEnabled(method, value);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (previousEnabled) {
          _enabled.add(method);
        } else {
          _enabled.remove(method);
        }
        if (previousProvider != null) _providers[method] = previousProvider;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Impossible de modifier ce mode de paiement.')),
      );
    } finally {
      if (mounted) setState(() => _pending.remove(method));
    }
  }

  Widget _providerSwitch(PaymentMethod method, String provider,
      {bool disabled = false}) {
    final isOn = _enabled.contains(method) && _providers[method] == provider;
    return _pending.contains(method)
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Switch(
            value: isOn,
            onChanged: disabled
                ? null
                : (v) => _toggleUnderProvider(method, provider, v),
          );
  }

  Widget _providerTile(PaymentMethod method, String provider,
      {bool disabled = false, String? subtitleOverride}) {
    return ListTile(
      leading: method.logoAsset != null
          ? CircleAvatar(backgroundImage: AssetImage(method.logoAsset!))
          : Icon(method.icon),
      title: Text(method.label),
      subtitle: subtitleOverride != null ? Text(subtitleOverride) : null,
      trailing: _providerSwitch(method, provider, disabled: disabled),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Modes de paiement')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                Text('Papi.mg', style: theme.textTheme.titleMedium),
                SizedBox(height: 0.5.h),
                Text(
                  'Paiement en ligne confirmé automatiquement.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 1.h),
                Card(
                  child: Column(
                    children: [
                      for (final m in _onlineCapableMethods) ...[
                        _providerTile(m, 'papi'),
                        if (m != _onlineCapableMethods.last)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                Text('FiveOne Pay', style: theme.textTheme.titleMedium),
                SizedBox(height: 0.5.h),
                Text(
                  'Second fournisseur de paiement en ligne Mobile Money — '
                  'MVola, Orange Money et Airtel Money disponibles.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 1.h),
                Card(
                  child: Column(
                    children: [
                      _providerTile(PaymentMethod.mvola, 'fiveonepay'),
                      const Divider(height: 1),
                      _providerTile(
                        PaymentMethod.orangeMoney,
                        'fiveonepay',
                      ),
                      const Divider(height: 1),
                      _providerTile(
                        PaymentMethod.airtelMoney,
                        'fiveonepay',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
                Text('Manuel', style: theme.textTheme.titleMedium),
                SizedBox(height: 0.5.h),
                Text(
                  'Le client transfère lui-même puis le staff vérifie la '
                  'réception (référence + preuve facultative).',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 1.h),
                Card(
                  child: Column(
                    children: [
                      for (final m in [
                        PaymentMethod.paiementLivraison,
                        PaymentMethod.virementBancaire,
                      ]) ...[
                        ListTile(
                          leading: m.logoAsset != null
                              ? CircleAvatar(
                                  backgroundImage: AssetImage(m.logoAsset!))
                              : Icon(m.icon),
                          title: Text(m.label),
                          subtitle: Text(
                            m.instructions?.split('\n').first ??
                                'Confirmé par le staff à la livraison',
                          ),
                          trailing: _pending.contains(m)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Switch(
                                  value: _enabled.contains(m),
                                  onChanged: (v) => _toggle(m, v),
                                ),
                        ),
                        if (m != PaymentMethod.virementBancaire)
                          const Divider(height: 1),
                      ],
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.build_outlined),
                        title: const Text('Secours manuel Mobile Money'),
                        subtitle: Text(
                          _manualFallback
                              ? 'Activé — Papi et FiveOne Pay désactivés pour '
                                  'tous, vérification manuelle imposée (ex: '
                                  'panne fournisseur)'
                              : 'Désactivé — le client choisit entre paiement '
                                  'automatique et manuel',
                        ),
                        trailing: _manualFallbackPending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Switch(
                                value: _manualFallback,
                                onChanged: _toggleManualFallback,
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
