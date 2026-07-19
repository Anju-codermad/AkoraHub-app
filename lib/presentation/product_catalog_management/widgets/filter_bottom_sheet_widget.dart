import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Filter bottom sheet widget for category selection
class FilterBottomSheetWidget extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const FilterBottomSheetWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      {'name': 'All', 'icon': 'apps', 'label': 'Tous les produits'},
      {'name': 'Soap', 'icon': 'soap', 'label': 'Savons'},
      {'name': 'Cleaning', 'icon': 'cleaning_services', 'label': 'Nettoyage'},
      {'name': 'Hygiene', 'icon': 'health_and_safety', 'label': 'Hygiène'},
      {'name': 'Cosmetics', 'icon': 'face', 'label': 'Cosmétiques'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'filter_list',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filtrer par catégorie',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 72,
                color: theme.colorScheme.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category['name'];

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: category['icon']!,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                  ),
                  title: Text(
                    category['label']!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? CustomIconWidget(
                          iconName: 'check_circle',
                          color: theme.colorScheme.primary,
                          size: 24,
                        )
                      : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onCategorySelected(category['name']!);
                  },
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
