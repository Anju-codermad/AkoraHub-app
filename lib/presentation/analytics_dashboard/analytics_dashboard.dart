import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/customer_demographics_widget.dart';
import './widgets/date_range_selector_widget.dart';
import './widgets/engagement_metrics_widget.dart';
import './widgets/metric_card_widget.dart';
import './widgets/product_performance_widget.dart';
import './widgets/revenue_chart_widget.dart';

/// Analytics Dashboard Screen
/// Provides comprehensive business performance insights through mobile-optimized data visualization
class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String _selectedPeriod = 'Week';

  // Mock data for key metrics
  final List<Map<String, dynamic>> _keyMetrics = [
    {
      'title': 'Total Revenue',
      'value': '\$45,280',
      'subtitle': 'Last 7 days',
      'iconName': 'attach_money',
      'changePercentage': '+12.5%',
      'isPositiveChange': true,
    },
    {
      'title': 'Total Orders',
      'value': '1,248',
      'subtitle': 'Last 7 days',
      'iconName': 'shopping_cart',
      'changePercentage': '+8.3%',
      'isPositiveChange': true,
    },
    {
      'title': 'New Customers',
      'value': '342',
      'subtitle': 'Last 7 days',
      'iconName': 'person_add',
      'changePercentage': '+15.7%',
      'isPositiveChange': true,
    },
    {
      'title': 'Conversion Rate',
      'value': '3.8%',
      'subtitle': 'Last 7 days',
      'iconName': 'trending_up',
      'changePercentage': '-2.1%',
      'isPositiveChange': false,
    },
  ];

  // Mock data for revenue chart
  final List<Map<String, dynamic>> _revenueData = [
    {'label': 'Mon', 'value': 4.5},
    {'label': 'Tue', 'value': 5.2},
    {'label': 'Wed', 'value': 4.8},
    {'label': 'Thu', 'value': 6.1},
    {'label': 'Fri', 'value': 7.3},
    {'label': 'Sat', 'value': 8.5},
    {'label': 'Sun', 'value': 6.8},
  ];

  // Mock data for customer demographics
  List<Map<String, dynamic>> _demographicsData = [];

  // Mock data for product performance
  final List<Map<String, dynamic>> _productData = [
    {
      'name': 'Lavender Soap',
      'sales': 85,
      'image':
          'https://images.unsplash.com/photo-1607006344878-f7eef45446f2',
      'semanticLabel':
          'Purple lavender soap bar with dried lavender flowers on white background',
    },
    {
      'name': 'Rose Cleanser',
      'sales': 72,
      'image':
          'https://images.unsplash.com/photo-1689001782628-79dc8c368686',
      'semanticLabel':
          'Pink rose-scented liquid cleanser bottle with rose petals',
    },
    {
      'name': 'Mint Shampoo',
      'sales': 68,
      'image':
          'https://images.unsplash.com/photo-1580272969116-9dfd196811cf',
      'semanticLabel': 'Green mint shampoo bottle with fresh mint leaves',
    },
    {
      'name': 'Coconut Lotion',
      'sales': 54,
      'image':
          'https://images.unsplash.com/photo-1550433223-cc568d2b63c3',
      'semanticLabel': 'White coconut body lotion bottle with coconut pieces',
    },
  ];

  // Mock data for engagement metrics
  List<Map<String, dynamic>> _engagementData = [];

  @override
  void initState() {
    super.initState();
    _initializeDemographicsData();
    _initializeEngagementData();
  }

  void _initializeDemographicsData() {
    final theme = Theme.of(context);
    _demographicsData = [
      {
        'label': 'Male 18-24',
        'value': 28,
        'color': theme.colorScheme.primary,
      },
      {
        'label': 'Female 18-24',
        'value': 35,
        'color': theme.colorScheme.secondary,
      },
      {
        'label': 'Male 25-34',
        'value': 18,
        'color': theme.colorScheme.tertiary,
      },
      {
        'label': 'Female 25-34',
        'value': 19,
        'color': theme.colorScheme.error,
      },
    ];
  }

  void _initializeEngagementData() {
    final theme = Theme.of(context);
    _engagementData = [
      {
        'label': 'Followers',
        'subtitle': 'Total followers',
        'value': '12.5K',
        'change': '+245',
        'isPositive': true,
        'icon': 'people',
        'color': theme.colorScheme.primary,
      },
      {
        'label': 'Engagement Rate',
        'subtitle': 'Avg. interactions',
        'value': '4.8%',
        'change': '+0.3%',
        'isPositive': true,
        'icon': 'favorite',
        'color': theme.colorScheme.error,
      },
      {
        'label': 'Profile Views',
        'subtitle': 'Last 7 days',
        'value': '8,342',
        'change': '+12%',
        'isPositive': true,
        'icon': 'visibility',
        'color': theme.colorScheme.secondary,
      },
      {
        'label': 'Messages',
        'subtitle': 'Customer inquiries',
        'value': '156',
        'change': '-8',
        'isPositive': false,
        'icon': 'message',
        'color': theme.colorScheme.tertiary,
      },
    ];
  }

  void _handleDateRangeChange(DateTime startDate, DateTime endDate) {
    setState(() {
      _startDate = startDate;
      _endDate = endDate;
      _isLoading = true;
    });

    // Simulate data refresh
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        HapticFeedback.lightImpact();
      }
    });
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleExport(String format) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting analytics report as $format...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Report',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'picture_as_pdf',
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                title: const Text('Export as PDF'),
                subtitle: const Text('Detailed analytics report'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport('PDF');
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'table_chart',
                  color: theme.colorScheme.tertiary,
                  size: 24,
                ),
                title: const Text('Export as Excel'),
                subtitle: const Text('Raw data spreadsheet'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport('Excel');
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'share',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Share Report'),
                subtitle: const Text('Send via email or messaging'),
                onTap: () {
                  Navigator.pop(context);
                  _handleExport('Share');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        variant: CustomAppBarVariant.standard,
        title: 'Analytics Dashboard',
        showBackButton: false,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: theme.appBarTheme.foregroundColor ??
                  theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _showExportOptions,
            tooltip: 'Export Report',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications_outlined',
              color: theme.appBarTheme.foregroundColor ??
                  theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/messaging-center');
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Range Selector
              DateRangeSelectorWidget(
                onDateRangeChanged: _handleDateRangeChange,
                initialStartDate: _startDate,
                initialEndDate: _endDate,
              ),
              SizedBox(height: 2.h),

              // Key Metrics Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 3.w,
                  mainAxisSpacing: 2.h,
                  childAspectRatio: 1.1,
                ),
                itemCount: _keyMetrics.length,
                itemBuilder: (context, index) {
                  final metric = _keyMetrics[index];
                  return MetricCardWidget(
                    title: metric['title'],
                    value: metric['value'],
                    subtitle: metric['subtitle'],
                    iconName: metric['iconName'],
                    changePercentage: metric['changePercentage'],
                    isPositiveChange: metric['isPositiveChange'],
                  );
                },
              ),
              SizedBox(height: 2.h),

              // Revenue Chart
              if (_isLoading)
                Container(
                  height: 40.h,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                RevenueChartWidget(
                  revenueData: _revenueData,
                  period: _selectedPeriod,
                ),
              SizedBox(height: 2.h),

              // Customer Demographics
              CustomerDemographicsWidget(
                demographicsData: _demographicsData,
              ),
              SizedBox(height: 2.h),

              // Product Performance
              ProductPerformanceWidget(
                productData: _productData,
              ),
              SizedBox(height: 2.h),

              // Engagement Metrics
              EngagementMetricsWidget(
                engagementData: _engagementData,
              ),
              SizedBox(height: 2.h),

              // Additional Insights Section
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'lightbulb',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performance Insight',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your sales are 12% higher than last week. Keep up the great work!',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentRoute: '/analytics-dashboard',
        onNavigate: (route) {
          if (route != '/analytics-dashboard') {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
