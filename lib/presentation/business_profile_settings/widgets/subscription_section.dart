import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Subscription Section Widget
///
/// Displays subscription information and management including:
/// - Current plan status and details
/// - Usage metrics (products, storage)
/// - Plan upgrade options
/// - Billing information
/// - Payment history
class SubscriptionSection extends StatelessWidget {
  final Map<String, dynamic> businessData;

  const SubscriptionSection({
    super.key,
    required this.businessData,
  });

  void _showUpgradeDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your plan:',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),
            _buildPlanOption(
              context,
              'Monthly Plan',
              '\$5/month',
              'Billed monthly',
              false,
            ),
            SizedBox(height: 1.h),
            _buildPlanOption(
              context,
              'Annual Plan',
              '\$60/year',
              'Save \$12 per year',
              true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Redirecting to payment...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(
    BuildContext context,
    String title,
    String price,
    String description,
    bool recommended,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: recommended
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: recommended
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: recommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (recommended)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            price,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscription = businessData["subscription"] as Map<String, dynamic>;
    final isActive = subscription["status"] == "active";

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'card_membership',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Subscription',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'EXPIRED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Current Plan
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscription["plan"] == "annual"
                      ? 'Annual Plan'
                      : 'Monthly Plan',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  subscription["price"] as String,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'calendar_today',
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Valid until ${subscription["endDate"]}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Usage Metrics
          Text(
            'Usage Statistics',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          // Products Usage
          _buildUsageMetric(
            context,
            'Products',
            subscription["productsUsed"] as int,
            subscription["productsLimit"] as int,
            'inventory_2',
          ),

          SizedBox(height: 2.h),

          // Storage Usage
          _buildUsageMetric(
            context,
            'Storage',
            (subscription["storageUsed"] as double).toInt(),
            (subscription["storageLimit"] as double).toInt(),
            'storage',
            unit: 'GB',
          ),

          SizedBox(height: 3.h),

          // Upgrade Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showUpgradeDialog(context),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'upgrade',
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  const Text('Upgrade Plan'),
                ],
              ),
            ),
          ),

          SizedBox(height: 1.h),

          // Manage Subscription
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to subscription management
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
              child: const Text('Manage Subscription'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageMetric(
    BuildContext context,
    String label,
    int used,
    int limit,
    String iconName, {
    String unit = '',
  }) {
    final theme = Theme.of(context);
    final percentage = (used / limit * 100).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$used / $limit $unit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 80
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          '${percentage.toStringAsFixed(0)}% used',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
