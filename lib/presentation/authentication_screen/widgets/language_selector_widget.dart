import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Language selector widget for switching between supported languages
class LanguageSelectorWidget extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const LanguageSelectorWidget({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final languages = [
      {'code': 'fr', 'name': 'Français'},
      {'code': 'mg', 'name': 'Malagasy'},
      {'code': 'en', 'name': 'English'},
      {'code': 'ar', 'name': 'العربية'},
    ];

    return PopupMenuButton<String>(
      initialValue: currentLanguage,
      onSelected: onLanguageChanged,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      itemBuilder: (context) => languages.map((lang) {
        return PopupMenuItem<String>(
          value: lang['code']!,
          child: Text(
            lang['name']!,
            style: theme.textTheme.bodyMedium,
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate,
              color: theme.colorScheme.onSurface,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              currentLanguage.toUpperCase(),
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            CustomIconWidget(
              iconName: 'arrow_drop_down',
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
