import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../../core/app_export.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'
    as emoji_picker;

/// Campaign creation wizard with multi-step form
class CampaignCreationWizard extends StatefulWidget {
  final Function(Map<String, dynamic>) onCampaignCreated;

  const CampaignCreationWizard({
    super.key,
    required this.onCampaignCreated,
  });

  @override
  State<CampaignCreationWizard> createState() => _CampaignCreationWizardState();
}

class _CampaignCreationWizardState extends State<CampaignCreationWizard> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Campaign data
  String _campaignTitle = '';
  List<String> _selectedSegments = [];
  String _messageContent = '';
  List<String> _attachedMedia = [];
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _enableABTesting = false;
  String _messageVariantA = '';
  String _messageVariantB = '';

  // Controllers
  final quill.QuillController _quillController = quill.QuillController.basic();
  bool _showEmojiPicker = false;

  final List<Map<String, dynamic>> _availableSegments = [
    {'id': 1, 'name': 'All Customers', 'count': 1250},
    {'id': 2, 'name': 'New Customers', 'count': 320},
    {'id': 3, 'name': 'VIP Customers', 'count': 85},
    {'id': 4, 'name': 'Inactive (30 days)', 'count': 180},
    {'id': 5, 'name': 'High Spenders', 'count': 95},
  ];

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  int _getTargetAudienceCount() {
    if (_selectedSegments.isEmpty) return 0;
    return _availableSegments
        .where(
            (segment) => _selectedSegments.contains(segment['name'] as String))
        .fold(0, (sum, segment) => sum + (segment['count'] as int));
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _createCampaign();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _createCampaign() {
    if (_formKey.currentState?.validate() ?? false) {
      final campaign = {
        'title': _campaignTitle,
        'segments': _selectedSegments,
        'audienceSize': _getTargetAudienceCount(),
        'message': _messageContent,
        'media': _attachedMedia,
        'scheduledDate': _scheduledDate,
        'scheduledTime': _scheduledTime,
        'abTesting': _enableABTesting,
        'variantA': _messageVariantA,
        'variantB': _messageVariantB,
      };
      widget.onCampaignCreated(campaign);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          _buildStepIndicator(theme),
          Expanded(
            child: Form(
              key: _formKey,
              child: _buildStepContent(theme),
            ),
          ),
          _buildNavigationButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Create Campaign',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'close',
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    final steps = ['Audience', 'Message', 'Media', 'Schedule'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted || isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surface,
                          border: Border.all(
                            color: isCompleted || isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? CustomIconWidget(
                                  iconName: 'check',
                                  size: 16,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isActive
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[index],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildAudienceStep(theme);
      case 1:
        return _buildMessageStep(theme);
      case 2:
        return _buildMediaStep(theme);
      case 3:
        return _buildScheduleStep(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAudienceStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Campaign Title',
              hintText: 'Enter campaign name',
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Title is required' : null,
            onChanged: (value) => _campaignTitle = value,
          ),
          const SizedBox(height: 24),
          Text(
            'Select Target Audience',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableSegments.length,
            itemBuilder: (context, index) {
              final segment = _availableSegments[index];
              final isSelected =
                  _selectedSegments.contains(segment['name'] as String);

              return CheckboxListTile(
                title: Text(segment['name'] as String),
                subtitle: Text('${segment['count']} customers'),
                value: isSelected,
                onChanged: (selected) {
                  setState(() {
                    if (selected ?? false) {
                      _selectedSegments.add(segment['name'] as String);
                    } else {
                      _selectedSegments.remove(segment['name'] as String);
                    }
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'people',
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Recipients',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${_getTargetAudienceCount()} customers',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStep(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compose Message',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(12),
                        child: quill.QuillEditor.basic(
                          controller: _quillController,
                          config: const quill.QuillEditorConfig(
                            placeholder: 'Type your message here...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _showEmojiPicker = !_showEmojiPicker);
                            },
                            icon: CustomIconWidget(
                              iconName: 'emoji_emotions',
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            label: const Text('Add Emoji'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              // Product link insertion logic
                            },
                            icon: CustomIconWidget(
                              iconName: 'link',
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            label: const Text('Insert Product Link'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SwitchListTile(
                        title: const Text('Enable A/B Testing'),
                        subtitle: const Text('Test two message variations'),
                        value: _enableABTesting,
                        onChanged: (value) {
                          setState(() => _enableABTesting = value);
                        },
                      ),
                      if (_enableABTesting) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Variant A Message',
                            hintText: 'Enter first message variation',
                          ),
                          maxLines: 3,
                          onChanged: (value) => _messageVariantA = value,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Variant B Message',
                            hintText: 'Enter second message variation',
                          ),
                          maxLines: 3,
                          onChanged: (value) => _messageVariantB = value,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_showEmojiPicker)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        final text = _quillController.document.toPlainText();
                        _quillController.document.insert(text.length, emoji.emoji);
                      },
                      config: const emoji_picker.Config(
                        height: 250,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: emoji_picker.EmojiViewConfig(
                          columns: 7,
                          emojiSizeMax: 28,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attach Media',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add images or videos to your campaign (optional)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (_attachedMedia.isEmpty)
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () {
                  // Media picker logic
                  setState(() {
                    _attachedMedia.add(
                        'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800');
                  });
                },
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'add_photo_alternate',
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to add media',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Images and videos will be optimized',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _attachedMedia.length + 1,
              itemBuilder: (context, index) {
                if (index == _attachedMedia.length) {
                  return InkWell(
                    onTap: () {
                      // Add more media
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'add',
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomImageWidget(
                        imageUrl: _attachedMedia[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        semanticLabel: 'Campaign media attachment ${index + 1}',
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() => _attachedMedia.removeAt(index));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: CustomIconWidget(
                            iconName: 'close',
                            size: 16,
                            color: theme.colorScheme.onError,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Media will be automatically compressed for optimal mobile delivery',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleStep(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Campaign',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'calendar_today',
              size: 24,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Send Date'),
            subtitle: Text(
              _scheduledDate != null
                  ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                  : 'Select date',
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _scheduledDate = date);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: CustomIconWidget(
              iconName: 'access_time',
              size: 24,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Send Time'),
            subtitle: Text(
              _scheduledTime != null
                  ? '${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
                  : 'Select time',
            ),
            trailing: CustomIconWidget(
              iconName: 'arrow_forward_ios',
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) {
                setState(() => _scheduledTime = time);
              }
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'preview',
                      size: 24,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Campaign Preview',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your campaign will be sent to ${_getTargetAudienceCount()} customers',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                if (_scheduledDate != null && _scheduledTime != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Scheduled for ${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year} at ${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              // Show device preview
            },
            icon: CustomIconWidget(
              iconName: 'phone_android',
              size: 20,
              color: theme.colorScheme.primary,
            ),
            label: const Text('Preview on Device'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              child: Text(_currentStep < 3 ? 'Next' : 'Create Campaign'),
            ),
          ),
        ],
      ),
    );
  }
}