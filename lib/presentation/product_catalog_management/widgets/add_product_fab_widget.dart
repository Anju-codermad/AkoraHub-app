import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Floating action button for adding new products
class AddProductFabWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const AddProductFabWidget({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: CustomIconWidget(
        iconName: 'add',
        color: theme.floatingActionButtonTheme.foregroundColor ??
            theme.colorScheme.onTertiary,
        size: 24,
      ),
      label: Text(
        'Ajouter',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.floatingActionButtonTheme.foregroundColor ??
              theme.colorScheme.onTertiary,
        ),
      ),
      backgroundColor: theme.floatingActionButtonTheme.backgroundColor ??
          theme.colorScheme.tertiary,
      elevation: theme.floatingActionButtonTheme.elevation ?? 4.0,
    );
  }
}
