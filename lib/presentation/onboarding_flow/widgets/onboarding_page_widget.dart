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

            // Illustration : icône unique sur fond dégradé (remplace les
            // anciennes images externes img.rocket.new — supprimées le
            // 23/07 pour ne plus dépendre d'un CDN tiers dans le premier
            // écran vu par chaque nouvel utilisateur). Aucun réseau
            // requis, aucune image cassée possible.
            Container(
              constraints: BoxConstraints(
                maxHeight: 35.h,
                maxWidth: 90.w,
              ),
              width: 90.w,
              height: 35.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Semantics(
                  label: pageData["semanticLabel"] as String?,
                  child: CustomIconWidget(
                    iconName: pageData["iconName"] as String,
                    size: 22.w,
                    color: theme.colorScheme.primary,
                  ),
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
