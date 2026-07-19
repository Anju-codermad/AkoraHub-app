import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/advanced_options_widget.dart';
import './widgets/basic_information_widget.dart';
import './widgets/inventory_section_widget.dart';
import './widgets/media_gallery_widget.dart';
import './widgets/pricing_section_widget.dart';

/// Product Detail Editor Screen
/// Provides comprehensive product information management optimized for mobile input
class ProductDetailEditor extends StatefulWidget {
  const ProductDetailEditor({super.key});

  @override
  State<ProductDetailEditor> createState() => _ProductDetailEditorState();
}

class _ProductDetailEditorState extends State<ProductDetailEditor> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _lowStockAlertController = TextEditingController();
  final _seoTagsController = TextEditingController();

  // Product data
  List<String> _productImages = [];
  String _selectedCategory = '';
  String _selectedCurrency = 'MGA';
  bool _inventoryTrackingEnabled = false;
  bool _isVisible = true;
  bool _isPromotional = false;
  bool _hasUnsavedChanges = false;
  bool _isAutoSaving = false;
  DateTime _lastAutoSave = DateTime.now();

  // Multi-language support
  Map<String, String> _multiLanguageNames = {
    'fr': '',
    'mg': '',
    'en': '',
    'ar': '',
  };
  Map<String, String> _multiLanguageDescriptions = {
    'fr': '',
    'mg': '',
    'en': '',
    'ar': '',
  };
  String _currentLanguage = 'fr';

  @override
  void initState() {
    super.initState();
    _setupAutoSave();
    _loadProductData();
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockQuantityController.dispose();
    _lowStockAlertController.dispose();
    _seoTagsController.dispose();
    super.dispose();
  }

  void _setupAutoSave() {
    // Auto-save every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _hasUnsavedChanges) {
        _autoSaveProduct();
      }
      if (mounted) {
        _setupAutoSave();
      }
    });
  }

  Future<void> _loadProductData() async {
    // Load existing product data if editing
    // This would typically come from navigation arguments
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data for demonstration
    setState(() {
      _productImages = [
        'https://images.unsplash.com/photo-1585386959984-a4155224a1ad?w=800',
        'https://images.unsplash.com/photo-1584305574647-0cc949a2bb9f?w=800',
      ];
    });
  }

  Future<void> _autoSaveProduct() async {
    if (!_hasUnsavedChanges) return;

    setState(() {
      _isAutoSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isAutoSaving = false;
      _hasUnsavedChanges = false;
      _lastAutoSave = DateTime.now();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-saved at ${_formatTime(_lastAutoSave)}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.mediumImpact();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: 2.h),
              Text(
                'Saving product...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate save operation
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Product saved successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _hasUnsavedChanges = false;
      });

      // Navigate back after successful save
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _handleImagesUpdated(List<String> images) {
    setState(() {
      _productImages = images;
      _markAsChanged();
    });
  }

  void _handleCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _markAsChanged();
    });
  }

  void _handleCurrencyChanged(String currency) {
    setState(() {
      _selectedCurrency = currency;
      _markAsChanged();
    });
  }

  void _handleInventoryToggled(bool enabled) {
    setState(() {
      _inventoryTrackingEnabled = enabled;
      _markAsChanged();
    });
  }

  void _handleVisibilityChanged(bool visible) {
    setState(() {
      _isVisible = visible;
      _markAsChanged();
    });
  }

  void _handlePromotionalChanged(bool promotional) {
    setState(() {
      _isPromotional = promotional;
      _markAsChanged();
    });
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
              final canPop = await _onWillPop();
              if (canPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Editor',
                style: theme.appBarTheme.titleTextStyle,
              ),
              if (_isAutoSaving)
                Text(
                  'Auto-saving...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                )
              else if (_hasUnsavedChanges)
                Text(
                  'Unsaved changes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                )
              else
                Text(
                  'Last saved: ${_formatTime(_lastAutoSave)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _hasUnsavedChanges ? _saveProduct : null,
              child: Text(
                'Save',
                style: TextStyle(
                  color: _hasUnsavedChanges
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media Gallery Section
                MediaGalleryWidget(
                  images: _productImages,
                  onImagesUpdated: _handleImagesUpdated,
                ),

                SizedBox(height: 2.h),

                // Basic Information Section
                BasicInformationWidget(
                  productNameController: _productNameController,
                  descriptionController: _descriptionController,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: _handleCategorySelected,
                  onChanged: _markAsChanged,
                  multiLanguageNames: _multiLanguageNames,
                  multiLanguageDescriptions: _multiLanguageDescriptions,
                  currentLanguage: _currentLanguage,
                  onLanguageChanged: (language) {
                    setState(() {
                      _currentLanguage = language;
                    });
                  },
                ),

                SizedBox(height: 2.h),

                // Pricing Section
                PricingSectionWidget(
                  priceController: _priceController,
                  selectedCurrency: _selectedCurrency,
                  onCurrencyChanged: _handleCurrencyChanged,
                  onChanged: _markAsChanged,
                ),

                SizedBox(height: 2.h),

                // Inventory Section
                InventorySectionWidget(
                  inventoryTrackingEnabled: _inventoryTrackingEnabled,
                  stockQuantityController: _stockQuantityController,
                  lowStockAlertController: _lowStockAlertController,
                  onInventoryToggled: _handleInventoryToggled,
                  onChanged: _markAsChanged,
                ),

                SizedBox(height: 2.h),

                // Advanced Options Section
                AdvancedOptionsWidget(
                  seoTagsController: _seoTagsController,
                  isVisible: _isVisible,
                  isPromotional: _isPromotional,
                  onVisibilityChanged: _handleVisibilityChanged,
                  onPromotionalChanged: _handlePromotionalChanged,
                  onChanged: _markAsChanged,
                ),

                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
