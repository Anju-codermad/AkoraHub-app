import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

const List<String> _epiSuggestions = [
  'gants',
  'lunettes',
  'masque',
  'ventilation',
  'tablier',
  'bottes',
];

const List<String> _niveauxDanger = ['Aucun', 'Modéré', 'Élevé', 'Corrosif'];

/// Formulaire d'édition de la fiche technique "Académie" d'une matière
/// première (06/08) — voir
/// supabase/phase81_patch_academie_matieres_premieres.sql. Accessible
/// UNIQUEMENT depuis la fiche d'une matière première existante
/// (raw_material_editor_screen.dart), jamais depuis un produit fini.
/// Modèle générique, applicable à toute catégorie chimique.
class AcademieEditorScreen extends StatefulWidget {
  final String rawMaterialId;
  final String rawMaterialName;

  const AcademieEditorScreen({
    super.key,
    required this.rawMaterialId,
    required this.rawMaterialName,
  });

  @override
  State<AcademieEditorScreen> createState() => _AcademieEditorScreenState();
}

class _AcademieEditorScreenState extends State<AcademieEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _academieId;

  final _nomChimiqueCtrl = TextEditingController();
  final _synonymesCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _aspectCtrl = TextEditingController();
  final _phCtrl = TextEditingController();
  final _solubiliteCtrl = TextEditingController();
  final _particulariteCtrl = TextEditingController();
  final _differenceCtrl = TextEditingController();
  final _premiersSecoursCtrl = TextEditingController();
  final _incompatibilitesCtrl = TextEditingController();
  final _stockageCtrl = TextEditingController();

  String? _niveauDanger;
  final Set<String> _epiRequis = {};
  String _statutVerification = 'a_valider';

  List<Map<String, dynamic>> _usages = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nomChimiqueCtrl.dispose();
    _synonymesCtrl.dispose();
    _gradeCtrl.dispose();
    _aspectCtrl.dispose();
    _phCtrl.dispose();
    _solubiliteCtrl.dispose();
    _particulariteCtrl.dispose();
    _differenceCtrl.dispose();
    _premiersSecoursCtrl.dispose();
    _incompatibilitesCtrl.dispose();
    _stockageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final sheet = await SupabaseConfig.client
          .from('matieres_premieres_academie')
          .select()
          .eq('matiere_premiere_id', widget.rawMaterialId)
          .maybeSingle();
      if (sheet != null) {
        _academieId = sheet['id'] as String;
        _nomChimiqueCtrl.text = sheet['nom_chimique'] as String? ?? '';
        _synonymesCtrl.text = sheet['synonymes'] as String? ?? '';
        _gradeCtrl.text = sheet['grade'] as String? ?? '';
        _aspectCtrl.text = sheet['aspect'] as String? ?? '';
        _phCtrl.text = sheet['ph_solution'] as String? ?? '';
        _solubiliteCtrl.text = sheet['solubilite'] as String? ?? '';
        _particulariteCtrl.text = sheet['particularite'] as String? ?? '';
        _differenceCtrl.text =
            sheet['difference_produit_similaire'] as String? ?? '';
        _premiersSecoursCtrl.text = sheet['premiers_secours'] as String? ?? '';
        _incompatibilitesCtrl.text = sheet['incompatibilites'] as String? ?? '';
        _stockageCtrl.text = sheet['stockage'] as String? ?? '';
        _niveauDanger = sheet['niveau_danger'] as String?;
        _statutVerification =
            sheet['statut_verification'] as String? ?? 'a_valider';
        _epiRequis
          ..clear()
          ..addAll(List<String>.from(sheet['epi_requis'] as List? ?? []));

        final usages = await SupabaseConfig.client
            .from('matieres_premieres_usages')
            .select()
            .eq('academie_id', _academieId as Object)
            .order('ordre');
        _usages = List<Map<String, dynamic>>.from(usages);
      }
    } catch (_) {
      // Migration phase81 pas encore exécutée, ou pas de fiche Académie
      // pour l'instant — formulaire vide, comportement normal.
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _addUsageRow() {
    setState(() {
      _usages.add({
        'domaine_application': '',
        'technique_methode': '',
        'dosage_concentration': '',
        'a_verifier_labo': false,
      });
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Nom chimique, nom commun, aspect, pH en solution et solubilité sont obligatoires.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final saved = await SupabaseConfig.client
          .from('matieres_premieres_academie')
          .upsert(
            {
              'matiere_premiere_id': widget.rawMaterialId,
              'nom_chimique': _nomChimiqueCtrl.text.trim().isEmpty
                  ? null
                  : _nomChimiqueCtrl.text.trim(),
              'synonymes': _synonymesCtrl.text.trim().isEmpty
                  ? null
                  : _synonymesCtrl.text.trim(),
              'grade': _gradeCtrl.text.trim().isEmpty
                  ? null
                  : _gradeCtrl.text.trim(),
              'aspect': _aspectCtrl.text.trim().isEmpty
                  ? null
                  : _aspectCtrl.text.trim(),
              'ph_solution':
                  _phCtrl.text.trim().isEmpty ? null : _phCtrl.text.trim(),
              'solubilite': _solubiliteCtrl.text.trim().isEmpty
                  ? null
                  : _solubiliteCtrl.text.trim(),
              'particularite': _particulariteCtrl.text.trim().isEmpty
                  ? null
                  : _particulariteCtrl.text.trim(),
              'difference_produit_similaire':
                  _differenceCtrl.text.trim().isEmpty
                      ? null
                      : _differenceCtrl.text.trim(),
              'niveau_danger': _niveauDanger,
              'epi_requis': _epiRequis.toList(),
              'premiers_secours': _premiersSecoursCtrl.text.trim().isEmpty
                  ? null
                  : _premiersSecoursCtrl.text.trim(),
              'incompatibilites': _incompatibilitesCtrl.text.trim().isEmpty
                  ? null
                  : _incompatibilitesCtrl.text.trim(),
              'stockage': _stockageCtrl.text.trim().isEmpty
                  ? null
                  : _stockageCtrl.text.trim(),
              'statut_verification': _statutVerification,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'matiere_premiere_id',
          )
          .select()
          .single();
      final academieId = saved['id'] as String;

      await SupabaseConfig.client
          .from('matieres_premieres_usages')
          .delete()
          .eq('academie_id', academieId);
      final validUsages = _usages
          .where((u) =>
              (u['domaine_application'] as String? ?? '').trim().isNotEmpty)
          .toList();
      if (validUsages.isNotEmpty) {
        await SupabaseConfig.client.from('matieres_premieres_usages').insert([
          for (var i = 0; i < validUsages.length; i++)
            {
              'academie_id': academieId,
              'domaine_application':
                  (validUsages[i]['domaine_application'] as String).trim(),
              'technique_methode':
                  (validUsages[i]['technique_methode'] as String? ?? '')
                          .trim()
                          .isEmpty
                      ? null
                      : (validUsages[i]['technique_methode'] as String).trim(),
              'dosage_concentration':
                  (validUsages[i]['dosage_concentration'] as String? ?? '')
                          .trim()
                          .isEmpty
                      ? null
                      : (validUsages[i]['dosage_concentration'] as String)
                          .trim(),
              'a_verifier_labo': validUsages[i]['a_verifier_labo'] == true,
              'ordre': i,
            },
        ]);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fiche Académie enregistrée.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Erreur lors de l\'enregistrement (migration phase81 exécutée ?) : $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

    Widget textField(TextEditingController ctrl, String label,
        {int maxLines = 1, bool required = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
              labelText: required ? '$label *' : label,
              border: const OutlineInputBorder()),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null
              : null,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Académie — ${widget.rawMaterialName}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Text('Fiche technique', style: theme.textTheme.titleMedium),
          SizedBox(height: 0.5.h),
          Text('* Champs obligatoires', style: theme.textTheme.bodySmall),
          SizedBox(height: 1.h),
          textField(_nomChimiqueCtrl, 'Nom chimique', required: true),
          textField(_synonymesCtrl, 'Nom commun', required: true),
          textField(_gradeCtrl, 'Grade (Standard / Alimentaire / Cosmétique / Technique)'),
          textField(_aspectCtrl, 'Aspect', required: true),
          textField(_phCtrl, 'pH en solution', required: true),
          textField(_solubiliteCtrl, 'Solubilité', required: true),
          textField(_particulariteCtrl, 'Particularité (ex : hygroscopique, exothermique)'),
          textField(_differenceCtrl, 'Différence avec un produit similaire',
              maxLines: 2),
          SizedBox(height: 1.h),
          Text('Sécurité', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          DropdownButtonFormField<String>(
            initialValue: _niveauDanger,
            decoration: const InputDecoration(
                labelText: 'Niveau de danger', border: OutlineInputBorder()),
            items: _niveauxDanger
                .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                .toList(),
            onChanged: (v) => setState(() => _niveauDanger = v),
          ),
          SizedBox(height: 1.5.h),
          Text('EPI requis', style: theme.textTheme.labelLarge),
          SizedBox(height: 0.5.h),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _epiSuggestions
                .map((e) => FilterChip(
                      label: Text(e),
                      selected: _epiRequis.contains(e),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _epiRequis.add(e);
                        } else {
                          _epiRequis.remove(e);
                        }
                      }),
                    ))
                .toList(),
          ),
          SizedBox(height: 1.5.h),
          textField(_premiersSecoursCtrl, 'Premiers secours', maxLines: 3),
          textField(_incompatibilitesCtrl, 'Incompatibilités', maxLines: 2),
          textField(_stockageCtrl, 'Stockage', maxLines: 2),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vérifié (labo)'),
            subtitle: const Text(
                'Désactivé = badge "⚠️ À vérifier en labo" affiché au client'),
            value: _statutVerification == 'verifie',
            onChanged: (v) => setState(
                () => _statutVerification = v ? 'verifie' : 'a_valider'),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Text('Usages détaillés', style: theme.textTheme.titleMedium),
              ),
              TextButton.icon(
                onPressed: _addUsageRow,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un usage'),
              ),
            ],
          ),
          for (var i = 0; i < _usages.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue:
                                _usages[i]['domaine_application'] as String?,
                            decoration: const InputDecoration(
                                labelText: 'Domaine d\'application',
                                isDense: true),
                            onChanged: (v) =>
                                _usages[i]['domaine_application'] = v,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => setState(() => _usages.removeAt(i)),
                        ),
                      ],
                    ),
                    TextFormField(
                      initialValue: _usages[i]['technique_methode'] as String?,
                      decoration: const InputDecoration(
                          labelText: 'Technique / méthode', isDense: true),
                      onChanged: (v) => _usages[i]['technique_methode'] = v,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue:
                          _usages[i]['dosage_concentration'] as String?,
                      decoration: const InputDecoration(
                          labelText: 'Dosage / concentration (ex : 1-5%)',
                          isDense: true),
                      onChanged: (v) => _usages[i]['dosage_concentration'] = v,
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('À vérifier en labo'),
                      value: _usages[i]['a_verifier_labo'] == true,
                      onChanged: (v) =>
                          setState(() => _usages[i]['a_verifier_labo'] = v),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 2.h),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enregistrer'),
          ),
          SizedBox(height: 4.h),
        ],
        ),
      ),
    );
  }
}
