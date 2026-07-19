import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Advanced Options Widget
/// Handles SEO, visibility, and promotional settings
class AdvancedOptionsWidget extends StatefulWidget {
  final TextEditingController seoTagsController;
  final bool isVisible;
  final bool isPromotional;
  final Function(bool) onVisibilityChanged;
  final Function(bool) onPromotionalChanged;
  final VoidCallback onChanged;

  const AdvancedOptionsWidget({
    super.key,
    required this.seoTagsController,
    required this.isVisible,
    required this.isPromotional,
    required this.onVisibilityChanged,
    required this.onPromotionalChanged,
    required this.onChanged,
  });

  @override
  State<AdvancedOptionsWidget> createState() => _AdvancedOptionsWidgetState();
}

class _AdvancedOptionsWidgetState extends State<AdvancedOptionsWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Advanced Options',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
          if (_isExpanded) ...[
            SizedBox(height: 2.h),

            // SEO Tags
            TextFormField(
              controller: widget.seoTagsController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'SEO Tags',
                hintText: 'Enter tags separated by commas',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'tag',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              onChanged: (_) => widget.onChanged(),
            ),
            SizedBox(height: 1.h),
            Text(
              'Tags help customers find your product through search',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            SizedBox(height: 2.h),
            Divider(color: theme.colorScheme.outline),
            SizedBox(height: 2.h),

            // Visibility Settings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: widget.isVisible
                                ? 'visibility'
                                : 'visibility_off',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Product Visibility',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.isVisible
                            ? 'Product is visible to customers'
                            : 'Product is hidden from customers',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.isVisible,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    widget.onVisibilityChanged(value);
                  },
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Promotional Flag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'local_offer',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Promotional Product',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Mark as featured or promotional item',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.isPromotional,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    widget.onPromotionalChanged(value);
                  },
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Premium Features Notice
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.w),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'workspace_premium',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Features',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Upgrade to access advanced analytics, automated inventory alerts, and priority support',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
