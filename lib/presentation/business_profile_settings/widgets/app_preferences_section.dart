import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// App Preferences Section Widget
///
/// Manages application settings and preferences including:
/// - Language selection (French, Malagasy, English, Arabic)
/// - Notification preferences (orders, messages, promotions, analytics)
/// - Privacy settings (visibility of contact information)
/// - Theme preferences
class AppPreferencesSection extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final VoidCallback onChanged;

  const AppPreferencesSection({
    super.key,
    required this.businessData,
    required this.onChanged,
  });

  @override
  State<AppPreferencesSection> createState() => _AppPreferencesSectionState();
}

class _AppPreferencesSectionState extends State<AppPreferencesSection> {
  late Map<String, bool> _notifications;
  late Map<String, bool> _privacy;
  late String _selectedLanguage;

  final List<Map<String, String>> _languages = [
    {"code": "fr", "name": "Français", "flag": "🇫🇷"},
    {"code": "mg", "name": "Malagasy", "flag": "🇲🇬"},
    {"code": "en", "name": "English", "flag": "🇬🇧"},
    {"code": "ar", "name": "العربية", "flag": "🇸🇦"},
  ];

  @override
  void initState() {
    super.initState();
    final preferences =
        widget.businessData["preferences"] as Map<String, dynamic>;
    _notifications =
        Map<String, bool>.from(preferences["notifications"] as Map);
    _privacy = Map<String, bool>.from(preferences["privacy"] as Map);
    _selectedLanguage = preferences["language"] as String;
  }

  void _showLanguageDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((lang) {
            final isSelected = _selectedLanguage == lang["code"];
            return RadioListTile<String>(
              value: lang["code"]!,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                  widget.onChanged();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to ${lang["name"]}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              title: Row(
                children: [
                  Text(lang["flag"]!),
                  SizedBox(width: 3.w),
                  Text(lang["name"]!),
                ],
              ),
              activeColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLanguage = _languages.firstWhere(
      (lang) => lang["code"] == _selectedLanguage,
      orElse: () => _languages[0],
    );

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
                iconName: 'settings',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'App Preferences',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Language Selection
          Text(
            'Language',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          InkWell(
            onTap: _showLanguageDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    currentLanguage["flag"]!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      currentLanguage["name"]!,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'arrow_forward_ios',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Notifications
          Text(
            'Notifications',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),

          _buildNotificationToggle(
            'Orders',
            'Get notified about new orders and updates',
            'orders',
            'shopping_bag',
          ),

          _buildNotificationToggle(
            'Messages',
            'Receive notifications for new customer messages',
            'messages',
            'message',
          ),

          _buildNotificationToggle(
            'Promotions',
            'Stay updated with promotional campaigns',
            'promotions',
            'campaign',
          ),

          _buildNotificationToggle(
            'Analytics',
            'Get insights about your business performance',
            'analytics',
            'analytics',
          ),

          SizedBox(height: 3.h),

          // Privacy Settings
          Text(
            'Privacy Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),

          _buildPrivacyToggle(
            'Show Phone Number',
            'Display phone number on business profile',
            'showPhone',
            'phone',
          ),

          _buildPrivacyToggle(
            'Show Email Address',
            'Display email address on business profile',
            'showEmail',
            'email',
          ),

          _buildPrivacyToggle(
            'Show Physical Address',
            'Display business address on profile',
            'showAddress',
            'location_on',
          ),

          SizedBox(height: 3.h),

          // Additional Settings
          _buildSettingItem(
            'Data & Storage',
            'Manage app data and storage usage',
            'storage',
            () {
              // Navigate to data management
            },
          ),

          _buildSettingItem(
            'Security',
            'Password and security settings',
            'security',
            () {
              // Navigate to security settings
            },
          ),

          _buildSettingItem(
            'Help & Support',
            'Get help and contact support',
            'help_outline',
            () {
              // Navigate to help center
            },
          ),

          _buildSettingItem(
            'About',
            'App version and legal information',
            'info_outline',
            () {
              // Show about dialog
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String description,
    String key,
    String iconName,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
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
                ],
              ),
            ),
            Switch(
              value: _notifications[key] ?? false,
              onChanged: (value) {
                setState(() {
                  _notifications[key] = value;
                });
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyToggle(
    String title,
    String description,
    String key,
    String iconName,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: iconName,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
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
                ],
              ),
            ),
            Switch(
              value: _privacy[key] ?? false,
              onChanged: (value) {
                setState(() {
                  _privacy[key] = value;
                });
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String description,
    String iconName,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: theme.colorScheme.tertiary,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
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
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: 'arrow_forward_ios',
                color: theme.colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
