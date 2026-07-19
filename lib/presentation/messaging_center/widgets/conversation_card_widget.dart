import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/app_export.dart';

/// Conversation card widget for displaying individual conversations
/// Supports swipe actions for quick reply and settings
class ConversationCardWidget extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;
  final VoidCallback onQuickReply;
  final VoidCallback onSettings;
  final VoidCallback onMute;

  const ConversationCardWidget({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onQuickReply,
    required this.onSettings,
    required this.onMute,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasUnread = (conversation['unreadCount'] as int? ?? 0) > 0;
    final String channel = conversation['channel'] as String? ?? 'internal';
    final bool isMuted = conversation['isMuted'] as bool? ?? false;

    return Slidable(
      key: ValueKey(conversation['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onQuickReply(),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.reply,
            label: 'Quick Reply',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onMute(),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            icon:
                isMuted ? Icons.notifications_active : Icons.notifications_off,
            label: isMuted ? 'Unmute' : 'Mute',
          ),
          SlidableAction(
            onPressed: (_) => onSettings(),
            backgroundColor: theme.colorScheme.tertiary,
            foregroundColor: theme.colorScheme.onTertiary,
            icon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: hasUnread
                ? theme.colorScheme.primary.withValues(alpha: 0.05)
                : theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer avatar
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasUnread
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: CustomImageWidget(
                        imageUrl:
                            conversation['customerPhoto'] as String? ?? '',
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        semanticLabel:
                            conversation['customerPhotoLabel'] as String? ??
                                'Customer profile photo',
                      ),
                    ),
                  ),
                  // Channel indicator
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: channel == 'whatsapp'
                              ? 'chat'
                              : channel == 'system'
                                  ? 'notifications'
                                  : 'message',
                          size: 12,
                          color: channel == 'whatsapp'
                              ? const Color(0xFF25D366)
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Conversation details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation['customerName'] as String? ??
                                'Unknown',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isMuted)
                          CustomIconWidget(
                            iconName: 'notifications_off',
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation['lastMessage'] as String? ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasUnread
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            hasUnread ? FontWeight.w500 : FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          conversation['timestamp'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (conversation['hasAttachment'] as bool? ??
                            false) ...[
                          const SizedBox(width: 8),
                          CustomIconWidget(
                            iconName: 'attach_file',
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  child: Center(
                    child: Text(
                      (conversation['unreadCount'] as int) > 99
                          ? '99+'
                          : (conversation['unreadCount'] as int).toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
