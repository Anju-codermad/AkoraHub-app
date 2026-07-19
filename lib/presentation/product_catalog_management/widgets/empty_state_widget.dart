import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Empty state widget shown when no products exist
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onAddProduct;

  const EmptyStateWidget({
    super.key,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'inventory_2',
                  color: theme.colorScheme.primary,
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aucun produit',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Commencez à construire votre catalogue en ajoutant votre premier produit',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onAddProduct();
              },
              icon: CustomIconWidget(
                iconName: 'add',
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              label: const Text('Ajouter un produit'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'lightbulb',
                        color: theme.colorScheme.tertiary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Conseils utiles',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(
                    context,
                    'Ajoutez des photos de haute qualité pour attirer les clients',
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(
                    context,
                    'Rédigez des descriptions détaillées et précises',
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(
                    context,
                    'Mettez à jour régulièrement vos stocks',
                  ),
                  const SizedBox(height: 12),
                  _buildTipItem(
                    context,
                    'Organisez vos produits par catégories',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: CustomIconWidget(
            iconName: 'check_circle',
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
