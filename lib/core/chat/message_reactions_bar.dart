import 'package:flutter/material.dart';

/// Barre de réactions emoji groupées sous une bulle de message (29/09).
/// Tapoter un groupe bascule VOTRE PROPRE réaction sur cet emoji (comme
/// WhatsApp) — retirer si c'est déjà la vôtre, sinon la remplacer.
class MessageReactionsBar extends StatelessWidget {
  final List<Map<String, dynamic>> reactions;
  final String? myUserId;
  final void Function(String emoji) onTapEmoji;

  const MessageReactionsBar({
    super.key,
    required this.reactions,
    required this.myUserId,
    required this.onTapEmoji,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    final counts = <String, int>{};
    final mine = <String>{};
    for (final r in reactions) {
      final emoji = r['emoji'] as String;
      counts[emoji] = (counts[emoji] ?? 0) + 1;
      if (r['user_id'] == myUserId) mine.add(emoji);
    }
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final entry in counts.entries)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onTapEmoji(entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: mine.contains(entry.key)
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: mine.contains(entry.key)
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${entry.key} ${entry.value}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
