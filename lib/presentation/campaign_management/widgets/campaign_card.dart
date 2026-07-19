import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/app_export.dart';

/// Campaign card with swipe actions
class CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onEdit;
  final VoidCallback onViewAnalytics;
  final VoidCallback onDelete;

  const CampaignCard({
    super.key,
    required this.campaign,
    required this.onTap,
    required this.onDuplicate,
    required this.onEdit,
    required this.onViewAnalytics,
    required this.onDelete,
  });

  Color _getStatusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'active':
        return theme.colorScheme.tertiary;
      case 'scheduled':
        return theme.colorScheme.secondary;
      case 'completed':
        return theme.colorScheme.onSurfaceVariant;
      case 'draft':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(campaign['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDuplicate(),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.content_copy,
            label: 'Duplicate',
          ),
          SlidableAction(
            onPressed: (context) => onEdit(),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (context) => onViewAnalytics(),
            backgroundColor: theme.colorScheme.tertiary,
            foregroundColor: theme.colorScheme.onTertiary,
            icon: Icons.analytics,
            label: 'Analytics',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onDelete(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (campaign['thumbnail'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomImageWidget(
                          imageUrl: campaign['thumbnail'] as String,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          semanticLabel:
                              campaign['thumbnailLabel'] as String? ??
                                  'Campaign thumbnail image',
                        ),
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
                                  campaign['title'] as String,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    context,
                                    campaign['status'] as String,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  campaign['status'] as String,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _getStatusColor(
                                      context,
                                      campaign['status'] as String,
                                    ),
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
                                iconName: 'people',
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${campaign['audienceSize']} recipients',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'schedule',
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                campaign['sendDate'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetric(
                        context,
                        'Open Rate',
                        '${campaign['openRate']}%',
                        Icons.mail_outline,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _buildMetric(
                        context,
                        'Click Rate',
                        '${campaign['clickRate']}%',
                        Icons.touch_app,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _buildMetric(
                        context,
                        'Delivered',
                        '${campaign['delivered']}',
                        Icons.check_circle_outline,
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

  Widget _buildMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon
              .toString()
              .split('.')
              .last
              .replaceAll('IconData(U+', '')
              .replaceAll(')', ''),
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
