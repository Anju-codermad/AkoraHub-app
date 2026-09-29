import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'link_preview_service.dart';

/// Carte d'aperçu de lien (29/09) — affichée sous un message qui
/// contient une URL, si l'aperçu (`og:title`/`og:image`) a pu être
/// récupéré. N'affiche rien si l'aperçu échoue, plutôt qu'une carte
/// vide ou une erreur.
class LinkPreviewCard extends StatefulWidget {
  final String url;

  const LinkPreviewCard({super.key, required this.url});

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  late final Future<LinkPreviewData?> _future;

  @override
  void initState() {
    super.initState();
    _future = LinkPreviewService.fetch(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LinkPreviewData?>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || (data.title == null && data.imageUrl == null)) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => launchUrl(Uri.parse(widget.url),
                mode: LaunchMode.externalApplication),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 260),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.imageUrl != null)
                    Image.network(
                      data.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.title != null)
                          Text(
                            data.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        if (data.siteName != null)
                          Text(
                            data.siteName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
