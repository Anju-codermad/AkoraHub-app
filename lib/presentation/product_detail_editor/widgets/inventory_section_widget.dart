import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Inventory Section Widget
/// Handles inventory tracking and stock management
class InventorySectionWidget extends StatelessWidget {
  final bool inventoryTrackingEnabled;
  final TextEditingController stockQuantityController;
  final TextEditingController lowStockAlertController;
  final Function(bool) onInventoryToggled;
  final VoidCallback onChanged;

  const InventorySectionWidget({
    super.key,
    required this.inventoryTrackingEnabled,
    required this.stockQuantityController,
    required this.lowStockAlertController,
    required this.onInventoryToggled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Inventory Tracking',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: inventoryTrackingEnabled,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  onInventoryToggled(value);
                },
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Enable to track product stock levels and receive low stock alerts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (inventoryTrackingEnabled) ...[
            SizedBox(height: 2.h),
            TextFormField(
              controller: stockQuantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Stock Quantity *',
                hintText: 'Enter current stock',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'inventory',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) {
                if (inventoryTrackingEnabled &&
                    (value == null || value.isEmpty)) {
                  return 'Stock quantity is required';
                }
                return null;
              },
              onChanged: (_) => onChanged(),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: lowStockAlertController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Low Stock Alert Threshold',
                hintText: 'Alert when stock falls below',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'notifications_active',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              onChanged: (_) => onChanged(),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'lightbulb_outline',
                    color: theme.colorScheme.tertiary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'You will receive notifications when stock reaches the alert threshold',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
