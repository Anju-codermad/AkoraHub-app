import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../supabase/supabase_config.dart';

/// Génère un PDF de facture ou de devis, avec le logo et les coordonnées
/// de l'entreprise (lus depuis `company_settings`) — utilisé côté client
/// pour permettre le téléchargement d'un document déjà émis par l'Admin.
class DocumentPdfGenerator {
  DocumentPdfGenerator._();

  static Future<Uint8List> build({
    required String documentType, // 'Facture' ou 'Devis'
    required String documentNumber,
    required DateTime date,
    required Map<String, dynamic>? customer,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
  }) async {
    final companyInfo = await _fetchCompanyInfo();
    pw.MemoryImage? logoImage;
    final logoUrl = companyInfo['logo'] as String?;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(logoUrl));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {
        // Pas grave si le logo ne charge pas — le PDF reste utilisable
        // sans, plutôt que de faire échouer tout le téléchargement.
      }
    }

    final doc = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    final companyName =
        (companyInfo['companyName'] as String?)?.isNotEmpty == true
            ? companyInfo['companyName'] as String
            : 'Akora Fanadiovana';
    final companyAddress = companyInfo['address'] as String?;
    final companyPhone = companyInfo['phone'] as String?;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(companyName.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      if (companyAddress != null && companyAddress.isNotEmpty)
                        pw.Text(companyAddress),
                      if (companyPhone != null && companyPhone.isNotEmpty)
                        pw.Text('Tél : $companyPhone'),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Container(
                      width: 70,
                      height: 70,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('${documentType.toUpperCase()} N° $documentNumber',
                  style:
                      pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('Date : $dateStr'),
              pw.SizedBox(height: 12),
              pw.Text('Client :',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(customer?['full_name'] ?? ''),
              if ((customer?['company_name'] ?? '').toString().isNotEmpty)
                pw.Text(customer!['company_name']),
              if ((customer?['phone'] ?? '').toString().isNotEmpty)
                pw.Text('Tél : ${customer!['phone']}'),
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
                  ...items.map((item) {
                    final qty = (item['quantity'] ?? 0) as num;
                    final unitPrice = (item['unit_price'] ?? 0) as num;
                    return pw.TableRow(children: [
                      _cell((item['product_name'] ?? '').toString()),
                      _cell(qty.toString()),
                      _cell(unitPrice.toStringAsFixed(0)),
                      _cell((qty * unitPrice).toStringAsFixed(0)),
                    ]);
                  }),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TOTAL : ${totalAmount.toStringAsFixed(0)} Ar',
                  style:
                      pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _cell(String text, {bool bold = false}) {
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

  static Future<Map<String, dynamic>> _fetchCompanyInfo() async {
    if (!SupabaseConfig.isConfigured) return {};
    try {
      final result = await SupabaseConfig.client
          .from('company_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();
      final data = result?['data'];
      if (data == null) return {};
      final map = Map<String, dynamic>.from(data);
      // companyName/description sont stockés en sous-objet multi-langue
      // (voir business_profile_settings.dart) — on prend la version 'fr'.
      final companyNameField = map['companyName'];
      String? companyName;
      if (companyNameField is Map) {
        companyName = companyNameField['fr'] as String?;
      } else if (companyNameField is String) {
        companyName = companyNameField;
      }
      final addressField = map['address'];
      String? address;
      if (addressField is Map) {
        final parts = [
          addressField['street'],
          addressField['city'],
        ].where((p) => p != null && p.toString().isNotEmpty);
        address = parts.join(', ');
      }
      return {
        'logo': map['logo'],
        'companyName': companyName,
        'address': address,
        'phone': map['phone'],
      };
    } catch (_) {
      return {};
    }
  }
}
