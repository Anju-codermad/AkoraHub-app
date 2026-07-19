import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Visual Identity Section Widget
///
/// Manages business visual branding including:
/// - Brand color customization (primary, secondary, accent)
/// - Color scheme preview
/// - Branding consistency across customer-facing materials
class VisualIdentitySection extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final VoidCallback onChanged;

  const VisualIdentitySection({
    super.key,
    required this.businessData,
    required this.onChanged,
  });

  @override
  State<VisualIdentitySection> createState() => _VisualIdentitySectionState();
}

class _VisualIdentitySectionState extends State<VisualIdentitySection> {
  late Map<String, Color> _brandColors;

  @override
  void initState() {
    super.initState();
    final colors = widget.businessData["brandColors"] as Map<String, dynamic>;
    _brandColors = {
      "primary": _hexToColor(colors["primary"] as String),
      "secondary": _hexToColor(colors["secondary"] as String),
      "accent": _hexToColor(colors["accent"] as String),
    };
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _showColorPicker(String colorType) {
    final theme = Theme.of(context);
    final currentColor = _brandColors[colorType]!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose ${colorType.toUpperCase()} Color'),
        content: SizedBox(
          width: 80.w,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 2.w,
            ),
            itemCount: _predefinedColors.length,
            itemBuilder: (context, index) {
              final color = _predefinedColors[index];
              final isSelected = color.value == currentColor.value;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _brandColors[colorType] = color;
                  });
                  widget.onChanged();
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: CustomIconWidget(
                            iconName: 'check',
                            color: _getContrastColor(color),
                            size: 20,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  static final List<Color> _predefinedColors = [
    const Color(0xFF1B365D),
    const Color(0xFF4A90A4),
    const Color(0xFFE8B931),
    const Color(0xFFD32F2F),
    const Color(0xFF2E7D32),
    const Color(0xFFF57C00),
    const Color(0xFF7B1FA2),
    const Color(0xFF0288D1),
    const Color(0xFF00796B),
    const Color(0xFFC2185B),
    const Color(0xFF5D4037),
    const Color(0xFF455A64),
    const Color(0xFF1976D2),
    const Color(0xFF388E3C),
    const Color(0xFFF57F17),
    const Color(0xFF512DA8),
    const Color(0xFF0097A7),
    const Color(0xFFE64A19),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              CustomIconWidget(
                iconName: 'palette',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Visual Identity',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          Text(
            'Customize your brand colors to maintain consistency across all customer-facing materials.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          SizedBox(height: 3.h),

          // Primary Color
          _buildColorSelector(
            context,
            'Primary Color',
            'primary',
            _brandColors["primary"]!,
            'Main brand color used for buttons and key elements',
          ),

          SizedBox(height: 2.h),

          // Secondary Color
          _buildColorSelector(
            context,
            'Secondary Color',
            'secondary',
            _brandColors["secondary"]!,
            'Supporting color for accents and highlights',
          ),

          SizedBox(height: 2.h),

          // Accent Color
          _buildColorSelector(
            context,
            'Accent Color',
            'accent',
            _brandColors["accent"]!,
            'Accent color for special elements and CTAs',
          ),

          SizedBox(height: 3.h),

          // Color Preview
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: _brandColors["primary"],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Primary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  _getContrastColor(_brandColors["primary"]!),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Container(
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: _brandColors["secondary"],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Secondary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  _getContrastColor(_brandColors["secondary"]!),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Container(
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: _brandColors["accent"],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Accent',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _getContrastColor(_brandColors["accent"]!),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector(
    BuildContext context,
    String label,
    String colorType,
    Color color,
    String description,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        InkWell(
          onTap: () => _showColorPicker(colorType),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    _colorToHex(color),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                CustomIconWidget(
                  iconName: 'edit',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
