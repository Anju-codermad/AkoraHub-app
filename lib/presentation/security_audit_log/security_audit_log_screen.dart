import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Journal de sécurité (Admin uniquement) — connexions échouées/réussies,
/// changements de mot de passe, réinitialisations demandées, changements
/// de rôle. Alimenté par supabase/phase34_patch_security_audit_log.sql
/// (RLS : lecture réservée à l'Admin, écriture uniquement via les
/// fonctions SECURITY DEFINER — jamais d'insert direct depuis un client).
class SecurityAuditLogScreen extends StatefulWidget {
  const SecurityAuditLogScreen({super.key});

  @override
  State<SecurityAuditLogScreen> createState() =>
      _SecurityAuditLogScreenState();
}

class _SecurityAuditLogScreenState extends State<SecurityAuditLogScreen> {
  List<Map<String, dynamic>> _events = [];
  Map<String, Map<String, dynamic>> _profilesById = {};
  bool _isLoading = true;
  String? _error;
  static const _pageSize = 30;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final _scrollController = ScrollController();

  final Map<String, String> _eventLabels = const {
    'login_failed': 'Connexion échouée',
    'login_success': 'Connexion réussie',
    'password_reset_requested': 'Réinitialisation de mot de passe demandée',
    'password_changed': 'Mot de passe changé',
    'role_changed': 'Rôle modifié',
  };

  final Map<String, IconData> _eventIcons = const {
    'login_failed': Icons.lock_outline,
    'login_success': Icons.login,
    'password_reset_requested': Icons.mail_outline,
    'password_changed': Icons.password_outlined,
    'role_changed': Icons.admin_panel_settings_outlined,
  };

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _load() async {
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
      _page = 0;
      _hasMore = true;
    });
    try {
      final rows = await SupabaseConfig.client
          .from('security_audit_log')
          .select()
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);
      final list = List<Map<String, dynamic>>.from(rows);
      final profiles = await _fetchProfiles(list);
      setState(() {
        _events = list;
        _profilesById = profiles;
        _isLoading = false;
        _hasMore = list.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error =
            'Impossible de charger le journal. La migration phase34 a-t-elle été exécutée ?';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final rows = await SupabaseConfig.client
          .from('security_audit_log')
          .select()
          .order('created_at', ascending: false)
          .range(nextPage * _pageSize, nextPage * _pageSize + _pageSize - 1);
      final list = List<Map<String, dynamic>>.from(rows);
      final profiles = await _fetchProfiles(list);
      if (!mounted) return;
      setState(() {
        _events = [..._events, ...list];
        _profilesById = {..._profilesById, ...profiles};
        _page = nextPage;
        _hasMore = list.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchProfiles(
      List<Map<String, dynamic>> events) async {
    final ids = events
        .map((e) => e['user_id'] as String?)
        .whereType<String>()
        .toSet()
        .where((id) => !_profilesById.containsKey(id))
        .toList();
    if (ids.isEmpty) return {};
    try {
      final rows = await SupabaseConfig.client
          .from('profiles')
          .select('id, full_name, company_name')
          .inFilter('id', ids);
      return {
        for (final row in List<Map<String, dynamic>>.from(rows))
          row['id'] as String: row,
      };
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Journal de sécurité')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _events.isEmpty
                  ? const Center(
                      child: Text('Aucun événement pour le moment.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: EdgeInsets.all(4.w),
                        itemCount: _events.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => SizedBox(height: 1.h),
                        itemBuilder: (context, index) {
                          if (index >= _events.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final event = _events[index];
                          final eventType = event['event_type'] as String;
                          final userId = event['user_id'] as String?;
                          final profile =
                              userId != null ? _profilesById[userId] : null;
                          final personName = profile != null
                              ? (profile['company_name'] ??
                                  profile['full_name'] ??
                                  'Utilisateur')
                              : (userId != null ? 'Utilisateur' : '—');
                          final createdAt =
                              DateTime.tryParse(event['created_at'] ?? '');
                          final metadata =
                              event['metadata'] as Map<String, dynamic>?;
                          final isFailed = eventType == 'login_failed';
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                _eventIcons[eventType] ?? Icons.info_outline,
                                color: isFailed
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.primary,
                              ),
                              title:
                                  Text(_eventLabels[eventType] ?? eventType),
                              subtitle: Text(
                                [
                                  personName,
                                  if (eventType == 'role_changed' &&
                                      metadata != null)
                                    '${metadata['old_role']} → ${metadata['new_role']}',
                                  if (createdAt != null)
                                    dateFormat.format(createdAt.toLocal()),
                                ].join(' · '),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
