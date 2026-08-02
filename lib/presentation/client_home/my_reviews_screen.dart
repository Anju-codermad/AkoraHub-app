import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';
import 'product_detail_client.dart';

/// "Mes avis laissés" (Profil client, Lot 3, 03/08) — tous les avis
/// (`product_reviews`, Phase 3) du client connecté, avec le badge
/// "Achat vérifié" (Phase 55) déjà utilisé sur la fiche produit et dans
/// la Communauté.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  List<Map<String, dynamic>> _reviews = [];
  Map<String, Map<String, dynamic>> _products = {};
  Set<String> _verifiedProductIds = {};
  bool _isLoading = true;
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null || !SupabaseConfig.isConfigured) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final reviews = await SupabaseConfig.client
          .from('product_reviews')
          .select()
          .eq('author_id', uid)
          .order('created_at', ascending: false);
      final reviewList = List<Map<String, dynamic>>.from(reviews);
      final productIds =
          reviewList.map((r) => r['product_id'] as String).toSet();

      Future<Map<String, Map<String, dynamic>>> loadProducts() async {
        if (productIds.isEmpty) return {};
        try {
          final rows = await SupabaseConfig.client
              .from('products')
              .select('id, name, price_detail, image_url')
              .inFilter('id', productIds.toList());
          return {
            for (final row in List<Map<String, dynamic>>.from(rows))
              row['id'] as String: row,
          };
        } catch (_) {
          return {};
        }
      }

      // Un avis par produit : un appel RPC par produit distinct plutôt
      // qu'un nouvel appel groupé — le nombre d'avis laissés par UN
      // client reste toujours petit.
      Future<Set<String>> loadVerified() async {
        final verified = <String>{};
        await Future.wait(productIds.map((pid) async {
          try {
            final result = await SupabaseConfig.client.rpc(
                'has_ordered_product', params: {'uid': uid, 'pid': pid});
            if (result == true) verified.add(pid);
          } catch (_) {}
        }));
        return verified;
      }

      final results = await Future.wait<dynamic>([
        loadProducts(),
        loadVerified(),
      ]);
      if (!mounted) return;
      setState(() {
        _reviews = reviewList;
        _products = results[0] as Map<String, Map<String, dynamic>>;
        _verifiedProductIds = results[1] as Set<String>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes avis')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _reviews.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 20.h),
                        Center(
                          child: Text('Vous n\'avez laissé aucun avis.',
                              style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(4.w),
                      itemCount: _reviews.length,
                      separatorBuilder: (_, __) => SizedBox(height: 1.h),
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        final product = _products[review['product_id']];
                        final isVerified =
                            _verifiedProductIds.contains(review['product_id']);
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: product?['image_url'] != null
                                  ? NetworkImage(product!['image_url'])
                                  : null,
                              child: product?['image_url'] == null
                                  ? const Icon(Icons.shopping_bag_outlined)
                                  : null,
                            ),
                            title: Text(product?['name'] ?? 'Produit'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(
                                      5,
                                      (i) => Icon(
                                        i < (review['rating'] ?? 0)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 14,
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      SizedBox(width: 2.w),
                                      Icon(Icons.verified,
                                          size: 14,
                                          color: theme.colorScheme.primary),
                                    ],
                                  ],
                                ),
                                if ((review['comment'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(review['comment']),
                                Text(
                                  _dateFormat.format(
                                      DateTime.parse(review['created_at'])),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: product == null
                                ? null
                                : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailClient(
                                            product: product),
                                      ),
                                    ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
