import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Social login options widget
class SocialLoginWidget extends StatelessWidget {
  final Function(String) onSocialLogin;
  final Map<String, String> translations;

  const SocialLoginWidget({
    super.key,
    required this.onSocialLogin,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                translations['or_continue_with'] ?? 'Or continue with',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onSocialLogin('google'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: Text(
                  'Google',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: OutlinedButton(
                onPressed: () => onSocialLogin('facebook'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: Text(
                  'Facebook',
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
