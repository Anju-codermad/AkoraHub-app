import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/supabase/supabase_config.dart';
import '../product_management_real/batch_list_screen.dart' show qrBatchPrefix;

/// Scanner de traçabilité : le client scanne le QR code d'un lot pour voir
/// sa date de fabrication, sa DLC, et le produit associé.
class ProductScannerScreen extends StatefulWidget {
  const ProductScannerScreen({super.key});

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  bool _isProcessing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);

    if (code.startsWith(qrBatchPrefix)) {
      await _lookupBatch(code.substring(qrBatchPrefix.length));
    } else {
      await _lookupBarcode(code);
    }
  }

  Future<void> _lookupBatch(String batchId) async {
    try {
      final batch = await SupabaseConfig.client
          .from('production_batches')
          .select('*, products(name, category, description)')
          .eq('id', batchId)
          .maybeSingle();

      if (!mounted) return;

      if (batch == null) {
        _showResult(
          success: false,
          message: 'Ce code ne correspond à aucun lot connu.',
        );
      } else {
        _showResult(success: true, batch: batch);
      }
    } catch (_) {
      if (!mounted) return;
      _showResult(
        success: false,
        message: 'Erreur lors de la vérification. Réessayez.',
      );
    }
  }

  /// Code-barre EAN/UPC classique, déjà imprimé sur l'emballage — identifie
  /// le PRODUIT (générique), contrairement au QR code qui identifie un lot
  /// précis avec sa date de fabrication et sa DLC.
  Future<void> _lookupBarcode(String barcode) async {
    try {
      final product = await SupabaseConfig.client
          .from('products')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();

      if (!mounted) return;

      if (product == null) {
        _showResult(
          success: false,
          message: 'Aucun produit AkoraHub ne correspond à ce code-barre.',
        );
      } else {
        _showResult(success: true, product: product);
      }
    } catch (_) {
      if (!mounted) return;
      _showResult(
        success: false,
        message: 'Erreur lors de la vérification. Réessayez.',
      );
    }
  }

  void _showResult({
    required bool success,
    Map<String, dynamic>? batch,
    Map<String, dynamic>? product,
    String? message,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final batchProduct = batch?['products'];
    final expiry = batch?['expiry_date'] != null
        ? DateTime.tryParse(batch!['expiry_date'])
        : null;
    final expired = expiry != null && expiry.isBefore(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              success
                  ? (expired ? Icons.error_outline : Icons.verified_outlined)
                  : Icons.help_outline,
              size: 48,
              color: success
                  ? (expired ? Colors.red : Colors.green)
                  : Colors.orange,
            ),
            const SizedBox(height: 12),
            if (success && batchProduct != null) ...[
              Text(batchProduct['name'] ?? '',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Lot n° ${batch!['batch_number']}'),
              Text(
                  'Fabriqué le ${dateFormat.format(DateTime.parse(batch['manufacture_date']))}'),
              if (expiry != null)
                Text(
                  expired
                      ? 'Expiré le ${dateFormat.format(expiry)}'
                      : 'DLC : ${dateFormat.format(expiry)}',
                  style: TextStyle(
                    color: expired ? Colors.red : null,
                    fontWeight: expired ? FontWeight.bold : null,
                  ),
                ),
              if ((batchProduct['category'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Chip(label: Text(batchProduct['category'])),
              ],
              const SizedBox(height: 8),
              Text(
                'Produit authentique AkoraHub — traçabilité vérifiée.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.green[700]),
              ),
            ] else if (success && product != null) ...[
              Text(product['name'] ?? '',
                  style: Theme.of(context).textTheme.titleLarge),
              if ((product['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(product['description']),
              ],
              if ((product['category'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Chip(label: Text(product['category'])),
              ],
              const SizedBox(height: 8),
              Text(
                'Produit authentique AkoraHub.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.green[700]),
              ),
            ] else
              Text(message ?? 'Code non reconnu.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _isProcessing = false);
                },
                child: const Text('Scanner un autre code'),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un produit')),
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
                  'Visez le QR code du lot ou le code-barre du produit',
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

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
