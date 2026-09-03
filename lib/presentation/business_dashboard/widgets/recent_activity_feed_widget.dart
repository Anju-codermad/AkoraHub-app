import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/supabase/supabase_config.dart';

/// Recent Activity Feed Widget
/// Affiche les dernières commandes et inscriptions réelles (Supabase).
class RecentActivityFeedWidget extends StatefulWidget {
  final DateTime lastUpdated;
  final Function(String activityId, String activityType) onActivityTap;

  const RecentActivityFeedWidget({
    super.key,
    required this.lastUpdated,
    required this.onActivityTap,
  });

  @override
  State<RecentActivityFeedWidget> createState() =>
      _RecentActivityFeedWidgetState();
}

class _RecentActivityFeedWidgetState extends State<RecentActivityFeedWidget> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    if (!SupabaseConfig.isConfigured) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      // Les 2 requêtes sont indépendantes — lancées en parallèle plutôt
      // qu'à la suite pour ne pas cumuler leurs temps de réseau.
      final results = await Future.wait([
        SupabaseConfig.client
            .from('orders')
            .select(
                'id, order_number, created_at, profiles(full_name, company_name)')
            .order('created_at', ascending: false)
            .limit(3),
        SupabaseConfig.client
            .from('profiles')
            .select('id, full_name, company_name, created_at')
            .eq('role', 'client')
            .order('created_at', ascending: false)
            .limit(3),
      ]);
      final orders = results[0];
      final clients = results[1];

      final List<Map<String, dynamic>> combined = [];

      for (final o in orders) {
        final customer = o['profiles'];
        final name = customer != null
            ? (customer['company_name'] ?? customer['full_name'] ?? 'Client')
            : 'Client';
        combined.add({
          'id': o['id'],
          'type': 'order',
          'icon': 'shopping_bag',
          'title': 'Nouvelle commande',
          'description': '${o['order_number']} — $name',
          'timestamp': DateTime.tryParse(o['created_at'] ?? '') ??
              DateTime.now(),
        });
      }

      for (final c in clients) {
        combined.add({
          'id': c['id'],
          'type': 'customer',
          'icon': 'person_add',
          'title': 'Nouveau client inscrit',
          'description': c['company_name'] ?? c['full_name'] ?? 'Client',
          'timestamp': DateTime.tryParse(c['created_at'] ?? '') ??
              DateTime.now(),
        });
      }

      combined.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      if (!mounted) return;
      setState(() {
        _activities = combined.take(5).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}j';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activité récente',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Mis à jour : ${_getTimeAgo(widget.lastUpdated)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_activities.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Text(
                'Aucune activité pour le moment.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activities.length,
              separatorBuilder: (context, index) => Divider(
                height: 2.h,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              itemBuilder: (context, index) {
                final activity = _activities[index];
                return _buildActivityItem(
                  context,
                  theme,
                  activity['id'].toString(),
                  activity['type'] as String,
                  activity['icon'] as String,
                  activity['title'] as String,
                  activity['description'] as String,
                  activity['timestamp'] as DateTime,
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
  ) {
    Color getTypeColor() {
      switch (type) {
        case 'order':
          return theme.colorScheme.primary;
        case 'customer':
          return theme.colorScheme.secondary;
        default:
          return theme.colorScheme.onSurfaceVariant;
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onActivityTap(id, type),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 1.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
