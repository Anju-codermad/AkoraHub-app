import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Metrics Cards Widget
/// Displays real key performance indicators pulled from Supabase.
class MetricsCardsWidget extends StatefulWidget {
  final Function(String metricType) onMetricTap;

  const MetricsCardsWidget({
    super.key,
    required this.onMetricTap,
  });

  @override
  State<MetricsCardsWidget> createState() => _MetricsCardsWidgetState();
}

class _MetricsCardsWidgetState extends State<MetricsCardsWidget> {
  int _productsCount = 0;
  int _pendingOrdersCount = 0;
  int _clientsCount = 0;
  int _unreadMessagesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    if (!SupabaseConfig.isConfigured) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final products =
          await SupabaseConfig.client.from('products').select('id').count();
      final pendingOrders = await SupabaseConfig.client
          .from('orders')
          .select('id')
          .inFilter('status', ['recue', 'en_preparation', 'expediee']).count();
      final clients = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('role', 'client')
          .count();
      // Messages client non lus par le staff — même filtre que
      // messaging_center_real.dart pour rester cohérent.
      final unreadMessages = await SupabaseConfig.client
          .from('messages')
          .select('id')
          .eq('sender_role', 'client')
          .eq('read_by_staff', false)
          .count();

      if (!mounted) return;
      setState(() {
        _productsCount = products.count;
        _pendingOrdersCount = pendingOrders.count;
        _clientsCount = clients.count;
        _unreadMessagesCount = unreadMessages.count;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final metrics = [
      {
        'type': 'products',
        'icon': 'inventory_2',
        'label': 'Produits',
        'value': _isLoading ? '—' : '$_productsCount',
      },
      {
        'type': 'orders',
        'icon': 'shopping_bag',
        'label': 'Commandes en attente',
        'value': _isLoading ? '—' : '$_pendingOrdersCount',
      },
      {
        'type': 'clients',
        'icon': 'people',
        'label': 'Clients inscrits',
        'value': _isLoading ? '—' : '$_clientsCount',
      },
      {
        'type': 'messages',
        'icon': 'message',
        'label': 'Messages',
        'value': _isLoading ? '—' : '$_unreadMessagesCount',
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue d\'ensemble',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 1.5,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return _buildMetricCard(
                context,
                theme,
                metric['type'] as String,
                metric['icon'] as String,
                metric['label'] as String,
                metric['value'] as String,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    ThemeData theme,
    String type,
    String icon,
    String label,
    String value,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onMetricTap(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: icon,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'arrow_forward_ios',
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                    size: 14,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
