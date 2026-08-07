import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/formation/academie_repo.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/utils/formation_web_link.dart';
import '../../raw_materials_management/raw_material_style.dart';

/// Fiche détaillée d'une matière première, réservée à ceux qui l'ont
/// achetée (la RLS de `raw_materials` — phase45_patch_formation_per_product_pricing.sql
/// — bloque déjà l'accès serveur ; cet écran affiche un message clair
/// plutôt qu'un écran vide si jamais il est atteint sans achat validé,
/// ex: lien direct vers une fiche non achetée).
class RawMaterialDetailClient extends StatefulWidget {
  final String materialId;

  const RawMaterialDetailClient({super.key, required this.materialId});

  @override
  State<RawMaterialDetailClient> createState() =>
      _RawMaterialDetailClientState();
}

class _RawMaterialDetailClientState extends State<RawMaterialDetailClient> {
  Map<String, dynamic>? _material;
  List<String> _photos = [];
  List<Map<String, dynamic>> _usages = [];
  List<Map<String, dynamic>> _packaging = [];
  List<Map<String, dynamic>> _priceHistory = [];
  bool _isLoading = true;
  bool _accessDenied = false;
  int _photoIndex = 0;
  // "Académie Matières Premières" (06/08, fusionnée avec l'achat de base
  // le 06/08 — phase83) — fiche technique avancée automatiquement
  // débloquée pour quiconque a accès à cette fiche produit (voir
  // supabase/phase83_patch_fusion_academie_matieres.sql). null tant que
  // le staff n'a pas encore rempli cette fiche pour ce produit.
  Map<String, dynamic>? _academieSheet;
  final _currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('raw_materials')
            .select()
            .eq('id', widget.materialId)
            .maybeSingle(),
        SupabaseConfig.client
            .from('raw_material_images')
            .select('image_url')
            .eq('raw_material_id', widget.materialId)
            .order('position'),
        SupabaseConfig.client
            .from('raw_material_usages')
            .select('*, products(name)')
            .eq('raw_material_id', widget.materialId)
            .order('sort_order'),
        SupabaseConfig.client
            .from('raw_material_packaging')
            .select()
            .eq('raw_material_id', widget.materialId)
            .order('sort_order'),
        SupabaseConfig.client
            .from('raw_material_price_history')
            .select()
            .eq('raw_material_id', widget.materialId)
            .order('recorded_at'),
      ]);
      final material = results[0] as Map<String, dynamic>?;
      if (material == null) {
        setState(() {
          _isLoading = false;
          _accessDenied = true;
        });
        return;
      }
      final academieSheet = await AcademieRepo.fetchSheet(widget.materialId);
      setState(() {
        _material = material;
        _photos = List<Map<String, dynamic>>.from(results[1] as List)
            .map((r) => r['image_url'] as String)
            .toList();
        _usages = List<Map<String, dynamic>>.from(results[2] as List);
        _packaging = List<Map<String, dynamic>>.from(results[3] as List);
        _priceHistory = List<Map<String, dynamic>>.from(results[4] as List);
        _academieSheet = academieSheet;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _accessDenied = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_accessDenied || _material == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès réservé')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 48, color: theme.colorScheme.outline),
                SizedBox(height: 2.h),
                const Text(
                  'Cette fiche nécessite d\'avoir acheté l\'accès à ce produit.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                FilledButton(
                  onPressed: () => openFormationPurchaseWeb(context),
                  child: const Text('Acheter l\'accès'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final m = _material!;
    final status = m['stock_status'] as String? ?? 'en_stock';
    final usagesByDomain = <String, List<Map<String, dynamic>>>{};
    for (final u in _usages) {
      usagesByDomain.putIfAbsent(u['domain'] as String, () => []).add(u);
    }

    return Scaffold(
      appBar: AppBar(title: Text(rawMaterialShortName(m['name']))),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          ..._buildProductSection(theme, m, status, usagesByDomain),
          ..._buildAcademieSection(theme),
        ],
      ),
    );
  }

  List<Widget> _buildProductSection(
    ThemeData theme,
    Map<String, dynamic> m,
    String status,
    Map<String, List<Map<String, dynamic>>> usagesByDomain,
  ) {
    return [
          _buildGallery(theme),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Text(rawMaterialShortName(m['name']),
                    style: theme.textTheme.headlineSmall),
              ),
              Chip(
                label: Text(rawMaterialStatusLabel(status)),
                backgroundColor:
                    rawMaterialStatusColor(status).withValues(alpha: 0.15),
                labelStyle: TextStyle(color: rawMaterialStatusColor(status)),
              ),
            ],
          ),
          Row(
            children: [
              Icon(iconForChemicalCategory(m['category_name'] as String? ?? ''),
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(m['category_name'] ?? '', style: theme.textTheme.bodyMedium),
            ],
          ),
          if ((m['current_price'] as num?) != null) ...[
            SizedBox(height: 1.5.h),
            Text('Prix actuel : ${_currency.format(m['current_price'])}',
                style: theme.textTheme.titleMedium),
          ],
          if ((m['description'] as String?)?.isNotEmpty == true) ...[
            SizedBox(height: 2.h),
            Text('Description', style: theme.textTheme.titleMedium),
            SizedBox(height: 0.5.h),
            Text(m['description'] as String),
          ],
          if (usagesByDomain.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text('Utilise dans la fabrication de',
                style: theme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            for (final domain in rawMaterialUsageDomains)
              if (usagesByDomain[domain] != null) ...[
                Row(
                  children: [
                    Icon(iconForUsageDomain(domain),
                        size: 18, color: colorForUsageDomain(domain)),
                    const SizedBox(width: 6),
                    Text(domain,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: colorForUsageDomain(domain))),
                  ],
                ),
                SizedBox(height: 0.5.h),
                ...usagesByDomain[domain]!.map((u) {
                  final label = u['products'] is Map
                      ? u['products']['name'] as String?
                      : u['usage_label'] as String?;
                  return Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(label ?? '')),
                        if ((u['dosage'] as String?)?.isNotEmpty == true)
                          Chip(
                            label: Text(u['dosage'],
                                style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 1.h),
              ],
          ],
          if (_packaging.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text('Conditionnement', style: theme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _packaging.map((p) {
                final price = p['price'] as num?;
                return Chip(
                  avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: Text(price != null
                      ? '${p['label']} — ${_currency.format(price)}'
                      : p['label'] ?? ''),
                );
              }).toList(),
            ),
          ],
          if (_priceHistory.isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text('Historique de prix', style: theme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            if (_priceHistory.length >= 2)
              _PriceHistorySparkline(entries: _priceHistory),
            SizedBox(height: 1.h),
            ..._priceHistory.reversed.map((entry) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timeline_outlined),
                  title: Text(_currency.format(entry['price'])),
                  subtitle: Text([
                    _dateFormat.format(DateTime.parse(entry['recorded_at'])),
                    if (entry['note'] != null) entry['note'],
                  ].join(' · ')),
                )),
          ],
          SizedBox(height: 4.h),
    ];
  }

  /// Section "Académie" (06/08, fusionnée avec l'achat de base le 06/08
  /// — phase83) — fiche technique avancée, automatiquement débloquée
  /// pour quiconque a accès à cette fiche produit (plus d'achat séparé).
  /// Affichée dans le MÊME scroll que la fiche produit, à la suite,
  /// sans titre "Académie" ni séparateur.
  List<Widget> _buildAcademieSection(ThemeData theme) {
    final sheet = _academieSheet;
    if (sheet == null) {
      return [
        SizedBox(height: 1.h),
        Text(
          'Fiche technique en cours de préparation par notre équipe pour ce produit.',
          style: theme.textTheme.bodySmall
              ?.copyWith(fontStyle: FontStyle.italic),
        ),
      ];
    }

    final epi = List<String>.from(sheet['epi_requis'] as List? ?? []);
    final usages = List<Map<String, dynamic>>.from(sheet['usages'] as List? ?? []);
    Widget field(String label, String? value) {
      if (value == null || value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
            Text(value),
          ],
        ),
      );
    }

    return [
        if ((sheet['statut_verification'] as String?) == 'a_valider')
          Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('⚠️ À vérifier en labo')),
              ],
            ),
          ),
        field('Nom chimique', sheet['nom_chimique'] as String?),
        field('Synonymes', sheet['synonymes'] as String?),
        field('Grade', sheet['grade'] as String?),
        field('Aspect', sheet['aspect'] as String?),
        field('pH en solution', sheet['ph_solution'] as String?),
        field('Solubilité', sheet['solubilite'] as String?),
        field('Particularité', sheet['particularite'] as String?),
        field('Différence avec un produit similaire',
            sheet['difference_produit_similaire'] as String?),
        if ((sheet['niveau_danger'] as String?)?.isNotEmpty == true) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Niveau de danger / précaution',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(color: Colors.red)),
                      Text(sheet['niveau_danger'] as String),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (epi.isNotEmpty) ...[
          Text('EPI requis',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: epi
                .map((e) => Chip(
                      avatar: const Icon(Icons.shield_outlined, size: 16),
                      label: Text(e),
                    ))
                .toList(),
          ),
          SizedBox(height: 1.5.h),
        ],
        field('Premiers secours', sheet['premiers_secours'] as String?),
        field('Incompatibilités', sheet['incompatibilites'] as String?),
        field('Stockage', sheet['stockage'] as String?),
        if (usages.isNotEmpty) ...[
          SizedBox(height: 1.h),
          Text('Usages détaillés', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          ...usages.map((u) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(u['domaine_application'] ?? '',
                                style: theme.textTheme.titleSmall),
                          ),
                          if (u['a_verifier_labo'] == true)
                            const Tooltip(
                              message: 'À vérifier en labo',
                              child: Icon(Icons.warning_amber_outlined,
                                  color: Colors.orange, size: 18),
                            ),
                        ],
                      ),
                      if ((u['technique_methode'] as String?)?.isNotEmpty == true)
                        Text(u['technique_methode']),
                      if ((u['dosage_legacy'] as String?)?.isNotEmpty == true)
                        Text('Dosage : ${u['dosage_legacy']}',
                            style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              )),
        ],
        SizedBox(height: 4.h),
    ];
  }

  Widget _buildGallery(ThemeData theme) {
    final photos = _photos.isNotEmpty
        ? _photos
        : ((_material!['image_url'] as String?)?.isNotEmpty == true
            ? [_material!['image_url'] as String]
            : <String>[]);
    if (photos.isEmpty) {
      return Container(
        height: 20.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.science_outlined,
            size: 56, color: theme.colorScheme.outline),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 20.h,
            width: double.infinity,
            child: PageView.builder(
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _photoIndex = i),
              itemBuilder: (context, i) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Image.network(
                  photos[i],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Icon(
                    Icons.science_outlined,
                    size: 56,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (photos.length > 1) ...[
          SizedBox(height: 1.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < photos.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _photoIndex
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Petite courbe d'évolution du prix, dessinée à la main (pas de
/// dépendance de graphique) — juste assez pour visualiser la tendance.
class _PriceHistorySparkline extends StatelessWidget {
  final List<Map<String, dynamic>> entries;

  const _PriceHistorySparkline({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prices = entries.map((e) => (e['price'] as num).toDouble()).toList();
    return SizedBox(
      height: 12.h,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          prices: prices,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  _SparklinePainter({required this.prices, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final range = (maxPrice - minPrice).abs() < 0.001 ? 1 : maxPrice - minPrice;
    const padding = 8.0;
    final usableHeight = size.height - padding * 2;
    final usableWidth = size.width;
    final step = usableWidth / (prices.length - 1);

    Offset pointAt(int i) {
      final x = step * i;
      final normalized = (prices[i] - minPrice) / range;
      final y = padding + usableHeight - (normalized * usableHeight);
      return Offset(x, y);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < prices.length; i++) {
      final p = pointAt(i);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = color;
    for (var i = 0; i < prices.length; i++) {
      canvas.drawCircle(pointAt(i), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.prices != prices || oldDelegate.color != color;
}
