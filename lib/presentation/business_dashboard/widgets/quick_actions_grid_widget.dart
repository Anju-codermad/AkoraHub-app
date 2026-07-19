import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Quick Actions Grid Widget
/// Provides one-tap access to frequent tasks
class QuickActionsGridWidget extends StatelessWidget {
  final Function(String actionType) onActionTap;

  const QuickActionsGridWidget({
    super.key,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actions = [
      {
        'type': 'add_product',
        'icon': 'add_shopping_cart',
        'label': 'Add Product',
        'color': theme.colorScheme.primary,
      },
      {
        'type': 'create_campaign',
        'icon': 'campaign',
        'label': 'Create Campaign',
        'color': theme.colorScheme.secondary,
      },
      {
        'type': 'view_orders',
        'icon': 'receipt_long',
        'label': 'View Orders',
        'color': theme.colorScheme.tertiary,
      },
      {
        'type': 'customer_messages',
        'icon': 'chat',
        'label': 'Messages',
        'color': AppTheme.successLight,
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 0.85,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _buildActionButton(
                context,
                theme,
                action['type'] as String,
                action['icon'] as String,
                action['label'] as String,
                action['color'] as Color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    String type,
    String icon,
    String label,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onActionTap(type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: icon,
                  color: color,
                  size: 24,
                ),
              ),
              SizedBox(height: 1.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.w),
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
