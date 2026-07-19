import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/customer_analytics_summary.dart';
import './widgets/customer_filter_chips.dart';
import './widgets/customer_list_item.dart';
import './widgets/customer_search_bar.dart';

/// Customer Management Screen
/// Enables business owners to track prospects, manage relationships, and analyze customer demographics
class CustomerManagement extends StatefulWidget {
  const CustomerManagement({super.key});

  @override
  State<CustomerManagement> createState() => _CustomerManagementState();
}

class _CustomerManagementState extends State<CustomerManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final Set<int> _selectedCustomers = {};
  bool _isMultiSelectMode = false;

  // Mock customer data
  final List<Map<String, dynamic>> _allCustomers = [
    {
      "id": 1,
      "name": "Rakoto Andrianina",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_153a2154a-1763295329939.png",
      "avatarSemanticLabel":
          "Professional headshot of a Malagasy man with short black hair wearing a blue shirt",
      "location": "Antananarivo, Madagascar",
      "status": "Active",
      "lastInteraction": "2 hours ago",
      "engagementScore": 85,
      "hasReminder": true,
      "unreadMessages": 3,
      "phone": "+261 34 12 345 67",
      "email": "rakoto.andrianina@email.mg",
      "joinDate": "2024-11-15",
      "totalPurchases": 12,
      "lastPurchase": "2025-12-06",
    },
    {
      "id": 2,
      "name": "Ravelo Miora",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_125dc5bf9-1763300423293.png",
      "avatarSemanticLabel":
          "Professional headshot of a Malagasy woman with long black hair wearing a white blouse",
      "location": "Toamasina, Madagascar",
      "status": "New",
      "lastInteraction": "1 day ago",
      "engagementScore": 45,
      "hasReminder": false,
      "unreadMessages": 0,
      "phone": "+261 33 98 765 43",
      "email": "ravelo.miora@email.mg",
      "joinDate": "2025-12-05",
      "totalPurchases": 1,
      "lastPurchase": "2025-12-05",
    },
    {
      "id": 3,
      "name": "Randria Hery",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_153a2154a-1763295329939.png",
      "avatarSemanticLabel":
          "Professional headshot of a Malagasy man with glasses and short hair wearing a gray suit",
      "location": "Antsirabe, Madagascar",
      "status": "Active",
      "lastInteraction": "5 hours ago",
      "engagementScore": 92,
      "hasReminder": false,
      "unreadMessages": 1,
      "phone": "+261 32 45 678 90",
      "email": "randria.hery@email.mg",
      "joinDate": "2024-10-20",
      "totalPurchases": 25,
      "lastPurchase": "2025-12-07",
    },
    {
      "id": 4,
      "name": "Razafindrakoto Nivo",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_1b96d57f6-1763294775540.png",
      "avatarSemanticLabel":
          "Professional headshot of a Malagasy woman with curly hair wearing a red dress",
      "location": "Fianarantsoa, Madagascar",
      "status": "Inactive",
      "lastInteraction": "2 weeks ago",
      "engagementScore": 15,
      "hasReminder": true,
      "unreadMessages": 0,
      "phone": "+261 34 56 789 01",
      "email": "razafindrakoto.nivo@email.mg",
      "joinDate": "2024-08-10",
      "totalPurchases": 5,
      "lastPurchase": "2025-11-20",
    },
    {
      "id": 5,
      "name": "Rasoanaivo Faly",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_153a2154a-1763295329939.png",
      "avatarSemanticLabel":
          "Professional headshot of a Malagasy man with short hair wearing a green polo shirt",
      "location": "Mahajanga, Madagascar",
      "status": "Active",
      "lastInteraction": "Yesterday",
      "engagementScore": 78,
      "hasReminder": false,
      "unreadMessages": 2,
      "phone": "+261 33 23 456 78",
      "email": "rasoanaivo.faly@email.mg",
      "joinDate": "2024-09-05",
      "totalPurchases": 18,
      "lastPurchase": "2025-12-07",
    },
    {
      "id": 6,
      "name": "Raharison Lalaina",
      "avatar":
          "https://img.rocket.new/generatedImages/rocket_gen_img_125dc5bf9-1763300423293.png",
      "avatarSemanticLabel":
          "Professional headshot of a Malagasy woman with shoulder-length hair wearing a yellow blouse",
      "location": "Toliara, Madagascar",
      "status": "New",
      "lastInteraction": "3 hours ago",
      "engagementScore": 35,
      "hasReminder": true,
      "unreadMessages": 5,
      "phone": "+261 32 67 890 12",
      "email": "raharison.lalaina@email.mg",
      "joinDate": "2025-12-07",
      "totalPurchases": 0,
      "lastPurchase": null,
    },
  ];

  // Analytics data
  final Map<String, dynamic> _analyticsData = {
    "totalCustomers": 156,
    "activeThisMonth": 89,
    "newCustomers": 23,
    "demographics": {
      "male": 78,
      "female": 72,
      "other": 6,
      "total": 156,
    },
  };

  List<Map<String, dynamic>> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = List.from(_allCustomers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers() {
    setState(() {
      _filteredCustomers = _allCustomers.where((customer) {
        final matchesSearch = customer['name']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()) ||
            customer['location']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        final matchesFilter = _selectedFilter == 'All' ||
            customer['status'].toString().toLowerCase() ==
                _selectedFilter.toLowerCase();

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _handleCustomerAction(int customerId, String action) {
    final customer = _allCustomers.firstWhere((c) => c['id'] == customerId);

    switch (action) {
      case 'whatsapp':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening WhatsApp chat with ${customer['name']}'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'call':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calling ${customer['phone']}'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'email':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening email to ${customer['email']}'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'history':
        Navigator.pushNamed(
          context,
          '/customer-management',
          arguments: {'customerId': customerId, 'view': 'history'},
        );
        break;
    }
  }

  void _handleCustomerTap(int customerId) {
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedCustomers.contains(customerId)) {
          _selectedCustomers.remove(customerId);
          if (_selectedCustomers.isEmpty) {
            _isMultiSelectMode = false;
          }
        } else {
          _selectedCustomers.add(customerId);
        }
      });
    } else {
      Navigator.pushNamed(
        context,
        '/customer-management',
        arguments: {'customerId': customerId, 'view': 'detail'},
      );
    }
  }

  void _handleLongPress(int customerId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isMultiSelectMode = true;
      _selectedCustomers.add(customerId);
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Filters',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Filter by Location',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'Antananarivo',
                  'Toamasina',
                  'Antsirabe',
                  'Fianarantsoa',
                  'Mahajanga',
                  'Toliara',
                ].map((location) {
                  return FilterChip(
                    label: Text(location),
                    onSelected: (selected) {},
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Filter by Engagement',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'High (80-100%)',
                  'Medium (50-79%)',
                  'Low (0-49%)',
                ].map((engagement) {
                  return FilterChip(
                    label: Text(engagement),
                    onSelected: (selected) {},
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBulkActionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_selectedCustomers.length} customers selected',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'campaign',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Send Campaign'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/campaign-management');
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'download',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Export Data'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exporting customer data...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'label',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Add Tags'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adding tags to selected customers...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
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
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        title: Text(
          'Customer Management',
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          if (_isMultiSelectMode)
            IconButton(
              icon: CustomIconWidget(
                iconName: 'close',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedCustomers.clear();
                });
              },
              tooltip: 'Cancel Selection',
            )
          else
            IconButton(
              icon: CustomIconWidget(
                iconName: 'more_vert',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: CustomIconWidget(
                              iconName: 'import_contacts',
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            title: const Text('Import Contacts'),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Importing contacts...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: CustomIconWidget(
                              iconName: 'download',
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            title: const Text('Export All'),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Exporting all customers...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              tooltip: 'More Options',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {
            _filterCustomers();
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Customer data refreshed'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  CustomerSearchBar(
                    searchController: _searchController,
                    onSearchChanged: (value) => _filterCustomers(),
                    onFilterTap: _showFilterBottomSheet,
                  ),
                  CustomerFilterChips(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                        _filterCustomers();
                      });
                    },
                  ),
                  CustomerAnalyticsSummary(
                    analyticsData: _analyticsData,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (_filteredCustomers.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'people_outline',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No customers found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final customer = _filteredCustomers[index];
                    return GestureDetector(
                      onLongPress: () =>
                          _handleLongPress(customer['id'] as int),
                      child: CustomerListItem(
                        customer: customer,
                        onTap: () => _handleCustomerTap(customer['id'] as int),
                        onAction: (action) => _handleCustomerAction(
                            customer['id'] as int, action),
                        isSelected: _selectedCustomers.contains(customer['id']),
                      ),
                    );
                  },
                  childCount: _filteredCustomers.length,
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: _isMultiSelectMode
          ? FloatingActionButton.extended(
              onPressed: _showBulkActionsBottomSheet,
              icon: CustomIconWidget(
                iconName: 'check_circle',
                color: Colors.white,
                size: 24,
              ),
              label: Text(
                'Actions (${_selectedCustomers.length})',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Add Customer',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ListTile(
                            leading: CustomIconWidget(
                              iconName: 'person_add',
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            title: const Text('Add Manually'),
                            subtitle: const Text('Enter customer details'),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Opening customer form...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: CustomIconWidget(
                              iconName: 'contacts',
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                            title: const Text('Import from Contacts'),
                            subtitle: const Text('Select from phone contacts'),
                            onTap: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Accessing contacts...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: CustomIconWidget(
                iconName: 'add',
                color: Colors.white,
                size: 24,
              ),
            ),
    );
  }
}
