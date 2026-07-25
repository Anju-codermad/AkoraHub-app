import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Préfixe utilisé pour encoder l'identifiant du lot dans le QR code.
/// Le scanner côté client s'en sert pour reconnaître qu'un code lu est
/// bien un lot AkoraHub, pas un QR code quelconque.
const String qrBatchPrefix = 'akorahub:batch:';

/// Liste des lots de production existants pour un produit, avec accès au
/// QR code de traçabilité de chacun (le client peut scanner l'étiquette
/// pour voir la date de fabrication, la DLC, et la conformité).
class BatchListScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const BatchListScreen({super.key, required this.product});

  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> {
  List<Map<String, dynamic>> _batches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseConfig.client
          .from('production_batches')
          .select()
          .eq('product_id', widget.product['id'])
          .order('manufacture_date', ascending: false);
      setState(() {
        _batches = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showQrCode(Map<String, dynamic> batch) async {
    final qrData = '$qrBatchPrefix${batch['id']}';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lot ${batch['batch_number']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Le client scanne ce code depuis l\'app pour voir la date de fabrication, la DLC et le produit.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              SharePlus.instance.share(ShareParams(
                text:
                    'Lot ${batch['batch_number']} — ${widget.product['name']}\nCode de traçabilité : $qrData',
              ));
            },
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Partager'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _addBatch() async {
    final product = widget.product;
    final batchNumberCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    DateTime manufactureDate = DateTime.now();
    DateTime? expiryDate;
    bool isSavingBatch = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Nouveau lot — ${product['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: batchNumberCtrl,
                decoration: const InputDecoration(labelText: 'Numéro de lot'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantité'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    'Fabrication : ${DateFormat('dd/MM/yyyy').format(manufactureDate)}'),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: manufactureDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => manufactureDate = picked);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(expiryDate == null
                    ? 'DLC (optionnel)'
                    : 'DLC : ${DateFormat('dd/MM/yyyy').format(expiryDate!)}'),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setDialogState(() => expiryDate = picked);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: isSavingBatch
                  ? null
                  : () async {
                      if (batchNumberCtrl.text.trim().isEmpty) return;
                      if (isSavingBatch) return;
                      setDialogState(() => isSavingBatch = true);
                      try {
                        await SupabaseConfig.client
                            .from('production_batches')
                            .insert({
                          'product_id': product['id'],
                          'batch_number': batchNumberCtrl.text.trim(),
                          'manufacture_date': manufactureDate
                              .toIso8601String()
                              .split('T')
                              .first,
                          'expiry_date': expiryDate
                              ?.toIso8601String()
                              .split('T')
                              .first,
                          'quantity':
                              double.tryParse(quantityCtrl.text) ?? 0,
                        });
                        if (!mounted) return;
                        Navigator.pop(context);
                        _load();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lot enregistré.')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        setDialogState(() => isSavingBatch = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Erreur lors de l\'enregistrement du lot.')),
                        );
                      }
                    },
              child: isSavingBatch
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: Text('Lots — ${widget.product['name']}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBatch,
        icon: const Icon(Icons.add),
        label: const Text('Lot'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _batches.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: 20.h),
                        const Center(
                            child: Text('Aucun lot pour ce produit.')),
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.all(4.w),
                      itemCount: _batches.length,
                      separatorBuilder: (_, __) => SizedBox(height: 1.h),
                      itemBuilder: (context, index) {
                        final b = _batches[index];
                        final expiry = b['expiry_date'] != null
                            ? DateTime.tryParse(b['expiry_date'])
                            : null;
                        final expired =
                            expiry != null && expiry.isBefore(DateTime.now());
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.inventory_2_outlined,
                              color: expired
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                            title: Text('Lot ${b['batch_number']}'),
                            subtitle: Text(
                              'Fabriqué le ${dateFormat.format(DateTime.parse(b['manufacture_date']))}'
                              '${expiry != null ? ' · DLC ${dateFormat.format(expiry)}' : ''}'
                              ' · Qté ${b['quantity']}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.qr_code_2),
                              tooltip: 'QR code de traçabilité',
                              onPressed: () => _showQrCode(b),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
