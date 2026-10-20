import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Détail d'un article Actualités — `post` est la ligne `news_posts` déjà
/// chargée par [NewsListScreen], pas de requête supplémentaire ici.
class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;

  const NewsDetailScreen({super.key, required this.post});

  Future<void> _openCta(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir ce lien.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = post['title'] as String? ?? '';
    final coverUrl = post['cover_image_url'] as String?;
    final body = post['body'] as String? ?? '';
    final ctaLabel = post['cta_label'] as String?;
    final ctaUrl = post['cta_url'] as String?;
    final publishedAt = DateTime.tryParse(post['published_at'] ?? '');
    // Le corps est du texte brut, paragraphes séparés par des lignes
    // vides (pas de HTML/Markdown à parser — voir demande explicite).
    final paragraphs = body
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Actualités')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (coverUrl != null && coverUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: coverUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: theme.colorScheme.surfaceContainerHighest),
                  errorWidget: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (publishedAt != null) ...[
                    SizedBox(height: 1.h),
                    Text(
                      DateFormat('dd/MM/yyyy').format(publishedAt.toLocal()),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  SizedBox(height: 2.h),
                  for (final paragraph in paragraphs) ...[
                    Text(paragraph, style: theme.textTheme.bodyMedium),
                    SizedBox(height: 2.h),
                  ],
                  if (ctaUrl != null && ctaUrl.isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    FilledButton(
                      onPressed: () => _openCta(context, ctaUrl),
                      child: Text(
                          (ctaLabel != null && ctaLabel.isNotEmpty)
                              ? ctaLabel
                              : 'En savoir plus'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
