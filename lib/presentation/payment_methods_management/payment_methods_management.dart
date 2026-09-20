import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/payment/payment_method_settings_repo.dart';
import '../../core/payment/payment_methods.dart';

/// Permet à l'Admin d'activer/désactiver chaque mode de paiement proposé
/// au checkout client (paiement à la livraison, virement bancaire, Orange
/// Money, Mvola, Airtel Money) — utile par exemple si un numéro Mobile
/// Money personnel devient temporairement indisponible.
///
/// Tous les modes sont manuels (référence + preuve facultative, vérifiée
/// par le staff) — Papi.mg et FiveOne Pay (paiement en ligne automatique)
/// ont été retirés le 20/09/2026, demande explicite de la propriétaire, en
/// attendant une intégration directe avec les opérateurs Mobile Money.
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await PaymentMethodSettingsRepo.fetchEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _isLoading = false;
    });
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
                      for (final m in PaymentMethod.values) ...[
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
                        if (m != PaymentMethod.values.last)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
