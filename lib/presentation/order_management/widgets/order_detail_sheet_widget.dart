import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Order detail bottom sheet widget
/// Displays comprehensive order information with product breakdown
class OrderDetailSheetWidget extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onGenerateInvoice;
  final VoidCallback onContactCustomer;

  const OrderDetailSheetWidget({
    super.key,
    required this.order,
    required this.onGenerateInvoice,
    required this.onContactCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final products = (order['products'] as List?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Order Details',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: Icons.close.codePoint.toRadixString(16),
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(context, 'Customer Information', [
                    _buildInfoRow(context, 'Name',
                        order['customerName'] as String? ?? 'N/A'),
                    _buildInfoRow(context, 'Email',
                        order['customerEmail'] as String? ?? 'N/A'),
                    _buildInfoRow(context, 'Phone',
                        order['customerPhone'] as String? ?? 'N/A'),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection(context, 'Order Information', [
                    _buildInfoRow(context, 'Order ID',
                        order['orderId'] as String? ?? 'N/A'),
                    _buildInfoRow(context, 'Date',
                        order['orderDate'] as String? ?? 'N/A'),
                    _buildInfoRow(
                        context, 'Status', order['status'] as String? ?? 'N/A'),
                    _buildInfoRow(context, 'Payment',
                        order['paymentStatus'] as String? ?? 'N/A'),
                  ]),
                  const SizedBox(height: 16),
                  Text(
                    'Products',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...products.map((product) => _buildProductItem(
                      context, product as Map<String, dynamic>)),
                  const SizedBox(height: 16),
                  Divider(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        order['totalAmount'] as String? ?? '\$0.00',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onContactCustomer,
                          icon: CustomIconWidget(
                            iconName: Icons.message.codePoint.toRadixString(16),
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          label: const Text('Contact'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onGenerateInvoice,
                          icon: CustomIconWidget(
                            iconName: Icons.picture_as_pdf.codePoint
                                .toRadixString(16),
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                          label: const Text('Invoice'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, Map<String, dynamic> product) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (product['image'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomImageWidget(
                imageUrl: product['image'] as String,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                semanticLabel:
                    product['semanticLabel'] as String? ?? 'Product image',
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] as String? ?? 'Unknown Product',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${product['quantity'] ?? 0}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            product['price'] as String? ?? '\$0.00',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
