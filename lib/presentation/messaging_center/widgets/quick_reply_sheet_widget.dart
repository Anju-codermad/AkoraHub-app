import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Quick reply bottom sheet widget for sending predefined responses
class QuickReplySheetWidget extends StatelessWidget {
  final Function(String) onReplySelected;
  final String businessType;

  const QuickReplySheetWidget({
    super.key,
    required this.onReplySelected,
    required this.businessType,
  });

  List<Map<String, String>> _getQuickReplies() {
    // Business-specific quick replies
    switch (businessType) {
      case 'soap':
        return [
          {
            'title': 'Product Inquiry',
            'message':
                'Thank you for your interest in our soap products. How can I help you today?'
          },
          {
            'title': 'Pricing Information',
            'message':
                'I\'d be happy to provide pricing details. Which products are you interested in?'
          },
          {
            'title': 'Availability',
            'message':
                'All our products are currently in stock and ready for delivery.'
          },
          {
            'title': 'Custom Order',
            'message':
                'We offer custom soap formulations. Let me know your requirements.'
          },
        ];
      case 'cosmetics':
        return [
          {
            'title': 'Product Recommendation',
            'message':
                'I can help you find the perfect product for your skin type. What are you looking for?'
          },
          {
            'title': 'Ingredients Info',
            'message':
                'All our products use natural ingredients. Which product would you like to know about?'
          },
          {
            'title': 'Usage Instructions',
            'message':
                'I\'ll be happy to provide detailed usage instructions for any product.'
          },
          {
            'title': 'Skin Consultation',
            'message':
                'Let\'s schedule a consultation to find the best products for your needs.'
          },
        ];
      case 'training':
        return [
          {
            'title': 'Course Information',
            'message':
                'Thank you for your interest in our training programs. Which course are you interested in?'
          },
          {
            'title': 'Schedule',
            'message':
                'Our next training session starts soon. Would you like to know the schedule?'
          },
          {
            'title': 'Registration',
            'message':
                'I can help you with the registration process. Shall we proceed?'
          },
          {
            'title': 'Certification',
            'message':
                'All our courses include professional certification upon completion.'
          },
        ];
      case 'realestate':
        return [
          {
            'title': 'Property Viewing',
            'message':
                'I\'d be happy to arrange a property viewing. When would be convenient for you?'
          },
          {
            'title': 'Property Details',
            'message':
                'Let me provide you with detailed information about this property.'
          },
          {
            'title': 'Financing Options',
            'message':
                'We can discuss various financing options available for this property.'
          },
          {
            'title': 'Documentation',
            'message':
                'I can send you all the necessary property documents and legal information.'
          },
        ];
      default:
        return [
          {
            'title': 'General Inquiry',
            'message':
                'Thank you for contacting us. How can I assist you today?'
          },
          {
            'title': 'More Information',
            'message':
                'I\'d be happy to provide more information. What would you like to know?'
          },
          {
            'title': 'Follow Up',
            'message':
                'Thank you for your patience. I\'m following up on your previous inquiry.'
          },
          {
            'title': 'Availability',
            'message': 'I\'m available to answer any questions you may have.'
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quickReplies = _getQuickReplies();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'reply',
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Replies',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'close',
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Quick reply list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: quickReplies.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final reply = quickReplies[index];
                return InkWell(
                  onTap: () {
                    onReplySelected(reply['message']!);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reply['title']!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reply['message']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Add custom reply button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Open custom reply input
                },
                icon: CustomIconWidget(
                  iconName: 'edit',
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                label: const Text('Create Custom Reply'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
