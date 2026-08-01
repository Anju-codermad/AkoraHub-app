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

// Rotation de couleurs de marque (icône) pour les sections/cartes —
// mêmes teintes que le reste de l'app, pas de couleurs Material génériques.
const List<Color> _sectionColors = [
  Color(0xFF085041), // vert (icône)
  Color(0xFF0B2C64), // marine (icône)
  Color(0xFFFE5905), // orange (icône)
  Color(0xFF3E7C59),
  Color(0xFFB8863B),
  Color(0xFF3D5A6C),
];

/// Catalogue AkoraFormation côté client : cours regroupés par catégorie
/// (une section par catégorie) — voir supabase/phase43_patch_formation_courses.sql
/// et phase50 (achat + contenu protégé). Distinct de "Formation" (base de
/// matières premières, accessible séparément depuis le Profil).
///
/// Design (02/08) : inspiré d'une appli de bibliothèque/vidéos consultée
/// par l'utilisatrice — rangée horizontale de "cartes affiche" pour les
/// cours réellement disponibles à l'achat/consultation (comme une rangée
/// de vignettes vidéo), et liste verticale sobre icône+chevron pour les
/// cours pas encore disponibles (comme une liste de bibliothèque). Pas de
/// vraies vignettes vidéo (pas d'assets images autorisés) : les cartes
/// utilisent un dégradé des couleurs de marque + l'icône de catégorie.
class AkoraFormationScreen extends StatefulWidget {
  /// Fait apparaître cette catégorie en premier dans la liste des sections.
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

  final _currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
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

  /// Catégories, avec `initialCategory` placée en premier si fournie.
  List<String> get _categories {
    final all = _courses.map((c) => c['category'] as String).toSet().toList()
      ..sort();
    final initial = widget.initialCategory;
    if (initial != null && all.remove(initial)) {
      all.insert(0, initial);
    }
    return all;
  }

  bool _isAvailable(Map<String, dynamic> c) =>
      c['status'] == 'deja_developpee' && c['price'] != null;

  void _openCourseContent(Map<String, dynamic> c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseContentScreen(
          courseId: c['id'] as String,
          courseTitle: c['title'] ?? '',
        ),
      ),
    );
  }

  void _showCourseInfoSheet(Map<String, dynamic> c) {
    final status = c['status'] as String;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 1.h),
            Chip(
              label: Text(_statusLabel(status)),
              backgroundColor: _statusColor(status).withValues(alpha: 0.15),
              labelStyle: TextStyle(color: _statusColor(status)),
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(height: 2.h),
            Text(
              status == 'en_projet'
                  ? 'Cette formation est en cours de préparation. Revenez bientôt !'
                  : 'Cette formation n\'est pas encore programmée.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _categories;

    return Scaffold(
      appBar: AppBar(title: const Text('AkoraFormation')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _courses.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        children: [
                          SizedBox(height: 20.h),
                          Center(
                            child: Text(
                              'Aucune formation pour le moment.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(0, 1.h, 0, 2.h),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final color =
                              _sectionColors[index % _sectionColors.length];
                          return _buildCategorySection(category, color);
                        },
                      ),
                    ),
    );
  }

  Widget _buildCategorySection(String category, Color color) {
    final theme = Theme.of(context);
    final courses = _courses.where((c) => c['category'] == category).toList();
    final available = courses.where(_isAvailable).toList();
    final others = courses.where((c) => !_isAvailable(c)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
          child: Row(
            children: [
              Icon(iconForFormationCategory(category), color: color, size: 20),
              SizedBox(width: 2.w),
              Text(category, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
        if (available.isNotEmpty)
          SizedBox(
            height: 24.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: available.length,
              separatorBuilder: (_, __) => SizedBox(width: 3.w),
              itemBuilder: (context, i) =>
                  _PosterCard(course: available[i], color: color, state: this),
            ),
          ),
        if (others.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Card(
              margin: EdgeInsets.only(top: available.isNotEmpty ? 1.h : 0),
              child: Column(
                children: [
                  for (int i = 0; i < others.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _ChevronRow(course: others[i], state: this),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PosterCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final Color color;
  final _AkoraFormationScreenState state;

  const _PosterCard({required this.course, required this.color, required this.state});

  @override
  Widget build(BuildContext context) {
    final courseId = course['id'] as String;
    final title = course['title'] ?? '';
    final price = course['price'] as num?;
    final isOwned = state._ownedCourseIds.contains(courseId);
    final isPending = state._pendingCourseIds.contains(courseId);

    return GestureDetector(
      onTap: () {
        if (isOwned) {
          state._openCourseContent(course);
        } else if (isPending) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Votre paiement est en cours de vérification.')));
        } else {
          openFormationPurchaseWeb(context);
        }
      },
      child: Container(
        width: 42.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.75)],
          ),
        ),
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconForFormationCategory(course['category'] as String? ?? ''),
                color: Colors.white, size: 32),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isOwned)
                  Text(
                    NumberFormat.currency(
                            locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0)
                        .format(price),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  )
                else
                  const SizedBox.shrink(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOwned
                            ? Icons.play_circle_outline
                            : isPending
                                ? Icons.hourglass_empty
                                : Icons.lock_outline,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOwned
                            ? 'Voir'
                            : isPending
                                ? 'En attente'
                                : 'Acheter',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChevronRow extends StatelessWidget {
  final Map<String, dynamic> course;
  final _AkoraFormationScreenState state;

  const _ChevronRow({required this.course, required this.state});

  @override
  Widget build(BuildContext context) {
    final status = course['status'] as String;
    return ListTile(
      leading: Icon(iconForFormationCategory(course['category'] as String? ?? ''),
          color: _statusColor(status)),
      title: Text(course['title'] ?? ''),
      subtitle: Text(_statusLabel(status)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => state._showCourseInfoSheet(course),
    );
  }
}
