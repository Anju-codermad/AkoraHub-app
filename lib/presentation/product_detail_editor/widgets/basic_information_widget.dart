import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Basic Information Widget
/// Handles product name, description, and category selection
class BasicInformationWidget extends StatefulWidget {
  final TextEditingController productNameController;
  final TextEditingController descriptionController;
  final String selectedCategory;
  final Function(String) onCategorySelected;
  final VoidCallback onChanged;
  final Map<String, String> multiLanguageNames;
  final Map<String, String> multiLanguageDescriptions;
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const BasicInformationWidget({
    super.key,
    required this.productNameController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onChanged,
    required this.multiLanguageNames,
    required this.multiLanguageDescriptions,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<BasicInformationWidget> createState() => _BasicInformationWidgetState();
}

class _BasicInformationWidgetState extends State<BasicInformationWidget> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _showFormatting = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Soap Manufacturing', 'icon': 'soap'},
    {'name': 'Cleaning Products', 'icon': 'cleaning_services'},
    {'name': 'Hygiene Products', 'icon': 'health_and_safety'},
    {'name': 'Cosmetics', 'icon': 'face'},
    {'name': 'Training Services', 'icon': 'school'},
    {'name': 'Exhibition Services', 'icon': 'event'},
    {'name': 'Real Estate', 'icon': 'home'},
  ];

  final List<Map<String, String>> _languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'mg', 'name': 'Malagasy', 'flag': '🇲🇬'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _isListening = false;
          });
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
      },
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          widget.productNameController.text = result.recognizedWords;
          widget.onChanged();
        });
      },
    );
  }

  Future<void> _stopListening() async {
    HapticFeedback.lightImpact();
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _showCategoryPicker() {
    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected =
                      widget.selectedCategory == category['name'];

                  return ListTile(
                    leading: CustomIconWidget(
                      iconName: category['icon'] as String,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    title: Text(category['name'] as String),
                    trailing: isSelected
                        ? CustomIconWidget(
                            iconName: 'check_circle',
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          )
                        : null,
                    onTap: () {
                      widget.onCategorySelected(category['name'] as String);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _applyFormatting(String format) {
    HapticFeedback.selectionClick();
    final text = widget.descriptionController.text;
    final selection = widget.descriptionController.selection;

    if (selection.start == selection.end) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select text to format'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedText = text.substring(selection.start, selection.end);
    String formattedText = '';

    switch (format) {
      case 'bold':
        formattedText = '**$selectedText**';
        break;
      case 'italic':
        formattedText = '*$selectedText*';
        break;
      case 'bullet':
        formattedText = '• $selectedText';
        break;
    }

    final newText =
        text.replaceRange(selection.start, selection.end, formattedText);
    widget.descriptionController.text = newText;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          // Language selector
          SizedBox(
            height: 6.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = widget.currentLanguage == language['code'];

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onLanguageChanged(language['code']!);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 2.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                    child: Row(
                      children: [
                        Text(
                          language['flag']!,
                          style: TextStyle(fontSize: 18.sp),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          language['name']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 2.h),

          // Product name field
          TextFormField(
            controller: widget.productNameController,
            decoration: InputDecoration(
              labelText: 'Product Name *',
              hintText: 'Enter product name',
              suffixIcon: IconButton(
                icon: CustomIconWidget(
                  iconName: _isListening ? 'mic' : 'mic_none',
                  color: _isListening
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                onPressed: _isListening ? _stopListening : _startListening,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Product name is required';
              }
              return null;
            },
            onChanged: (_) => widget.onChanged(),
          ),

          SizedBox(height: 2.h),

          // Category selector
          GestureDetector(
            onTap: _showCategoryPicker,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.selectedCategory.isEmpty
                        ? 'Select Category *'
                        : widget.selectedCategory,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.selectedCategory.isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'arrow_drop_down',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Description field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Description',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFormatting = !_showFormatting;
                      });
                    },
                    icon: CustomIconWidget(
                      iconName: _showFormatting ? 'expand_less' : 'expand_more',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    label: Text(
                      'Formatting',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_showFormatting) ...[
                SizedBox(height: 1.h),
                Row(
                  children: [
                    IconButton(
                      icon: CustomIconWidget(
                        iconName: 'format_bold',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () => _applyFormatting('bold'),
                      tooltip: 'Bold',
                    ),
                    IconButton(
                      icon: CustomIconWidget(
                        iconName: 'format_italic',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () => _applyFormatting('italic'),
                      tooltip: 'Italic',
                    ),
                    IconButton(
                      icon: CustomIconWidget(
                        iconName: 'format_list_bulleted',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () => _applyFormatting('bullet'),
                      tooltip: 'Bullet',
                    ),
                  ],
                ),
              ],
              SizedBox(height: 1.h),
              TextFormField(
                controller: widget.descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Enter product description',
                ),
                onChanged: (_) => widget.onChanged(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
