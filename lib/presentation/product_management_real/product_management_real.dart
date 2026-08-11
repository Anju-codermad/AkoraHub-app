import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';

import '../../core/reference_data/reference_table_cache.dart';
import '../../core/supabase/supabase_config.dart';
import 'product_variants_screen.dart';
import 'batch_list_screen.dart';

/// Usages suggérés à la publication d'un produit (Savonnerie, Industriel,
/// Nettoyage...) — reproduit les badges déjà utilisés sur les visuels
/// marketing des produits (ex. "Soude Caustique"). Liste de DÉPART
/// uniquement : la liste réellement proposée dans le formulaire
/// (`_knownUsages`, voir `_loadData`) l'enrichit avec tout usage déjà tapé
/// manuellement sur n'importe quel produit, pour qu'un usage ajouté une
/// fois devienne réutilisable partout. Reste un `text[]` libre sur
/// `products.use_cases` plutôt qu'une table à part, un simple tag
/// descriptif n'a pas besoin d'être une entité normalisée.
const List<String> kProductUsageSuggestions = [
  'Savonnerie',
  'Industriel',
  'Nettoyage',
  'Construction & BTP',
  'Détergents',
  'Médical',
  'Cosmétique',
  'Lessive',
  'Désinfection',
  'Agriculture',
  'Traitement de l\'eau',
  'Textile',
  'Papier',
  'Métallurgie',
  'Alimentaire',
];

/// Usages suggérés PAR CATÉGORIE (05/08) — la liste générique ci-dessus
/// vise les matières premières industrielles, mais ne colle pas à un
/// produit fini comme "Gel Sol Universel" (catégorie "Carrelage & Sols").
/// Couvre les 10 catégories du pilier "Akora Fanadiovana" (celui avec les
/// vrais produits déjà vendus — voir supabase/phase6_patch_categories.sql
/// et phase42_patch_produits_categories.sql pour la liste exacte des noms
/// de catégorie, qui doivent matcher exactement les clés ci-dessous).
/// Les catégories des piliers pas encore activés (Matières Premières,
/// Anti-Nuisibles, Peinture, Akora Soins) ne sont pas couvertes : elles
/// retombent sur `kProductUsageSuggestions` (voir usage dans
/// `_showProductDialog`).
const Map<String, List<String>> kProductUsageSuggestionsByCategory = {
  'Carrelage & Sols': [
    'Marbre',
    'Granit',
    'Carrelage',
    'Grès cérame',
    'Parquet',
    'Terre cuite',
    'PVC',
    'Béton',
  ],
  'Cuisine & Vaisselle': [
    'Vaisselle',
    'Plan de travail',
    'Four',
    'Plaque de cuisson',
    'Réfrigérateur',
    'Évier',
    'Graisses & Huiles',
    'Ustensiles de cuisine',
  ],
  'Désinfectants & Hygiène': [
    'Surfaces',
    'Sanitaires',
    'Mains',
    'Sols',
    'Textiles',
    'Air ambiant',
    'Poubelles',
    'Objets & Jouets',
  ],
  'Entretien Véhicules': [
    'Carrosserie',
    'Jantes',
    'Vitres auto',
    'Intérieur & Sièges',
    'Moteur',
    'Moto',
    'Chromes & Plastiques',
    'Pare-brise',
  ],
  'Lessive & Textile': [
    'Linge blanc',
    'Linge couleur',
    'Linge délicat',
    'Tapis & Moquettes',
    'Rideaux',
    'Vêtements de travail',
    'Tissus d\'ameublement',
    'Lavage à la main',
  ],
  'Sanitaire & Salle de Bain': [
    'WC',
    'Douche & Baignoire',
    'Robinetterie',
    'Carrelage salle de bain',
    'Joints',
    'Miroirs',
    'Lavabo',
    'Anti-calcaire',
  ],
  'Soins du Corps & Cosmétiques': [
    'Peau',
    'Cheveux',
    'Mains',
    'Visage',
    'Corps',
    'Hydratation',
    'Hygiène intime',
    'Rasage',
  ],
  'Vitres & Surfaces': [
    'Vitres',
    'Miroirs',
    'Écrans',
    'Vitrines',
    'Plexiglas',
    'Meubles laqués',
    'Inox',
    'Surfaces vernies',
  ],
  'Cire & Bougie': [
    'Bois',
    'Meubles',
    'Parquet ciré',
    'Cuir',
    'Décoration',
    'Ambiance & Senteur',
    'Chandelier',
    'Extérieur bois',
  ],
  'Produits spécialisés': [
    'Usage professionnel',
    'Usage industriel',
    'Grande surface',
    'Collectivités',
    'Sur mesure',
  ],
};

/// Gestion réelle des produits : tarification Gros/Détail par seuil de
/// quantité, stock, et lots de production (n° lot, fabrication, DLC).
/// Remplace progressivement l'ancien écran basé sur des données fictives.
class ProductManagementReal extends ConsumerStatefulWidget {
  const ProductManagementReal({super.key});

  @override
  ConsumerState<ProductManagementReal> createState() =>
      _ProductManagementRealState();
}

class _ProductManagementRealState
    extends ConsumerState<ProductManagementReal> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _businessUnits = [];
  List<Map<String, dynamic>> _nameSuggestions = [];
  // Usages suggérés à la publication d'un produit : la liste de départ
  // (`kProductUsageSuggestions`) enrichie de tout usage déjà tapé
  // manuellement sur n'importe quel produit — un usage ajouté une fois
  // devient donc réutilisable partout, sans table de référence à part.
  List<String> _knownUsages = List<String>.from(kProductUsageSuggestions);
  bool _isLoading = true;
  String? _error;
  final _currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  // Pagination : la liste des produits n'avait pas de limite (toute la
  // table chargée d'un coup) — remplacé par un chargement par pages de
  // 20, la suite arrivant en scrollant vers le bas. Piliers/catégories/
  // suggestions de matières premières restent chargés en entier (petites
  // tables de référence utilisées par les menus déroulants du formulaire).
  static const _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final _scrollController = ScrollController();

  // Recherche + filtre de statut (10/08) — la liste a explosé après la
  // complétion automatique du catalogue depuis l'Académie (phase148,
  // des centaines de nouveaux "Brouillon"), la retrouver un produit
  // précis ou distinguer ce qui est déjà publié devenait impossible
  // sans un moyen de filtrer. Les deux sont appliqués côté serveur
  // (voir `_buildProductsQuery`) plutôt que côté client, pour rester
  // valables au-delà de la seule page déjà chargée.
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  // 'all' | 'published' | 'draft'
  String _statusFilter = 'all';
  int? _publishedCount;
  int? _draftCount;
  // null = toutes catégories (11/08 — la liste mélangeait les 13
  // catégories, rendant un produit déjà publié difficile à retrouver).
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// Construit la requête produits en appliquant le filtre de statut et la
  /// recherche par nom actuellement sélectionnés — réutilisé par
  /// `_loadData` (1ère page) et `_loadMoreProducts` (pages suivantes) pour
  /// ne jamais les faire diverger.
  dynamic _buildProductsQuery() {
    var query = SupabaseConfig.client.from('products').select();
    if (_statusFilter == 'published') {
      query = query.eq('visibility', true);
    } else if (_statusFilter == 'draft') {
      query = query.eq('visibility', false);
    }
    if (_categoryFilter != null) {
      query = query.eq('category', _categoryFilter!);
    }
    final q = _searchQuery.trim();
    if (q.isNotEmpty) {
      query = query.ilike('name', '%$q%');
    }
    return query;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
      _loadData();
    });
  }

  void _onStatusFilterChanged(String value) {
    if (_statusFilter == value) return;
    setState(() => _statusFilter = value);
    _loadData();
  }

  void _onCategoryFilterChanged(String? value) {
    if (_categoryFilter == value) return;
    setState(() => _categoryFilter = value);
    _loadData();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadData() async {
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
      _page = 0;
      _hasMore = true;
    });
    try {
      // Les requêtes sont indépendantes — lancées en parallèle plutôt
      // qu'à la suite pour ne pas cumuler leurs temps de réseau (chacune
      // garde son propre repli silencieux en cas d'échec). Les catégories
      // passent désormais par le cache partagé (formats/parfums/catégories
      // — lib/core/reference_data/reference_table_cache.dart) plutôt
      // qu'une requête dédiée à chaque ouverture de cet écran.
      Future<List<Map<String, dynamic>>> loadNameSuggestions() async {
        try {
          final result = await SupabaseConfig.client
              .from('raw_material_name_suggestions')
              .select()
              .order('name');
          return List<Map<String, dynamic>>.from(result);
        } catch (_) {
          // Table pas encore créée (migration phase33 non exécutée) : le
          // champ nom reste un simple texte libre, rien de bloquant.
          return [];
        }
      }

      Future<void> refreshCategoriesCache() =>
          ref.read(categoriesCacheProvider.notifier).refresh();

      // Tous les usages déjà utilisés, tous produits confondus — juste la
      // colonne `use_cases` (léger), pas de pagination nécessaire pour ça.
      Future<List<String>> loadKnownUsages() async {
        try {
          final rows = await SupabaseConfig.client
              .from('products')
              .select('use_cases');
          final known = <String>{...kProductUsageSuggestions};
          for (final row in rows) {
            final usages = row['use_cases'] as List?;
            if (usages != null) known.addAll(usages.map((u) => u.toString()));
          }
          return known.toList();
        } catch (_) {
          // Colonne pas encore créée (migration phase73 non exécutée) :
          // repli sur la liste de suggestions de départ, rien de bloquant.
          return List<String>.from(kProductUsageSuggestions);
        }
      }

      final results = await Future.wait<dynamic>([
        // Tri alphabétique (11/08, remplace le tri par date de création) —
        // retrouver un produit déjà publié est plus facile en connaissant
        // son nom qu'en devinant quand il a été ajouté.
        _buildProductsQuery().order('name', ascending: true).range(
              0,
              _pageSize - 1,
            ),
        SupabaseConfig.client.from('business_units').select(),
        loadNameSuggestions(),
        refreshCategoriesCache(),
        loadKnownUsages(),
        // Compteurs Publiés/Brouillons (10/08) — affichés sur les puces de
        // filtre pour donner une vue d'ensemble immédiate, indépendants du
        // filtre de statut actuellement choisi (mais respectent la
        // recherche en cours, pour rester cohérents avec ce qui est listé).
        (() {
          var q = SupabaseConfig.client
              .from('products')
              .select('id')
              .eq('visibility', true);
          final s = _searchQuery.trim();
          if (s.isNotEmpty) q = q.ilike('name', '%$s%');
          return q.count();
        })(),
        (() {
          var q = SupabaseConfig.client
              .from('products')
              .select('id')
              .eq('visibility', false);
          final s = _searchQuery.trim();
          if (s.isNotEmpty) q = q.ilike('name', '%$s%');
          return q.count();
        })(),
      ]);
      final products = results[0];
      final units = results[1];
      final nameSuggestions = results[2];
      final knownUsages = results[4];
      final publishedCountRes = results[5];
      final draftCountRes = results[6];
      final productsList = List<Map<String, dynamic>>.from(products);
      setState(() {
        _products = productsList;
        _businessUnits = List<Map<String, dynamic>>.from(units);
        _nameSuggestions = List<Map<String, dynamic>>.from(nameSuggestions);
        _knownUsages = List<String>.from(knownUsages);
        _publishedCount = publishedCountRes.count;
        _draftCount = draftCountRes.count;
        _isLoading = false;
        _hasMore = productsList.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les produits.';
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final data = await _buildProductsQuery()
          .order('name', ascending: true)
          .range(nextPage * _pageSize, nextPage * _pageSize + _pageSize - 1);
      final rows = List<Map<String, dynamic>>.from(data);
      if (!mounted) return;
      setState(() {
        _products = [..._products, ...rows];
        _page = nextPage;
        _hasMore = rows.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<String?> _addNewCategory(String businessUnitId) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return null;

    try {
      await SupabaseConfig.client
          .from('categories')
          .insert({'business_unit_id': businessUnitId, 'name': name});
      // Invalide le cache partagé (force: true, ignore le TTL) pour que
      // cette catégorie fraîchement créée apparaisse immédiatement dans le
      // menu déroulant, plutôt que d'attendre jusqu'à 6h.
      await ref.read(categoriesCacheProvider.notifier).refresh(force: true);
      return name;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Erreur — cette catégorie existe peut-être déjà pour ce pilier.')),
      );
      return null;
    }
  }

  Future<void> _showProductDialog({Map<String, dynamic>? product}) async {
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final descCtrl =
        TextEditingController(text: product?['description'] ?? '');
    final barcodeCtrl =
        TextEditingController(text: product?['barcode'] ?? '');
    final priceDetailCtrl = TextEditingController(
        text: (product?['price_detail'] ?? '').toString());
    final priceGrosCtrl =
        TextEditingController(text: (product?['price_gros'] ?? '').toString());
    final grosThresholdCtrl = TextEditingController(
        text: (product?['gros_threshold_qty'] ?? 10).toString());
    final stockCtrl =
        TextEditingController(text: (product?['stock_quantity'] ?? 0).toString());

    String? selectedUnitId = product?['business_unit_id'] ??
        (_businessUnits.isNotEmpty ? _businessUnits.first['id'] : null);

    // La catégorie est stockée en texte sur `products.category` (compatible
    // avec les anciens produits créés avant la table `categories`), mais on
    // la choisit désormais dans un menu déroulant scopé au pilier plutôt que
    // de la retaper à la main (évite les fautes de frappe qui cassent le
    // regroupement des filtres côté client).
    String? selectedCategoryName = product?['category'];

    // Usages du produit (Savonnerie, Industriel, Nettoyage...) — voir
    // `kProductUsageSuggestions`. Simple liste de tags cochés, affichés en
    // badges sur la fiche produit côté client.
    final selectedUsages = <String>{
      ...List<String>.from(product?['use_cases'] ?? const []),
    };
    final usageCustomCtrl = TextEditingController();

    // Galerie photo (jusqu'à 10). `existingPhotos` = déjà en base (si
    // édition) ; `newPhotos` = fraîchement sélectionnées, pas encore
    // uploadées ; `removedExistingIds` = existantes marquées à supprimer.
    List<Map<String, dynamic>> existingPhotos = [];
    if (isEditing) {
      try {
        final result = await SupabaseConfig.client
            .from('product_images')
            .select()
            .eq('product_id', product['id'])
            .order('position');
        existingPhotos = List<Map<String, dynamic>>.from(result);
      } catch (_) {
        // Table `product_images` pas encore créée (migration phase8 non
        // exécutée) : on continue sans bloquer l'édition du produit.
      }
    }
    final List<XFile> newPhotos = [];
    final removedExistingIds = <String>{};
    bool isSaving = false;

    // Brouillon/Publié (09/08, demande explicite : les nouveaux produits
    // ne doivent pas apparaître côté client tant que la photo n'est pas
    // prête) — réutilise `products.visibility`, qui existait déjà en base
    // (phase1_schema) mais n'était pilotable que par défaut SQL (`true`),
    // jamais depuis ce formulaire. Un produit édité garde son statut
    // actuel ; un nouveau produit démarre en Brouillon.
    bool isVisible =
        isEditing ? (product['visibility'] as bool? ?? true) : false;

    // Lien optionnel vers une fiche Académie (09/08) — affiche un lien
    // "Fiche sécurité" sur la page produit client (voir
    // `academie_summary_public`, phase147). Liste chargée une fois à
    // l'ouverture du formulaire : le staff a un accès complet à
    // `raw_materials` (RLS `current_role_is_staff()`), pas besoin de
    // passer par la vue publique ici.
    List<Map<String, dynamic>> rawMaterialOptions = [];
    try {
      final rows = await SupabaseConfig.client
          .from('raw_materials')
          .select('id, name, category_name')
          .order('name');
      rawMaterialOptions = List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      // Repli silencieux : le champ de liaison sera juste vide si la
      // requête échoue (hors-ligne, table pas encore migrée...).
    }
    String? selectedRawMaterialId = product?['raw_material_id'] as String?;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Modifier le produit' : 'Nouveau produit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (context) {
                  // Suggestions de noms de matières premières (chimiques +
                  // alimentaires), scopées au pilier sélectionné, pour
                  // éviter de tout taper à la main — voir
                  // supabase/phase33_patch_raw_material_name_suggestions.sql.
                  // Reste un champ texte libre : on peut toujours taper un
                  // nom qui n'est pas dans la liste.
                  final selectedSlug = _businessUnits.firstWhere(
                    (u) => u['id'] == selectedUnitId,
                    orElse: () => <String, dynamic>{},
                  )['slug'];
                  final suggestionsForUnit = selectedSlug == null
                      ? const <Map<String, dynamic>>[]
                      : _nameSuggestions
                          .where((s) => s['business_unit_slug'] == selectedSlug)
                          .toList();
                  return Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.trim().isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      final query = textEditingValue.text.toLowerCase();
                      return suggestionsForUnit
                          .map((s) => s['name'] as String)
                          .where((n) => n.toLowerCase().contains(query));
                    },
                    onSelected: (selection) {
                      nameCtrl.text = selection;
                      // Pré-remplit aussi la catégorie si on la connaît et
                      // qu'aucune n'est encore choisie — gain de temps,
                      // reste modifiable ensuite.
                      final match = suggestionsForUnit.firstWhere(
                        (s) => s['name'] == selection,
                        orElse: () => <String, dynamic>{},
                      );
                      final matchedCategory = match['category_name'] as String?;
                      if (matchedCategory != null &&
                          (selectedCategoryName == null ||
                              selectedCategoryName!.isEmpty)) {
                        setDialogState(
                            () => selectedCategoryName = matchedCategory);
                      }
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onSubmitted) {
                      controller.text = nameCtrl.text;
                      controller.selection = TextSelection.collapsed(
                          offset: controller.text.length);
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                            labelText: 'Nom du produit'),
                        onChanged: (v) => nameCtrl.text = v,
                      );
                    },
                  );
                }),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: barcodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Code-barre (EAN/UPC, optionnel)',
                    helperText:
                        'Celui deja imprime sur l\'emballage du produit',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'Scanner le code-barre',
                      onPressed: () async {
                        final scanned = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _BarcodeCaptureScreen(),
                          ),
                        );
                        if (scanned != null) {
                          barcodeCtrl.text = scanned;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Photos (jusqu\'à 10, optionnel)',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final keptExisting = existingPhotos
                      .where((p) => !removedExistingIds.contains(p['id']))
                      .toList();
                  final totalCount = keptExisting.length + newPhotos.length;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final photo in keptExisting)
                        _PhotoThumb(
                          image: NetworkImage(photo['image_url'] as String),
                          onRemove: () => setDialogState(
                              () => removedExistingIds.add(photo['id'])),
                        ),
                      for (var i = 0; i < newPhotos.length; i++)
                        _PhotoThumb(
                          image: FileImage(File(newPhotos[i].path)),
                          onRemove: () =>
                              setDialogState(() => newPhotos.removeAt(i)),
                        ),
                      if (totalCount < 10)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final remaining = 10 - totalCount;
                            try {
                              final picked = await ImagePicker()
                                  .pickMultiImage(limit: remaining);
                              if (picked.isEmpty) return;
                              setDialogState(() {
                                newPhotos.addAll(
                                    picked.take(remaining).toList());
                              });
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Impossible d\'ouvrir la galerie photo.')),
                              );
                            }
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined),
                          ),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final categoriesForUnit = ref
                      .read(categoriesCacheProvider)
                      .where((c) =>
                          c['business_unit_id'] == selectedUnitId &&
                          c['active'] != false)
                      .toList();
                  // Si la catégorie du produit édité n'existe plus dans la
                  // liste (pilier changé, catégorie supprimée...), on évite
                  // de planter le Dropdown en la proposant quand même.
                  final items = <String>{
                    ...categoriesForUnit.map((c) => c['name'] as String),
                    if (selectedCategoryName != null &&
                        selectedCategoryName!.isNotEmpty)
                      selectedCategoryName!,
                  }.toList();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCategoryName,
                          decoration: const InputDecoration(
                              labelText: 'Catégorie (optionnel)'),
                          items: items
                              .map((name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setDialogState(() => selectedCategoryName = v),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Ajouter une catégorie',
                        onPressed: selectedUnitId == null
                            ? null
                            : () async {
                                final name =
                                    await _addNewCategory(selectedUnitId!);
                                if (name != null) {
                                  setDialogState(
                                      () => selectedCategoryName = name);
                                }
                              },
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                const Text('Pilier d\'entreprise'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: _businessUnits.map((u) {
                    return ChoiceChip(
                      label: Text(u['name']),
                      selected: selectedUnitId == u['id'],
                      onSelected: (_) {
                        setDialogState(() {
                          selectedUnitId = u['id'];
                          selectedCategoryName = null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Lien optionnel vers une fiche Académie (09/08) — voir
                // commentaire à la déclaration de `rawMaterialOptions`.
                Builder(builder: (context) {
                  final selectedMaterial = rawMaterialOptions.firstWhere(
                    (m) => m['id'] == selectedRawMaterialId,
                    orElse: () => <String, dynamic>{},
                  );
                  return Autocomplete<Map<String, dynamic>>(
                    initialValue: TextEditingValue(
                        text: selectedMaterial['name'] as String? ?? ''),
                    displayStringForOption: (m) =>
                        m['name'] as String? ?? '',
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.trim().isEmpty) {
                        return rawMaterialOptions;
                      }
                      final query = textEditingValue.text.toLowerCase();
                      return rawMaterialOptions.where((m) =>
                          (m['name'] as String? ?? '')
                              .toLowerCase()
                              .contains(query));
                    },
                    onSelected: (m) async {
                      final materialId = m['id'] as String?;
                      setDialogState(
                          () => selectedRawMaterialId = materialId);
                      // Auto-remplissage description/usages (09/08,
                      // demande explicite : "chaque produit doit avoir
                      // sa description automatiquement") — uniquement si
                      // les champs sont encore vides, pour ne jamais
                      // écraser un texte déjà saisi à la main. Même
                      // logique que le pré-remplissage de catégorie sur
                      // le champ "Nom du produit" plus haut.
                      if (materialId == null) return;
                      try {
                        final academie = await SupabaseConfig.client
                            .from('matieres_premieres_academie')
                            .select('id, particularite')
                            .eq('matiere_premiere_id', materialId)
                            .maybeSingle();
                        if (academie == null) return;
                        if (descCtrl.text.trim().isEmpty) {
                          final particularite =
                              (academie['particularite'] as String?)?.trim();
                          if (particularite != null &&
                              particularite.isNotEmpty) {
                            descCtrl.text = particularite;
                          }
                        }
                        if (selectedUsages.isEmpty) {
                          final usages = await SupabaseConfig.client
                              .from('matieres_premieres_usages')
                              .select('domaine_application')
                              .eq('academie_id', academie['id']);
                          setDialogState(() {
                            for (final row
                                in List<Map<String, dynamic>>.from(usages)) {
                              final domaine =
                                  row['domaine_application'] as String?;
                              if (domaine != null && domaine.isNotEmpty) {
                                selectedUsages.add(domaine);
                              }
                            }
                          });
                        }
                      } catch (_) {
                        // Repli silencieux : le staff garde la main pour
                        // remplir manuellement si la fiche Académie
                        // n'est pas accessible.
                      }
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Lier à une fiche Académie (optionnel)',
                          helperText: 'Affiche un lien "Fiche sécurité" '
                              'sur la page produit client',
                          suffixIcon: selectedRawMaterialId == null
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Retirer le lien',
                                  onPressed: () {
                                    controller.clear();
                                    setDialogState(
                                        () => selectedRawMaterialId = null);
                                  },
                                ),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 12),
                const Text('Usages (affichés sur la fiche produit)'),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  // Priorité aux usages propres à la catégorie choisie
                  // (kProductUsageSuggestionsByCategory, 05/08) — beaucoup
                  // plus pertinents qu'une liste générique unique (un
                  // "Gel Sol" n'a rien à voir avec "Savonnerie" ou
                  // "Métallurgie"). _knownUsages (liste générique + tout
                  // usage ajouté manuellement sur n'importe quel produit,
                  // voir _loadData) ne sert VRAIMENT de repli que si la
                  // catégorie n'a pas de liste dédiée (11/08, corrige un
                  // décalage entre ce commentaire et le code : avant, les
                  // deux étaient toujours mélangés, ce qui noyait la liste
                  // sous des centaines d'usages accumulés dans tout le
                  // catalogue — illisible une fois les ~150 matières
                  // premières Académie sync-ées automatiquement, cf.
                  // phase159).
                  final categoryOptions =
                      kProductUsageSuggestionsByCategory[selectedCategoryName];
                  final allOptions = <String>{
                    ...?categoryOptions,
                    if (categoryOptions == null || categoryOptions.isEmpty)
                      ..._knownUsages,
                    ...selectedUsages,
                  }.toList()
                    // Déjà cochés en premier (visible immédiatement sans
                    // scroller, notamment pour les fiches auto-remplies
                    // depuis l'Académie), puis le reste par ordre alphabétique.
                    ..sort((a, b) {
                      final aSelected = selectedUsages.contains(a);
                      final bSelected = selectedUsages.contains(b);
                      if (aSelected != bSelected) {
                        return aSelected ? -1 : 1;
                      }
                      return a.toLowerCase().compareTo(b.toLowerCase());
                    });
                  return Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: allOptions.map((usage) {
                      return FilterChip(
                        label: Text(usage),
                        selected: selectedUsages.contains(usage),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedUsages.add(usage);
                            } else {
                              selectedUsages.remove(usage);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: usageCustomCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Autre usage (optionnel)',
                          isDense: true,
                        ),
                        onSubmitted: (_) {
                          final value = usageCustomCtrl.text.trim();
                          if (value.isEmpty) return;
                          setDialogState(() {
                            selectedUsages.add(value);
                            usageCustomCtrl.clear();
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Ajouter cet usage',
                      onPressed: () {
                        final value = usageCustomCtrl.text.trim();
                        if (value.isEmpty) return;
                        setDialogState(() {
                          selectedUsages.add(value);
                          usageCustomCtrl.clear();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: priceDetailCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Prix Détail (Ar)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priceGrosCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Prix Gros (Ar)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: grosThresholdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Seuil quantité pour prix Gros',
                    helperText:
                        'Au-delà de cette quantité commandée, le prix Gros s\'applique automatiquement',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock actuel'),
                ),
                const SizedBox(height: 12),
                // Brouillon/Publié (09/08) — voir commentaire à la
                // déclaration de `isVisible`.
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isVisible ? 'Publié' : 'Brouillon',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                              isVisible
                                  ? 'Visible immédiatement dans le catalogue client.'
                                  : 'Invisible côté client tant que non publié (ex. photo pas encore prête).',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isVisible,
                        onChanged: (v) =>
                            setDialogState(() => isVisible = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                if (nameCtrl.text.trim().isEmpty) return;
                // Avertissement doux (pas un blocage dur — cohérent avec
                // le reste de l'app) avant de publier sans aucune photo :
                // le staff peut vouloir préparer la fiche à l'avance et
                // publier volontairement avant la photo, mais on évite
                // que ça arrive par inadvertance.
                final hasAnyPhoto = newPhotos.isNotEmpty ||
                    existingPhotos.any(
                        (p) => !removedExistingIds.contains(p['id']));
                if (isVisible && !hasAnyPhoto) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Publier sans photo ?'),
                      content: const Text(
                          'Ce produit n\'a encore aucune photo. Les '
                          'clients le verront tel quel dans le catalogue. '
                          'Publier quand même ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Publier quand même'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                }
                // Verrou anti-double-clic : sans ça, un appui multiple
                // pendant l'upload des photos (qui peut prendre plusieurs
                // secondes) créait plusieurs produits identiques.
                if (isSaving) return;
                setDialogState(() => isSaving = true);

                final payload = {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'barcode': barcodeCtrl.text.trim().isEmpty
                      ? null
                      : barcodeCtrl.text.trim(),
                  'category': selectedCategoryName ?? '',
                  'business_unit_id': selectedUnitId,
                  'use_cases': selectedUsages.toList(),
                  'visibility': isVisible,
                  'raw_material_id': selectedRawMaterialId,
                  'price_detail':
                      double.tryParse(priceDetailCtrl.text) ?? 0,
                  'price_gros': double.tryParse(priceGrosCtrl.text) ?? 0,
                  'gros_threshold_qty':
                      int.tryParse(grosThresholdCtrl.text) ?? 10,
                  'stock_quantity': double.tryParse(stockCtrl.text) ?? 0,
                };

                try {
                  String productId;
                  if (isEditing) {
                    productId = product['id'] as String;
                    await SupabaseConfig.client
                        .from('products')
                        .update(payload)
                        .eq('id', productId);
                  } else {
                    final inserted = await SupabaseConfig.client
                        .from('products')
                        .insert(payload)
                        .select()
                        .single();
                    productId = inserted['id'] as String;
                  }

                  // La galerie photo est gérée dans un try/catch séparé :
                  // si la migration `phase8_patch_product_images.sql` n'a
                  // pas encore été exécutée (table/bucket absents), le
                  // produit lui-même doit quand même s'enregistrer plutôt
                  // que d'afficher une fausse erreur globale.
                  var photosFailed = false;
                  if (newPhotos.isNotEmpty || removedExistingIds.isNotEmpty) {
                    try {
                      // Upload des nouvelles photos vers le bucket `products`.
                      final uploadedUrls = <String>[];
                      for (var i = 0; i < newPhotos.length; i++) {
                        final file = File(newPhotos[i].path);
                        final fileName =
                            '$productId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
                        await SupabaseConfig.client.storage
                            .from('products')
                            .upload(fileName, file);
                        uploadedUrls.add(SupabaseConfig.client.storage
                            .from('products')
                            .getPublicUrl(fileName));
                      }

                      // Suppression des fichiers retirés (best-effort).
                      for (final photo in existingPhotos) {
                        if (!removedExistingIds.contains(photo['id'])) {
                          continue;
                        }
                        try {
                          final url = photo['image_url'] as String;
                          final path = url.split('/products/').last;
                          await SupabaseConfig.client.storage
                              .from('products')
                              .remove([path]);
                        } catch (_) {}
                      }

                      // On réécrit la galerie au complet (existantes
                      // conservées + nouvelles) avec des positions propres
                      // 0..n-1 — plus simple qu'un update partiel vu le
                      // petit nombre de lignes (≤10).
                      await SupabaseConfig.client
                          .from('product_images')
                          .delete()
                          .eq('product_id', productId);
                      final keptUrls = existingPhotos
                          .where(
                              (p) => !removedExistingIds.contains(p['id']))
                          .map((p) => p['image_url'] as String)
                          .toList();
                      final finalUrls = [...keptUrls, ...uploadedUrls];
                      if (finalUrls.isNotEmpty) {
                        await SupabaseConfig.client
                            .from('product_images')
                            .insert([
                          for (var i = 0; i < finalUrls.length; i++)
                            {
                              'product_id': productId,
                              'image_url': finalUrls[i],
                              'position': i,
                            },
                        ]);
                      }
                      // La 1ère photo sert de couverture pour les vignettes
                      // catalogue (products.image_url).
                      await SupabaseConfig.client.from('products').update({
                        'image_url':
                            finalUrls.isNotEmpty ? finalUrls.first : null,
                      }).eq('id', productId);
                    } catch (_) {
                      photosFailed = true;
                    }
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                  if (photosFailed) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Produit enregistré, mais les photos n\'ont pas pu être sauvegardées.')));
                  }
                } catch (e) {
                  if (!mounted) return;
                  setDialogState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'enregistrement.')),
                  );
                }
              },
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text(
          '"${product['name']}" sera définitivement supprimé, ainsi que ses variantes, lots et photos associés. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseConfig.client
          .from('products')
          .delete()
          .eq('id', product['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit supprimé.')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Erreur lors de la suppression (le produit a peut-être déjà des commandes liées).')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Produits (Gros / Détail)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Produit'),
      ),
      body: Column(
        children: [
          _buildFilterBar(theme),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _products.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            Center(
                              child: Text(
                                _searchQuery.isNotEmpty ||
                                        _statusFilter != 'all'
                                    ? 'Aucun produit ne correspond à ce filtre.'
                                    : 'Aucun produit pour le moment.\nAppuyez sur "+" pour en créer un.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: EdgeInsets.all(4.w),
                          itemCount: _products.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => SizedBox(height: 1.h),
                          itemBuilder: (context, index) {
                            if (index >= _products.length) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            final p = _products[index];
                            final isDraft = p['visibility'] == false;
                            // "Stock bas" n'a de sens que pour un produit
                            // déjà publié et vendu — sur un brouillon tout
                            // juste créé (stock à 0 par défaut, voir
                            // phase148), ce badge ne fait que doubler
                            // l'information déjà donnée par "Brouillon"
                            // sans rien apporter (10/08).
                            final lowStock = !isDraft &&
                                (p['stock_quantity'] ?? 0) <=
                                    (p['low_stock_threshold'] ?? 5);
                            return Card(
                              child: Padding(
                                padding: EdgeInsets.all(3.w),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p['name'] ?? '',
                                            style: theme.textTheme.titleMedium,
                                          ),
                                        ),
                                        // Brouillon/Publié (09/08) — le
                                        // repère visuel dans la liste
                                        // admin pour savoir en un coup
                                        // d'œil ce qui attend encore une
                                        // photo avant publication.
                                        if (isDraft) ...[
                                          Chip(
                                            label: const Text('Brouillon'),
                                            backgroundColor: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            labelStyle: TextStyle(
                                                color: theme
                                                    .colorScheme.onSurfaceVariant,
                                                fontSize: 11),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        if (lowStock)
                                          Chip(
                                            label: const Text('Stock bas'),
                                            backgroundColor:
                                                theme.colorScheme.errorContainer,
                                            labelStyle: TextStyle(
                                                color: theme
                                                    .colorScheme.onErrorContainer,
                                                fontSize: 11),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      'Détail : ${_currency.format(p['price_detail'] ?? 0)}  ·  '
                                      'Gros (≥${p['gros_threshold_qty']}) : ${_currency.format(p['price_gros'] ?? 0)}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    Text(
                                      'Stock : ${p['stock_quantity']}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    SizedBox(height: 1.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        FilledButton.tonalIcon(
                                          onPressed: () =>
                                              _showProductDialog(product: p),
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 18),
                                          label: const Text('Modifier'),
                                        ),
                                        SizedBox(width: 2.w),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (value) {
                                            if (value == 'variantes') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ProductVariantsScreen(
                                                          product: p),
                                                ),
                                              );
                                            } else if (value == 'lot') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      BatchListScreen(
                                                          product: p),
                                                ),
                                              );
                                            } else if (value == 'supprimer') {
                                              _deleteProduct(p);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'variantes',
                                              child: Row(children: [
                                                Icon(Icons.tune, size: 18),
                                                SizedBox(width: 8),
                                                Text('Variantes'),
                                              ]),
                                            ),
                                            const PopupMenuItem(
                                              value: 'lot',
                                              child: Row(children: [
                                                Icon(
                                                    Icons
                                                        .inventory_2_outlined,
                                                    size: 18),
                                                SizedBox(width: 8),
                                                Text('Lots & QR code'),
                                              ]),
                                            ),
                                            const PopupMenuDivider(),
                                            PopupMenuItem(
                                              value: 'supprimer',
                                              child: Row(children: [
                                                Icon(Icons.delete_outline,
                                                    size: 18,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error),
                                                const SizedBox(width: 8),
                                                Text('Supprimer',
                                                    style: TextStyle(
                                                        color: Theme.of(
                                                                context)
                                                            .colorScheme
                                                            .error)),
                                              ]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
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

  /// Barre de recherche + filtre de statut (10/08) — voir commentaire à la
  /// déclaration de `_searchCtrl`/`_statusFilter`.
  Widget _buildFilterBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(4.w, 2.w, 4.w, 2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Rechercher un produit par nom...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          SizedBox(height: 1.5.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected: _statusFilter == 'all',
                  onSelected: (_) => _onStatusFilterChanged('all'),
                ),
                SizedBox(width: 2.w),
                ChoiceChip(
                  label: Text('Publiés'
                      '${_publishedCount != null ? ' ($_publishedCount)' : ''}'),
                  selected: _statusFilter == 'published',
                  onSelected: (_) => _onStatusFilterChanged('published'),
                ),
                SizedBox(width: 2.w),
                ChoiceChip(
                  label: Text('Brouillons'
                      '${_draftCount != null ? ' ($_draftCount)' : ''}'),
                  selected: _statusFilter == 'draft',
                  onSelected: (_) => _onStatusFilterChanged('draft'),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildCategoryDropdown(theme),
        ],
      ),
    );
  }

  /// Menu déroulant Catégorie (11/08) — 13 catégories désormais, trop pour
  /// des chips (deuxième ligne à faire défiler) ; un menu compact reste
  /// discret puisqu'il sert bien plus rarement que Publié/Brouillon.
  /// Les noms viennent du cache partagé (categoriesCacheProvider), rafraîchi
  /// par `_loadData` — toutes catégories/piliers confondus, dédupliquées
  /// (`products.category` est un simple texte, pas scopé par pilier ici).
  Widget _buildCategoryDropdown(ThemeData theme) {
    final categories = ref.watch(categoriesCacheProvider);
    final names = categories
        .map((c) => c['name'] as String?)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        initialValue: _categoryFilter,
        isExpanded: true,
        decoration: InputDecoration(
          isDense: true,
          labelText: 'Catégorie',
          prefixIcon: const Icon(Icons.category_outlined, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Toutes catégories'),
          ),
          for (final name in names)
            DropdownMenuItem<String>(value: name, child: Text(name)),
        ],
        onChanged: _onCategoryFilterChanged,
      ),
    );
  }
}

/// Miniature de photo produit avec bouton de suppression, utilisée dans le
/// formulaire d'ajout/édition (aussi bien pour les photos déjà en base que
/// pour celles fraîchement sélectionnées, pas encore uploadées).
class _PhotoThumb extends StatelessWidget {
  final ImageProvider image;
  final VoidCallback onRemove;

  const _PhotoThumb({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(image: image, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: Colors.black87,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Écran plein écran minimal pour scanner un code-barre EAN/UPC et le
/// renvoyer au formulaire produit (Navigator.pop avec la valeur lue).
class _BarcodeCaptureScreen extends StatefulWidget {
  const _BarcodeCaptureScreen();

  @override
  State<_BarcodeCaptureScreen> createState() => _BarcodeCaptureScreenState();
}

class _BarcodeCaptureScreenState extends State<_BarcodeCaptureScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (code == null || code.isEmpty) return;
    _handled = true;
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner le code-barre')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Visez le code-barre du produit',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
