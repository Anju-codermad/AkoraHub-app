import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Recent Activity Feed Widget
/// Shows latest customer interactions, orders, and system notifications
class RecentActivityFeedWidget extends StatelessWidget {
  final DateTime lastUpdated;
  final Function(String activityId) onActivityTap;

  const RecentActivityFeedWidget({
    super.key,
    required this.lastUpdated,
    required this.onActivityTap,
  });

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activities = [
      {
        'id': '1',
        'type': 'order',
        'icon': 'shopping_bag',
        'title': 'New order received',
        'description': 'Order #12345 from Sarah Johnson',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
        'avatar':
            'https://img.rocket.new/generatedImages/rocket_gen_img_176e07230-1763293461602.png',
        'semanticLabel':
            'Profile photo of a woman with long brown hair wearing a white shirt',
      },
      {
        'id': '2',
        'type': 'customer',
        'icon': 'person_add',
        'title': 'New follower',
        'description': 'Michael Chen started following your business',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'avatar':
            'https://img.rocket.new/generatedImages/rocket_gen_img_1137886c8-1763293866701.png',
        'semanticLabel':
            'Profile photo of a man with short dark hair wearing a blue shirt',
      },
      {
        'id': '3',
        'type': 'message',
        'icon': 'chat',
        'title': 'New message',
        'description': 'Emma Wilson: "Is this product available in blue?"',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
        'avatar':
            'https://images.unsplash.com/photo-1632955518095-622aaf6eb793',
        'semanticLabel':
            'Profile photo of a woman with blonde hair wearing a pink top',
      },
      {
        'id': '4',
        'type': 'review',
        'icon': 'star',
        'title': 'New review',
        'description': 'David Martinez left a 5-star review',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
        'avatar':
            'https://img.rocket.new/generatedImages/rocket_gen_img_17fea9682-1764690565935.png',
        'semanticLabel':
            'Profile photo of a man with beard wearing a gray sweater',
      },
      {
        'id': '5',
        'type': 'system',
        'icon': 'info',
        'title': 'Subscription reminder',
        'description': 'Your subscription renews in 7 days',
        'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
        'avatar': null,
        'semanticLabel': null,
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Last updated: ${_getTimeAgo(lastUpdated)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => Divider(
              height: 2.h,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityItem(
                context,
                theme,
                activity['id'] as String,
                activity['type'] as String,
                activity['icon'] as String,
                activity['title'] as String,
                activity['description'] as String,
                activity['timestamp'] as DateTime,
                activity['avatar'] as String?,
                activity['semanticLabel'] as String?,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    ThemeData theme,
    String id,
    String type,
    String icon,
    String title,
    String description,
    DateTime timestamp,
    String? avatar,
    String? semanticLabel,
  ) {
    Color getTypeColor() {
      switch (type) {
        case 'order':
          return theme.colorScheme.primary;
        case 'customer':
          return theme.colorScheme.secondary;
        case 'message':
          return theme.colorScheme.tertiary;
        case 'review':
          return AppTheme.warningLight;
        default:
          return theme.colorScheme.onSurfaceVariant;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onActivityTap(id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomImageWidget(
                        imageUrl: avatar,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        semanticLabel: semanticLabel ?? 'User profile photo',
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: getTypeColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: icon,
                          color: getTypeColor(),
                          size: 20,
                        ),
                      ),
                    ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _getTimeAgo(timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
