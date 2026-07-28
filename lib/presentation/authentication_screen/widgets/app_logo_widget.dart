import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// App logo widget with brand recognition
class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 25.w,
          height: 25.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: CustomImageWidget(
              imageUrl: 'assets/images/img_app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'AkoraHub',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Votre plateforme multi-activités',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
