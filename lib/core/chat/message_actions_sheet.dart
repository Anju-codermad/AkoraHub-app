import 'package:flutter/material.dart';

/// Emojis rapides (29/09) — mêmes 6 que WhatsApp/Messenger.
const List<String> quickReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// Menu d'actions au clic long sur une bulle de message (29/09) :
/// réagir, répondre, copier, transférer, modifier, épingler, enregistrer,
/// supprimer. Partagé entre le fil client (`chat_screen.dart`) et le fil
/// staff (`messaging_center_real.dart`). Chaque callback optionnel nul
/// masque l'action correspondante (ex : `onEdit` nul si ce n'est pas son
/// propre message).
Future<void> showMessageActionsSheet(
  BuildContext context, {
  required bool isPinned,
  required bool isStarred,
  required String? myReaction,
  required void Function(String emoji) onReact,
  required VoidCallback onTogglePin,
  required VoidCallback onToggleStar,
  required VoidCallback onReply,
  required VoidCallback onCopy,
  required VoidCallback onDeleteForMe,
  VoidCallback? onForward,
  VoidCallback? onEdit,
  VoidCallback? onDeleteForEveryone,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final emoji in quickReactionEmojis)
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.pop(ctx);
                      onReact(emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: emoji == myReaction
                            ? Theme.of(ctx)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.15)
                            : null,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.reply_outlined),
            title: const Text('Répondre'),
            onTap: () {
              Navigator.pop(ctx);
              onReply();
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('Copier le texte'),
            onTap: () {
              Navigator.pop(ctx);
              onCopy();
            },
          ),
          if (onForward != null)
            ListTile(
              leading: const Icon(Icons.forward_outlined),
              title: const Text('Transférer'),
              onTap: () {
                Navigator.pop(ctx);
                onForward();
              },
            ),
          if (onEdit != null)
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
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
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Supprimer pour moi'),
            onTap: () {
              Navigator.pop(ctx);
              onDeleteForMe();
            },
          ),
          if (onDeleteForEveryone != null)
            ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: Theme.of(ctx).colorScheme.error),
              title: Text(
                'Supprimer pour tout le monde',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDeleteForEveryone();
              },
            ),
        ],
      ),
    ),
  );
}
