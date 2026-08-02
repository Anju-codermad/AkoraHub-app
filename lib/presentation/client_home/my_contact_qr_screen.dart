import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sizer/sizer.dart';

/// QR de contact personnel (Profil client, Lot 4, 03/08) — encode une
/// vCard standard (nom, société, téléphone), lisible par n'importe quel
/// lecteur QR/appareil photo, pas seulement depuis AkoraHub (contrairement
/// à un id interne qui n'aurait de sens que scanné depuis l'app elle-même,
/// aucun système de "scan pour ajouter en ami" n'existe à ce jour).
class MyContactQrScreen extends StatelessWidget {
  final String? fullName;
  final String? companyName;
  final String? phone;

  const MyContactQrScreen({
    super.key,
    this.fullName,
    this.companyName,
    this.phone,
  });

  String get _displayName =>
      (fullName?.trim().isNotEmpty == true) ? fullName!.trim() : 'Contact AkoraHub';

  String get _vCard {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCARD')
      ..writeln('VERSION:3.0')
      ..writeln('FN:$_displayName');
    if (companyName?.trim().isNotEmpty == true) {
      buffer.writeln('ORG:${companyName!.trim()}');
    }
    if (phone?.trim().isNotEmpty == true) {
      buffer.writeln('TEL:${phone!.trim()}');
    }
    buffer.writeln('END:VCARD');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ma carte de contact')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _vCard,
                  version: QrVersions.auto,
                  size: 220,
                ),
              ),
              SizedBox(height: 3.h),
              Text(_displayName,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              if (companyName?.trim().isNotEmpty == true)
                Text(companyName!, style: theme.textTheme.bodyMedium),
              SizedBox(height: 2.h),
              Text(
                'Faites scanner ce code pour partager vos coordonnées — '
                'n\'importe quel lecteur QR (même hors de l\'app) peut '
                'l\'ajouter directement aux contacts du téléphone.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
