import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Order search widget with filters
/// Provides search by order number, customer name, and date range
class OrderSearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onFilterTap;

  const OrderSearchWidget({
    super.key,
    required this.onSearch,
    required this.onFilterTap,
  });

  @override
  State<OrderSearchWidget> createState() => _OrderSearchWidgetState();
}

class _OrderSearchWidgetState extends State<OrderSearchWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: widget.onSearch,
                decoration: InputDecoration(
                  hintText: 'Search orders...',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomIconWidget(
                      iconName: Icons.search.codePoint.toRadixString(16),
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: Icons.clear.codePoint.toRadixString(16),
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onFilterTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: Icons.filter_list.codePoint.toRadixString(16),
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
