import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Customer context sidebar widget showing customer information and history
class CustomerContextWidget extends StatelessWidget {
  final Map<String, dynamic> customerData;
  final VoidCallback onClose;

  const CustomerContextWidget({
    super.key,
    required this.customerData,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Customer Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'close',
                      size: 24,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer profile
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: CustomImageWidget(
                                imageUrl:
                                    customerData['photo'] as String? ?? '',
                                width: 76,
                                height: 76,
                                fit: BoxFit.cover,
                                semanticLabel:
                                    customerData['photoLabel'] as String? ??
                                        'Customer profile photo',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            customerData['name'] as String? ?? 'Unknown',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customerData['email'] as String? ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Contact information
                    _buildSection(
                      context,
                      'Contact Information',
                      [
                        _buildInfoRow(
                          context,
                          'phone',
                          'Phone',
                          customerData['phone'] as String? ?? 'Not provided',
                        ),
                        _buildInfoRow(
                          context,
                          'location_on',
                          'Location',
                          customerData['location'] as String? ?? 'Not provided',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Recent orders
                    _buildSection(
                      context,
                      'Recent Orders',
                      [
                        ...(customerData['recentOrders']
                                    as List<Map<String, dynamic>>? ??
                                [])
                            .map((order) => _buildOrderCard(context, order))
                            .toList(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Preferences
                    _buildSection(
                      context,
                      'Preferences',
                      [
                        _buildInfoRow(
                          context,
                          'favorite',
                          'Favorite Products',
                          (customerData['favoriteProducts'] as List<String>? ??
                                  [])
                              .join(', '),
                        ),
                        _buildInfoRow(
                          context,
                          'shopping_cart',
                          'Total Orders',
                          (customerData['totalOrders'] as int? ?? 0).toString(),
                        ),
                        _buildInfoRow(
                          context,
                          'attach_money',
                          'Total Spent',
                          '\$${(customerData['totalSpent'] as double? ?? 0.0).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Interaction history
                    _buildSection(
                      context,
                      'Interaction History',
                      [
                        ...(customerData['interactions']
                                    as List<Map<String, dynamic>>? ??
                                [])
                            .map((interaction) =>
                                _buildInteractionCard(context, interaction))
                            .toList(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'shopping_bag',
                size: 24,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['product'] as String? ?? 'Unknown Product',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  order['date'] as String? ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${(order['amount'] as double? ?? 0.0).toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionCard(
      BuildContext context, Map<String, dynamic> interaction) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: interaction['type'] as String == 'message'
                ? 'message'
                : interaction['type'] as String == 'call'
                    ? 'phone'
                    : 'event',
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interaction['description'] as String? ?? '',
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  interaction['date'] as String? ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
