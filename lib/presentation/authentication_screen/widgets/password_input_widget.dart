import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Password input field with visibility toggle
class PasswordInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(String) onChanged;
  final Map<String, String> translations;

  const PasswordInputWidget({
    super.key,
    required this.controller,
    this.errorText,
    required this.onChanged,
    required this.translations,
  });

  @override
  State<PasswordInputWidget> createState() => _PasswordInputWidgetState();
}

class _PasswordInputWidgetState extends State<PasswordInputWidget> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.translations['password_label'] ?? 'Password',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: widget.controller,
          obscureText: !_isPasswordVisible,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.translations['password_hint'] ?? '••••••••',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomIconWidget(
                iconName: 'lock',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: CustomIconWidget(
                iconName: _isPasswordVisible ? 'visibility' : 'visibility_off',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            errorText: widget.errorText,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}
