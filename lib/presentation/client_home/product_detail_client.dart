import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'community/public_profiles_repo.dart';
import 'favorites_provider.dart';

class ProductDetailClient extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailClient({super.key, required this.product});

  @override
  ConsumerState<ProductDetailClient> createState() =>
      _ProductDetailClientState();
}

class _ProductDetailClientState extends ConsumerState<ProductDetailClient> {
  int _quantity = 1;
  bool _isLoadingVariants = true;
  List<Map<String, dynamic>> _variants = [];
  String? _selectedFormatId;
  String? _selectedParfumId;
  List<String> _photos = [];
  int _photoIndex = 0;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadVariants();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final data = await SupabaseConfig.client
          .from('product_images')
          .select('image_url')
          .eq('product_id', widget.product['id'])
          .order('position');
      final urls = List<Map<String, dynamic>>.from(data)
          .map((row) => row['image_url'] as String)
          .toList();
      if (mounted && urls.isNotEmpty) {
        setState(() => _photos = urls);
      }
    } catch (_) {
      // Table `product_images` pas encore créée (migration phase8 non
      // exécutée) : on se rabat sur `image_url` (couverture) ci-dessous.
    }
  }

  Future<void> _loadVariants() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() => _isLoadingVariants = false);
      return;
    }
    try {
      final data = await SupabaseConfig.client
          .from('product_variants')
          .select('*, formats(name), parfums(name)')
          .eq('product_id', widget.product['id']);
      final variants = List<Map<String, dynamic>>.from(data);
      setState(() {
        _variants = variants;
        if (variants.isNotEmpty) {
          _selectedFormatId = variants.first['format_id'];
          _selectedParfumId = variants.first['parfum_id'];
        }
        _isLoadingVariants = false;
      });
    } catch (_) {
      setState(() => _isLoadingVariants = false);
    }
  }

  List<Map<String, dynamic>> get _availableFormats {
    final seen = <String>{};
    final list = <Map<String, dynamic>>[];
    for (final v in _variants) {
      final id = v['format_id'] as String?;
      if (id != null && seen.add(id)) {
        list.add({'id': id, 'name': v['formats']?['name'] ?? ''});
      }
    }
    return list;
  }

  List<Map<String, dynamic>> get _availableParfums {
    final seen = <String>{};
    final list = <Map<String, dynamic>>[];
    for (final v in _variants) {
      if (v['format_id'] != _selectedFormatId) continue;
      final id = v['parfum_id'] as String?;
      if (id != null && seen.add(id)) {
        list.add({'id': id, 'name': v['parfums']?['name'] ?? ''});
      }
    }
    return list;
  }

  Map<String, dynamic>? get _selectedVariant {
    for (final v in _variants) {
      if (v['format_id'] == _selectedFormatId &&
          v['parfum_id'] == _selectedParfumId) {
        return v;
      }
    }
    // Repli : le premier variant correspondant au format, peu importe le parfum.
    for (final v in _variants) {
      if (v['format_id'] == _selectedFormatId) return v;
    }
    return _variants.isNotEmpty ? _variants.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.product;
    final variant = _selectedVariant;
    final hasVariants = _variants.isNotEmpty;

    // Repli sur les prix du produit lui-même si aucune variante n'existe.
    final priceDetail = (variant?['price_detail'] ?? p['price_detail'] ?? 0)
        .toDouble();
    final priceGros =
        (variant?['price_gros'] ?? p['price_gros'] ?? 0).toDouble();
    final threshold =
        (variant?['gros_threshold_qty'] ?? p['gros_threshold_qty'] ?? 10)
            as int;
    final isGros = _quantity >= threshold;
    final unitPrice = isGros ? priceGros : priceDetail;
    final total = unitPrice * _quantity;

    final isFavorite = ref.watch(favoritesProvider).contains(p['id']);

    return Scaffold(
      appBar: AppBar(
        title: Text(p['name'] ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Partager',
            onPressed: () {
              final price = (p['price_detail'] as num?)?.toDouble() ?? 0;
              SharePlus.instance.share(ShareParams(
                text: '${p['name'] ?? 'Ce produit'} — '
                    '${_currency.format(price)} sur AkoraHub',
              ));
            },
          ),
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border),
            color: isFavorite ? Colors.amber : null,
            tooltip: isFavorite
                ? 'Retirer des favoris'
                : 'Ajouter aux favoris',
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggle(p['id']),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(builder: (context) {
                // `_photos` (table product_images) prime si dispo ; sinon
                // repli sur la couverture unique `image_url` ; sinon icône.
                final photos = _photos.isNotEmpty
                    ? _photos
                    : ((p['image_url'] as String?)?.isNotEmpty == true
                        ? [p['image_url'] as String]
                        : <String>[]);
                if (photos.isEmpty) {
                  return Container(
                    height: 20.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.inventory_2_outlined,
                        size: 56, color: theme.colorScheme.outline),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 20.h,
                        width: double.infinity,
                        child: PageView.builder(
                          itemCount: photos.length,
                          onPageChanged: (i) =>
                              setState(() => _photoIndex = i),
                          itemBuilder: (context, i) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Hero(
                              // Seule la 1ère photo partage le tag de la
                              // vignette catalogue/favoris (celle qu'on
                              // voit avant l'ouverture de cette fiche) —
                              // les suivantes ont un tag unique pour ne
                              // jamais entrer en conflit dans le PageView.
                              tag: i == 0
                                  ? 'product-image-${p['id']}'
                                  : 'product-image-${p['id']}-$i',
                              child: Image.network(
                                photos[i],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) => Icon(
                                  Icons.inventory_2_outlined,
                                  size: 56,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (photos.length > 1) ...[
                      SizedBox(height: 1.h),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < photos.length; i++)
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _photoIndex
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline
                                          .withValues(alpha: 0.3),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              }),
              SizedBox(height: 2.h),
              Text(p['name'] ?? '', style: theme.textTheme.headlineSmall),
              if ((p['category'] ?? '').toString().isNotEmpty) ...[
                SizedBox(height: 0.5.h),
                Chip(
                  label: Text(p['category']),
                  visualDensity: VisualDensity.compact,
                ),
              ],
              if ((p['use_cases'] as List?)?.isNotEmpty ?? false) ...[
                SizedBox(height: 1.h),
                Text('Usages', style: theme.textTheme.labelLarge),
                SizedBox(height: 0.5.h),
                Wrap(
                  spacing: 2.w,
                  runSpacing: 0.8.h,
                  children: [
                    for (final usage in (p['use_cases'] as List))
                      Chip(
                        avatar: Icon(Icons.check_circle,
                            size: 16, color: theme.colorScheme.primary),
                        label: Text(usage.toString()),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.35),
                      ),
                  ],
                ),
              ],
              SizedBox(height: 1.h),
              if ((p['description'] ?? '').toString().isNotEmpty)
                Text(p['description'], style: theme.textTheme.bodyMedium),
              SizedBox(height: 2.h),

              if (_isLoadingVariants)
                const Center(child: CircularProgressIndicator())
              else if (hasVariants) ...[
                Text('Format', style: theme.textTheme.titleSmall),
                SizedBox(height: 0.5.h),
                DropdownButtonFormField<String>(
                  initialValue: _selectedFormatId,
                  decoration: const InputDecoration(isDense: true),
                  items: _availableFormats
                      .map((f) => DropdownMenuItem(
                            value: f['id'] as String,
                            child: Text(f['name']),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _selectedFormatId = v;
                    // Réinitialise le parfum si celui choisi n'est plus valide.
                    final valid = _availableParfums.map((e) => e['id']);
                    if (!valid.contains(_selectedParfumId)) {
                      _selectedParfumId =
                          _availableParfums.isNotEmpty
                              ? _availableParfums.first['id']
                              : null;
                    }
                  }),
                ),
                if (_availableParfums.isNotEmpty) ...[
                  SizedBox(height: 1.5.h),
                  Text('Parfum', style: theme.textTheme.titleSmall),
                  SizedBox(height: 0.5.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedParfumId,
                    decoration: const InputDecoration(isDense: true),
                    items: _availableParfums
                        .map((f) => DropdownMenuItem(
                              value: f['id'] as String,
                              child: Text(f['name']),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedParfumId = v),
                  ),
                ],
                SizedBox(height: 2.h),
              ],

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
                        final formatName = variant?['formats']?['name'];
                        final parfumName = variant?['parfums']?['name'];
                        final label = [
                          p['name'] ?? '',
                          if (formatName != null) formatName,
                          if (parfumName != null) parfumName,
                        ].join(' - ');

                        ref.read(cartProvider.notifier).addItem(CartItem(
                              productId: variant?['id'] ?? p['id'],
                              name: label,
                              priceDetail: priceDetail,
                              priceGros: priceGros,
                              grosThresholdQty: threshold,
                              quantity: _quantity,
                            ));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$label ajouté au panier'),
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
  Map<String, Map<String, dynamic>> _authorProfiles = {};
  Set<String> _verifiedAuthorIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  /// Corrige au passage un bug déjà présent : l'ancien `.select('*,
  /// profiles(full_name, company_name)')` ne fonctionnait JAMAIS pour les
  /// avis d'un autre client — la RLS de `profiles` limite la lecture à sa
  /// propre ligne (voir supabase/phase9_patch_public_profiles.sql), donc
  /// cette jointure imbriquée renvoyait toujours `null` et l'affichage
  /// retombait silencieusement sur "Client". Remplacé par
  /// `PublicProfilesRepo.fetchByIds`, le même chemin déjà utilisé partout
  /// ailleurs pour afficher le nom des AUTRES clients (Communauté, amis).
  ///
  /// Ajoute aussi "Achat vérifié" (Lot 5 Communauté, 02/08) : un appel
  /// groupé à `verified_reviewers` (voir
  /// supabase/phase55_patch_verified_purchases_reviews.sql) plutôt qu'un
  /// appel par avis.
  Future<void> _loadReviews() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('product_reviews')
            .select()
            .eq('product_id', widget.productId)
            .order('created_at', ascending: false),
        SupabaseConfig.client
            .rpc('verified_reviewers', params: {'pid': widget.productId}),
      ]);
      final reviews = List<Map<String, dynamic>>.from(results[0] as List);
      final verifiedIds = List<Map<String, dynamic>>.from(results[1] as List)
          .map((r) => r['author_id'] as String)
          .toSet();
      final authorIds =
          reviews.map((r) => r['author_id'] as String).toSet();
      final profiles = await PublicProfilesRepo.fetchByIds(authorIds);
      setState(() {
        _reviews = reviews;
        _verifiedAuthorIds = verifiedIds;
        _authorProfiles = profiles;
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
            final authorId = r['author_id'] as String;
            final name =
                PublicProfilesRepo.displayName(_authorProfiles[authorId]);
            final isVerified = _verifiedAuthorIds.contains(authorId);
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
                      if (isVerified) ...[
                        SizedBox(width: 2.w),
                        Tooltip(
                          message:
                              'Ce client a réellement commandé ce produit',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  size: 14,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 2),
                              Text('Achat vérifié',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                          color: theme.colorScheme.primary)),
                            ],
                          ),
                        ),
                      ],
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
