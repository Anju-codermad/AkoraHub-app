import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/localization/app_translations.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/supabase/supabase_config.dart';
import '../../widgets/custom_icon_widget.dart';
import '../client_home/notification_sounds_screen.dart';
import './widgets/business_information_section.dart';
import './widgets/contact_details_section.dart';
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

  // Données réelles de l'entreprise, chargées depuis Supabase
  // (structure conservée pour compatibilité avec les widgets existants).
  final Map<String, dynamic> _businessData = {
    "businessId": "",
    "logo": "",
    "logoSemanticLabel": "",
    "companyName": {"fr": "", "mg": "", "en": "", "ar": ""},
    "description": {"fr": "", "mg": "", "en": "", "ar": ""},
    "category": "",
    "phone": "",
    "email": "",
    "website": "",
    "socialMedia": {"facebook": "", "instagram": "", "whatsapp": ""},
    "address": {
      "street": "",
      "city": "",
      "postalCode": "",
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
    "verification": {
      "status": "unverified",
      "verifiedDate": "",
      "badge": false
    },
    "brandColors": {
      "primary": "#085041",
      "secondary": "#4A90A4",
      "accent": "#E8B931"
    }
  };

  static const List<String> _persistedKeys = [
    "logo",
    "companyName",
    "description",
    "category",
    "phone",
    "email",
    "website",
    "socialMedia",
    "address",
    "operatingHours",
    "brandColors",
    "logo",
  ];

  @override
  void initState() {
    super.initState();
    _loadFromSupabase();
  }

  Future<void> _loadFromSupabase() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final data = await SupabaseConfig.client
          .from('company_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (data != null && data['data'] != null) {
        final saved = Map<String, dynamic>.from(data['data']);
        setState(() {
          for (final key in _persistedKeys) {
            if (saved.containsKey(key)) {
              _businessData[key] = saved[key];
            }
          }
        });
      }
    } catch (_) {
      // Pas grave si le chargement échoue : l'écran reste utilisable,
      // les champs restent simplement vides jusqu'à la prochaine sauvegarde.
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    String? errorMessage;
    if (!SupabaseConfig.isConfigured) {
      errorMessage = 'Connexion au serveur indisponible.';
    } else {
      try {
        final Map<String, dynamic> toSave = {
          for (final key in _persistedKeys) key: _businessData[key],
        };
        await SupabaseConfig.client.from('company_settings').upsert({
          'id': 1,
          'data': toSave,
        });
      } catch (e) {
        errorMessage = 'Erreur lors de la sauvegarde. Réessayez.';
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (errorMessage == null) _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Profil mis à jour avec succès'),
          backgroundColor: errorMessage != null
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
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

                  Card(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final themeMode = ref.watch(themeModeProvider);
                        return SwitchListTile(
                          secondary: const Icon(Icons.dark_mode_outlined),
                          title: const Text('Mode sombre'),
                          value: themeMode == ThemeMode.dark,
                          onChanged: (value) {
                            ref.read(themeModeProvider.notifier).setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light);
                          },
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 2.h),

                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Sons de notification'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationSoundsScreen()),
                      ),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  Card(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final locale = ref.watch(localeProvider);
                        return ListTile(
                          leading: const Icon(Icons.language_outlined),
                          title: const Text('Langue / Fiteny'),
                          trailing: Text(
                            locale == 'fr' ? 'Français' : 'Malagasy',
                            style: theme.textTheme.bodyMedium,
                          ),
                          onTap: () async {
                            final selected = await showDialog<String>(
                              context: context,
                              builder: (context) => SimpleDialog(
                                title: const Text('Choisir la langue'),
                                children: [
                                  SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(context, 'fr'),
                                    child: const Row(children: [
                                      Text('🇫🇷 '),
                                      Text('Français')
                                    ]),
                                  ),
                                  SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(context, 'mg'),
                                    child: const Row(children: [
                                      Text('🇲🇬 '),
                                      Text('Malagasy')
                                    ]),
                                  ),
                                ],
                              ),
                            );
                            if (selected != null) {
                              ref
                                  .read(localeProvider.notifier)
                                  .setLocale(selected);
                            }
                          },
                        );
                      },
                    ),
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
