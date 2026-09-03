import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/formation/formation_repo.dart';
import '../../core/notifications/product_stock_alert_repo.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/reference_data/reference_table_cache.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/utils/formation_web_link.dart';
import '../../core/utils/price_unit.dart';
import '../raw_materials_management/raw_material_style.dart';
import 'catalog_tab.dart' show ProductCard;
import 'community/public_profiles_repo.dart';
import 'favorites_provider.dart';
import 'formation/raw_material_detail_client.dart';
import 'usual_cart_provider.dart';

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
  String? _selectedConcentrationId;
  List<String> _photos = [];
  int _photoIndex = 0;
  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  // Lien fiche Académie (09/08) — voir `_loadAcademieLink`.
  String? _rawMaterialId;
  Map<String, dynamic>? _academieSummary;
  bool _hasFormationAccess = false;

  @override
  void initState() {
    super.initState();
    _loadVariants();
    _loadPhotos();
    _loadAcademieLink();
  }

  /// Résumé sécurité gratuit + statut d'accès Formation, pour la section
  /// "Fiche sécurité" (09/08, demande explicite : le résumé — niveau de
  /// danger, usages généraux, description — reste gratuit, le détail
  /// technique complet — dosages, EPI, premiers secours — reste réservé
  /// à l'achat Formation existant, voir `academie_summary_public` et
  /// `has_purchased_raw_material`, phase147/phase45).
  ///
  /// Requête `raw_material_id` fraîche plutôt que de se fier à
  /// `widget.product` : selon l'écran d'où on arrive (mur, favoris,
  /// scanner...), le `Map` passé en paramètre ne contient pas forcément
  /// toutes les colonnes de `products` (certains écrans ne sélectionnent
  /// qu'un sous-ensemble de champs).
  Future<void> _loadAcademieLink() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final row = await SupabaseConfig.client
          .from('products')
          .select('raw_material_id')
          .eq('id', widget.product['id'])
          .maybeSingle();
      final materialId = row?['raw_material_id'] as String?;
      if (materialId == null) return;
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('academie_summary_public')
            .select()
            .eq('matiere_premiere_id', materialId)
            .maybeSingle(),
        FormationRepo.fetchMyPurchasedIds(),
      ]);
      if (!mounted) return;
      setState(() {
        _rawMaterialId = materialId;
        _academieSummary = results[0] as Map<String, dynamic>?;
        _hasFormationAccess =
            (results[1] as Set<String>).contains(materialId);
      });
    } catch (_) {
      // Repli silencieux : migration phase147 pas encore exécutée, produit
      // sans matière liée, ou hors-ligne — la section reste masquée.
    }
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
          .select('*, formats(name), parfums(name), concentrations(name)')
          .eq('product_id', widget.product['id']);
      final variants = List<Map<String, dynamic>>.from(data);
      setState(() {
        _variants = variants;
        if (variants.isNotEmpty) {
          final defaultVariant = _defaultVariantInKg(variants) ?? variants.first;
          _selectedFormatId = defaultVariant['format_id'];
          _selectedParfumId = defaultVariant['parfum_id'];
          _selectedConcentrationId = defaultVariant['concentration_id'];
        }
        _isLoadingVariants = false;
      });
    } catch (_) {
      setState(() => _isLoadingVariants = false);
    }
  }

  /// Choisit le format présélectionné à l'ouverture de la fiche produit
  /// (24/08, sur demande) : quand plusieurs conditionnements existent,
  /// privilégier celui en kg (le plus petit, ex. "1 kg" plutôt que "Sac
  /// 25 kg") au lieu du 1er variant renvoyé par la requête (ordre non
  /// garanti). S'appuie sur `formats.base_unit_quantity` (phase172) : un
  /// format en grammes a une valeur < 1 (ex. 0.5 pour "500 g"), donc ce
  /// filtre `>= 1` exclut naturellement les formats en grammes sans avoir
  /// à analyser le texte du nom. Retourne null si aucun format en kg
  /// n'existe parmi les variantes (repli sur le 1er variant, inchangé).
  Map<String, dynamic>? _defaultVariantInKg(
      List<Map<String, dynamic>> variants) {
    final formats = ref.read(formatsCacheProvider);
    Map<String, dynamic>? best;
    num? bestQty;
    for (final v in variants) {
      final format = formats.firstWhere(
        (f) => f['id'] == v['format_id'],
        orElse: () => <String, dynamic>{},
      );
      final qty = format['base_unit_quantity'] as num?;
      if (qty != null && qty >= 1 && (bestQty == null || qty < bestQty)) {
        bestQty = qty;
        best = v;
      }
    }
    return best;
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

  // Axe dédié (25/08) : distinct de Parfum, pour les produits vendus par
  // concentration/degré (Eau de Javel, Peroxyde d'hydrogène) plutôt que
  // par senteur — voir phase183_patch_concentration_axis.sql.
  List<Map<String, dynamic>> get _availableConcentrations {
    final seen = <String>{};
    final list = <Map<String, dynamic>>[];
    for (final v in _variants) {
      if (v['format_id'] != _selectedFormatId) continue;
      if (v['parfum_id'] != _selectedParfumId) continue;
      final id = v['concentration_id'] as String?;
      if (id != null && seen.add(id)) {
        list.add({'id': id, 'name': v['concentrations']?['name'] ?? ''});
      }
    }
    return list;
  }

  Map<String, dynamic>? get _selectedVariant {
    for (final v in _variants) {
      if (v['format_id'] == _selectedFormatId &&
          v['parfum_id'] == _selectedParfumId &&
          v['concentration_id'] == _selectedConcentrationId) {
        return v;
      }
    }
    // Replis successifs, du plus proche au plus large.
    for (final v in _variants) {
      if (v['format_id'] == _selectedFormatId &&
          v['parfum_id'] == _selectedParfumId) {
        return v;
      }
    }
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
    final unitLabel =
        unitSuffixFromFormatName(variant?['formats']?['name'] as String?);
    final unitSuffix = unitLabel != null ? '/$unitLabel' : '';

    final isFavorite = ref.watch(favoritesProvider).contains(p['id']);
    final isInUsualCart = ref.watch(usualCartProvider).contains(p['id']);
    // Même convention que ProductCard (catalog_tab.dart) pour la rupture
    // de stock (06/08, "M'alerter quand disponible").
    final stockQty = (p['stock_quantity'] as num?)?.toDouble();
    final outOfStock = stockQty != null && stockQty <= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(p['name'] ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Partager',
            onPressed: () {
              // Lien produit partageable (24/08) — ouvre directement la
              // fiche si AkoraHub est déjà installée, sinon propose le
              // téléchargement (voir docs/formation-access/produit.html
              // et core/deeplink/deep_link_service.dart).
              final link =
                  'https://groupe-akora.com/produit.html?id=${p['id']}';
              SharePlus.instance.share(ShareParams(
                text: '${p['name'] ?? 'Ce produit'} — '
                    '${_currency.format(priceDetail)}$unitSuffix sur AkoraHub\n$link',
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
          IconButton(
            icon: Icon(isInUsualCart
                ? Icons.shopping_bag
                : Icons.shopping_bag_outlined),
            tooltip: isInUsualCart
                ? 'Retirer du panier habituel'
                : 'Ajouter au panier habituel',
            onPressed: () =>
                ref.read(usualCartProvider.notifier).toggle(p['id']),
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
                // Photo propre à la variante sélectionnée (25/08, ex. Eau
                // de Javel 9°/12°/18° — étiquette différente par degré)
                // prioritaire sur tout le reste ; sinon `_photos` (table
                // product_images) ; sinon repli sur la couverture unique
                // `image_url` ; sinon icône.
                final variantPhoto = variant?['image_url'] as String?;
                final photos = (variantPhoto?.isNotEmpty == true)
                    ? [variantPhoto!]
                    : (_photos.isNotEmpty
                        ? _photos
                        : ((p['image_url'] as String?)?.isNotEmpty == true
                            ? [p['image_url'] as String]
                            : <String>[]));
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
              if (_rawMaterialId != null && _academieSummary != null) ...[
                SizedBox(height: 1.5.h),
                _AcademieSummaryCard(
                  summary: _academieSummary!,
                  hasAccess: _hasFormationAccess,
                  onOpenFull: () {
                    if (_hasFormationAccess) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RawMaterialDetailClient(
                              materialId: _rawMaterialId!),
                        ),
                      );
                    } else {
                      openFormationPurchaseWeb(context);
                    }
                  },
                ),
              ],
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
                    // Réinitialise parfum/concentration si le choix
                    // précédent n'est plus valide pour ce format.
                    final validParfums = _availableParfums.map((e) => e['id']);
                    if (!validParfums.contains(_selectedParfumId)) {
                      _selectedParfumId = _availableParfums.isNotEmpty
                          ? _availableParfums.first['id']
                          : null;
                    }
                    final validConcentrations =
                        _availableConcentrations.map((e) => e['id']);
                    if (!validConcentrations.contains(_selectedConcentrationId)) {
                      _selectedConcentrationId =
                          _availableConcentrations.isNotEmpty
                              ? _availableConcentrations.first['id']
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
                    onChanged: (v) => setState(() {
                      _selectedParfumId = v;
                      final validConcentrations =
                          _availableConcentrations.map((e) => e['id']);
                      if (!validConcentrations
                          .contains(_selectedConcentrationId)) {
                        _selectedConcentrationId =
                            _availableConcentrations.isNotEmpty
                                ? _availableConcentrations.first['id']
                                : null;
                      }
                    }),
                  ),
                ],
                if (_availableConcentrations.isNotEmpty) ...[
                  SizedBox(height: 1.5.h),
                  Text('Concentration', style: theme.textTheme.titleSmall),
                  SizedBox(height: 0.5.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedConcentrationId,
                    decoration: const InputDecoration(isDense: true),
                    items: _availableConcentrations
                        .map((f) => DropdownMenuItem(
                              value: f['id'] as String,
                              child: Text(f['name']),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedConcentrationId = v),
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
                    Text(
                        'Prix Détail : ${_currency.format(priceDetail)}$unitSuffix'),
                    Text(
                        'Prix Gros (dès $threshold unités) : ${_currency.format(priceGros)}$unitSuffix'),
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
              if (outOfStock) ...[
                _StockAlertButton(productId: p['id']),
                SizedBox(height: 1.5.h),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: outOfStock
                          ? null
                          : () {
                        final formatName = variant?['formats']?['name'];
                        final parfumName = variant?['parfums']?['name'];
                        final concentrationName =
                            variant?['concentrations']?['name'];
                        final label = [
                          p['name'] ?? '',
                          if (formatName != null) formatName,
                          if (parfumName != null) parfumName,
                          if (concentrationName != null) concentrationName,
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
                      child: Text(
                          outOfStock ? 'Rupture de stock' : 'Ajouter au panier'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              _BoughtTogetherSection(productId: p['id'], currency: _currency),
              _SimilarProductsSection(
                  productId: p['id'],
                  category: p['category'],
                  currency: _currency),
              _ReviewsSection(productId: p['id']),
            ],
          ),
        ),
      ),
    );
  }
}

/// "M'alerter quand disponible" (06/08) — bascule un abonnement (voir
/// `ProductStockAlertRepo` + supabase/phase77_patch_product_stock_alerts.sql)
/// pour recevoir une notification push dès que ce produit repasse en
/// stock. Un client déjà abonné voit un bouton désactivé "Vous serez
/// alerté" pour éviter un double abonnement (contrainte unique côté SQL
/// de toute façon, mais ça évite l'aller-retour réseau inutile).
class _StockAlertButton extends StatefulWidget {
  final String productId;

  const _StockAlertButton({required this.productId});

  @override
  State<_StockAlertButton> createState() => _StockAlertButtonState();
}

class _StockAlertButtonState extends State<_StockAlertButton> {
  bool _isSubscribed = false;
  bool _isLoading = true;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final subscribed = await ProductStockAlertRepo.isSubscribed(widget.productId);
    if (!mounted) return;
    setState(() {
      _isSubscribed = subscribed;
      _isLoading = false;
    });
  }

  Future<void> _toggle() async {
    setState(() => _isToggling = true);
    try {
      if (_isSubscribed) {
        await ProductStockAlertRepo.unsubscribe(widget.productId);
      } else {
        await ProductStockAlertRepo.subscribe(widget.productId);
      }
      if (!mounted) return;
      setState(() {
        _isSubscribed = !_isSubscribed;
        _isToggling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSubscribed
            ? 'Vous serez alerté dès que ce produit sera de nouveau en stock.'
            : 'Alerte annulée.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isToggling = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Impossible de mettre à jour cette alerte (migration phase77 exécutée ?).')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final icon = Icon(_isSubscribed
        ? Icons.notifications_active
        : Icons.notifications_none);
    final label = Text(_isSubscribed
        ? 'Vous serez alerté (toucher pour annuler)'
        : 'M\'alerter quand disponible');
    return SizedBox(
      width: double.infinity,
      child: _isSubscribed
          ? OutlinedButton.icon(
              onPressed: _isToggling ? null : _toggle,
              icon: icon,
              label: label,
            )
          : FilledButton.icon(
              onPressed: _isToggling ? null : _toggle,
              icon: icon,
              label: label,
            ),
    );
  }
}

/// "Vous pourriez aussi aimer" (06/08) — produits achetés dans la même
/// commande que celui-ci par n'importe quel client, voir
/// `products_bought_together` (supabase/phase75). Panier-jumelage
/// classique du e-commerce ; pas de personnalisation par client ici
/// (contrairement au fil "Pour toi" de la Communauté, wall_tab.dart).
/// Masquée si vide (produit jamais commandé avec un autre, ou migration
/// phase75 pas encore exécutée).
class _BoughtTogetherSection extends ConsumerStatefulWidget {
  final String productId;
  final NumberFormat currency;

  const _BoughtTogetherSection(
      {required this.productId, required this.currency});

  @override
  ConsumerState<_BoughtTogetherSection> createState() =>
      _BoughtTogetherSectionState();
}

class _BoughtTogetherSectionState
    extends ConsumerState<_BoughtTogetherSection> {
  List<Map<String, dynamic>> _recommended = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final ranked = await SupabaseConfig.client.rpc(
        'products_bought_together',
        params: {'pid': widget.productId, 'max_results': 8},
      );
      final rankedIds = List<Map<String, dynamic>>.from(ranked)
          .map((r) => r['product_id'] as String)
          .toList();
      if (rankedIds.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final products = await SupabaseConfig.client
          .from('products')
          .select()
          .inFilter('id', rankedIds);
      final byId = {
        for (final row in List<Map<String, dynamic>>.from(products))
          row['id'] as String: row,
      };
      if (!mounted) return;
      setState(() {
        _recommended = [
          for (final id in rankedIds)
            if (byId.containsKey(id)) byId[id]!,
        ];
        _isLoading = false;
      });
    } catch (_) {
      // Repli silencieux : migration phase75 pas encore exécutée, ou
      // hors-ligne — la section reste simplement masquée.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _quickAdd(Map<String, dynamic> product) {
    ref.read(cartProvider.notifier).addItem(
          CartItem(
            productId: product['id'],
            name: product['name'] ?? '',
            priceDetail: (product['price_detail'] ?? 0).toDouble(),
            priceGros: (product['price_gros'] ?? 0).toDouble(),
            grosThresholdQty: (product['gros_threshold_qty'] ?? 10) as int,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ajouté au panier'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _recommended.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vous pourriez aussi aimer',
              style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          SizedBox(
            height: 26.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommended.length,
              itemBuilder: (context, index) {
                final p = _recommended[index];
                return Padding(
                  padding: EdgeInsets.only(right: 3.w),
                  child: SizedBox(
                    width: 38.w,
                    child: ProductCard(
                      product: p,
                      currency: widget.currency,
                      isFavorite:
                          ref.watch(favoritesProvider).contains(p['id']),
                      enableHero: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailClient(product: p),
                          ),
                        );
                      },
                      onQuickAdd: () => _quickAdd(p),
                      onToggleFavorite: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(p['id']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "Produits similaires" (09/08) — autres produits de la même catégorie,
/// même structure que `_BoughtTogetherSection` juste au-dessus (carrousel
/// horizontal de `ProductCard`) mais scoping par `category` plutôt que
/// par co-achat.
class _SimilarProductsSection extends ConsumerStatefulWidget {
  final String productId;
  final String? category;
  final NumberFormat currency;

  const _SimilarProductsSection(
      {required this.productId,
      required this.category,
      required this.currency});

  @override
  ConsumerState<_SimilarProductsSection> createState() =>
      _SimilarProductsSectionState();
}

class _SimilarProductsSectionState
    extends ConsumerState<_SimilarProductsSection> {
  List<Map<String, dynamic>> _similar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final category = widget.category;
    if (!SupabaseConfig.isConfigured ||
        category == null ||
        category.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final rows = await SupabaseConfig.client
          .from('products')
          .select()
          .eq('category', category)
          .eq('visibility', true)
          .neq('id', widget.productId)
          .limit(8);
      if (!mounted) return;
      setState(() {
        _similar = List<Map<String, dynamic>>.from(rows);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _quickAdd(Map<String, dynamic> product) {
    ref.read(cartProvider.notifier).addItem(
          CartItem(
            productId: product['id'],
            name: product['name'] ?? '',
            priceDetail: (product['price_detail'] ?? 0).toDouble(),
            priceGros: (product['price_gros'] ?? 0).toDouble(),
            grosThresholdQty: (product['gros_threshold_qty'] ?? 10) as int,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ajouté au panier'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _similar.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 3.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Produits similaires', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          SizedBox(
            height: 26.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _similar.length,
              itemBuilder: (context, index) {
                final p = _similar[index];
                return Padding(
                  padding: EdgeInsets.only(right: 3.w),
                  child: SizedBox(
                    width: 38.w,
                    child: ProductCard(
                      product: p,
                      currency: widget.currency,
                      isFavorite:
                          ref.watch(favoritesProvider).contains(p['id']),
                      enableHero: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailClient(product: p),
                          ),
                        );
                      },
                      onQuickAdd: () => _quickAdd(p),
                      onToggleFavorite: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(p['id']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte "Fiche sécurité" (09/08) — résumé gratuit (niveau de danger,
/// domaines d'usage, particularité) toujours visible ; le détail complet
/// (dosages, EPI, premiers secours, incompatibilités...) reste réservé à
/// l'achat Formation existant (`RawMaterialDetailClient`, verrouillé côté
/// serveur par RLS — voir `has_purchased_raw_material`).
class _AcademieSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  final bool hasAccess;
  final VoidCallback onOpenFull;

  const _AcademieSummaryCard({
    required this.summary,
    required this.hasAccess,
    required this.onOpenFull,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final niveauDanger = summary['niveau_danger'] as String?;
    final particularite = summary['particularite'] as String?;
    final domaines =
        (summary['domaines_usage'] as List?)?.whereType<String>().toList() ??
            const <String>[];
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined,
                  size: 18, color: theme.colorScheme.primary),
              SizedBox(width: 2.w),
              Text('Fiche sécurité', style: theme.textTheme.titleSmall),
              if (niveauDanger != null && niveauDanger.isNotEmpty) ...[
                const Spacer(),
                Chip(
                  label: Text(niveauDanger),
                  backgroundColor:
                      dangerLevelColor(niveauDanger).withValues(alpha: 0.18),
                  labelStyle: TextStyle(
                      color: dangerLevelColor(niveauDanger),
                      fontWeight: FontWeight.w700,
                      fontSize: 11),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          if (domaines.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Wrap(
              spacing: 1.5.w,
              runSpacing: 0.5.h,
              children: [
                for (final d in domaines)
                  Chip(
                    label: Text(d, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          if (particularite != null && particularite.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(particularite, style: theme.textTheme.bodySmall),
          ],
          SizedBox(height: 1.h),
          if (hasAccess)
            TextButton.icon(
              onPressed: onOpenFull,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Voir la fiche technique complète'),
            )
          else
            Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 16, color: theme.colorScheme.outline),
                SizedBox(width: 1.5.w),
                Expanded(
                  child: Text(
                    'Dosages, EPI et premiers secours réservés aux '
                    'détenteurs de l\'accès Formation.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
                TextButton(
                  onPressed: onOpenFull,
                  child: const Text('Débloquer'),
                ),
              ],
            ),
        ],
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
