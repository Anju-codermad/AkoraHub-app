import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Email input field with validation
class EmailInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(String) onChanged;
  final Map<String, String> translations;

  const EmailInputWidget({
    super.key,
    required this.controller,
    this.errorText,
    required this.onChanged,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translations['email_label'] ?? 'Email',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: translations['email_hint'] ?? 'business@example.com',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomIconWidget(
                iconName: 'email',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            errorText: errorText,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}
