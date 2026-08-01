import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/payment/payment_method_settings_repo.dart';
import '../../core/payment/payment_methods.dart';

/// Permet à l'Admin d'activer/désactiver chaque mode de paiement proposé
/// au checkout client (paiement à la livraison, virement bancaire, Orange
/// Money, Mvola, Airtel Money) — utile par exemple si un numéro Mobile
/// Money personnel devient temporairement indisponible, ou pour retirer
/// les modes manuels une fois un vrai paiement en ligne en place.
class PaymentMethodsManagement extends StatefulWidget {
  const PaymentMethodsManagement({super.key});

  @override
  State<PaymentMethodsManagement> createState() =>
      _PaymentMethodsManagementState();
}

class _PaymentMethodsManagementState extends State<PaymentMethodsManagement> {
  Set<PaymentMethod> _enabled = PaymentMethod.values.toSet();
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
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _manualFallback = manualFallback;
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
                for (final method in PaymentMethod.values) ...[
                  Card(
                    child: ListTile(
                      leading: method.logoAsset != null
                          ? CircleAvatar(
                              backgroundImage: AssetImage(method.logoAsset!))
                          : Icon(method.icon),
                      title: Text(method.label),
                      subtitle: Text(
                        method.instructions?.split('\n').first ??
                            'Confirmé par le staff à la livraison',
                      ),
                      trailing: _pending.contains(method)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Switch(
                              value: _enabled.contains(method),
                              onChanged: (v) => _toggle(method, v),
                            ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                ],
                SizedBox(height: 2.h),
                Text(
                  'Mvola, Orange Money et Airtel Money passent normalement '
                  'par Papi (paiement en ligne confirmé automatiquement). '
                  'Ce réglage permet de revenir au flux manuel (référence + '
                  'photo, vérifiée par le staff) en cas de problème avec '
                  'Papi.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                SizedBox(height: 1.h),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.build_outlined),
                    title: const Text('Mode manuel (secours)'),
                    subtitle: Text(
                      _manualFallback
                          ? 'Activé — Papi désactivé pour tous, vérification manuelle imposée (ex: Papi en panne)'
                          : 'Désactivé — le client choisit entre paiement automatique (Papi) et manuel',
                    ),
                    trailing: _manualFallbackPending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: _manualFallback,
                            onChanged: _toggleManualFallback,
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
