import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';

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
              SizedBox(height: 3.h),
              _ReviewsSection(productId: p['id']),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewsSection extends StatefulWidget {
  final String productId;

  const _ReviewsSection({required this.productId});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await SupabaseConfig.client
          .from('product_reviews')
          .select('*, profiles(full_name, company_name)')
          .eq('product_id', widget.productId)
          .order('created_at', ascending: false);
      setState(() {
        _reviews = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(
        0, (s, r) => s + ((r['rating'] ?? 0) as int));
    return sum / _reviews.length;
  }

  Future<void> _addReview() async {
    int rating = 5;
    final controller = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Donner votre avis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () =>
                        setDialogState(() => rating = i + 1),
                  );
                }),
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Votre commentaire (optionnel)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseConfig.client.from('product_reviews').upsert({
        'product_id': widget.productId,
        'author_id': userId,
        'rating': rating,
        'comment': controller.text.trim(),
      });
      _loadReviews();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi de l\'avis.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Avis clients', style: theme.textTheme.titleMedium),
                if (_reviews.isNotEmpty) ...[
                  SizedBox(width: 2.w),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  Text(' ${_averageRating.toStringAsFixed(1)} (${_reviews.length})'),
                ],
              ],
            ),
            TextButton(
              onPressed: _addReview,
              child: const Text('Donner un avis'),
            ),
          ],
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_reviews.isEmpty)
          const Text('Aucun avis pour le moment.')
        else
          ..._reviews.map((r) {
            final author = r['profiles'];
            final name = author != null
                ? (author['company_name'] ?? author['full_name'] ?? 'Client')
                : 'Client';
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(width: 2.w),
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < (r['rating'] ?? 0)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  if ((r['comment'] ?? '').toString().isNotEmpty)
                    Text(r['comment']),
                ],
              ),
            );
          }),
      ],
    );
  }
}
