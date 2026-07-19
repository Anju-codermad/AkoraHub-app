import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Metrics Cards Widget
/// Displays key performance indicators in card format
class MetricsCardsWidget extends StatelessWidget {
  final Function(String metricType) onMetricTap;

  const MetricsCardsWidget({
    super.key,
    required this.onMetricTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final metrics = [
      {
        'type': 'sales',
        'icon': 'attach_money',
        'label': 'Today\'s Sales',
        'value': '\$2,450',
        'change': '+12.5%',
        'isPositive': true,
      },
      {
        'type': 'orders',
        'icon': 'shopping_bag',
        'label': 'Pending Orders',
        'value': '18',
        'change': '+3',
        'isPositive': true,
      },
      {
        'type': 'followers',
        'icon': 'people',
        'label': 'New Followers',
        'value': '247',
        'change': '+15.2%',
        'isPositive': true,
      },
      {
        'type': 'messages',
        'icon': 'message',
        'label': 'Messages',
        'value': '12',
        'change': '5 unread',
        'isPositive': false,
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 1.5,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return _buildMetricCard(
                context,
                theme,
                metric['type'] as String,
                metric['icon'] as String,
                metric['label'] as String,
                metric['value'] as String,
                metric['change'] as String,
                metric['isPositive'] as bool,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    ThemeData theme,
    String type,
    String icon,
    String label,
    String value,
    String change,
    bool isPositive,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onMetricTap(type),
        onLongPress: () {
          // Show detailed breakdown
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Long press detected for $label'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: icon,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'arrow_forward_ios',
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                    size: 14,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      if (isPositive)
                        CustomIconWidget(
                          iconName: 'trending_up',
                          color: theme.colorScheme.tertiary,
                          size: 14,
                        )
                      else
                        CustomIconWidget(
                          iconName: 'info_outline',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 14,
                        ),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          change,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isPositive
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
