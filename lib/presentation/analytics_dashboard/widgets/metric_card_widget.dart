import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Metric card widget displaying key performance indicators
class MetricCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String iconName;
  final Color? iconColor;
  final String? changePercentage;
  final bool? isPositiveChange;
  final VoidCallback? onTap;

  const MetricCardWidget({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.iconName,
    this.iconColor,
    this.changePercentage,
    this.isPositiveChange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.colorScheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: iconName,
                    color: iconColor ?? theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                if (changePercentage != null && isPositiveChange != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPositiveChange!
                          ? theme.colorScheme.tertiary.withValues(alpha: 0.12)
                          : theme.colorScheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: isPositiveChange!
                              ? 'trending_up'
                              : 'trending_down',
                          color: isPositiveChange!
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.error,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          changePercentage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isPositiveChange!
                                ? theme.colorScheme.tertiary
                                : theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 0.5.h),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
