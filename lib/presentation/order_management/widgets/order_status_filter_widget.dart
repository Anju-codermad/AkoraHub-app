import 'package:flutter/material.dart';

/// Order status filter tabs widget
/// Displays filter tabs with notification badges for order counts
class OrderStatusFilterWidget extends StatelessWidget {
  final String selectedStatus;
  final Function(String) onStatusChanged;
  final Map<String, int> statusCounts;

  const OrderStatusFilterWidget({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.statusCounts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = ['All', 'Pending', 'Processing', 'Completed', 'Cancelled'];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statuses.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = statuses[index];
          final isSelected = selectedStatus == status;
          final count = statusCounts[status] ?? 0;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onStatusChanged(status),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onError,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
