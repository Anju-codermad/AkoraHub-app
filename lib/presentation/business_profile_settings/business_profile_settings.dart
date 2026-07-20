import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/supabase/supabase_config.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/app_preferences_section.dart';
import './widgets/business_information_section.dart';
import './widgets/contact_details_section.dart';
import './widgets/subscription_section.dart';
import './widgets/visual_identity_section.dart';

/// Business Profile Settings Screen
///
/// Provides comprehensive business information management and platform customization
/// through mobile-optimized interface. Features include:
/// - Business information editing with multi-language support
/// - Visual identity customization (logo, colors, branding)
/// - Contact details management with validation
/// - Subscription plan management and usage metrics
/// - App preferences (language, notifications, privacy)
/// - Verification status and business profile export
class BusinessProfileSettings extends StatefulWidget {
  const BusinessProfileSettings({super.key});

  @override
  State<BusinessProfileSettings> createState() =>
      _BusinessProfileSettingsState();
}

class _BusinessProfileSettingsState extends State<BusinessProfileSettings> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  // Mock business data
  final Map<String, dynamic> _businessData = {
    "businessId": "BUS001",
    "logo":
        "https://img.rocket.new/generatedImages/rocket_gen_img_1723a3e01-1765201490500.png",
    "logoSemanticLabel":
        "Circular logo with blue and gold gradient showing soap bubbles and botanical elements",
    "companyName": {
      "fr": "Savonnerie Artisanale Madagascar",
      "mg": "Savony Malagasy Asa Tanana",
      "en": "Madagascar Artisan Soap",
      "ar": "صابون مدغشقر الحرفي"
    },
    "description": {
      "fr":
          "Fabricant de savons naturels et produits de beauté biologiques depuis 2020",
      "mg":
          "Mpamokatra savony voajanahary sy vokatra hatsaran-tarehy biolojika hatramin'ny 2020",
      "en": "Natural soap and organic beauty products manufacturer since 2020",
      "ar": "مصنع صابون طبيعي ومنتجات تجميل عضوية منذ 2020"
    },
    "category": "soap_manufacturing",
    "phone": "+261 34 12 345 67",
    "email": "contact@savonnerie-madagascar.com",
    "website": "https://savonnerie-madagascar.com",
    "socialMedia": {
      "facebook": "savonnerie.madagascar",
      "instagram": "@savonnerie_mg",
      "whatsapp": "+261341234567"
    },
    "address": {
      "street": "Lot II M 25 Bis Ambohimanarina",
      "city": "Antananarivo",
      "postalCode": "101",
      "country": "Madagascar",
      "latitude": -18.8792,
      "longitude": 47.5079
    },
    "operatingHours": {
      "monday": {"open": "08:00", "close": "17:00", "closed": false},
      "tuesday": {"open": "08:00", "close": "17:00", "closed": false},
      "wednesday": {"open": "08:00", "close": "17:00", "closed": false},
      "thursday": {"open": "08:00", "close": "17:00", "closed": false},
      "friday": {"open": "08:00", "close": "17:00", "closed": false},
      "saturday": {"open": "09:00", "close": "13:00", "closed": false},
      "sunday": {"open": "", "close": "", "closed": true}
    },
    "subscription": {
      "plan": "annual",
      "status": "active",
      "startDate": "2024-01-15",
      "endDate": "2025-01-15",
      "price": "\$60",
      "productsUsed": 45,
      "productsLimit": 100,
      "storageUsed": 2.3,
      "storageLimit": 5.0
    },
    "preferences": {
      "language": "fr",
      "notifications": {
        "orders": true,
        "messages": true,
        "promotions": false,
        "analytics": true
      },
      "privacy": {"showPhone": true, "showEmail": true, "showAddress": true}
    },
    "verification": {
      "status": "verified",
      "verifiedDate": "2024-02-01",
      "badge": true
    },
    "brandColors": {
      "primary": "#1B365D",
      "secondary": "#4A90A4",
      "accent": "#E8B931"
    }
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (SupabaseConfig.isConfigured) {
      await SupabaseConfig.client.auth.signOut();
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/authentication-screen',
      (route) => false,
    );
  }

  Future<void> _exportProfile() async {
    setState(() => _isLoading = true);

    // Simulate PDF generation
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Business profile exported successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            textColor: Theme.of(context).colorScheme.tertiary,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Discard',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: theme.appBarTheme.elevation,
          leading: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: theme.appBarTheme.foregroundColor ??
                  theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Business Profile',
            style: theme.appBarTheme.titleTextStyle,
          ),
          actions: [
            if (_hasUnsavedChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              icon: CustomIconWidget(
                iconName: 'more_vert',
                color: theme.appBarTheme.foregroundColor ??
                    theme.colorScheme.onSurface,
                size: 24,
              ),
              onSelected: (value) {
                if (value == 'export') {
                  _exportProfile();
                } else if (value == 'help') {
                  // Navigate to help
                } else if (value == 'logout') {
                  _handleLogout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'download',
                        color: theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      SizedBox(width: 3.w),
                      const Text('Export Profile'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'help',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'help_outline',
                        color: theme.colorScheme.onSurface,
                        size: 20,
                      ),
                      SizedBox(width: 3.w),
                      const Text('Help & Support'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'logout',
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'Déconnexion',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Status Banner
                  if (_businessData["verification"]["status"] == "verified")
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(4.w),
                      margin: EdgeInsets.only(bottom: 2.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'verified',
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verified Business',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  'Your business is verified and trusted',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Business Information Section
                  BusinessInformationSection(
                    businessData: _businessData,
                    onChanged: () {
                      setState(() => _hasUnsavedChanges = true);
                    },
                  ),

                  SizedBox(height: 2.h),

                  // Visual Identity Section
                  VisualIdentitySection(
                    businessData: _businessData,
                    onChanged: () {
                      setState(() => _hasUnsavedChanges = true);
                    },
                  ),

                  SizedBox(height: 2.h),

                  // Contact Details Section
                  ContactDetailsSection(
                    businessData: _businessData,
                    onChanged: () {
                      setState(() => _hasUnsavedChanges = true);
                    },
                  ),

                  SizedBox(height: 2.h),

                  // Subscription Section
                  SubscriptionSection(
                    businessData: _businessData,
                  ),

                  SizedBox(height: 2.h),

                  // App Preferences Section
                  AppPreferencesSection(
                    businessData: _businessData,
                    onChanged: () {
                      setState(() => _hasUnsavedChanges = true);
                    },
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Processing...',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
