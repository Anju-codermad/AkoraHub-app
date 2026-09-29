import 'package:flutter/material.dart';

/// Menu d'actions au clic long sur une bulle de message (29/09) :
/// épingler/désépingler, enregistrer/retirer des favoris. Partagé entre
/// le fil client (`chat_screen.dart`) et le fil staff
/// (`messaging_center_real.dart`) puisque les deux touchent aux mêmes
/// colonnes (`messages.pinned`) et à la même table
/// (`starred_messages`, phase251).
Future<void> showMessageActionsSheet(
  BuildContext context, {
  required bool isPinned,
  required bool isStarred,
  required VoidCallback onTogglePin,
  required VoidCallback onToggleStar,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            title: Text(isPinned ? 'Désépingler' : 'Épingler'),
            onTap: () {
              Navigator.pop(ctx);
              onTogglePin();
            },
          ),
          ListTile(
            leading: Icon(isStarred ? Icons.star : Icons.star_border),
            title: Text(
              isStarred
                  ? 'Retirer des messages enregistrés'
                  : 'Enregistrer le message',
            ),
            onTap: () {
              Navigator.pop(ctx);
              onToggleStar();
            },
          ),
        ],
      ),
    ),
  );
}
