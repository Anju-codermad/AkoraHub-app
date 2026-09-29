import 'package:flutter/material.dart';

/// Bandeau du message épinglé (29/09), affiché en haut du fil de
/// conversation — un seul message épinglé à la fois par conversation
/// (voir `messages.pinned`, phase251).
class PinnedMessageBanner extends StatelessWidget {
  final String content;
  final VoidCallback onTap;
  final VoidCallback onUnpin;

  const PinnedMessageBanner({
    super.key,
    required this.content,
    required this.onTap,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  content.isNotEmpty ? content : 'Pièce jointe épinglée',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Désépingler',
                onPressed: onUnpin,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
