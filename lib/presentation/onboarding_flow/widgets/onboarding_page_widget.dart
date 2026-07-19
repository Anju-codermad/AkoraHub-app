import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Individual onboarding page widget
/// Displays illustration, title, description and feature icon
class OnboardingPageWidget extends StatelessWidget {
  final Map<String, dynamic> pageData;

  const OnboardingPageWidget({
    super.key,
    required this.pageData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 2.h),

            // Feature icon
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: pageData["iconName"] as String,
                  size: 10.w,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Main illustration
            Container(
              constraints: BoxConstraints(
                maxHeight: 35.h,
                maxWidth: 90.w,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomImageWidget(
                  imageUrl: pageData["image"] as String,
                  width: 90.w,
                  height: 35.h,
                  fit: BoxFit.cover,
                  semanticLabel: pageData["semanticLabel"] as String,
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Title
            Text(
              pageData["title"] as String,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 2.h),

            // Description
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Text(
                pageData["description"] as String,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }
}
