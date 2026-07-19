import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Analytics summary card showing customer demographics
class CustomerAnalyticsSummary extends StatefulWidget {
  final Map<String, dynamic> analyticsData;

  const CustomerAnalyticsSummary({
    super.key,
    required this.analyticsData,
  });

  @override
  State<CustomerAnalyticsSummary> createState() =>
      _CustomerAnalyticsSummaryState();
}

class _CustomerAnalyticsSummaryState extends State<CustomerAnalyticsSummary> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'analytics',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Analytics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Demographics & Engagement',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: _isExpanded ? 'expand_less' : 'expand_more',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAnalyticsRow(
                    context,
                    'Total Customers',
                    widget.analyticsData['totalCustomers'].toString(),
                    Icons.people,
                  ),
                  const SizedBox(height: 16),
                  _buildAnalyticsRow(
                    context,
                    'Active This Month',
                    widget.analyticsData['activeThisMonth'].toString(),
                    Icons.trending_up,
                  ),
                  const SizedBox(height: 16),
                  _buildAnalyticsRow(
                    context,
                    'New Customers',
                    widget.analyticsData['newCustomers'].toString(),
                    Icons.person_add,
                  ),
                  const SizedBox(height: 16),
                  _buildDemographicsSection(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: icon
                .toString()
                .split('.')
                .last
                .replaceAll('IconData(U+', '')
                .replaceAll(')', ''),
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDemographicsSection(BuildContext context) {
    final theme = Theme.of(context);
    final demographics =
        widget.analyticsData['demographics'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Demographics Breakdown',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _buildDemographicBar(
          context,
          'Male',
          demographics['male'] as int,
          demographics['total'] as int,
          theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _buildDemographicBar(
          context,
          'Female',
          demographics['female'] as int,
          demographics['total'] as int,
          theme.colorScheme.secondary,
        ),
        const SizedBox(height: 8),
        _buildDemographicBar(
          context,
          'Other',
          demographics['other'] as int,
          demographics['total'] as int,
          theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildDemographicBar(
    BuildContext context,
    String label,
    int value,
    int total,
    Color color,
  ) {
    final theme = Theme.of(context);
    final percentage = (value / total * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / total,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
