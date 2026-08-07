import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/formation/academie_repo.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/utils/formation_web_link.dart';
import '../../raw_materials_management/raw_material_style.dart';

/// Formate le dosage structuré d'un usage détaillé (phase85) en un
/// badge lisible, ex : "1–5 %" (plage), "2 %" (valeur unique),
/// "Dilution 1:10". Retombe sur l'ancien champ texte libre
/// `dosage_legacy` pour les usages saisis avant la migration.
String? _formatDosage(Map<String, dynamic> u) {
  final type = u['dosage_type'] as String?;
  final unite = (u['unite_dosage'] as String?)?.trim() ?? '';
  switch (type) {
    case 'plage':
      final min = u['dosage_min'];
      final max = u['dosage_max'];
      if (min == null && max == null) break;
      final range = min != null && max != null
          ? '$min–$max'
          : '${min ?? max}';
      return unite.isEmpty ? range : '$range $unite';
    case 'valeur_unique':
      final value = u['dosage_min'];
      if (value == null) break;
      return unite.isEmpty ? '$value' : '$value $unite';
    case 'dilution':
      final texte = (u['dosage_texte'] as String?)?.trim();
      if (texte == null || texte.isEmpty) break;
      return 'Dilution $texte';
    case 'texte_libre':
      final texte = (u['dosage_texte'] as String?)?.trim();
      if (texte == null || texte.isEmpty) break;
      return texte;
  }
  final legacy = (u['dosage_legacy'] as String?)?.trim();
  return (legacy == null || legacy.isEmpty) ? null : legacy;
}

/// Extrait une valeur numérique de pH depuis le champ texte libre
/// `ph_solution` (ex : "fortement basique (pH 13-14)" -> 13.5,
/// "pH 3.5" -> 3.5) — best-effort seulement, ce champ n'a jamais été
/// contraint à un format précis côté admin. Retourne `null` si aucun
/// nombre n'est détectable ; l'affichage retombe alors sur le texte
/// brut sans badge coloré.
double? _extractPhValue(String? phText) {
  if (phText == null || phText.isEmpty) return null;
  final normalized = phText.replaceAll(',', '.');
  final rangeMatch =
      RegExp(r'(\d+(?:\.\d+)?)\s*[-–]\s*(\d+(?:\.\d+)?)').firstMatch(normalized);
  if (rangeMatch != null) {
    final a = double.tryParse(rangeMatch.group(1)!);
    final b = double.tryParse(rangeMatch.group(2)!);
    if (a != null && b != null) return (a + b) / 2;
  }
  final singleMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(normalized);
  if (singleMatch == null) return null;
  return double.tryParse(singleMatch.group(1)!);
}

Color _phColor(double ph) {
  if (ph < 2) return Colors.red;
  if (ph < 6) return Colors.orange;
  if (ph <= 8) return Colors.green;
  if (ph <= 12) return Colors.blue;
  return Colors.purple;
}

String _phLabel(double ph) {
  if (ph < 2) return 'Acide fort';
  if (ph < 6) return 'Acide faible';
  if (ph <= 8) return 'Neutre';
  if (ph <= 12) return 'Basique faible';
  return 'Basique fort';
}

/// Ligne icône + texte réutilisée pour les infos sécurité/stockage
/// courtes (premiers secours, incompatibilités, stockage structuré...).
Widget _iconTextRow(ThemeData theme, IconData icon, String text,
    {Color? color}) {
  final c = color ?? theme.colorScheme.primary;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

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
    final pictograms =
        List<Map<String, dynamic>>.from(sheet['pictograms'] as List? ?? []);
    final phrasesH =
        List<Map<String, dynamic>>.from(sheet['phrases_h'] as List? ?? []);
    final phrasesP =
        List<Map<String, dynamic>>.from(sheet['phrases_p'] as List? ?? []);
    final tempMin = sheet['temperature_stockage_min'] as num?;
    final tempMax = sheet['temperature_stockage_max'] as num?;
    final sensibleHumidite = sheet['sensible_humidite'] as bool? ?? false;
    final sensibleLumiere = sheet['sensible_lumiere'] as bool? ?? false;
    final dureeConservation = sheet['duree_conservation_mois'] as num?;
    final niveauColor = dangerLevelColor(sheet['niveau_danger'] as String?);
    final phValue = _extractPhValue(sheet['ph_solution'] as String?);
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
        if ((sheet['aspect'] as String?)?.isNotEmpty == true)
          _iconTextRow(
              theme, Icons.inventory_2_outlined, sheet['aspect'] as String),
        if ((sheet['ph_solution'] as String?)?.isNotEmpty == true) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('pH en solution',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(height: 4),
                if (phValue != null)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _phColor(phValue),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('pH ${phValue.toStringAsFixed(1)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text(_phLabel(phValue),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                SizedBox(height: phValue != null ? 4 : 0),
                Text(sheet['ph_solution'] as String),
              ],
            ),
          ),
        ],
        if ((sheet['solubilite'] as String?)?.isNotEmpty == true)
          _iconTextRow(theme, Icons.water_drop_outlined,
              sheet['solubilite'] as String),
        if (sheet['densite'] != null)
          _iconTextRow(theme, Icons.scale_outlined,
              'Densité : ${sheet['densite']} g/cm³'),
        if (sheet['point_eclair'] != null)
          _iconTextRow(theme, Icons.local_fire_department_outlined,
              'Point d\'éclair : ${sheet['point_eclair']} °C'),
        if ((sheet['particularite'] as String?)?.isNotEmpty == true) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(sheet['particularite'] as String,
                    style: TextStyle(
                        color: theme.colorScheme.onTertiaryContainer)),
                backgroundColor: theme.colorScheme.tertiaryContainer,
              ),
            ),
          ),
        ],
        field('Différence avec un produit similaire',
            sheet['difference_produit_similaire'] as String?),
        if ((sheet['niveau_danger'] as String?)?.isNotEmpty == true) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: niveauColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: niveauColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined,
                    color: niveauColor, size: 20),
                const SizedBox(width: 8),
                Text('Niveau de danger / précaution : ',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: niveauColor)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: niveauColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(sheet['niveau_danger'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
        if (pictograms.isNotEmpty) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: pictograms.map((p) {
              final imageUrl = p['image_url'] as String?;
              return Tooltip(
                message: '${p['code']} · ${p['nom'] ?? ''}',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) =>
                              const Icon(Icons.warning_amber,
                                  color: Colors.red, size: 36),
                        )
                      : const Icon(Icons.warning_amber,
                          color: Colors.red, size: 36),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 1.5.h),
        ],
        if (phrasesH.isNotEmpty || phrasesP.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...phrasesH.map((p) => Chip(
                    label: Text('${p['code']} ${p['texte'] ?? ''}',
                        style: TextStyle(color: theme.colorScheme.onError)),
                    backgroundColor: theme.colorScheme.error,
                  )),
              ...phrasesP.map((p) => Chip(
                    label: Text('${p['code']} ${p['texte'] ?? ''}',
                        style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer)),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  )),
            ],
          ),
          SizedBox(height: 1.5.h),
        ],
        if (epi.isNotEmpty) ...[
          Text('EPI requis',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: epi
                .map((e) => Tooltip(
                      message: e,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: Icon(epiIcon(e),
                            size: 18, color: theme.colorScheme.primary),
                      ),
                    ))
                .toList(),
          ),
          if ((sheet['notes_epi'] as String?)?.isNotEmpty == true) ...[
            SizedBox(height: 0.5.h),
            Text(sheet['notes_epi'] as String,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ],
          SizedBox(height: 1.5.h),
        ],
        if ((sheet['premiers_secours'] as String?)?.isNotEmpty == true)
          _iconTextRow(theme, Icons.medical_services_outlined,
              sheet['premiers_secours'] as String),
        if ((sheet['incompatibilites'] as String?)?.isNotEmpty == true)
          _iconTextRow(theme, Icons.warning_amber_outlined,
              sheet['incompatibilites'] as String,
              color: theme.colorScheme.error),
        field(
            'Stockage',
            (sheet['consignes_stockage'] as String?)?.isNotEmpty == true
                ? sheet['consignes_stockage'] as String
                : sheet['stockage'] as String?),
        if (tempMin != null || tempMax != null)
          _iconTextRow(
              theme,
              Icons.thermostat_outlined,
              tempMin != null && tempMax != null
                  ? 'Stockage : $tempMin°C à $tempMax°C'
                  : 'Stockage : ${tempMin ?? tempMax}°C'),
        if (sensibleHumidite)
          _iconTextRow(
              theme, Icons.water_drop_outlined, 'Sensible à l\'humidité'),
        if (sensibleLumiere)
          _iconTextRow(theme, Icons.light_mode_outlined,
              'Sensible à la lumière'),
        if (dureeConservation != null)
          _iconTextRow(theme, Icons.timer_outlined,
              'Conservation : $dureeConservation mois'),
        SizedBox(height: 1.h),
        Text('Usages détaillés', style: theme.textTheme.titleMedium),
        SizedBox(height: 1.h),
        if (usages.isEmpty)
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Aucun usage documenté pour cette matière.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic)),
              ),
            ],
          )
        else
          ..._buildUsagesGrouped(theme, usages),
        SizedBox(height: 4.h),
    ];
  }

  /// Usages détaillés groupés par domaine d'application (06/08) — un
  /// `ExpansionTile` par domaine (replié par défaut, sauf s'il n'y en a
  /// qu'un seul), pour ne pas noyer la fiche quand beaucoup de domaines
  /// sont documentés. L'ordre des domaines suit l'ordre d'apparition
  /// des usages (déjà trié par `ordre` en base), pas un tri alphabétique.
  List<Widget> _buildUsagesGrouped(
      ThemeData theme, List<Map<String, dynamic>> usages) {
    final byDomain = <String, List<Map<String, dynamic>>>{};
    for (final u in usages) {
      final domain = (u['domaine_application'] as String?)?.trim();
      byDomain
          .putIfAbsent(domain == null || domain.isEmpty ? 'Autres' : domain,
              () => [])
          .add(u);
    }
    final singleDomain = byDomain.length == 1;
    return byDomain.entries
        .map((entry) => Theme(
              // Retire le Divider par défaut de l'ExpansionTile pour ne
              // pas ajouter une ligne de séparation visible de plus.
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: singleDomain,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: Text('${entry.key} (${entry.value.length})',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                children:
                    entry.value.map((u) => _buildUsageCard(theme, u)).toList(),
              ),
            ))
        .toList();
  }

  Widget _buildUsageCard(ThemeData theme, Map<String, dynamic> u) {
    final title = (u['technique_methode'] as String?)?.trim();
    final tempOrTemps =
        (u['temperature_utilisation'] as String?)?.isNotEmpty == true ||
            (u['temps_action'] as String?)?.isNotEmpty == true;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                      title == null || title.isEmpty ? 'Sans titre' : title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (u['a_verifier_labo'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('⚠️ À vérifier en labo',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _buildDosageBadge(theme, u),
            if (tempOrTemps) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if ((u['temperature_utilisation'] as String?)
                          ?.isNotEmpty ==
                      true)
                    _miniIconText(theme, Icons.thermostat_outlined,
                        u['temperature_utilisation'] as String),
                  if ((u['temps_action'] as String?)?.isNotEmpty == true)
                    _miniIconText(theme, Icons.timer_outlined,
                        u['temps_action'] as String),
                ],
              ),
            ],
            if ((u['source_reference'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.link, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(u['source_reference'] as String,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Badge de dosage coloré selon le type (06/08) — la couleur donne un
  /// repère visuel rapide du type de dosage sans avoir à lire le texte.
  /// Réutilise `_formatDosage()` pour le texte (gère aussi le repli sur
  /// `dosage_legacy` pour les usages saisis avant la migration phase85).
  Widget _buildDosageBadge(ThemeData theme, Map<String, dynamic> u) {
    final type = u['dosage_type'] as String?;
    final text = _formatDosage(u);
    Color bg;
    Color fg;
    switch (type) {
      case 'plage':
        bg = theme.colorScheme.primaryContainer;
        fg = theme.colorScheme.onPrimaryContainer;
        break;
      case 'valeur_unique':
        bg = theme.colorScheme.secondaryContainer;
        fg = theme.colorScheme.onSecondaryContainer;
        break;
      case 'dilution':
        bg = theme.colorScheme.tertiaryContainer;
        fg = theme.colorScheme.onTertiaryContainer;
        break;
      default:
        bg = theme.colorScheme.surfaceContainerHighest;
        fg = theme.colorScheme.onSurfaceVariant;
        break;
    }
    final isEmpty = text == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isEmpty ? theme.colorScheme.surfaceContainerHighest : bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text ?? 'Dosage non spécifié',
          style: TextStyle(
              color: isEmpty ? theme.colorScheme.outline : fg,
              fontWeight: FontWeight.w600,
              fontSize: 12)),
    );
  }

  Widget _miniIconText(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
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
