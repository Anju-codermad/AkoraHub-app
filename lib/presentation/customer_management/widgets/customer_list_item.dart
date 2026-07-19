import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/app_export.dart';

/// Individual customer list item with swipe actions
class CustomerListItem extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onTap;
  final Function(String action) onAction;
  final bool isSelected;

  const CustomerListItem({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onAction,
    this.isSelected = false,
  });

  Color _getStatusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'active':
        return theme.colorScheme.tertiary;
      case 'new':
        return theme.colorScheme.primary;
      case 'inactive':
        return theme.colorScheme.onSurfaceVariant;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasReminder = customer['hasReminder'] as bool? ?? false;
    final unreadMessages = customer['unreadMessages'] as int? ?? 0;

    return Slidable(
      key: ValueKey(customer['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              onAction('whatsapp');
            },
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            icon: Icons.chat,
            label: 'WhatsApp',
          ),
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              onAction('call');
            },
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.phone,
            label: 'Call',
          ),
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              onAction('email');
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            icon: Icons.email,
            label: 'Email',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              onAction('history');
            },
            backgroundColor: theme.colorScheme.tertiary,
            foregroundColor: Colors.white,
            icon: Icons.history,
            label: 'History',
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _getStatusColor(
                              context, customer['status'] as String),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: CustomImageWidget(
                          imageUrl: customer['avatar'] as String,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          semanticLabel:
                              customer['avatarSemanticLabel'] as String,
                        ),
                      ),
                    ),
                    if (hasReminder)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer['name'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadMessages > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                unreadMessages > 99
                                    ? '99+'
                                    : unreadMessages.toString(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'location_on',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer['location'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                      context, customer['status'] as String)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              customer['status'] as String,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getStatusColor(
                                    context, customer['status'] as String),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomIconWidget(
                            iconName: 'schedule',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customer['lastInteraction'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: CustomIconWidget(
                        iconName: 'trending_up',
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${customer['engagementScore']}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
