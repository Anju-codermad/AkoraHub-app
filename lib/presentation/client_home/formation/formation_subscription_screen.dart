import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/formation/formation_repo.dart';
import '../../../core/payment/payment_method_settings_repo.dart';
import '../../../core/payment/payment_methods.dart';
import '../../../core/supabase/supabase_config.dart';

/// Abonnement Formation (accès payant aux fiches détaillées de matières
/// premières — voir supabase/phase40_schema.sql). Paiement manuel, même
/// principe que les commandes (référence + preuve, validée par le staff) :
/// pas de mode "paiement à la livraison" ici, ça n'a pas de sens pour un
/// abonnement.
class FormationSubscriptionScreen extends StatefulWidget {
  const FormationSubscriptionScreen({super.key});

  @override
  State<FormationSubscriptionScreen> createState() =>
      _FormationSubscriptionScreenState();
}

class _FormationSubscriptionScreenState
    extends State<FormationSubscriptionScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _mySubscription;
  List<Map<String, dynamic>> _plans = [];
  Set<PaymentMethod> _availableMethods = {};
  String? _selectedPlan;
  PaymentMethod? _selectedMethod;
  final _referenceCtrl = TextEditingController();
  XFile? _proofFile;
  bool _isSubmitting = false;
  final _currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'Ar', decimalDigits: 0);
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait<dynamic>([
      FormationRepo.fetchMySubscription(),
      FormationRepo.fetchPlanPricing(),
      PaymentMethodSettingsRepo.fetchEnabled(),
    ]);
    final methods = (results[2] as Set<PaymentMethod>)
        .where((m) => m != PaymentMethod.paiementLivraison)
        .toSet();
    setState(() {
      _mySubscription = results[0] as Map<String, dynamic>?;
      _plans = results[1] as List<Map<String, dynamic>>;
      _availableMethods = methods;
      if (_plans.isNotEmpty) _selectedPlan = _plans.first['plan'];
      if (methods.isNotEmpty) _selectedMethod = methods.first;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    final plan = _plans.firstWhere((p) => p['plan'] == _selectedPlan,
        orElse: () => <String, dynamic>{});
    if (plan.isEmpty || _selectedMethod == null) return;
    if (_isSubmitting) return;
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

      await FormationRepo.requestSubscription(
        plan: plan['plan'],
        amount: plan['price'],
        paymentMethodId: _selectedMethod!.id,
        paymentReference: _referenceCtrl.text.trim().isEmpty
            ? null
            : _referenceCtrl.text.trim(),
        paymentProofPath: proofPath,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Demande envoyée — votre abonnement sera activé après vérification du paiement.')));
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Erreur lors de l\'envoi de la demande (migration phase40 exécutée ?).')));
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

    final sub = _mySubscription;
    if (sub != null && sub['status'] == 'actif' && FormationRepo.isActive(sub)) {
      final expiresAt = sub['expires_at'] as String?;
      return Scaffold(
        appBar: AppBar(title: const Text('Abonnement Formation')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium,
                    size: 48, color: theme.colorScheme.primary),
                SizedBox(height: 2.h),
                const Text('Abonnement actif', style: TextStyle(fontSize: 18)),
                if (expiresAt != null)
                  Text(
                      'Valide jusqu\'au ${_dateFormat.format(DateTime.parse(expiresAt))}'),
              ],
            ),
          ),
        ),
      );
    }

    if (sub != null && sub['status'] == 'en_attente') {
      return Scaffold(
        appBar: AppBar(title: const Text('Abonnement Formation')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_top_outlined,
                    size: 48, color: theme.colorScheme.primary),
                SizedBox(height: 2.h),
                const Text(
                  'Votre demande d\'abonnement est en cours de vérification par notre équipe.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Abonnement Formation')),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          if (sub != null && sub['status'] == 'refuse')
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(
                'Votre précédente demande a été refusée — vérifiez la référence de paiement avant de réessayer.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (sub != null && sub['status'] == 'expire')
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: const Text('Votre abonnement a expiré — renouvelez-le ci-dessous.'),
            ),
          Text(
            'Débloquez les fiches complètes de la base Formation : description, dosages par usage, conditionnement et historique de prix.',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
          Text('Choisissez un plan', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          ..._plans.map((p) => Card(
                child: RadioListTile<String>(
                  value: p['plan'],
                  groupValue: _selectedPlan,
                  onChanged: (v) => setState(() => _selectedPlan = v),
                  title: Text(p['label'] ?? ''),
                  subtitle: Text(_currency.format(p['price'])),
                ),
              )),
          SizedBox(height: 2.h),
          Text('Mode de paiement', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableMethods.map((m) {
              return ChoiceChip(
                avatar: Icon(m.icon, size: 18),
                label: Text(m.label),
                selected: _selectedMethod == m,
                onSelected: (_) => setState(() => _selectedMethod = m),
              );
            }).toList(),
          ),
          if (_selectedMethod?.instructions != null) ...[
            SizedBox(height: 1.5.h),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_selectedMethod!.instructions!),
            ),
          ],
          SizedBox(height: 2.h),
          TextField(
            controller: _referenceCtrl,
            decoration: const InputDecoration(
                labelText: 'Référence de paiement (optionnel)'),
          ),
          SizedBox(height: 1.5.h),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                final picked =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (picked != null) setState(() => _proofFile = picked);
              } catch (_) {}
            },
            icon: const Icon(Icons.attach_file),
            label: Text(_proofFile == null
                ? 'Joindre une preuve de paiement (optionnel)'
                : 'Photo jointe ✓'),
          ),
          SizedBox(height: 3.h),
          FilledButton(
            onPressed: _isSubmitting || _selectedPlan == null ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Envoyer la demande'),
          ),
        ],
      ),
    );
  }
}
