import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Contact Details Section Widget
///
/// Manages business contact information including:
/// - Phone number with validation
/// - Email address with validation
/// - Website URL
/// - Social media links (Facebook, Instagram, WhatsApp)
/// - Physical address with map integration
/// - Operating hours for each day of the week
class ContactDetailsSection extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final VoidCallback onChanged;

  const ContactDetailsSection({
    super.key,
    required this.businessData,
    required this.onChanged,
  });

  @override
  State<ContactDetailsSection> createState() => _ContactDetailsSectionState();
}

class _ContactDetailsSectionState extends State<ContactDetailsSection> {
  final _formKey = GlobalKey<FormState>();
  bool _showOperatingHours = false;

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!RegExp(r'^\+?[\d\s-]+$').hasMatch(value)) {
      return 'Invalid phone number format';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!RegExp(r'^https?://').hasMatch(value)) {
        return 'URL must start with http:// or https://';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final address = widget.businessData["address"] as Map<String, dynamic>;
    final socialMedia =
        widget.businessData["socialMedia"] as Map<String, dynamic>;

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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'contact_phone',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Text(
                  'Contact Details',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Phone Number
            Text(
              'Phone Number',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              initialValue: widget.businessData["phone"] as String,
              decoration: InputDecoration(
                hintText: '+261 34 12 345 67',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'phone',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                widget.businessData["phone"] = value;
                widget.onChanged();
              },
            ),

            SizedBox(height: 2.h),

            // Email
            Text(
              'Email Address',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              initialValue: widget.businessData["email"] as String,
              decoration: InputDecoration(
                hintText: 'contact@business.com',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'email',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              onChanged: (value) {
                widget.businessData["email"] = value;
                widget.onChanged();
              },
            ),

            SizedBox(height: 2.h),

            // Website
            Text(
              'Website',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 1.h),
            TextFormField(
              initialValue: widget.businessData["website"] as String,
              decoration: InputDecoration(
                hintText: 'https://www.business.com',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'language',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              keyboardType: TextInputType.url,
              validator: _validateUrl,
              onChanged: (value) {
                widget.businessData["website"] = value;
                widget.onChanged();
              },
            ),

            SizedBox(height: 3.h),

            // Social Media
            Text(
              'Social Media',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),

            // Facebook
            TextFormField(
              initialValue: socialMedia["facebook"] as String,
              decoration: InputDecoration(
                labelText: 'Facebook',
                hintText: 'facebook.com/username',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'facebook',
                    color: const Color(0xFF1877F2),
                    size: 20,
                  ),
                ),
              ),
              onChanged: (value) {
                socialMedia["facebook"] = value;
                widget.onChanged();
              },
            ),

            SizedBox(height: 2.h),

            // Instagram
            TextFormField(
              initialValue: socialMedia["instagram"] as String,
              decoration: InputDecoration(
                labelText: 'Instagram',
                hintText: '@username',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'camera_alt',
                    color: const Color(0xFFE4405F),
                    size: 20,
                  ),
                ),
              ),
              onChanged: (value) {
                socialMedia["instagram"] = value;
                widget.onChanged();
              },
            ),

            SizedBox(height: 2.h),

            // WhatsApp
            TextFormField(
              initialValue: socialMedia["whatsapp"] as String,
              decoration: InputDecoration(
                labelText: 'WhatsApp',
                hintText: '+261 34 12 345 67',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'chat',
                    color: const Color(0xFF25D366),
                    size: 20,
                  ),
                ),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                socialMedia["whatsapp"] = value;
                widget.onChanged();
              },
            ),

            SizedBox(height: 3.h),

            // Address
            Text(
              'Business Address',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),

            TextFormField(
              initialValue: address["street"] as String,
              decoration: InputDecoration(
                labelText: 'Street Address',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'location_on',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ),
              onChanged: (value) {
                address["street"] = value;
                widget.onChanged();
              },
            ),

            SizedBox(height: 2.h),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: address["city"] as String,
                    decoration: const InputDecoration(
                      labelText: 'City',
                    ),
                    onChanged: (value) {
                      address["city"] = value;
                      widget.onChanged();
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: TextFormField(
                    initialValue: address["postalCode"] as String,
                    decoration: const InputDecoration(
                      labelText: 'Postal Code',
                    ),
                    onChanged: (value) {
                      address["postalCode"] = value;
                      widget.onChanged();
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            TextFormField(
              initialValue: address["country"] as String,
              decoration: const InputDecoration(
                labelText: 'Country',
              ),
              onChanged: (value) {
                address["country"] = value;
                widget.onChanged();
              },
            ),

            SizedBox(height: 3.h),

            // Operating Hours
            InkWell(
              onTap: () {
                setState(() => _showOperatingHours = !_showOperatingHours);
              },
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'schedule',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Operating Hours',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    CustomIconWidget(
                      iconName:
                          _showOperatingHours ? 'expand_less' : 'expand_more',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            if (_showOperatingHours) ...[
              SizedBox(height: 2.h),
              _buildOperatingHoursSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOperatingHoursSection(BuildContext context) {
    final theme = Theme.of(context);
    final operatingHours =
        widget.businessData["operatingHours"] as Map<String, dynamic>;
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: List.generate(days.length, (index) {
          final day = days[index];
          final dayData = operatingHours[day] as Map<String, dynamic>;
          final isClosed = dayData["closed"] as bool;

          return Padding(
            padding: EdgeInsets.only(bottom: index < days.length - 1 ? 2.h : 0),
            child: Row(
              children: [
                SizedBox(
                  width: 25.w,
                  child: Text(
                    dayNames[index],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: isClosed
                      ? Text(
                          'Closed',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTimeChip(
                              context,
                              time: dayData["open"] as String,
                              onPicked: (value) {
                                setState(() => dayData["open"] = value);
                                widget.onChanged();
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text('-', style: theme.textTheme.bodyMedium),
                            ),
                            _buildTimeChip(
                              context,
                              time: dayData["close"] as String,
                              onPicked: (value) {
                                setState(() => dayData["close"] = value);
                                widget.onChanged();
                              },
                            ),
                          ],
                        ),
                ),
                Switch(
                  value: !isClosed,
                  onChanged: (value) {
                    setState(() => dayData["closed"] = !value);
                    widget.onChanged();
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Chip d'heure cliquable — ouvre un sélecteur d'heure natif et renvoie
  /// la nouvelle valeur au format "HH:mm" (le même que celui déjà stocké
  /// dans `operatingHours`, voir business_profile_settings.dart).
  Widget _buildTimeChip(
    BuildContext context, {
    required String time,
    required ValueChanged<String> onPicked,
  }) {
    final theme = Theme.of(context);
    final parts = time.split(':');
    final initial = TimeOfDay(
      hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked == null) return;
        final hh = picked.hour.toString().padLeft(2, '0');
        final mm = picked.minute.toString().padLeft(2, '0');
        onPicked('$hh:$mm');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(time, style: theme.textTheme.bodyMedium),
      ),
    );
  }
}
