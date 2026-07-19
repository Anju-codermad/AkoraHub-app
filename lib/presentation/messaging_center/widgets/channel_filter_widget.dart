import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Channel filter widget for filtering conversations by channel type
class ChannelFilterWidget extends StatelessWidget {
  final String selectedChannel;
  final Function(String) onChannelSelected;
  final Map<String, int> channelCounts;

  const ChannelFilterWidget({
    super.key,
    required this.selectedChannel,
    required this.onChannelSelected,
    required this.channelCounts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> channels = [
      {
        'id': 'all',
        'label': 'All',
        'icon': 'inbox',
        'count': channelCounts['all'] ?? 0,
      },
      {
        'id': 'whatsapp',
        'label': 'WhatsApp',
        'icon': 'chat',
        'count': channelCounts['whatsapp'] ?? 0,
      },
      {
        'id': 'internal',
        'label': 'Internal',
        'icon': 'message',
        'count': channelCounts['internal'] ?? 0,
      },
      {
        'id': 'system',
        'label': 'System',
        'icon': 'notifications',
        'count': channelCounts['system'] ?? 0,
      },
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: channels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final channel = channels[index];
          final isSelected = selectedChannel == channel['id'];
          final count = channel['count'] as int;

          return InkWell(
            onTap: () => onChannelSelected(channel['id'] as String),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: channel['icon'] as String,
                    size: 20,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    channel['label'] as String,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
