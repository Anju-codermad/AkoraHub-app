import 'package:flutter/material.dart';

/// Coche(s) d'accusé de lecture façon WhatsApp (✓ envoyé / ✓✓ lu) — 29/09.
/// À afficher uniquement sous ses PROPRES messages envoyés, jamais sous
/// ceux reçus (voir chat_screen.dart / messaging_center_real.dart).
class ReadReceiptTicks extends StatelessWidget {
  final bool isRead;
  final Color color;

  const ReadReceiptTicks({
    super.key,
    required this.isRead,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      isRead ? Icons.done_all : Icons.done,
      size: 14,
      color: isRead ? Colors.lightBlueAccent : color,
    );
  }
}
