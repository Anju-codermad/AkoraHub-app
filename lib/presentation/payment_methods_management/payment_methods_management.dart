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
    return Scaffold(
      appBar: AppBar(title: const Text('Modes de paiement')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: EdgeInsets.all(4.w),
              itemCount: PaymentMethod.values.length,
              separatorBuilder: (_, __) => SizedBox(height: 1.h),
              itemBuilder: (context, index) {
                final method = PaymentMethod.values[index];
                final enabled = _enabled.contains(method);
                return Card(
                  child: ListTile(
                    leading: Icon(method.icon),
                    title: Text(method.label),
                    subtitle: Text(
                      method.instructions?.split('\n').first ??
                          'Confirmé par le staff à la livraison',
                    ),
                    trailing: _pending.contains(method)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: enabled,
                            onChanged: (v) => _toggle(method, v),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
