import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/supabase/supabase_config.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/greeting_header_widget.dart';
import './widgets/metrics_cards_widget.dart';
import './widgets/quick_actions_grid_widget.dart';
import './widgets/recent_activity_feed_widget.dart';

/// Business Dashboard Screen
/// Central hub for business owners to monitor performance and access key features
class BusinessDashboard extends StatefulWidget {
  const BusinessDashboard({super.key});

  @override
  State<BusinessDashboard> createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  bool _isRefreshing = false;
  DateTime _lastUpdated = DateTime.now();
  int _unreadMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Badge de la cloche : messages client non lus par le staff, même
    // filtre que la carte "Messages" (metrics_cards_widget.dart) et la
    // liste des conversations (messaging_center_real.dart).
    var unread = 0;
    if (SupabaseConfig.isConfigured) {
      try {
        final result = await SupabaseConfig.client
            .from('messages')
            .select('id')
            .eq('sender_role', 'client')
            .eq('read_by_staff', false)
            .count();
        unread = result.count;
      } catch (_) {
        // Repli silencieux : le badge reste à 0 si la requête échoue.
      }
    }
    if (!mounted) return;
    setState(() {
      _lastUpdated = DateTime.now();
      _unreadMessagesCount = unread;
    });
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(seconds: 1));
    await _loadDashboardData();

    if (mounted) {
      setState(() => _isRefreshing = false);
      HapticFeedback.lightImpact();
    }
  }

  void _handleBottomNavigation(String route) {
    if (route == '/business-dashboard') return;
    Navigator.pushNamed(context, route);
  }

  void _showCreateOptions() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildCreateOptionsSheet(),
    );
  }

  Widget _buildCreateOptionsSheet() {
    final theme = Theme.of(context);
    // Seulement de vraies actions "créer quelque chose de nouveau" ici.
    // Piliers/Bannière/Équipe/Facturation/Alertes sont des écrans de
    // gestion, pas des créations rapides — déplacés vers le menu "Plus"
    // (onglet du bas), plus logique pour de la navigation.
    final createOptions = [
      {
        'icon': 'add_shopping_cart',
        'label': 'Ajouter un produit',
        'route': '/product-management-real'
      },
      {
        'icon': 'receipt_long',
        'label': 'Nouvelle commande',
        'route': '/order-management-real'
      },
      {
        'icon': 'request_quote',
        'label': 'Devis',
        'route': '/quotes-management'
      },
      {
        'icon': 'person_add',
        'label': 'Ajouter un client',
        'route': '/customer-management-real'
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Create New',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 2.h),
          ...createOptions.map((option) => ListTile(
                leading: CustomIconWidget(
                  iconName: option['icon'] as String,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text(
                  option['label'] as String,
                  style: theme.textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, option['route'] as String);
                },
              )),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: GreetingHeaderWidget(
          notificationCount: _unreadMessagesCount,
          onNotificationTap: () {
            Navigator.pushNamed(context, '/messaging-center');
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),
                  MetricsCardsWidget(
                    onMetricTap: (metricType) {
                      HapticFeedback.selectionClick();
                      // Navigate to detailed view based on metric type
                      if (metricType == 'products') {
                        Navigator.pushNamed(
                            context, '/product-management-real');
                      } else if (metricType == 'orders') {
                        Navigator.pushNamed(context, '/order-management-real');
                      } else if (metricType == 'clients') {
                        Navigator.pushNamed(context, '/customer-management-real');
                      } else if (metricType == 'messages') {
                        Navigator.pushNamed(context, '/messaging-center');
                      }
                    },
                  ),
                  SizedBox(height: 3.h),
                  QuickActionsGridWidget(
                    onActionTap: (actionType) {
                      HapticFeedback.selectionClick();
                      if (actionType == 'add_product') {
                        Navigator.pushNamed(
                            context, '/product-management-real');
                      } else if (actionType == 'view_orders') {
                        Navigator.pushNamed(context, '/order-management-real');
                      } else if (actionType == 'customer_messages') {
                        Navigator.pushNamed(context, '/messaging-center');
                      }
                    },
                  ),
                  SizedBox(height: 3.h),
                  RecentActivityFeedWidget(
                    lastUpdated: _lastUpdated,
                    onActivityTap: (activityId, activityType) {
                      HapticFeedback.selectionClick();
                      if (activityType == 'order') {
                        Navigator.pushNamed(context, '/order-management-real');
                      } else if (activityType == 'customer') {
                        Navigator.pushNamed(
                            context, '/customer-management-real');
                      }
                    },
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOptions,
        icon: CustomIconWidget(
          iconName: 'add',
          color: theme.floatingActionButtonTheme.foregroundColor ??
              theme.colorScheme.onPrimary,
          size: 24,
        ),
        label: Text(
          'New',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.floatingActionButtonTheme.foregroundColor ??
                theme.colorScheme.onPrimary,
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/business-dashboard',
        onNavigate: _handleBottomNavigation,
        badgeCounts: {
          '/messaging-center': 3,
        },
      ),
    );
  }
}
