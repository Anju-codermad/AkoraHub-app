import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/formation/course_purchases_repo.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/utils/formation_web_link.dart';
import 'course_content_screen.dart';

String _statusLabel(String status) {
  switch (status) {
    case 'deja_developpee':
      return 'Disponible';
    case 'en_projet':
      return 'Bientôt disponible';
    case 'a_creer':
    default:
      return 'À venir';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'deja_developpee':
      return Colors.green;
    case 'en_projet':
      return Colors.orange;
    case 'a_creer':
    default:
      return Colors.blueGrey;
  }
}

IconData iconForFormationCategory(String category) {
  final c = category.toLowerCase();
  if (c.contains('capillaire') || c.contains('beauté')) return Icons.spa_outlined;
  if (c.contains('peinture')) return Icons.format_paint_outlined;
  if (c.contains('cire') || c.contains('bougie')) return Icons.local_fire_department_outlined;
  if (c.contains('agroalimentaire')) return Icons.restaurant_outlined;
  if (c.contains('chimie')) return Icons.science_outlined;
  if (c.contains('coaching') || c.contains('entrepreneur')) return Icons.trending_up_outlined;
  return Icons.cleaning_services_outlined;
}

/// Catalogue AkoraFormation côté client : liste des cours/modules par
/// catégorie, avec leur statut (Disponible / Bientôt / À venir) — voir
/// supabase/phase43_patch_formation_courses.sql. Distinct de "Formation"
/// (base de matières premières, accessible séparément depuis le Profil)
/// — ici ce sont de vrais cours/e-learning, pas des fiches ingrédients.
/// Pour l'instant, juste la structure ; le contenu réel des cours
/// "Disponible" n'est pas encore consultable depuis l'app.
class AkoraFormationScreen extends StatefulWidget {
  /// Pré-sélectionne une catégorie à l'ouverture (ex: depuis le hub
  /// Académie) — reste modifiable ensuite via les puces de filtre.
  final String? initialCategory;

  const AkoraFormationScreen({super.key, this.initialCategory});

  @override
  State<AkoraFormationScreen> createState() => _AkoraFormationScreenState();
}

class _AkoraFormationScreenState extends State<AkoraFormationScreen> {
  List<Map<String, dynamic>> _courses = [];
  Set<String> _ownedCourseIds = {};
  Set<String> _pendingCourseIds = {};
  bool _isLoading = true;
  String? _error;
  late String _selectedCategory;

  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // `widget` n'est pas encore disponible dans un initialiseur de champ —
    // il faut lire `widget.initialCategory` ici, dans initState().
    _selectedCategory = widget.initialCategory ?? 'toutes';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('formation_courses')
            .select()
            .order('category')
            .order('sort_order'),
        CoursePurchasesRepo.fetchMyPurchasedCourseIds(),
        CoursePurchasesRepo.fetchMyPendingCourseIds(),
      ]);
      setState(() {
        _courses = List<Map<String, dynamic>>.from(results[0] as List);
        _ownedCourseIds = results[1] as Set<String>;
        _pendingCourseIds = results[2] as Set<String>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les formations pour le moment.';
      });
    }
  }

  List<String> get _categories =>
      _courses.map((c) => c['category'] as String).toSet().toList()..sort();

  List<Map<String, dynamic>> get _filtered => _selectedCategory == 'toutes'
      ? _courses
      : _courses.where((c) => c['category'] == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('AkoraFormation')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
                        child: Text(
                          'Nos cours et modules de formation, en cours de construction.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      if (_categories.isNotEmpty)
                        SizedBox(
                          height: 6.h,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: const Text('Toutes'),
                                  selected: _selectedCategory == 'toutes',
                                  onSelected: (_) =>
                                      setState(() => _selectedCategory = 'toutes'),
                                ),
                              ),
                              ..._categories.map((c) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      avatar: Icon(iconForFormationCategory(c),
                                          size: 18),
                                      label: Text(c),
                                      selected: _selectedCategory == c,
                                      onSelected: (_) =>
                                          setState(() => _selectedCategory = c),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'Aucune formation pour le moment.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 2.h),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => SizedBox(height: 1.h),
                                itemBuilder: (context, index) {
                                  final c = filtered[index];
                                  final status = c['status'] as String;
                                  final courseId = c['id'] as String;
                                  final price = c['price'] as num?;
                                  final isOwned =
                                      _ownedCourseIds.contains(courseId);
                                  final isPending =
                                      _pendingCourseIds.contains(courseId);
                                  final isPurchasable = status ==
                                          'deja_developpee' &&
                                      price != null &&
                                      !isOwned;
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _statusColor(status)
                                            .withValues(alpha: 0.15),
                                        child: Icon(
                                          isOwned
                                              ? Icons.lock_open_outlined
                                              : iconForFormationCategory(
                                                  c['category'] as String? ??
                                                      ''),
                                          color: _statusColor(status),
                                        ),
                                      ),
                                      title: Text(c['title'] ?? ''),
                                      subtitle: Text([
                                        c['category'],
                                        if (c['module_count'] != null)
                                          '${c['module_count']} modules',
                                        if (isPurchasable)
                                          _currency.format(price),
                                      ].where((e) => e != null).join(' · ')),
                                      trailing: isOwned
                                          ? FilledButton(
                                              onPressed: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      CourseContentScreen(
                                                    courseId: courseId,
                                                    courseTitle:
                                                        c['title'] ?? '',
                                                  ),
                                                ),
                                              ),
                                              child: const Text('Voir'),
                                            )
                                          : isPending
                                              ? const Chip(
                                                  label: Text(
                                                      'En attente',
                                                      style: TextStyle(
                                                          fontSize: 11)),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                )
                                              : isPurchasable
                                                  ? OutlinedButton(
                                                      onPressed: () =>
                                                          openFormationPurchaseWeb(
                                                              context),
                                                      child: const Text(
                                                          'Acheter'),
                                                    )
                                                  : Chip(
                                                      label: Text(
                                                          _statusLabel(status),
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      11)),
                                                      backgroundColor:
                                                          _statusColor(status)
                                                              .withValues(
                                                                  alpha: 0.15),
                                                      labelStyle: TextStyle(
                                                          color: _statusColor(
                                                              status)),
                                                      visualDensity:
                                                          VisualDensity
                                                              .compact,
                                                    ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
