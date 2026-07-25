import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Load dashboard data
    setState(() {
      _lastUpdated = DateTime.now();
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
    final createOptions = [
      {
        'icon': 'add_shopping_cart',
        'label': 'Add Product',
        'route': '/product-management-real'
      },
      {
        'icon': 'receipt_long',
        'label': 'New Order',
        'route': '/order-management-real'
      },
      {
        'icon': 'request_quote',
        'label': 'Devis',
        'route': '/quotes-management'
      },
      {
        'icon': 'person_add',
        'label': 'Add Customer',
        'route': '/customer-management-real'
      },
      {
        'icon': 'business',
        'label': 'Piliers d\'entreprise',
        'route': '/business-units-management'
      },
      {
        'icon': 'add_photo_alternate',
        'label': 'Bannière hero — Accueil',
        'route': '/home-banners-management'
      },
      {
        'icon': 'groups',
        'label': 'Équipe & rôles',
        'route': '/staff-management'
      },
      {
        'icon': 'receipt_long',
        'label': 'Facturation',
        'route': '/invoicing'
      },
      {
        'icon': 'notifications_active',
        'label': 'Alertes',
        'route': '/alerts-center'
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
                      if (metricType == 'sales') {
                        Navigator.pushNamed(context, '/analytics-dashboard');
                      } else if (metricType == 'orders') {
                        Navigator.pushNamed(context, '/order-management-real');
                      } else if (metricType == 'followers') {
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
                    onActivityTap: (activityId) {
                      HapticFeedback.selectionClick();
                      // Navigate to activity detail
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
