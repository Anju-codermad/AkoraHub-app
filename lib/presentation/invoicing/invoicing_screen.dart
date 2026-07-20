import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

class InvoiceLineItem {
  String description;
  int quantity;
  double unitPrice;

  InvoiceLineItem({
    this.description = '',
    this.quantity = 1,
    this.unitPrice = 0,
  });

  double get total => quantity * unitPrice;
}

/// Génération de factures PDF (Facturation) — Phase 1.
class InvoicingScreen extends StatefulWidget {
  const InvoicingScreen({super.key});

  @override
  State<InvoicingScreen> createState() => _InvoicingScreenState();
}

class _InvoicingScreenState extends State<InvoicingScreen> {
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _customers = [];
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
      final invoices = await SupabaseConfig.client
          .from('invoices')
          .select()
          .order('created_at', ascending: false);
      final customers = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('role', 'client');
      setState(() {
        _invoices = List<Map<String, dynamic>>.from(invoices);
        _customers = List<Map<String, dynamic>>.from(customers);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les factures.';
      });
    }
  }

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final ms = now.millisecondsSinceEpoch.toString().substring(7);
    return 'FAC-${DateFormat('yyyyMM').format(now)}-$ms';
  }

  Future<void> _createInvoice() async {
    Map<String, dynamic>? selectedCustomer =
        _customers.isNotEmpty ? _customers.first : null;
    final List<InvoiceLineItem> items = [InvoiceLineItem()];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double total =
              items.fold(0, (sum, item) => sum + item.total);

          return AlertDialog(
            title: const Text('Nouvelle facture'),
            content: SizedBox(
              width: 90.w,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Client'),
                    const SizedBox(height: 4),
                    DropdownButton<Map<String, dynamic>>(
                      isExpanded: true,
                      value: selectedCustomer,
                      hint: const Text('Choisir un client'),
                      items: _customers.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(
                              c['full_name'] ?? c['company_name'] ?? 'Client'),
                        );
                      }).toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedCustomer = v),
                    ),
                    const SizedBox(height: 12),
                    const Text('Articles'),
                    const SizedBox(height: 4),
                    ...items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: item.description,
                                decoration: const InputDecoration(
                                    hintText: 'Description', isDense: true),
                                onChanged: (v) => item.description = v,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue: item.quantity.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    hintText: 'Qté', isDense: true),
                                onChanged: (v) => setDialogState(() =>
                                    item.quantity = int.tryParse(v) ?? 1),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: item.unitPrice.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    hintText: 'Prix Unit.', isDense: true),
                                onChanged: (v) => setDialogState(() =>
                                    item.unitPrice = double.tryParse(v) ?? 0),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 18),
                              onPressed: items.length > 1
                                  ? () =>
                                      setDialogState(() => items.removeAt(i))
                                  : null,
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () =>
                          setDialogState(() => items.add(InvoiceLineItem())),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Ajouter une ligne'),
                    ),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total : ${_currency.format(total)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: selectedCustomer == null
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _generateAndSaveInvoice(
                            selectedCustomer!, items, total);
                      },
                child: const Text('Générer la facture'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generateAndSaveInvoice(Map<String, dynamic> customer,
      List<InvoiceLineItem> items, double total) async {
    final invoiceNumber = _generateInvoiceNumber();
    final pdfBytes = await _buildInvoicePdf(
      invoiceNumber: invoiceNumber,
      customer: customer,
      items: items,
      total: total,
    );

    try {
      await SupabaseConfig.client.from('invoices').insert({
        'invoice_number': invoiceNumber,
        'customer_id': customer['id'],
        'total_amount': total,
      });
      if (mounted) _loadData();
    } catch (_) {
      // On continue même si l'enregistrement échoue : la facture PDF
      // reste consultable/imprimable pour l'utilisateur.
    }

    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  Future<Uint8List> _buildInvoicePdf({
    required String invoiceNumber,
    required Map<String, dynamic> customer,
    required List<InvoiceLineItem> items,
    required double total,
  }) async {
    final doc = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('AKORA FANADIOVANA',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text('Antananarivo, Madagascar'),
              pw.SizedBox(height: 20),
              pw.Text('FACTURE N° $invoiceNumber',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Date : $dateStr'),
              pw.SizedBox(height: 12),
              pw.Text('Client :',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(customer['full_name'] ?? ''),
              if ((customer['company_name'] ?? '').toString().isNotEmpty)
                pw.Text(customer['company_name']),
              if ((customer['phone'] ?? '').toString().isNotEmpty)
                pw.Text('Tél : ${customer['phone']}'),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _cell('Description', bold: true),
                      _cell('Qté', bold: true),
                      _cell('Prix Unit.', bold: true),
                      _cell('Total', bold: true),
                    ],
                  ),
                  ...items.map((item) => pw.TableRow(children: [
                        _cell(item.description),
                        _cell(item.quantity.toString()),
                        _cell(item.unitPrice.toStringAsFixed(0)),
                        _cell(item.total.toStringAsFixed(0)),
                      ])),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TOTAL : ${total.toStringAsFixed(0)} Ar',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Facturation')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInvoice,
        icon: const Icon(Icons.receipt_long),
        label: const Text('Nouvelle facture'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _invoices.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            Center(
                              child: Text(
                                'Aucune facture pour le moment.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _invoices.length,
                          separatorBuilder: (_, __) => SizedBox(height: 1.h),
                          itemBuilder: (context, index) {
                            final inv = _invoices[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.receipt_long),
                                title: Text(inv['invoice_number'] ?? ''),
                                subtitle: Text(_currency
                                    .format(inv['total_amount'] ?? 0)),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
