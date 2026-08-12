import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/constants/client_types.dart';
import '../../core/supabase/supabase_config.dart';
import '../customer_360/customer_360_screen.dart';

/// PostgREST peut renvoyer un agrégat (`count()`, `sum()`) sous une forme
/// inattendue selon le type Postgres sous-jacent — un `as num?` direct
/// planterait alors avec un `TypeError` au lieu de simplement convertir
/// (voir customer_analytics_dashboard.dart, même correctif).
num _asNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

/// Liste réelle des clients (comptes créés via l'inscription), avec leur
/// type (Hôtel/Hôpital/Entreprise/Particulier) et coordonnées.
class CustomerManagementReal extends StatefulWidget {
  const CustomerManagementReal({super.key});

  @override
  State<CustomerManagementReal> createState() =>
      _CustomerManagementRealState();
}

class _CustomerManagementRealState extends State<CustomerManagementReal> {
  List<Map<String, dynamic>> _customers = [];
  Map<String, Map<String, dynamic>> _segments = {};
  bool _isLoading = true;
  bool _isSendingNotification = false;
  String? _error;
  String _typeFilter = 'tous';
  String _segmentFilter = 'tous';
  String _regionFilter = 'toutes';

  /// Seuil de valeur totale (lifetime value) au-dessus duquel un client
  /// est considéré "gros compte" — hypothèse de départ, ajustable si
  /// besoin (pas de règle métier communiquée par ailleurs).
  static const num _grosCompteThreshold = 1000000;
  static const int _inactifAfterDays = 90;

  final Map<String, String> _segmentLabels = const {
    'nouveau': 'Nouveaux',
    'recurrent': 'Récurrents',
    'inactif': 'Inactifs',
    'gros_compte': 'Gros comptes',
  };

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion au serveur indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('profiles')
            .select()
            .eq('role', 'client')
            .order('created_at', ascending: false),
        SupabaseConfig.client.from('customer_segments').select(),
      ]);
      final segments = List<Map<String, dynamic>>.from(results[1]);
      setState(() {
        _customers = List<Map<String, dynamic>>.from(results[0]);
        _segments = {
          for (final s in segments) s['customer_id'] as String: s,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les clients.';
      });
    }
  }

  /// Segment d'activité (mutuellement exclusif) : null si le client n'a
  /// encore jamais commandé (pas assez de signal pour le classer).
  String? _activitySegment(String customerId) {
    final agg = _segments[customerId];
    final orderCount = _asNum(agg?['order_count']).toInt();
    if (orderCount == 0) return null;
    final lastOrderAt =
        DateTime.tryParse(agg?['last_order_at']?.toString() ?? '');
    if (lastOrderAt != null &&
        DateTime.now().difference(lastOrderAt).inDays > _inactifAfterDays) {
      return 'inactif';
    }
    return orderCount == 1 ? 'nouveau' : 'recurrent';
  }

  bool _isGrosCompte(String customerId) {
    final value = _asNum(_segments[customerId]?['lifetime_value']);
    return value >= _grosCompteThreshold;
  }

  /// Régions distinctes présentes chez les clients (Madagascar comme
  /// texte libre pour les autres pays) — pour filtrer et retrouver
  /// rapidement les clients d'une zone lors des livraisons (12/08,
  /// demande explicite).
  List<String> get _availableRegions {
    final regions = _customers
        .map((c) => (c['region'] as String?)?.trim())
        .where((r) => r != null && r.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    regions.sort();
    return regions;
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _customers;
    if (_typeFilter != 'tous') {
      list = list.where((c) => c['client_type'] == _typeFilter).toList();
    }
    if (_segmentFilter != 'tous') {
      list = list.where((c) {
        final id = c['id'] as String;
        return _segmentFilter == 'gros_compte'
            ? _isGrosCompte(id)
            : _activitySegment(id) == _segmentFilter;
      }).toList();
    }
    if (_regionFilter != 'toutes') {
      list = list.where((c) => c['region'] == _regionFilter).toList();
    }
    return list;
  }

  /// Compte les clients par type (Hôtel/Hôpital/Entreprise/Particulier).
  Map<String, int> _typeCounts() {
    final counts = <String, int>{};
    for (final c in _customers) {
      final type = (c['client_type'] as String?) ?? 'particulier';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  static const _ageBrackets = [
    'Moins de 25 ans',
    '25-34 ans',
    '35-44 ans',
    '45-54 ans',
    '55 ans et plus',
    'Non renseigné',
  ];

  String _bracketFor(Map<String, dynamic> c) {
    final birthDate = DateTime.tryParse(c['birth_date']?.toString() ?? '');
    if (birthDate == null) return 'Non renseigné';
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age < 25
        ? 'Moins de 25 ans'
        : age < 35
            ? '25-34 ans'
            : age < 45
                ? '35-44 ans'
                : age < 55
                    ? '45-54 ans'
                    : '55 ans et plus';
  }

  /// Compte les clients par tranche d'âge, calculée depuis `birth_date`
  /// (Phase 19). Un client sans date de naissance renseignée compte à
  /// part plutôt que d'être exclu du total.
  Map<String, int> _ageBracketCounts() {
    final counts = <String, int>{for (final b in _ageBrackets) b: 0};
    for (final c in _customers) {
      final bracket = _bracketFor(c);
      counts[bracket] = counts[bracket]! + 1;
    }
    return counts;
  }

  /// Répartition Femme/Homme/Non renseigné dans chaque tranche d'âge
  /// (`profiles.gender`, Phase 163) — permet la barre empilée façon
  /// "Âge et genre" (demande explicite du 12/08, référence Facebook
  /// Page Insights).
  Map<String, Map<String, int>> _ageGenderBreakdown() {
    final result = <String, Map<String, int>>{
      for (final b in _ageBrackets) b: {'femme': 0, 'homme': 0, 'inconnu': 0}
    };
    for (final c in _customers) {
      final bracket = _bracketFor(c);
      final gender = c['gender'] as String?;
      final key = (gender == 'homme' || gender == 'femme') ? gender! : 'inconnu';
      result[bracket]![key] = result[bracket]![key]! + 1;
    }
    return result;
  }

  /// Répartition globale Femme/Homme (clients ayant renseigné leur sexe
  /// uniquement — même convention que les outils d'analytics grand
  /// public type Facebook Insights, qui n'incluent pas les "inconnus"
  /// dans le pourcentage affiché).
  Map<String, int> _genderCounts() {
    final counts = {'femme': 0, 'homme': 0};
    for (final c in _customers) {
      final gender = c['gender'] as String?;
      if (gender == 'homme' || gender == 'femme') {
        counts[gender!] = counts[gender]! + 1;
      }
    }
    return counts;
  }

  /// Localisations les plus fréquentes (texte `location`, alimenté par la
  /// géolocalisation Niveau 1 côté client — voir phase5_patch_geolocation.sql).
  /// Regroupement par correspondance exacte : suffisant tant que le nombre
  /// de clients reste petit, sans complexité de normalisation de texte.
  List<MapEntry<String, int>> _topLocations({int limit = 5}) {
    final counts = <String, int>{};
    for (final c in _customers) {
      final loc = (c['location'] as String?)?.trim();
      if (loc == null || loc.isEmpty) continue;
      counts[loc] = (counts[loc] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Régions les plus fréquentes (`profiles.region`, Phase 165) — liste
  /// fermée des 24 régions pour Madagascar, texte libre pour les autres
  /// pays (voir profile_tab.dart).
  List<MapEntry<String, int>> _topRegions({int limit = 5}) {
    final counts = <String, int>{};
    for (final c in _customers) {
      final region = (c['region'] as String?)?.trim();
      if (region == null || region.isEmpty) continue;
      counts[region] = (counts[region] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Pays les plus fréquents (`profiles.country`, Phase 164) — distinct
  /// de `location` (ville/région) : plusieurs clients hors Madagascar
  /// (Maurice, Réunion, Comores...), ce champ n'est donc pas toujours
  /// "Madagascar" comme on aurait pu le supposer à tort.
  List<MapEntry<String, int>> _topCountries({int limit = 5}) {
    final counts = <String, int>{};
    for (final c in _customers) {
      final country = (c['country'] as String?)?.trim();
      if (country == null || country.isEmpty) continue;
      counts[country] = (counts[country] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  Widget _buildDemographicsCard(ThemeData theme) {
    if (_customers.isEmpty) return const SizedBox.shrink();
    final total = _customers.length;
    final typeCounts = _typeCounts();
    final ageCounts = _ageBracketCounts();
    final ageGender = _ageGenderBreakdown();
    final genderCounts = _genderCounts();
    final genderKnown = genderCounts['femme']! + genderCounts['homme']!;
    final topLocations = _topLocations();
    final topCountries = _topCountries();
    final topRegions = _topRegions();

    const femmeColor = Color(0xFF90CAF9);
    const hommeColor = Color(0xFF1565C0);

    Widget buildLegendChip(String label, int count, Color color) {
      final pct = genderKnown == 0 ? 0 : (count * 100 / genderKnown).round();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
          ),
          SizedBox(width: 1.5.w),
          Text('$label $pct% ($count)', style: theme.textTheme.bodySmall),
        ],
      );
    }

    Widget buildAgeGenderBar(String label, int bracketTotal) {
      final breakdown = ageGender[label]!;
      final pct = total == 0 ? 0.0 : bracketTotal / total;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 0.5.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text('${(pct * 100).round()}%',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 0.3.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct,
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          if (breakdown['femme']! > 0)
                            Expanded(
                                flex: breakdown['femme']!,
                                child: Container(color: femmeColor)),
                          if (breakdown['homme']! > 0)
                            Expanded(
                                flex: breakdown['homme']!,
                                child: Container(color: hommeColor)),
                          if (breakdown['inconnu']! > 0)
                            Expanded(
                                flex: breakdown['inconnu']!,
                                child: Container(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.3))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildBar(String label, int count) {
      final pct = total == 0 ? 0.0 : count / total;
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 0.5.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(label,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
                Text('$count (${(pct * 100).round()}%)',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 0.3.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor:
                    theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          'Données démographiques',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Basé sur les $total client(s) inscrit(s)'),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Par type de client', style: theme.textTheme.labelLarge),
                ...kClientTypeOptions
                    .where((e) => (typeCounts[e['value']] ?? 0) > 0)
                    .map((e) => buildBar(
                        e['label']!, typeCounts[e['value']] ?? 0)),
                SizedBox(height: 1.5.h),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 3.w,
                  runSpacing: 0.5.h,
                  children: [
                    Text('Âge et genre', style: theme.textTheme.labelLarge),
                    if (genderKnown > 0) ...[
                      buildLegendChip('Femmes', genderCounts['femme']!, femmeColor),
                      buildLegendChip('Hommes', genderCounts['homme']!, hommeColor),
                    ],
                  ],
                ),
                SizedBox(height: 0.5.h),
                ...ageCounts.entries
                    .where((e) => e.value > 0)
                    .map((e) => buildAgeGenderBar(e.key, e.value)),
                if (topRegions.isNotEmpty) ...[
                  SizedBox(height: 1.5.h),
                  Text('Principales régions',
                      style: theme.textTheme.labelLarge),
                  ...topRegions.map((e) => buildBar(e.key, e.value)),
                ],
                if (topLocations.isNotEmpty) ...[
                  SizedBox(height: 1.5.h),
                  Text('Principales villes',
                      style: theme.textTheme.labelLarge),
                  ...topLocations.map((e) => buildBar(e.key, e.value)),
                ],
                if (topCountries.isNotEmpty) ...[
                  SizedBox(height: 1.5.h),
                  Text('Principaux pays', style: theme.textTheme.labelLarge),
                  ...topCountries.map((e) => buildBar(e.key, e.value)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'hotel':
        return Icons.hotel;
      case 'hopital':
        return Icons.local_hospital;
      case 'restaurant':
        return Icons.restaurant;
      case 'ecole':
        return Icons.school;
      case 'entreprise':
        return Icons.business_center;
      case 'usine':
        return Icons.factory;
      case 'pharmacie':
        return Icons.local_pharmacy;
      case 'salon_beaute':
        return Icons.content_cut;
      case 'commerce':
        return Icons.storefront;
      case 'administration':
        return Icons.account_balance;
      case 'ong':
        return Icons.volunteer_activism;
      default:
        return Icons.person;
    }
  }

  Future<void> _sendTargetedNotification(
      String title, String body, List<String> customerIds) async {
    setState(() => _isSendingNotification = true);
    try {
      final response = await SupabaseConfig.client.functions.invoke(
        'send-targeted-notification',
        body: {
          'customerIds': customerIds,
          'title': title,
          'body': body,
        },
      );
      final data = response.data as Map?;
      if (!mounted) return;
      final sent = data?['sent'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification envoyée à $sent client(s).')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible d\'envoyer la notification.')));
    } finally {
      if (mounted) setState(() => _isSendingNotification = false);
    }
  }

  void _showNotificationDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final targetLabel = _segmentFilter == 'tous'
        ? 'tous les clients affichés'
        : _segmentLabels[_segmentFilter] ?? _segmentFilter;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notification ciblée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destinataires : $targetLabel (${_filtered.length})'),
            SizedBox(height: 2.h),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Message'),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              final body = bodyController.text.trim();
              if (title.isEmpty || body.isEmpty) return;
              Navigator.pop(dialogContext);
              _sendTargetedNotification(
                  title, body, _filtered.map((c) => c['id'] as String).toList());
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: _isSendingNotification
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.campaign_outlined),
            tooltip: 'Notification ciblée',
            onPressed:
                _isSendingNotification ? null : _showNotificationDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    _buildDemographicsCard(theme),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                          horizontal: 4.w, vertical: 1.h),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Tous'),
                            selected: _typeFilter == 'tous',
                            onSelected: (_) =>
                                setState(() => _typeFilter = 'tous'),
                          ),
                          SizedBox(width: 2.w),
                          ...kClientTypeOptions.map((type) => Padding(
                                padding: EdgeInsets.only(right: 2.w),
                                child: ChoiceChip(
                                  label: Text(type['label']!),
                                  selected: _typeFilter == type['value'],
                                  onSelected: (_) => setState(
                                      () => _typeFilter = type['value']!),
                                ),
                              )),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(
                          left: 4.w, right: 4.w, bottom: 1.h),
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Tous segments'),
                            selected: _segmentFilter == 'tous',
                            onSelected: (_) =>
                                setState(() => _segmentFilter = 'tous'),
                          ),
                          SizedBox(width: 2.w),
                          ..._segmentLabels.entries.map((entry) => Padding(
                                padding: EdgeInsets.only(right: 2.w),
                                child: ChoiceChip(
                                  label: Text(entry.value),
                                  selected: _segmentFilter == entry.key,
                                  onSelected: (_) => setState(
                                      () => _segmentFilter = entry.key),
                                ),
                              )),
                        ],
                      ),
                    ),
                    // Filtre par région (12/08, demande explicite) : ne
                    // s'affiche que si au moins un client a une région
                    // renseignée — inutile de montrer un filtre vide.
                    if (_availableRegions.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(
                            left: 4.w, right: 4.w, bottom: 1.h),
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Toutes régions'),
                              selected: _regionFilter == 'toutes',
                              onSelected: (_) =>
                                  setState(() => _regionFilter = 'toutes'),
                            ),
                            SizedBox(width: 2.w),
                            ..._availableRegions.map((region) => Padding(
                                  padding: EdgeInsets.only(right: 2.w),
                                  child: ChoiceChip(
                                    label: Text(region),
                                    selected: _regionFilter == region,
                                    onSelected: (_) => setState(
                                        () => _regionFilter = region),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: _filtered.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(height: 20.h),
                                  const Center(
                                      child: Text('Aucun client.')),
                                ],
                              )
                            : ListView.separated(
                                padding: EdgeInsets.all(4.w),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
                                  final c = _filtered[index];
                                  final id = c['id'] as String;
                                  final segment = _activitySegment(id);
                                  final grosCompte = _isGrosCompte(id);
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Icon(
                                            _iconForType(c['client_type'])),
                                      ),
                                      title: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              c['company_name'] ??
                                                  c['full_name'] ??
                                                  'Client',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (c['is_vip'] == true) ...[
                                            SizedBox(width: 1.w),
                                            const Icon(
                                                Icons.workspace_premium,
                                                size: 16,
                                                color: Colors.amber),
                                          ],
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            [
                                              kClientTypeLabels[
                                                      c['client_type']] ??
                                                  '',
                                              if ((c['phone'] ?? '')
                                                  .toString()
                                                  .isNotEmpty)
                                                c['phone'],
                                              if ((c['region'] ?? '')
                                                  .toString()
                                                  .isNotEmpty)
                                                c['region'],
                                            ]
                                                .where((s) => s != '')
                                                .join(' · '),
                                          ),
                                          if (segment != null ||
                                              grosCompte)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  top: 0.5.h),
                                              child: Wrap(
                                                spacing: 6,
                                                children: [
                                                  if (segment != null)
                                                    Chip(
                                                      label: Text(
                                                          _segmentLabels[
                                                                  segment] ??
                                                              segment),
                                                      visualDensity:
                                                          VisualDensity
                                                              .compact,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                  if (grosCompte)
                                                    const Chip(
                                                      label:
                                                          Text('Gros compte'),
                                                      visualDensity:
                                                          VisualDensity
                                                              .compact,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      isThreeLine: segment != null ||
                                          grosCompte,
                                      trailing:
                                          const Icon(Icons.chevron_right),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => Customer360Screen(
                                              customerId: c['id'] as String),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
