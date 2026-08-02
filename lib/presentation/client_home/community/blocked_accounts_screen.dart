import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/community/community_moderation_repo.dart';
import 'public_profiles_repo.dart';

/// Comptes bloqués — écran de gestion (Lot 1 Communauté, 02/08). Voir
/// supabase/phase51_patch_block_hide_save_posts.sql : la lecture de
/// `user_blocks` est volontairement limitée à SES PROPRES blocages
/// (jamais qui M'A bloqué), donc cet écran ne peut montrer que la liste
/// des gens que l'utilisateur connecté a lui-même bloqués.
class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  List<Map<String, dynamic>> _blocked = [];
  Map<String, Map<String, dynamic>> _profiles = {};
  bool _isLoading = true;
  final Set<String> _unblocking = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final blocked = await CommunityModerationRepo.fetchBlocked();
    final ids = blocked.map((r) => r['blocked_id'] as String).toSet();
    final profiles = await PublicProfilesRepo.fetchByIds(ids);
    if (!mounted) return;
    setState(() {
      _blocked = blocked;
      _profiles = profiles;
      _isLoading = false;
    });
  }

  Future<void> _unblock(String userId) async {
    setState(() => _unblocking.add(userId));
    try {
      await CommunityModerationRepo.unblock(userId);
      if (!mounted) return;
      setState(() {
        _blocked.removeWhere((r) => r['blocked_id'] == userId);
        _unblocking.remove(userId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _unblocking.remove(userId));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur, réessayez.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Comptes bloqués')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blocked.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Text(
                      'Vous n\'avez bloqué personne.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _blocked.length,
                  separatorBuilder: (_, __) => SizedBox(height: 1.h),
                  itemBuilder: (context, index) {
                    final row = _blocked[index];
                    final userId = row['blocked_id'] as String;
                    final profile = _profiles[userId];
                    final isUnblocking = _unblocking.contains(userId);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profile?['avatar_url'] != null
                              ? NetworkImage(profile!['avatar_url'])
                              : null,
                          child: profile?['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(PublicProfilesRepo.displayName(profile)),
                        trailing: TextButton(
                          onPressed:
                              isUnblocking ? null : () => _unblock(userId),
                          child: isUnblocking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Text('Débloquer'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
