import 'package:flutter/material.dart';

/// Filter chips for campaign status filtering
class CampaignFilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const CampaignFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ['All', 'Active', 'Scheduled', 'Completed', 'Draft'];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                onFilterChanged(filter);
              }
            },
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.5),
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          );
        },
      ),
    );
  }
}
