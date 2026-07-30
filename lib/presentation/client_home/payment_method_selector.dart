import 'package:flutter/material.dart';

import 'payment_method.dart';

/// Sélecteur visuel du mode de paiement : affiche le logo de chaque
/// opérateur mobile money (Orange Money, Mvola, Airtel Money) sous
/// forme d'avatar circulaire cliquable. L'opérateur sélectionné est
/// mis en évidence par un contour coloré.
class PaymentMethodSelector extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelected;

  const PaymentMethodSelector({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode de paiement', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: PaymentMethod.available.map((method) {
            final isSelected = method.id == selectedId;
            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: GestureDetector(
                onTap: () => onSelected(method.id),
                child: Column(
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
                        backgroundImage: AssetImage(method.logoAsset),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
