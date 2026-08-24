import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Validation des publications Communauté avant mise en ligne (24/08, sur
/// demande) — voir supabase/phase177_patch_posts_approval_workflow.sql.
/// Différent de la modération des signalements (post_reports_management) :
/// ici on valide AVANT publication, pas après un signalement. Deux
/// actions : Approuver (visible sur le mur public) ou Rejeter (reste
/// invisible au public, l'auteur garde la publication visible pour
/// lui-même).
class PostApprovalManagement extends StatefulWidget {
  const PostApprovalManagement({super.key});

  @override
  State<PostApprovalManagement> createState() =>
      _PostApprovalManagementState();
}

class _PostApprovalManagementState extends State<PostApprovalManagement> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _error;
  final _dateFormat = DateFormat('d MMM yyyy à HH:mm', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _isLoading = false;
        _error = 'Connexion au serveur indisponible.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await SupabaseConfig.client
          .from('posts')
          .select('*, profiles(full_name, company_name)')
          .eq('approval_status', 'pending')
          .order('created_at', ascending: false);
      setState(() {
        _posts = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger les publications (migration phase177 exécutée ?).';
      });
    }
  }

  Future<void> _setStatus(Map<String, dynamic> post, String status) async {
    try {
      await SupabaseConfig.client
          .from('posts')
          .update({'approval_status': status}).eq('id', post['id']);
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Publications à valider')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: _posts.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 15.h),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 48,
                                      color: theme.colorScheme.primary),
                                  SizedBox(height: 1.h),
                                  const Text(
                                      'Aucune publication en attente.'),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: EdgeInsets.all(4.w),
                          children: _posts.map((post) {
                            final author = post['profiles'] as Map?;
                            final authorName = author?['company_name'] ??
                                author?['full_name'] ??
                                'Client';
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(authorName,
                                        style: theme.textTheme.titleSmall),
                                    Text(_dateFormat
                                        .format(DateTime.parse(
                                            post['created_at']))),
                                    const Divider(height: 20),
                                    if ((post['content'] as String?)
                                            ?.isNotEmpty ==
                                        true)
                                      Text(post['content']),
                                    if (post['image_url'] != null) ...[
                                      SizedBox(height: 1.h),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.network(
                                          post['image_url'],
                                          height: 20.h,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () =>
                                              _setStatus(post, 'rejected'),
                                          style: TextButton.styleFrom(
                                              foregroundColor:
                                                  theme.colorScheme.error),
                                          child: const Text('Rejeter'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              _setStatus(post, 'approved'),
                                          child: const Text('Approuver'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
    );
  }
}
