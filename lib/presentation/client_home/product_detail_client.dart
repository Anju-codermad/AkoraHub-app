import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/providers/cart_provider.dart';

class ProductDetailClient extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailClient({super.key, required this.product});

  @override
  ConsumerState<ProductDetailClient> createState() =>
      _ProductDetailClientState();
}

class _ProductDetailClientState extends ConsumerState<ProductDetailClient> {
  int _quantity = 1;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.product;
    final priceDetail = (p['price_detail'] ?? 0).toDouble();
    final priceGros = (p['price_gros'] ?? 0).toDouble();
    final threshold = (p['gros_threshold_qty'] ?? 10) as int;
    final isGros = _quantity >= threshold;
    final unitPrice = isGros ? priceGros : priceDetail;
    final total = unitPrice * _quantity;

    return Scaffold(
      appBar: AppBar(title: Text(p['name'] ?? '')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    size: 56, color: theme.colorScheme.outline),
              ),
              SizedBox(height: 2.h),
              Text(p['name'] ?? '', style: theme.textTheme.headlineSmall),
              if ((p['category'] ?? '').toString().isNotEmpty) ...[
                SizedBox(height: 0.5.h),
                Chip(
                  label: Text(p['category']),
                  visualDensity: VisualDensity.compact,
                ),
              ],
              SizedBox(height: 1.h),
              if ((p['description'] ?? '').toString().isNotEmpty)
                Text(p['description'], style: theme.textTheme.bodyMedium),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prix Détail : ${_currency.format(priceDetail)}'),
                    Text(
                        'Prix Gros (dès $threshold unités) : ${_currency.format(priceGros)}'),
                    SizedBox(height: 1.h),
                    Text(
                      isGros
                          ? '✓ Tarif Gros appliqué automatiquement'
                          : 'Encore ${threshold - _quantity} unité(s) pour le tarif Gros',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quantité', style: theme.textTheme.titleMedium),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Text('$_quantity',
                          style: theme.textTheme.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: theme.textTheme.titleLarge),
                  Text(
                    _currency.format(total),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).addItem(CartItem(
                              productId: p['id'],
                              name: p['name'] ?? '',
                              priceDetail: priceDetail,
                              priceGros: priceGros,
                              grosThresholdQty: threshold,
                              quantity: _quantity,
                            ));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('${p['name']} ajouté au panier'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Ajouter au panier'),
                    ),
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
