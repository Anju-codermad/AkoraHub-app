import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import './widgets/campaign_card.dart';
import './widgets/campaign_creation_wizard.dart';
import './widgets/campaign_filter_chips.dart';

/// Campaign Management screen for creating and monitoring marketing campaigns
class CampaignManagement extends StatefulWidget {
  const CampaignManagement({super.key});

  @override
  State<CampaignManagement> createState() => _CampaignManagementState();
}

class _CampaignManagementState extends State<CampaignManagement> {
  String _selectedFilter = 'All';
  bool _isRefreshing = false;

  final List<Map<String, dynamic>> _campaigns = [
    {
      'id': 1,
      'title': 'Summer Sale 2025',
      'status': 'Active',
      'thumbnail':
          'https://images.unsplash.com/photo-1650878481537-5277de91cc85',
      'thumbnailLabel':
          'Colorful summer sale promotional banner with bright yellow and orange gradient background',
      'audienceSize': 1250,
      'sendDate': '08 Dec 2025, 10:00 AM',
      'openRate': 68,
      'clickRate': 24,
      'delivered': 1180,
    },
    {
      'id': 2,
      'title': 'New Product Launch',
      'status': 'Scheduled',
      'thumbnail':
          'https://images.unsplash.com/photo-1695619575394-f357c8571cc5',
      'thumbnailLabel':
          'Modern smartphone product photography on white background with soft shadows',
      'audienceSize': 850,
      'sendDate': '15 Dec 2025, 09:00 AM',
      'openRate': 0,
      'clickRate': 0,
      'delivered': 0,
    },
    {
      'id': 3,
      'title': 'Holiday Greetings',
      'status': 'Completed',
      'thumbnail':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1473b9eea-1764893550847.png',
      'thumbnailLabel':
          'Festive holiday greeting card with red and gold decorations and Christmas ornaments',
      'audienceSize': 2100,
      'sendDate': '01 Dec 2025, 08:00 AM',
      'openRate': 72,
      'clickRate': 31,
      'delivered': 2050,
    },
    {
      'id': 4,
      'title': 'VIP Customer Exclusive',
      'status': 'Active',
      'thumbnail':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1a8078c69-1764801507430.png',
      'thumbnailLabel':
          'Luxury gold VIP membership card on black marble surface with elegant lighting',
      'audienceSize': 95,
      'sendDate': '05 Dec 2025, 02:00 PM',
      'openRate': 85,
      'clickRate': 42,
      'delivered': 92,
    },
    {
      'id': 5,
      'title': 'Re-engagement Campaign',
      'status': 'Draft',
      'thumbnail':
          'https://images.unsplash.com/photo-1576888474371-54b1c471988f',
      'thumbnailLabel':
          'Motivational comeback message with bold typography on gradient purple background',
      'audienceSize': 320,
      'sendDate': 'Not scheduled',
      'openRate': 0,
      'clickRate': 0,
      'delivered': 0,
    },
  ];

  List<Map<String, dynamic>> get _filteredCampaigns {
    if (_selectedFilter == 'All') return _campaigns;
    return _campaigns
        .where((campaign) => campaign['status'] == _selectedFilter)
        .toList();
  }

  Future<void> _refreshCampaigns() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign data refreshed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCampaignCreationWizard() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CampaignCreationWizard(
        onCampaignCreated: (campaign) {
          setState(() {
            _campaigns.insert(0, {
              'id': _campaigns.length + 1,
              'title': campaign['title'],
              'status': 'Draft',
              'thumbnail': campaign['media']?.isNotEmpty ?? false
                  ? campaign['media'][0]
                  : null,
              'thumbnailLabel': 'Campaign thumbnail image',
              'audienceSize': campaign['audienceSize'],
              'sendDate': campaign['scheduledDate'] != null
                  ? '${campaign['scheduledDate'].day}/${campaign['scheduledDate'].month}/${campaign['scheduledDate'].year}'
                  : 'Not scheduled',
              'openRate': 0,
              'clickRate': 0,
              'delivered': 0,
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Campaign created successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _viewCampaignDetail(Map<String, dynamic> campaign) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCampaignDetailSheet(campaign),
    );
  }

  Widget _buildCampaignDetailSheet(Map<String, dynamic> campaign) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    campaign['title'] as String,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'close',
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (campaign['thumbnail'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomImageWidget(
                        imageUrl: campaign['thumbnail'] as String,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        semanticLabel: campaign['thumbnailLabel'] as String,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Campaign Statistics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Total Recipients',
                          '${campaign['audienceSize']}',
                          Icons.people,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Delivered',
                          '${campaign['delivered']}',
                          Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Open Rate',
                          '${campaign['openRate']}%',
                          Icons.mail_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          theme,
                          'Click Rate',
                          '${campaign['clickRate']}%',
                          Icons.touch_app,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Recipient Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecipientBreakdown(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: icon
                .toString()
                .split('.')
                .last
                .replaceAll('IconData(U+', '')
                .replaceAll(')', ''),
            size: 24,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientBreakdown(ThemeData theme) {
    final segments = [
      {'name': 'All Customers', 'count': 650, 'percentage': 52},
      {'name': 'VIP Customers', 'count': 320, 'percentage': 26},
      {'name': 'New Customers', 'count': 280, 'percentage': 22},
    ];

    return Column(
      children: segments.map((segment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    segment['name'] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${segment['count']} (${segment['percentage']}%)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (segment['percentage'] as int) / 100,
                  minHeight: 8,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _duplicateCampaign(Map<String, dynamic> campaign) {
    HapticFeedback.mediumImpact();
    setState(() {
      _campaigns.insert(0, {
        ...campaign,
        'id': _campaigns.length + 1,
        'title': '${campaign['title']} (Copy)',
        'status': 'Draft',
        'sendDate': 'Not scheduled',
        'openRate': 0,
        'clickRate': 0,
        'delivered': 0,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Campaign duplicated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _editCampaign(Map<String, dynamic> campaign) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing ${campaign['title']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _viewAnalytics(Map<String, dynamic> campaign) {
    HapticFeedback.selectionClick();
    _viewCampaignDetail(campaign);
  }

  void _deleteCampaign(Map<String, dynamic> campaign) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content:
            Text('Are you sure you want to delete "${campaign['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _campaigns.removeWhere((c) => c['id'] == campaign['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Campaign deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Management'),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'search',
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
            },
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'filter_list',
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          CampaignFilterChips(
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = filter);
            },
          ),
          Expanded(
            child: _filteredCampaigns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'campaign',
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No campaigns found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first campaign to get started',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshCampaigns,
                    child: ListView.builder(
                      itemCount: _filteredCampaigns.length,
                      itemBuilder: (context, index) {
                        final campaign = _filteredCampaigns[index];
                        return CampaignCard(
                          campaign: campaign,
                          onTap: () => _viewCampaignDetail(campaign),
                          onDuplicate: () => _duplicateCampaign(campaign),
                          onEdit: () => _editCampaign(campaign),
                          onViewAnalytics: () => _viewAnalytics(campaign),
                          onDelete: () => _deleteCampaign(campaign),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCampaignCreationWizard,
        icon: CustomIconWidget(
          iconName: 'add',
          size: 24,
          color: theme.colorScheme.onTertiary,
        ),
        label: const Text('New Campaign'),
      ),
    );
  }
}
