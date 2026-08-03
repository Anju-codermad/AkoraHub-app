import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Validation des demandes d'achat de cours AkoraFormation (voir
/// supabase/phase50_patch_course_purchases_and_content.sql) — même
/// principe que FormationPurchasesManagement (matières premières), mais
/// sur `course_purchases`/`formation_courses`, un cours par ligne (pas de
/// batch_id partagé entre plusieurs cours, un achat = un cours).
///
/// Ajouté le 02/08 : cet écran n'existait pas du tout jusqu'ici — la
/// table et la page d'achat externe existaient, mais aucun moyen pour le
/// staff de valider une demande de cours (contrairement aux matières
/// premières). Un client ayant payé un cours restait donc bloqué
/// indéfiniment en "en_attente".
///
/// Depuis le 02/08 (fusion) : contenu sans Scaffold propre, utilisé comme
/// onglet de FormationPurchasesHub — voir formation_purchases_hub.dart.
class CoursePurchasesManagement extends StatefulWidget {
  const CoursePurchasesManagement({super.key});

  @override
  State<CoursePurchasesManagement> createState() =>
      _CoursePurchasesManagementState();
}

class _CoursePurchasesManagementState
    extends State<CoursePurchasesManagement> {
  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'en_attente';
  final _currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _loadData();
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
    });
    try {
      final data = await SupabaseConfig.client
          .from('course_purchases')
          .select(
              '*, profiles(full_name, company_name), formation_courses(title, category)')
          .order('created_at', ascending: false);
      setState(() {
        _purchases = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger les achats (migration phase50 exécutée ?).';
      });
    }
  }

  Future<void> _validate(Map<String, dynamic> p) async {
    try {
      await SupabaseConfig.client
          .from('course_purchases')
          .update({
            'status': 'validee',
            'validated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', p['id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Achat validé.')));
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la validation.')));
    }
  }

  Future<void> _refuse(Map<String, dynamic> p) async {
    try {
      await SupabaseConfig.client
          .from('course_purchases')
          .update({'status': 'refusee'})
          .eq('id', p['id']);
      if (!mounted) return;
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur lors du refus.')));
    }
  }

  /// Voir formation_purchases_management.dart pour le détail : PostgREST
  /// embarque parfois une relation "un seul" comme une liste plutôt
  /// qu'un objet, ce qui fait planter un `as Map?` classique.
  Map? _embedAsMap(dynamic value) {
    if (value is Map) return value;
    if (value is List && value.isNotEmpty && value.first is Map) {
      return value.first as Map;
    }
    return null;
  }

  Future<void> _viewProof(Map<String, dynamic> p) async {
    final path = p['payment_proof_path'] as String?;
    if (path == null) return;
    try {
      final url = await SupabaseConfig.client.storage
          .from('payment-proofs')
          .createSignedUrl(path, 300);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Image.network(url,
              errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Impossible d\'afficher l\'image.'))),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de charger la preuve de paiement.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<Map<String, dynamic>> filtered = [];
    String? buildError;
    try {
      filtered = _purchases
          .where(
              (p) => _statusFilter == 'tous' || p['status'] == _statusFilter)
          .toList();
    } catch (e) {
      buildError = 'Erreur d\'affichage (cours) : $e';
    }

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!))
            : buildError != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Text(buildError,
                          style: theme.textTheme.bodySmall),
                    ),
                  )
                : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                    padding: EdgeInsets.all(4.w),
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final status in [
                            'en_attente',
                            'validee',
                            'refusee',
                            'tous'
                          ])
                            ChoiceChip(
                              label: Text(status == 'tous'
                                  ? 'Tous'
                                  : status == 'en_attente'
                                      ? 'En attente'
                                      : status == 'validee'
                                          ? 'Validés'
                                          : 'Refusés'),
                              selected: _statusFilter == status,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = status),
                            ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      if (filtered.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Center(
                            child: Text('Aucune demande.',
                                style: theme.textTheme.bodyMedium),
                          ),
                        )
                      else
                        ...filtered.map((p) {
                          try {
                          final profile = _embedAsMap(p['profiles']);
                          final course = _embedAsMap(p['formation_courses']);
                          final status = p['status'] as String? ?? '';
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          profile?['company_name'] ??
                                              profile?['full_name'] ??
                                              'Client',
                                          style: theme.textTheme.titleSmall,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(status,
                                            style:
                                                const TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                      '${course?['title'] ?? ''} · ${course?['category'] ?? ''}'),
                                  Text(_currency.format(p['amount'] ?? 0)),
                                  if (p['payment_reference'] != null)
                                    Text('Référence : ${p['payment_reference']}'),
                                  if (DateTime.tryParse(
                                          p['created_at'] as String? ?? '') !=
                                      null)
                                    Text(
                                        'Demandé le ${_dateFormat.format(DateTime.parse(p['created_at']))}'),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (p['payment_proof_path'] != null)
                                        TextButton.icon(
                                          onPressed: () => _viewProof(p),
                                          icon: const Icon(Icons.image_outlined,
                                              size: 18),
                                          label: const Text('Preuve'),
                                        ),
                                      if (status == 'en_attente') ...[
                                        TextButton(
                                          onPressed: () => _refuse(p),
                                          child: const Text('Refuser'),
                                        ),
                                        FilledButton(
                                          onPressed: () => _validate(p),
                                          child: const Text('Valider'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                          } catch (e) {
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'Erreur d\'affichage sur une demande : $e',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            );
                          }
                        }),
                    ],
                  ),
                );
  }
}
