import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../core/reference_data/reference_table_cache.dart';
import '../../core/supabase/supabase_config.dart';

const List<String> _academieEpiSuggestions = [
  'gants',
  'lunettes',
  'masque',
  'ventilation',
  'tablier',
  'bottes',
];

const List<String> _academieNiveauxDanger = [
  'Aucun',
  'Modéré',
  'Élevé',
  'Corrosif'
];

const List<String> _academieGrades = [
  'Standard',
  'Alimentaire',
  'Cosmétique',
  'Technique',
];

/// Domaines d'application suggérés pour les usages détaillés Académie
/// (06/08) — liste de DÉPART uniquement : `_knownAcademieDomains` (voir
/// `_loadData`) l'enrichit avec tout domaine déjà tapé sur n'importe
/// quelle fiche Académie, même principe que `kProductUsageSuggestions`
/// (product_management_real.dart) — un domaine ajouté une fois devient
/// réutilisable partout.
///
/// Les 18 grandes catégories ci-dessous sont la classification fournie
/// par l'utilisatrice (06/08). Les usages plus spécifiques qui ne font
/// pas doublon (ex : "Dentifrice", "Piscine", "Galvanoplastie") sont
/// conservés en complément, pour un choix plus précis quand utile.
const List<String> kAcademieUsageDomains = [
  // 18 grandes catégories
  'Hygiène & Entretien (Détergence)',
  'Savonnerie',
  'Cosmétique & Soins du Corps',
  'Peinture & Revêtements',
  'Traitement de l\'Eau',
  'Industrie Textile',
  'Industrie du Papier & Carton',
  'Agroalimentaire',
  'Agriculture & Élevage',
  'Aquaculture / Pêche',
  'Bâtiment & Construction',
  'Industrie Métallurgique',
  'Industrie Chimique / Process',
  'Pharmaceutique (usage encadré)',
  'Sécurité & Désinfection',
  'Automobile & Mécanique',
  'Usage Domestique / DIY',
  'Autres Industries Spécialisées',
  // Usages plus spécifiques (complémentaires, pas de doublon ci-dessus)
  'Ajustement pH',
  'Dégraissage',
  'Débouchage canalisation',
  'Parfumerie',
  'Dentifrice / Hygiène bucco-dentaire',
  'Shampoing / Soins capillaires',
  'Savon liquide / Gel douche',
  'Lessive',
  'Blanchisserie',
  'Anti-tartre',
  'Décapage',
  'Polissage',
  'Conservation alimentaire',
  'Cuir & tannerie',
  'Vernis & laques',
  'Traitement du bois',
  'Adhésifs & colles',
  'Traitement des eaux usées',
  'Piscine',
  'Galvanoplastie',
  'Plasturgie',
  'Caoutchouc',
  'Mines & carrières',
  'Imprimerie',
  'Verre & céramique',
];

/// Fiche complète d'une matière première (Formation) — description,
/// dosages d'usage par domaine, conditionnement, historique de prix,
/// galerie photo, ET (06/08, fusionné dans le même écran) la fiche
/// technique "Académie" (nom chimique, sécurité, usages détaillés avec
/// dosage) — accès payant DISTINCT côté client (voir
/// supabase/phase81_patch_academie_matieres_premieres.sql), mais
/// rédigée en une seule fois par le staff plutôt que dans un second
/// écran séparé. Voir supabase/phase40_schema.sql pour le schéma de
/// base.
class RawMaterialEditorScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? material;

  const RawMaterialEditorScreen({super.key, this.material});

  @override
  ConsumerState<RawMaterialEditorScreen> createState() =>
      _RawMaterialEditorScreenState();
}

class _RawMaterialEditorScreenState
    extends ConsumerState<RawMaterialEditorScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  List<Map<String, dynamic>> _businessUnits = [];
  List<Map<String, dynamic>> _nameSuggestions = [];
  String? _selectedUnitId;
  String? _selectedCategoryName;
  String? _suggestionNote;

  // Photos (06/08 : déplacées dans la fiche Académie, plafond réduit à 5).
  List<Map<String, dynamic>> _existingPhotos = [];
  final List<XFile> _newPhotos = [];
  final Set<String> _removedExistingPhotoIds = {};

  // Fiche Académie (06/08) — voir
  // supabase/phase81_patch_academie_matieres_premieres.sql.
  String? _academieId;
  final _academieNomChimiqueCtrl = TextEditingController();
  String? _academieGrade;
  final _academieAspectCtrl = TextEditingController();
  final _academiePhCtrl = TextEditingController();
  final _academieSolubiliteCtrl = TextEditingController();
  final _academieParticulariteCtrl = TextEditingController();
  final _academieDifferenceCtrl = TextEditingController();
  final _academiePremiersSecoursCtrl = TextEditingController();
  final _academieIncompatibilitesCtrl = TextEditingController();
  final _academieStockageCtrl = TextEditingController();
  String? _academieNiveauDanger;
  final Set<String> _academieEpiRequis = {};
  String _academieStatutVerification = 'a_valider';
  List<Map<String, dynamic>> _academieUsages = [];
  List<String> _knownAcademieDomains = List<String>.from(kAcademieUsageDomains);
  // Fiches Académie existantes (autres matières) dont on peut copier les
  // réglages sécurité (grade, danger, EPI, premiers secours,
  // incompatibilités, stockage) — souvent répétitifs entre matières
  // similaires (ex : plusieurs bases fortes). Jamais nom_chimique/
  // aspect/pH/solubilité/usages, toujours propres à chaque substance.
  List<Map<String, dynamic>> _academieSafetyTemplates = [];

  /// A-t-on commencé à remplir la section Académie ? Si oui, les champs
  /// clés (nom chimique, aspect, pH, solubilité — "Nom commun" est
  /// toujours rempli via le champ "Nom" partagé avec la fiche de base)
  /// deviennent obligatoires (voir `_save`) — si la section est
  /// entièrement vide, on la laisse pour plus tard sans bloquer
  /// l'enregistrement du reste de la fiche.
  bool get _academieHasContent =>
      _academieId != null ||
      _academieNomChimiqueCtrl.text.trim().isNotEmpty ||
      _academieGrade != null ||
      _academieAspectCtrl.text.trim().isNotEmpty ||
      _academiePhCtrl.text.trim().isNotEmpty ||
      _academieSolubiliteCtrl.text.trim().isNotEmpty ||
      _academieParticulariteCtrl.text.trim().isNotEmpty ||
      _academieDifferenceCtrl.text.trim().isNotEmpty ||
      _academieNiveauDanger != null ||
      _academieEpiRequis.isNotEmpty ||
      _academiePremiersSecoursCtrl.text.trim().isNotEmpty ||
      _academieIncompatibilitesCtrl.text.trim().isNotEmpty ||
      _academieStockageCtrl.text.trim().isNotEmpty ||
      _academieStatutVerification != 'a_valider' ||
      _academieUsages.any((u) =>
          (u['domaine_application'] as String? ?? '').trim().isNotEmpty);

  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditing => widget.material != null;

  @override
  void initState() {
    super.initState();
    final m = widget.material;
    _nameCtrl = TextEditingController(text: m?['name'] ?? '');
    _descCtrl = TextEditingController(text: m?['description'] ?? '');
    _selectedUnitId = m?['business_unit_id'];
    _selectedCategoryName = m?['category_name'];
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _academieNomChimiqueCtrl.dispose();
    _academieAspectCtrl.dispose();
    _academiePhCtrl.dispose();
    _academieSolubiliteCtrl.dispose();
    _academieParticulariteCtrl.dispose();
    _academieDifferenceCtrl.dispose();
    _academiePremiersSecoursCtrl.dispose();
    _academieIncompatibilitesCtrl.dispose();
    _academieStockageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client.from('business_units').select(),
        SupabaseConfig.client
            .from('raw_material_name_suggestions')
            .select()
            .order('name'),
      ]);
      await ref.read(categoriesCacheProvider.notifier).refresh();

      _businessUnits = List<Map<String, dynamic>>.from(results[0] as List);
      _nameSuggestions = List<Map<String, dynamic>>.from(results[1] as List);
      _selectedUnitId ??=
          _businessUnits.isNotEmpty ? _businessUnits.first['id'] : null;

      if (_isEditing) {
        final photos = await SupabaseConfig.client
            .from('raw_material_images')
            .select()
            .eq('raw_material_id', widget.material!['id'])
            .order('position');
        _existingPhotos = List<Map<String, dynamic>>.from(photos);
      }
    } catch (_) {
      // Repli tolérant : la fiche reste éditable même si une des tables
      // enfant (phase40 pas encore exécutée) ne répond pas.
    }

    // Fiche Académie (06/08) — fusionnée dans le même écran d'édition.
    try {
      // Domaines déjà tapés sur N'IMPORTE QUELLE fiche Académie —
      // enrichit les suggestions de départ (kAcademieUsageDomains).
      final domainRows = await SupabaseConfig.client
          .from('matieres_premieres_usages')
          .select('domaine_application');
      final knownDomains = <String>{...kAcademieUsageDomains};
      for (final row in domainRows) {
        final domain = row['domaine_application'] as String?;
        if (domain != null && domain.trim().isNotEmpty) knownDomains.add(domain);
      }
      _knownAcademieDomains = knownDomains.toList();

      final safetyRows = await SupabaseConfig.client
          .from('matieres_premieres_academie')
          .select(
              'matiere_premiere_id, grade, niveau_danger, epi_requis, premiers_secours, incompatibilites, stockage, raw_materials(name)');
      _academieSafetyTemplates = List<Map<String, dynamic>>.from(safetyRows)
          .where((r) => r['matiere_premiere_id'] != widget.material?['id'])
          .toList();

      if (_isEditing) {
        final sheet = await SupabaseConfig.client
            .from('matieres_premieres_academie')
            .select()
            .eq('matiere_premiere_id', widget.material!['id'])
            .maybeSingle();
        if (sheet != null) {
          _academieId = sheet['id'] as String;
          _academieNomChimiqueCtrl.text = sheet['nom_chimique'] as String? ?? '';
          // "Nom commun" partage désormais le même champ que "Nom" (fiche
          // de base) — si une valeur plus riche existait déjà côté
          // Académie (synonymes multiples), on la reprend pour ne rien
          // perdre plutôt que de la remplacer par le nom de base, plus
          // court.
          final existingSynonymes = sheet['synonymes'] as String?;
          if (existingSynonymes != null && existingSynonymes.isNotEmpty) {
            _nameCtrl.text = existingSynonymes;
          }
          _academieGrade = sheet['grade'] as String?;
          _academieAspectCtrl.text = sheet['aspect'] as String? ?? '';
          _academiePhCtrl.text = sheet['ph_solution'] as String? ?? '';
          _academieSolubiliteCtrl.text = sheet['solubilite'] as String? ?? '';
          _academieParticulariteCtrl.text =
              sheet['particularite'] as String? ?? '';
          _academieDifferenceCtrl.text =
              sheet['difference_produit_similaire'] as String? ?? '';
          _academiePremiersSecoursCtrl.text =
              sheet['premiers_secours'] as String? ?? '';
          _academieIncompatibilitesCtrl.text =
              sheet['incompatibilites'] as String? ?? '';
          _academieStockageCtrl.text = sheet['stockage'] as String? ?? '';
          _academieNiveauDanger = sheet['niveau_danger'] as String?;
          _academieStatutVerification =
              sheet['statut_verification'] as String? ?? 'a_valider';
          _academieEpiRequis
            ..clear()
            ..addAll(List<String>.from(sheet['epi_requis'] as List? ?? []));

          final usages = await SupabaseConfig.client
              .from('matieres_premieres_usages')
              .select()
              .eq('academie_id', _academieId as Object)
              .order('ordre');
          _academieUsages = List<Map<String, dynamic>>.from(usages);
        }
      }
    } catch (_) {
      // Migration phase81 pas encore exécutée, ou pas de fiche Académie
      // pour l'instant — section vide, rien de bloquant.
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _addAcademieUsageRow() {
    setState(() {
      _academieUsages.add({
        'domaine_application': '',
        'technique_methode': '',
        'dosage_legacy': '',
        'a_verifier_labo': false,
      });
    });
  }

  /// Copie les réglages sécurité (grade, danger, EPI, premiers secours,
  /// incompatibilités, stockage) d'une autre fiche Académie déjà
  /// documentée — utile pour des matières similaires (ex : plusieurs
  /// bases fortes partagent souvent les mêmes EPI). Ne touche jamais
  /// nom chimique/aspect/pH/solubilité/usages, propres à chaque
  /// substance.
  Future<void> _pickAcademieSafetyTemplate() async {
    if (_academieSafetyTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Aucune autre fiche Académie à copier pour l\'instant.')));
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = _academieSafetyTemplates.where((t) {
              final name = (t['raw_materials'] is Map
                      ? t['raw_materials']['name'] as String?
                      : null) ??
                  '';
              return search.isEmpty ||
                  name.toLowerCase().contains(search.toLowerCase());
            }).toList();
            return AlertDialog(
              title: const Text('Dupliquer les réglages sécurité depuis…'),
              content: SizedBox(
                width: double.maxFinite,
                height: 320,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Rechercher une matière première…'),
                      onChanged: (v) => setDialogState(() => search = v),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('Aucun résultat.'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final t = filtered[i];
                                final name = t['raw_materials'] is Map
                                    ? t['raw_materials']['name'] as String?
                                    : null;
                                return ListTile(
                                  title: Text(name ?? 'Matière première'),
                                  onTap: () => Navigator.pop(context, t),
                                );
                              },
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
              ],
            );
          },
        );
      },
    );
    if (selected == null) return;
    setState(() {
      _academieGrade = selected['grade'] as String?;
      _academieNiveauDanger = selected['niveau_danger'] as String?;
      _academieEpiRequis
        ..clear()
        ..addAll(List<String>.from(selected['epi_requis'] as List? ?? []));
      _academiePremiersSecoursCtrl.text =
          selected['premiers_secours'] as String? ?? '';
      _academieIncompatibilitesCtrl.text =
          selected['incompatibilites'] as String? ?? '';
      _academieStockageCtrl.text = selected['stockage'] as String? ?? '';
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Réglages sécurité copiés — vérifie qu\'ils s\'appliquent bien à cette matière avant d\'enregistrer.')));
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

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Le nom et le pilier sont obligatoires.')));
      return;
    }
    if (_academieHasContent &&
        (_academieNomChimiqueCtrl.text.trim().isEmpty ||
            _academieAspectCtrl.text.trim().isEmpty ||
            _academiePhCtrl.text.trim().isEmpty ||
            _academieSolubiliteCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Dans la section Académie : nom chimique, aspect, pH en solution et solubilité sont obligatoires dès que cette section est commencée.')));
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);

    // Depuis le 06/08 (sur demande) : cet écran ne gère plus, côté fiche
    // de base, que Pilier + Catégorie chimique + Description + Photos —
    // danger (texte libre), stock, prix, usages catalogue, conditionnement
    // et historique de prix ne sont plus modifiables ici (les colonnes
    // restent en base, juste plus touchées par cet écran).
    final payload = {
      'name': _nameCtrl.text.trim(),
      'category_name': _selectedCategoryName ?? '',
      'business_unit_id': _selectedUnitId,
      'description':
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    };

    try {
      String materialId;
      if (_isEditing) {
        materialId = widget.material!['id'] as String;
        await SupabaseConfig.client
            .from('raw_materials')
            .update(payload)
            .eq('id', materialId);
      } else {
        final inserted = await SupabaseConfig.client
            .from('raw_materials')
            .insert(payload)
            .select()
            .single();
        materialId = inserted['id'] as String;
      }

      // Photos : même mécanique que product_images (phase8) — réécriture
      // complète de la galerie, bucket dédié `raw-materials`. Plafond
      // réduit à 5 (06/08, déplacées dans la fiche Académie).
      if (_newPhotos.isNotEmpty || _removedExistingPhotoIds.isNotEmpty) {
        try {
          final uploadedUrls = <String>[];
          for (var i = 0; i < _newPhotos.length; i++) {
            final file = File(_newPhotos[i].path);
            final fileName =
                '$materialId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            await SupabaseConfig.client.storage
                .from('raw-materials')
                .upload(fileName, file);
            uploadedUrls.add(SupabaseConfig.client.storage
                .from('raw-materials')
                .getPublicUrl(fileName));
          }
          for (final photo in _existingPhotos) {
            if (!_removedExistingPhotoIds.contains(photo['id'])) continue;
            try {
              final url = photo['image_url'] as String;
              final path = url.split('/raw-materials/').last;
              await SupabaseConfig.client.storage
                  .from('raw-materials')
                  .remove([path]);
            } catch (_) {}
          }
          await SupabaseConfig.client
              .from('raw_material_images')
              .delete()
              .eq('raw_material_id', materialId);
          final keptUrls = _existingPhotos
              .where((p) => !_removedExistingPhotoIds.contains(p['id']))
              .map((p) => p['image_url'] as String)
              .toList();
          final finalUrls = [...keptUrls, ...uploadedUrls];
          if (finalUrls.isNotEmpty) {
            await SupabaseConfig.client.from('raw_material_images').insert([
              for (var i = 0; i < finalUrls.length; i++)
                {
                  'raw_material_id': materialId,
                  'image_url': finalUrls[i],
                  'position': i,
                },
            ]);
          }
          await SupabaseConfig.client.from('raw_materials').update({
            'image_url': finalUrls.isNotEmpty ? finalUrls.first : null,
          }).eq('id', materialId);
        } catch (_) {}
      }

      // Fiche Académie (06/08) — même mécanique que usages/conditionnement :
      // upsert de la fiche puis réécriture complète des usages détaillés.
      // Section entièrement vide -> on la laisse pour plus tard, pas
      // d'écriture (évite aussi de violer le "not null" de phase82 avec
      // des chaînes vides).
      if (_academieHasContent) {
        final academieSaved = await SupabaseConfig.client
            .from('matieres_premieres_academie')
            .upsert(
              {
                'matiere_premiere_id': materialId,
                'nom_chimique': _academieNomChimiqueCtrl.text.trim(),
                'synonymes': _nameCtrl.text.trim(),
                'grade': _academieGrade,
                'aspect': _academieAspectCtrl.text.trim(),
                'ph_solution': _academiePhCtrl.text.trim(),
                'solubilite': _academieSolubiliteCtrl.text.trim(),
                'particularite': _academieParticulariteCtrl.text.trim().isEmpty
                    ? null
                    : _academieParticulariteCtrl.text.trim(),
                'difference_produit_similaire':
                    _academieDifferenceCtrl.text.trim().isEmpty
                        ? null
                        : _academieDifferenceCtrl.text.trim(),
                'niveau_danger': _academieNiveauDanger,
                'epi_requis': _academieEpiRequis.toList(),
                'premiers_secours':
                    _academiePremiersSecoursCtrl.text.trim().isEmpty
                        ? null
                        : _academiePremiersSecoursCtrl.text.trim(),
                'incompatibilites':
                    _academieIncompatibilitesCtrl.text.trim().isEmpty
                        ? null
                        : _academieIncompatibilitesCtrl.text.trim(),
                'stockage': _academieStockageCtrl.text.trim().isEmpty
                    ? null
                    : _academieStockageCtrl.text.trim(),
                'statut_verification': _academieStatutVerification,
                'updated_at': DateTime.now().toIso8601String(),
              },
              onConflict: 'matiere_premiere_id',
            )
            .select()
            .single();
        final academieId = academieSaved['id'] as String;
        _academieId = academieId;

        await SupabaseConfig.client
            .from('matieres_premieres_usages')
            .delete()
            .eq('academie_id', academieId);
        final validAcademieUsages = _academieUsages
            .where((u) =>
                (u['domaine_application'] as String? ?? '').trim().isNotEmpty)
            .toList();
        if (validAcademieUsages.isNotEmpty) {
          await SupabaseConfig.client
              .from('matieres_premieres_usages')
              .insert([
            for (var i = 0; i < validAcademieUsages.length; i++)
              {
                'academie_id': academieId,
                'domaine_application': (validAcademieUsages[i]
                        ['domaine_application'] as String)
                    .trim(),
                'technique_methode':
                    (validAcademieUsages[i]['technique_methode'] as String? ??
                                '')
                            .trim()
                            .isEmpty
                        ? null
                        : (validAcademieUsages[i]['technique_methode']
                                as String)
                            .trim(),
                'dosage_legacy': (validAcademieUsages[i]['dosage_legacy']
                                as String? ??
                            '')
                        .trim()
                        .isEmpty
                    ? null
                    : (validAcademieUsages[i]['dosage_legacy'] as String)
                        .trim(),
                'a_verifier_labo':
                    validAcademieUsages[i]['a_verifier_labo'] == true,
                'ordre': i,
              },
          ]);
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Erreur lors de l\'enregistrement (migration phase40 exécutée ?).')));
    }
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette fiche ?'),
        content: Text(
            '"${widget.material!['name']}" sera définitivement supprimée, avec ses photos, usages, conditionnements et historique de prix. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseConfig.client
          .from('raw_materials')
          .delete()
          .eq('id', widget.material!['id']);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche Académie')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final categoriesForUnit = ref
        .watch(categoriesCacheProvider)
        .where((c) =>
            c['business_unit_id'] == _selectedUnitId && c['active'] != false)
        .toList();
    final categoryItems = <String>{
      ...categoriesForUnit.map((c) => c['name'] as String),
      if (_selectedCategoryName != null && _selectedCategoryName!.isNotEmpty)
        _selectedCategoryName!,
    }.toList();

    final selectedSlug = _businessUnits.firstWhere(
      (u) => u['id'] == _selectedUnitId,
      orElse: () => <String, dynamic>{},
    )['slug'];
    final suggestionsForUnit = selectedSlug == null
        ? const <Map<String, dynamic>>[]
        : _nameSuggestions
            .where((s) => s['business_unit_slug'] == selectedSlug)
            .toList();

    Widget _academieField(TextEditingController ctrl, String label,
        {int maxLines = 1, bool required = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
              labelText: required ? '$label *' : label,
              border: const OutlineInputBorder()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Fiche Académie' : 'Nouvelle fiche Académie'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Text('Pilier d\'entreprise', style: theme.textTheme.labelLarge),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 8,
            children: _businessUnits.map((u) {
              return ChoiceChip(
                label: Text(u['name'] ?? ''),
                selected: _selectedUnitId == u['id'],
                onSelected: (_) => setState(() {
                  _selectedUnitId = u['id'];
                  _selectedCategoryName = null;
                }),
              );
            }).toList(),
          ),
          SizedBox(height: 3.h),
          const Divider(),
          SizedBox(height: 2.h),
          Text('* Champs obligatoires', style: theme.textTheme.bodySmall),
          SizedBox(height: 1.h),
          Text('Photos (jusqu\'à 5, optionnel)',
              style: theme.textTheme.labelLarge),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final photo in _existingPhotos
                  .where((p) => !_removedExistingPhotoIds.contains(p['id'])))
                _PhotoThumb(
                  image: NetworkImage(photo['image_url'] as String),
                  onRemove: () => setState(
                      () => _removedExistingPhotoIds.add(photo['id'])),
                ),
              for (var i = 0; i < _newPhotos.length; i++)
                _PhotoThumb(
                  image: FileImage(File(_newPhotos[i].path)),
                  onRemove: () => setState(() => _newPhotos.removeAt(i)),
                ),
              if ((_existingPhotos
                              .where((p) => !_removedExistingPhotoIds
                                  .contains(p['id']))
                              .length +
                          _newPhotos.length) <
                      5)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final current = _existingPhotos
                            .where((p) =>
                                !_removedExistingPhotoIds.contains(p['id']))
                            .length +
                        _newPhotos.length;
                    final remaining = 5 - current;
                    try {
                      final picked =
                          await ImagePicker().pickMultiImage(limit: remaining);
                      if (picked.isEmpty) return;
                      setState(() =>
                          _newPhotos.addAll(picked.take(remaining).toList()));
                    } catch (_) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Impossible d\'ouvrir la galerie photo.')));
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.add_a_photo_outlined),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          _academieField(_academieNomChimiqueCtrl, 'Nom chimique',
              required: true),
          Autocomplete<String>(
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
              _nameCtrl.text = selection;
              final match = suggestionsForUnit.firstWhere(
                (s) => s['name'] == selection,
                orElse: () => <String, dynamic>{},
              );
              setState(() {
                final matchedCategory = match['category_name'] as String?;
                if (matchedCategory != null &&
                    (_selectedCategoryName == null ||
                        _selectedCategoryName!.isEmpty)) {
                  _selectedCategoryName = matchedCategory;
                }
                _suggestionNote = match['note'] as String?;
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              controller.text = _nameCtrl.text;
              controller.selection =
                  TextSelection.collapsed(offset: controller.text.length);
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                    labelText: 'Nom commun *',
                    helperText: 'Sert aussi de titre à la fiche produit.',
                    border: OutlineInputBorder()),
                onChanged: (v) => _nameCtrl.text = v,
              );
            },
          ),
          if (_suggestionNote != null) ...[
            SizedBox(height: 0.5.h),
            Text('Repère (INS) : $_suggestionNote',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ],
          SizedBox(height: 1.5.h),
          DropdownButtonFormField<String>(
            initialValue: _academieGrade,
            decoration: const InputDecoration(
                labelText: 'Grade', border: OutlineInputBorder()),
            items: <String>{
              ..._academieGrades,
              if (_academieGrade != null) _academieGrade!,
            }
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _academieGrade = v),
          ),
          SizedBox(height: 1.5.h),
          _academieField(_academieAspectCtrl, 'Aspect', required: true),
          _academieField(_academiePhCtrl, 'pH en solution', required: true),
          _academieField(_academieSolubiliteCtrl, 'Solubilité',
              required: true),
          SizedBox(height: 1.5.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryName,
                  decoration:
                      const InputDecoration(labelText: 'Catégorie chimique'),
                  items: categoryItems
                      .map((name) =>
                          DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryName = v),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Ajouter une catégorie',
                onPressed: _selectedUnitId == null
                    ? null
                    : () async {
                        final name = await _addNewCategory(_selectedUnitId!);
                        if (name != null) {
                          setState(() => _selectedCategoryName = name);
                        }
                      },
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          TextField(
            controller: _descCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              helperText:
                  'Rédigée à partir de votre recherche — pas un copier-coller de fiche technique tierce.',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 1.5.h),
          _academieField(_academieParticulariteCtrl,
              'Particularité (ex : hygroscopique, exothermique)'),
          _academieField(_academieDifferenceCtrl,
              'Différence avec un produit similaire',
              maxLines: 2),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: Text('Sécurité', style: theme.textTheme.titleMedium),
              ),
              TextButton.icon(
                onPressed: _pickAcademieSafetyTemplate,
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Dupliquer depuis…'),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            initialValue: _academieNiveauDanger,
            decoration: const InputDecoration(
                labelText: 'Niveau de danger / précaution',
                border: OutlineInputBorder()),
            items: _academieNiveauxDanger
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (v) => setState(() => _academieNiveauDanger = v),
          ),
          SizedBox(height: 1.5.h),
          Text('EPI requis', style: theme.textTheme.labelLarge),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _academieEpiSuggestions
                .map((e) => FilterChip(
                      label: Text(e),
                      selected: _academieEpiRequis.contains(e),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _academieEpiRequis.add(e);
                        } else {
                          _academieEpiRequis.remove(e);
                        }
                      }),
                    ))
                .toList(),
          ),
          SizedBox(height: 1.5.h),
          _academieField(_academiePremiersSecoursCtrl, 'Premiers secours',
              maxLines: 3),
          _academieField(
              _academieIncompatibilitesCtrl, 'Incompatibilités',
              maxLines: 2),
          _academieField(_academieStockageCtrl, 'Stockage', maxLines: 2),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vérifié (labo)'),
            subtitle: const Text(
                'Désactivé = badge "⚠️ À vérifier en labo" affiché au client'),
            value: _academieStatutVerification == 'verifie',
            onChanged: (v) => setState(() =>
                _academieStatutVerification = v ? 'verifie' : 'a_valider'),
          ),
          SizedBox(height: 2.h),
          _SectionHeader(
            title: 'Usages détaillés (Académie)',
            onAdd: _addAcademieUsageRow,
          ),
          Text(
            'Visible seulement après achat Académie — domaine précis + dosage/technique, indépendant du catalogue.',
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: 1.h),
          for (var i = 0; i < _academieUsages.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (textEditingValue) {
                              final query =
                                  textEditingValue.text.toLowerCase();
                              if (query.isEmpty) return _knownAcademieDomains;
                              return _knownAcademieDomains.where(
                                  (d) => d.toLowerCase().contains(query));
                            },
                            onSelected: (selection) => setState(() =>
                                _academieUsages[i]['domaine_application'] =
                                    selection),
                            fieldViewBuilder:
                                (context, controller, focusNode, onSubmitted) {
                              controller.text = _academieUsages[i]
                                      ['domaine_application'] as String? ??
                                  '';
                              controller.selection = TextSelection.collapsed(
                                  offset: controller.text.length);
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                    labelText: 'Domaine d\'application',
                                    isDense: true),
                                onChanged: (v) => _academieUsages[i]
                                    ['domaine_application'] = v,
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              setState(() => _academieUsages.removeAt(i)),
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue:
                          _academieUsages[i]['technique_methode'] as String?,
                      decoration: const InputDecoration(
                          labelText: 'Technique / méthode', isDense: true),
                      onChanged: (v) =>
                          _academieUsages[i]['technique_methode'] = v,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue:
                          _academieUsages[i]['dosage_legacy'] as String?,
                      decoration: const InputDecoration(
                          labelText: 'Dosage / concentration (ex : 1-5%)',
                          isDense: true),
                      onChanged: (v) =>
                          _academieUsages[i]['dosage_legacy'] = v,
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('À vérifier en labo'),
                      value: _academieUsages[i]['a_verifier_labo'] == true,
                      onChanged: (v) => setState(
                          () => _academieUsages[i]['a_verifier_labo'] = v),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 4.h),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;

  const _SectionHeader({required this.title, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (onAdd != null)
          IconButton(
              icon: const Icon(Icons.add_circle_outline), onPressed: onAdd),
      ],
    );
  }
}

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
