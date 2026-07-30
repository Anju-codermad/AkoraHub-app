import 'package:flutter/material.dart';

import 'payment_methods.dart';

/// Sélecteur visuel du mode de paiement : avatar circulaire cliquable par
/// mode (logo réel de l'opérateur pour Orange Money/Mvola/Airtel Money,
/// icône générique pour paiement à la livraison/virement bancaire).
/// L'option sélectionnée est mise en évidence par un contour coloré.
/// N'affiche que les modes présents dans [methods] (déjà filtrés par
/// l'activation Admin, voir `payment_method_settings_repo.dart`).
class PaymentMethodSelector extends StatelessWidget {
  final List<PaymentMethod> methods;
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  const PaymentMethodSelector({
    super.key,
    required this.methods,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 14,
      runSpacing: 12,
      children: methods.map((method) {
        final isSelected = method == selected;
        final logoAsset = method.logoAsset;
        return GestureDetector(
          onTap: () => onSelected(method),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage:
                      logoAsset != null ? AssetImage(logoAsset) : null,
                  child: logoAsset == null
                      ? Icon(method.icon,
                          color: theme.colorScheme.onSurfaceVariant)
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                method.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
