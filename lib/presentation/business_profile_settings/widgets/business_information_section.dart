import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

/// Business Information Section Widget
///
/// Displays and manages core business information including:
/// - Business logo with camera/gallery picker
/// - Company name in multiple languages
/// - Business description in multiple languages
/// - Business category selection
/// - Operating hours management
class BusinessInformationSection extends StatefulWidget {
  final Map<String, dynamic> businessData;
  final VoidCallback onChanged;

  const BusinessInformationSection({
    super.key,
    required this.businessData,
    required this.onChanged,
  });

  @override
  State<BusinessInformationSection> createState() =>
      _BusinessInformationSectionState();
}

class _BusinessInformationSectionState
    extends State<BusinessInformationSection> {
  String _selectedLanguage = 'fr';
  final ImagePicker _imagePicker = ImagePicker();

  final List<Map<String, String>> _languages = [
    {"code": "fr", "name": "Français", "flag": "🇫🇷"},
    {"code": "mg", "name": "Malagasy", "flag": "🇲🇬"},
    {"code": "en", "name": "English", "flag": "🇬🇧"},
    {"code": "ar", "name": "العربية", "flag": "🇸🇦"},
  ];


  bool _isUploadingLogo = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!SupabaseConfig.isConfigured) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion au serveur indisponible.'),
            ),
          );
        }
        return;
      }

      setState(() => _isUploadingLogo = true);
      try {
        final fileName =
            'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await SupabaseConfig.client.storage.from('company-logo').upload(
            fileName, File(image.path),
            fileOptions: const FileOptions(upsert: true));
        final publicUrl = SupabaseConfig.client.storage
            .from('company-logo')
            .getPublicUrl(fileName);

        widget.businessData["logo"] = publicUrl;
        widget.onChanged();
        if (mounted) {
          setState(() => _isUploadingLogo = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo mis à jour — clique sur Enregistrer pour confirmer.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploadingLogo = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Le logo n\'a pas pu être envoyé (le bucket Storage "company-logo" existe-t-il ?).'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Change Business Logo',
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: 2.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'photo_library',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      ),
    );
  }

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
                iconName: 'business',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Business Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Business Logo
          Center(
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Stack(
                children: [
                  Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomImageWidget(
                            imageUrl: widget.businessData["logo"] as String,
                            width: 30.w,
                            height: 30.w,
                            fit: BoxFit.cover,
                            semanticLabel: widget
                                .businessData["logoSemanticLabel"] as String,
                          ),
                          if (_isUploadingLogo)
                            Container(
                              color: Colors.black45,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.cardColor,
                          width: 2,
                        ),
                      ),
                      child: CustomIconWidget(
                        iconName: 'camera_alt',
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 1.h),

          Center(
            child: Text(
              'Tap to change logo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          SizedBox(height: 3.h),

          // Language Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _languages.map((lang) {
                final isSelected = _selectedLanguage == lang["code"];
                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(lang["flag"]!),
                        SizedBox(width: 2.w),
                        Text(lang["name"]!),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedLanguage = lang["code"]!);
                      }
                    },
                    selectedColor:
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                    backgroundColor: theme.colorScheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 2.h),

          // Company Name
          Text(
            'Company Name',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          TextFormField(
            key: ValueKey('companyName_$_selectedLanguage'),
            initialValue: (widget.businessData["companyName"]
                as Map<String, dynamic>)[_selectedLanguage] as String,
            decoration: InputDecoration(
              hintText: 'Enter company name',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'business_center',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            onChanged: (value) {
              (widget.businessData["companyName"]
                  as Map<String, dynamic>)[_selectedLanguage] = value;
              widget.onChanged();
            },
          ),

          SizedBox(height: 2.h),

          // Business Description
          Text(
            'Business Description',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          TextFormField(
            key: ValueKey('description_$_selectedLanguage'),
            initialValue: (widget.businessData["description"]
                as Map<String, dynamic>)[_selectedLanguage] as String,
            decoration: InputDecoration(
              hintText: 'Describe your business',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'description',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            maxLines: 3,
            onChanged: (value) {
              (widget.businessData["description"]
                  as Map<String, dynamic>)[_selectedLanguage] = value;
              widget.onChanged();
            },
          ),

        ],
      ),
    );
  }
}
