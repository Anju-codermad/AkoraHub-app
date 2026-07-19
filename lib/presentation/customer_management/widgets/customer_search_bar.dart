import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Search bar with filter options for customer management
class CustomerSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final VoidCallback onFilterTap;

  const CustomerSearchBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'close',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'tune',
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                onFilterTap();
              },
              tooltip: 'Advanced Filters',
            ),
          ),
        ],
      ),
    );
  }
}
