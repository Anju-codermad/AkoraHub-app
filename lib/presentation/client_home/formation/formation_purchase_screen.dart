import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/formation/formation_repo.dart';
import '../../../core/payment/payment_method_settings_repo.dart';
import '../../../core/payment/payment_methods.dart';
import '../../../core/supabase/supabase_config.dart';

/// Achat de l'accès Formation, produit par produit (voir
/// supabase/phase45_patch_formation_per_product_pricing.sql) — remplace
/// l'ancien écran d'abonnement (formation_subscription_screen.dart,
/// supprimé le 01/08). Le client sélectionne un ou plusieurs produits
/// parmi ceux qu'il ne possède pas encore ; le prix par unité s'ajuste en
/// direct selon le palier dégressif atteint (cumulé avec ce qu'il possède
/// déjà). Paiement manuel (référence + preuve, validé par le staff) —
/// même principe que les commandes.
class FormationPurchaseScreen extends StatefulWidget {
  /// Pré-sélectionne un produit précis (ex: depuis le bouton "Acheter"
  /// d'une fiche verrouillée) — l'utilisateur peut toujours en ajouter
  /// d'autres à ce même achat pour bénéficier d'un meilleur palier.
  final String? initialSelectedId;

  const FormationPurchaseScreen({super.key, this.initialSelectedId});

  @override
  State<FormationPurchaseScreen> createState() =>
      _FormationPurchaseScreenState();
}

class _FormationPurchaseScreenState extends State<FormationPurchaseScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _materials = [];
  Set<String> _ownedIds = {};
  Set<String> _pendingIds = {};
  List<Map<String, dynamic>> _tiers = [];
  final Set<String> _selectedIds = {};
  String _search = '';

  Set<PaymentMethod> _availableMethods = {};
  PaymentMethod? _selectedMethod;
  final _referenceCtrl = TextEditingController();
  XFile? _proofFile;
  bool _isSubmitting = false;

  final _currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedId != null) {
      _selectedIds.add(widget.initialSelectedId!);
    }
    _load();
  }

  @override
  void dispose() {
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        SupabaseConfig.client
            .from('raw_materials_preview')
            .select()
            .order('name'),
        FormationRepo.fetchMyPurchasedIds(),
        FormationRepo.fetchMyPendingIds(),
        FormationRepo.fetchPricingTiers(),
        PaymentMethodSettingsRepo.fetchEnabled(),
      ]);
      final methods = (results[4] as Set<PaymentMethod>)
          .where((m) => m != PaymentMethod.paiementLivraison)
          .toSet();
      setState(() {
        _materials = List<Map<String, dynamic>>.from(results[0] as List);
        _ownedIds = results[1] as Set<String>;
        _pendingIds = results[2] as Set<String>;
        _tiers = results[3] as List<Map<String, dynamic>>;
        _availableMethods = methods;
        if (methods.isNotEmpty) _selectedMethod = methods.first;
        // Retire toute présélection déjà possédée/en attente (ex: fiche
        // ouverte alors que l'achat vient d'être validé entre-temps).
        _selectedIds.removeWhere(
            (id) => _ownedIds.contains(id) || _pendingIds.contains(id));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger le catalogue (migration phase45 exécutée ?).';
      });
    }
  }

  List<Map<String, dynamic>> get _availableMaterials => _materials.where((m) {
        final id = m['id'] as String;
        if (_ownedIds.contains(id) || _pendingIds.contains(id)) return false;
        if (_search.isEmpty) return true;
        return (m['name'] as String? ?? '')
            .toLowerCase()
            .contains(_search.toLowerCase());
      }).toList();

  num get _unitPrice => FormationRepo.unitPriceForPurchase(
        tiers: _tiers,
        alreadyOwned: _ownedIds.length,
        quantity: _selectedIds.length,
      );

  num get _total => _unitPrice * _selectedIds.length;

  Future<void> _submit() async {
    if (_selectedIds.isEmpty || _selectedMethod == null || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      String? proofPath;
      if (_proofFile != null && userId != null) {
        try {
          proofPath =
              '$userId/formation_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await SupabaseConfig.client.storage
              .from('payment-proofs')
              .upload(proofPath, File(_proofFile!.path));
        } catch (_) {
          proofPath = null;
        }
      }

      await FormationRepo.requestPurchase(
        rawMaterialIds: _selectedIds.toList(),
        unitPrice: _unitPrice,
        paymentMethodId: _selectedMethod!.id,
        paymentReference: _referenceCtrl.text.trim().isEmpty
            ? null
            : _referenceCtrl.text.trim(),
        paymentProofPath: proofPath,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Demande envoyée — l\'accès sera débloqué après vérification du paiement.')));
      setState(() => _selectedIds.clear());
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Erreur lors de l\'envoi de la demande (migration phase45 exécutée ?).')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acheter l\'accès Formation')),
        body: Center(child: Text(_error!)),
      );
    }

    final available = _availableMaterials;

    return Scaffold(
      appBar: AppBar(title: const Text('Acheter l\'accès Formation')),
      body: Column(
        children: [
          if (_pendingIds.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_outlined, size: 18),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      '${_pendingIds.length} produit(s) en attente de vérification par notre équipe.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher une matière première…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: available.isEmpty
                ? Center(
                    child: Text(
                      _materials.isEmpty
                          ? 'Aucune matière première pour le moment.'
                          : 'Vous avez déjà accès à tous les produits.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    itemCount: available.length,
                    itemBuilder: (context, index) {
                      final m = available[index];
                      final id = m['id'] as String;
                      return CheckboxListTile(
                        value: _selectedIds.contains(id),
                        title: Text(m['name'] ?? ''),
                        subtitle: Text(m['category_name'] ?? ''),
                        onChanged: (checked) => setState(() {
                          if (checked == true) {
                            _selectedIds.add(id);
                          } else {
                            _selectedIds.remove(id);
                          }
                        }),
                      );
                    },
                  ),
          ),
          if (_selectedIds.isNotEmpty)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_selectedIds.length} produit(s) sélectionné(s)'),
                      Text('${_currency.format(_unitPrice)} / produit',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleMedium),
                      Text(_currency.format(_total),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ),
                  SizedBox(height: 1.5.h),
                  if (_availableMethods.isNotEmpty) ...[
                    Text('Mode de paiement',
                        style: theme.textTheme.labelLarge),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableMethods.map((m) {
                        return ChoiceChip(
                          avatar: Icon(m.icon, size: 18),
                          label: Text(m.label),
                          selected: _selectedMethod == m,
                          onSelected: (_) =>
                              setState(() => _selectedMethod = m),
                        );
                      }).toList(),
                    ),
                    if (_selectedMethod?.instructions != null) ...[
                      SizedBox(height: 1.h),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_selectedMethod!.instructions!),
                      ),
                    ],
                    SizedBox(height: 1.5.h),
                    TextField(
                      controller: _referenceCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Référence de paiement (optionnel)'),
                    ),
                    SizedBox(height: 1.h),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final picked = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setState(() => _proofFile = picked);
                          }
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(_proofFile == null
                          ? 'Joindre une preuve de paiement (optionnel)'
                          : 'Photo jointe ✓'),
                    ),
                    SizedBox(height: 2.h),
                  ],
                  FilledButton(
                    onPressed: _isSubmitting ||
                            _selectedMethod == null ||
                            _selectedIds.isEmpty
                        ? null
                        : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(
                            'Envoyer la demande — ${_currency.format(_total)}'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
