import 'package:flutter/material.dart';

/// Bandeau "Réponse à ..." au-dessus du composer (29/09), le temps que
/// l'utilisateur rédige sa réponse — fermable sans envoyer.
class ReplyPreviewBar extends StatelessWidget {
  final String senderLabel;
  final String snippet;
  final VoidCallback onCancel;

  const ReplyPreviewBar({
    super.key,
    required this.senderLabel,
    required this.snippet,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  snippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Annuler la réponse',
            onPressed: onCancel,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Citation du message d'origine, affichée en haut d'une bulle qui y
/// répond (29/09) — tap pour scroller jusqu'au message cité.
class QuotedMessagePreview extends StatelessWidget {
  final String senderLabel;
  final String snippet;
  final VoidCallback? onTap;
  final Color foregroundColor;

  const QuotedMessagePreview({
    super.key,
    required this.senderLabel,
    required this.snippet,
    required this.foregroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: foregroundColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: foregroundColor.withValues(alpha: 0.6), width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: foregroundColor.withValues(alpha: 0.85),
              ),
            ),
            Text(
              snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: foregroundColor.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
