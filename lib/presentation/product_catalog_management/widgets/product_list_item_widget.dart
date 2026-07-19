import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/app_export.dart';

/// Product list item widget with swipe actions
class ProductListItemWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isGridView;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onVisibilityToggle;

  const ProductListItemWidget({
    super.key,
    required this.product,
    required this.isGridView,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.onVisibilityToggle,
  });

  Widget _buildStockBadge(BuildContext context) {
    final theme = Theme.of(context);
    final stock = product["stock"] as int;
    final isLowStock = stock < 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLowStock
            ? theme.colorScheme.error.withValues(alpha: 0.1)
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: isLowStock ? 'warning' : 'inventory',
            color: isLowStock
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$stock en stock',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isLowStock
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityBadge(BuildContext context) {
    final theme = Theme.of(context);
    final isVisible = product["visibility"] as bool;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVisible
            ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: isVisible ? 'visibility' : 'visibility_off',
            color: isVisible
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurfaceVariant,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isVisible ? 'Visible' : 'Masqué',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isVisible
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridViewCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CustomImageWidget(
                    imageUrl: product["image"],
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    semanticLabel: product["semanticLabel"],
                  ),
                ),
                if (isMultiSelectMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onTap,
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildVisibilityBadge(context),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product["name"],
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product["category"],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product["price"],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        _buildStockBadge(context),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListViewCard(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(product["id"]),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.selectionClick();
              onEdit();
            },
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.selectionClick();
              onVisibilityToggle();
            },
            backgroundColor: theme.colorScheme.tertiary,
            foregroundColor: theme.colorScheme.onTertiary,
            icon: (product["visibility"] as bool)
                ? Icons.visibility_off
                : Icons.visibility,
            label: (product["visibility"] as bool) ? 'Masquer' : 'Afficher',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              HapticFeedback.mediumImpact();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer le produit?'),
                  content: Text(
                      'Voulez-vous vraiment supprimer "${product["name"]}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );
            },
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (isMultiSelectMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onTap,
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: product["image"],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    semanticLabel: product["semanticLabel"],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product["name"],
                              style: theme.textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildVisibilityBadge(context),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product["category"],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product["price"],
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _buildStockBadge(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isGridView
        ? _buildGridViewCard(context)
        : _buildListViewCard(context);
  }
}
