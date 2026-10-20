import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/supabase/supabase_config.dart';
import 'news_detail_screen.dart';

/// Section Actualités (20/10, demande explicite) — lit `news_posts`,
/// table partagée avec le site web `groupe-akora-site` (voir
/// `site/actualites.html` côté site, même logique reproduite ici).
/// Lecture seule : la publication se fait uniquement depuis l'admin web
/// `admin-actualites.html`. RLS limite déjà la lecture publique aux
/// lignes `status = 'publie'`, mais on filtre aussi côté requête pour
/// rester explicite et ne jamais dépendre silencieusement de la policy.
class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _error;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseConfig.client
          .from('news_posts')
          .select()
          .eq('status', 'publie')
          .order('published_at', ascending: false);
      setState(() {
        _posts = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les actualités.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Actualités')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _posts.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            const Center(
                                child:
                                    Text('Aucune actualité pour le moment.')),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(4.w),
                          itemCount: _posts.length,
                          separatorBuilder: (_, __) => SizedBox(height: 2.h),
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            final coverUrl =
                                post['cover_image_url'] as String?;
                            final title = post['title'] as String? ?? '';
                            final excerpt = post['excerpt'] as String?;
                            final publishedAt =
                                DateTime.tryParse(post['published_at'] ?? '');
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NewsDetailScreen(post: post),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (coverUrl != null &&
                                        coverUrl.isNotEmpty)
                                      AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: CachedNetworkImage(
                                          imageUrl: coverUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(
                                              color: theme.colorScheme
                                                  .surfaceContainerHighest),
                                          errorWidget: (_, __, ___) =>
                                              Container(
                                            color: theme.colorScheme
                                                .surfaceContainerHighest,
                                            child: const Icon(Icons
                                                .image_not_supported_outlined),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: EdgeInsets.all(3.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(title,
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700)),
                                          if (excerpt != null &&
                                              excerpt.isNotEmpty) ...[
                                            SizedBox(height: 0.5.h),
                                            Text(
                                              excerpt,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme
                                                  .textTheme.bodyMedium
                                                  ?.copyWith(
                                                      color: theme.colorScheme
                                                          .onSurfaceVariant),
                                            ),
                                          ],
                                          if (publishedAt != null) ...[
                                            SizedBox(height: 1.h),
                                            Text(
                                              _dateFormat
                                                  .format(publishedAt.toLocal()),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                      color: theme.colorScheme
                                                          .onSurfaceVariant),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
