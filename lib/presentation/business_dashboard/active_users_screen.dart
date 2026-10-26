import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/chat/presence_helper.dart';
import '../../core/supabase/supabase_config.dart';

/// Détail de la carte "Utilisateurs actifs (7j)" du tableau de bord staff
/// (26/10, demande explicite — la carte n'était pas cliquable). Même
/// fenêtre de 7 jours que le compteur (`profiles.last_active_at`,
/// phase263), avec en plus le statut "En ligne maintenant" par
/// utilisateur (`profiles.last_seen_at`, voir `PresenceHelper` — mis à
/// jour en continu pendant que l'app est au premier plan, voir
/// `main.dart`/`_GlobalPresenceHeartbeat`, pas seulement dans un écran de
/// chat comme c'était le cas jusqu'ici).
class ActiveUsersScreen extends StatefulWidget {
  const ActiveUsersScreen({super.key});

  @override
  State<ActiveUsersScreen> createState() => _ActiveUsersScreenState();
}

class _ActiveUsersScreenState extends State<ActiveUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final sevenDaysAgo =
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      final rows = await SupabaseConfig.client
          .from('profiles')
          .select('id, full_name, company_name, avatar_url, role, '
              'last_active_at, last_seen_at')
          .gte('last_active_at', sevenDaysAgo)
          .order('last_active_at', ascending: false);
      final users = List<Map<String, dynamic>>.from(rows);
      // En ligne maintenant en premier, puis par dernière activité
      // décroissante (déjà l'ordre renvoyé par la requête, `sort` stable
      // préserve donc cet ordre secondaire au sein de chaque groupe).
      users.sort((a, b) {
        final aOnline = PresenceHelper.isOnline(a['last_seen_at'] as String?);
        final bOnline = PresenceHelper.isOnline(b['last_seen_at'] as String?);
        if (aOnline == bOnline) return 0;
        return aOnline ? -1 : 1;
      });
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les utilisateurs actifs.';
      });
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'commercial':
        return 'Commercial';
      case 'production':
        return 'Production';
      case 'comptable':
        return 'Comptable';
      default:
        return 'Client';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Utilisateurs actifs (7j)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _users.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 20.h),
                            const Center(
                                child: Text('Aucun utilisateur actif récemment.')),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final avatarUrl = user['avatar_url'] as String?;
                            final lastSeenAt = user['last_seen_at'] as String?;
                            final online = PresenceHelper.isOnline(lastSeenAt);
                            final fullName =
                                (user['full_name'] as String?)?.trim();
                            final name = (fullName != null && fullName.isNotEmpty)
                                ? fullName
                                : (user['company_name'] as String?) ??
                                    'Utilisateur';
                            final statusLabel = PresenceHelper.label(lastSeenAt);
                            return ListTile(
                              leading: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  if (online)
                                    Positioned(
                                      right: -1,
                                      bottom: -1,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.green,
                                          border: Border.all(
                                              color: theme.scaffoldBackgroundColor,
                                              width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              title: Text(name),
                              subtitle: Text(_roleLabel(user['role'] as String?)),
                              trailing: statusLabel.isEmpty
                                  ? null
                                  : Text(
                                      statusLabel,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: online
                                            ? Colors.green
                                            : theme.colorScheme.onSurfaceVariant,
                                        fontWeight:
                                            online ? FontWeight.w600 : null,
                                      ),
                                    ),
                            );
                          },
                        ),
                ),
    );
  }
}
