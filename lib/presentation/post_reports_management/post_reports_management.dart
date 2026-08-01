import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Modération des publications signalées par les clients (Communauté,
/// ex-Mur — voir supabase/phase47_patch_report_and_whatsapp_contact.sql).
/// Deux actions possibles : supprimer la publication (supprime aussi le
/// signalement en cascade), ou ignorer le signalement (la publication
/// reste, le signalement passe à "traité").
class PostReportsManagement extends StatefulWidget {
  const PostReportsManagement({super.key});

  @override
  State<PostReportsManagement> createState() =>
      _PostReportsManagementState();
}

class _PostReportsManagementState extends State<PostReportsManagement> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = 'en_attente';
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
          .from('post_reports')
          .select(
              '*, posts(content, image_url), profiles(full_name, company_name)')
          .order('created_at', ascending: false);
      setState(() {
        _reports = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger les signalements (migration phase47 exécutée ?).';
      });
    }
  }

  Future<void> _deletePost(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publication'),
        content: const Text(
            'Cette action est définitive et retire aussi le signalement. Continuer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseConfig.client
          .from('posts')
          .delete()
          .eq('id', report['post_id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication supprimée.')));
      _loadData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur lors de la suppression.')));
    }
  }

  Future<void> _dismiss(Map<String, dynamic> report) async {
    try {
      await SupabaseConfig.client
          .from('post_reports')
          .update({'status': 'traite'}).eq('id', report['id']);
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
    final filtered = _reports
        .where((r) => _statusFilter == 'tous' || r['status'] == _statusFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Signalements Communauté')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: EdgeInsets.all(4.w),
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final status in ['en_attente', 'traite', 'tous'])
                            ChoiceChip(
                              label: Text(status == 'tous'
                                  ? 'Tous'
                                  : status == 'en_attente'
                                      ? 'En attente'
                                      : 'Traités'),
                              selected: _statusFilter == status,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = status),
                            ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      if (filtered.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Center(
                            child: Text('Aucun signalement.',
                                style: theme.textTheme.bodyMedium),
                          ),
                        )
                      else
                        ...filtered.map((report) {
                          final post = report['posts'] as Map?;
                          final reporter = report['profiles'] as Map?;
                          final reporterName = reporter?['company_name'] ??
                              reporter?['full_name'] ??
                              'Client';
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text('Signalé par $reporterName',
                                            style: theme.textTheme.titleSmall),
                                      ),
                                      Chip(
                                        label: Text(report['status'],
                                            style:
                                                const TextStyle(fontSize: 11)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  Text(_dateFormat.format(
                                      DateTime.parse(report['created_at']))),
                                  if ((report['reason'] as String?)
                                          ?.isNotEmpty ==
                                      true) ...[
                                    SizedBox(height: 0.5.h),
                                    Text('Raison : ${report['reason']}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                fontStyle: FontStyle.italic)),
                                  ],
                                  const Divider(height: 20),
                                  if (post == null)
                                    const Text(
                                        'Publication déjà supprimée.',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic))
                                  else ...[
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
                                          height: 15.h,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 8),
                                  if (report['status'] == 'en_attente')
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _dismiss(report),
                                          child: const Text('Ignorer'),
                                        ),
                                        if (post != null)
                                          FilledButton(
                                            onPressed: () =>
                                                _deletePost(report),
                                            style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    theme.colorScheme.error),
                                            child: const Text(
                                                'Supprimer la publication'),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
