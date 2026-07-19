import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Order card widget with swipe actions
/// Displays order information with color-coded status badges
class OrderCardWidget extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final Function(String) onUpdateStatus;
  final VoidCallback onContactCustomer;
  final VoidCallback onGenerateInvoice;

  const OrderCardWidget({
    super.key,
    required this.order,
    required this.onTap,
    required this.onUpdateStatus,
    required this.onContactCustomer,
    required this.onGenerateInvoice,
  });

  Color _getStatusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'pending':
        return theme.colorScheme.error;
      case 'processing':
        return const Color(0xFFF57C00);
      case 'completed':
        return theme.colorScheme.tertiary;
      case 'cancelled':
        return theme.colorScheme.onSurfaceVariant;
      default:
        return theme.colorScheme.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order['status'] as String? ?? 'Pending';
    final statusColor = _getStatusColor(context, status);

    return Slidable(
      key: ValueKey(order['orderId']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              _showStatusUpdateSheet(context);
            },
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.edit,
            label: 'Update',
          ),
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              onContactCustomer();
            },
            backgroundColor: theme.colorScheme.tertiary,
            foregroundColor: theme.colorScheme.onTertiary,
            icon: Icons.message,
            label: 'Contact',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              HapticFeedback.mediumImpact();
              onGenerateInvoice();
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.picture_as_pdf,
            label: 'Invoice',
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['customerName'] as String? ??
                                'Unknown Customer',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order #${order['orderId'] as String? ?? 'N/A'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: _getStatusIcon(status)
                                .codePoint
                                .toRadixString(16),
                            color: statusColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  height: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Icons.calendar_today,
                        'Date',
                        order['orderDate'] as String? ?? 'N/A',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        Icons.attach_money,
                        'Total',
                        order['totalAmount'] as String? ?? '\$0.00',
                      ),
                    ),
                  ],
                ),
                if (order['paymentStatus'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: _getPaymentStatusIcon(
                            order['paymentStatus'] as String),
                        color: _getPaymentStatusColor(
                            context, order['paymentStatus'] as String),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Payment: ${order['paymentStatus']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getPaymentStatusColor(
                              context, order['paymentStatus'] as String),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: icon.codePoint.toRadixString(16),
                color: theme.colorScheme.onSurfaceVariant,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle.codePoint.toRadixString(16);
      case 'pending':
        return Icons.schedule.codePoint.toRadixString(16);
      case 'failed':
        return Icons.error.codePoint.toRadixString(16);
      default:
        return Icons.info.codePoint.toRadixString(16);
    }
  }

  Color _getPaymentStatusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'completed':
        return theme.colorScheme.tertiary;
      case 'pending':
        return const Color(0xFFF57C00);
      case 'failed':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  void _showStatusUpdateSheet(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = ['Pending', 'Processing', 'Completed', 'Cancelled'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Order Status',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...statuses.map((status) => ListTile(
                  leading: CustomIconWidget(
                    iconName:
                        _getStatusIcon(status).codePoint.toRadixString(16),
                    color: _getStatusColor(context, status),
                    size: 24,
                  ),
                  title: Text(status),
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmationDialog(context, status);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, String newStatus) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Status Update'),
        content: Text('Change order status to $newStatus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onUpdateStatus(newStatus);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
