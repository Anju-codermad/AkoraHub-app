import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/community/community_moderation_repo.dart';
import '../../../core/community/friends_repo.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/utils/whatsapp_link.dart';
import 'friend_chat_screen.dart';
import 'public_profiles_repo.dart';

/// Profil public "léger" d'un autre client, consultable en tapant sur son
/// nom/avatar dans le Mur. N'affiche que des infos non sensibles (nom,
/// société, secteur, avatar) via la vue `public_profiles`
/// (supabase/phase9_patch_public_profiles.sql), plus ses publications
/// publiques récentes. Aucune localisation précise n'est montrée ici ;
/// le numéro de téléphone n'apparaît que si le client l'a explicitement
/// rendu public (01/08, voir
/// supabase/phase47_patch_report_and_whatsapp_contact.sql et
/// security_settings_screen.dart) — masqué par défaut pour tout le
/// monde.
///
/// Depuis le 01/08, ce profil affiche aussi le bouton "Ajouter en ami"
/// (voir supabase/phase48_patch_friends_and_private_chat.sql) — réservé
/// aux clients ayant déjà fait au moins un achat.
class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _friendship;
  bool _isEligible = false;
  bool _isActingOnFriendship = false;
  bool _isBlocked = false;
  bool _isActingOnBlock = false;

  String? get _myId => SupabaseConfig.client.auth.currentUser?.id;

  final Map<String, String> _sectorLabels = const {
    'hotel': 'Hôtellerie',
    'hopital': 'Santé',
    'entreprise': 'Entreprises',
    'particulier': 'Particuliers',
  };

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
      final results = await Future.wait<dynamic>([
        PublicProfilesRepo.fetchByIds([widget.userId]),
        SupabaseConfig.client
            .from('posts')
            .select()
            .eq('author_id', widget.userId)
            .eq('visibility', 'public')
            .order('created_at', ascending: false)
            .limit(20),
        FriendsRepo.fetchFriendshipStatus(widget.userId),
        FriendsRepo.hasMadePurchase(),
        CommunityModerationRepo.fetchBlockedIds(),
      ]);
      if (!mounted) return;
      final profiles = results[0] as Map<String, Map<String, dynamic>>;
      final blockedIds = results[4] as Set<String>;
      setState(() {
        _profile = profiles[widget.userId];
        _posts = List<Map<String, dynamic>>.from(results[1] as List);
        _friendship = results[2] as Map<String, dynamic>?;
        _isEligible = results[3] as bool;
        _isBlocked = blockedIds.contains(widget.userId);
        _isLoading = false;
        if (_profile == null) {
          _error = 'Profil indisponible.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger ce profil.';
      });
    }
  }

  Future<void> _sendFriendRequest() async {
    setState(() => _isActingOnFriendship = true);
    try {
      await FriendsRepo.sendRequest(widget.userId);
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isActingOnFriendship = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible d\'envoyer la demande pour le moment.')));
    }
  }

  Future<void> _respondToRequest(bool accept) async {
    final friendship = _friendship;
    if (friendship == null) return;
    setState(() => _isActingOnFriendship = true);
    try {
      if (accept) {
        await FriendsRepo.acceptRequest(friendship['id']);
      } else {
        await FriendsRepo.refuseRequest(friendship['id']);
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isActingOnFriendship = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur, réessayez.')));
    }
  }

  Future<void> _cancelOrRemove() async {
    final friendship = _friendship;
    if (friendship == null) return;
    setState(() => _isActingOnFriendship = true);
    try {
      await FriendsRepo.removeFriendship(friendship['id']);
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isActingOnFriendship = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erreur, réessayez.')));
    }
  }

  /// Bloquer/débloquer ce client (Lot 1 Communauté, 02/08) — voir
  /// supabase/phase51_patch_block_hide_save_posts.sql. Un blocage exclut
  /// immédiatement ses publications du fil (RLS) et coupe les nouvelles
  /// demandes d'ami/messages, même déjà amis.
  Future<void> _toggleBlock() async {
    if (_isBlocked) {
      setState(() => _isActingOnBlock = true);
      try {
        await CommunityModerationRepo.unblock(widget.userId);
        if (!mounted) return;
        setState(() {
          _isBlocked = false;
          _isActingOnBlock = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _isActingOnBlock = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur, réessayez.')));
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquer ce client ?'),
        content: const Text(
            'Vous ne verrez plus ses publications, et il ne pourra plus vous envoyer de demande d\'ami ni de message.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isActingOnBlock = true);
    try {
      await CommunityModerationRepo.block(widget.userId);
      if (!mounted) return;
      setState(() {
        _isBlocked = true;
        _isActingOnBlock = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isActingOnBlock = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Erreur, réessayez.')));
    }
  }

  Widget _buildFriendSection(ThemeData theme) {
    if (widget.userId == _myId) return const SizedBox.shrink();

    if (_isBlocked) {
      return Center(
        child: Text('Vous avez bloqué ce client.',
            style: theme.textTheme.bodySmall),
      );
    }

    final status = _friendship?['status'] as String?;
    final iAmRequester = _friendship?['requester_id'] == _myId;

    if (status == 'acceptee') {
      return Center(
        child: Column(
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FriendChatScreen(
                    otherUserId: widget.userId,
                    otherUserName: PublicProfilesRepo.displayName(_profile),
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Discuter'),
            ),
            TextButton(
              onPressed: _isActingOnFriendship ? null : _cancelOrRemove,
              child: const Text('Retirer cet ami'),
            ),
          ],
        ),
      );
    }

    if (status == 'en_attente') {
      if (iAmRequester) {
        return Center(
          child: TextButton.icon(
            onPressed: _isActingOnFriendship ? null : _cancelOrRemove,
            icon: const Icon(Icons.hourglass_top_outlined, size: 18),
            label: const Text('Demande envoyée — Annuler'),
          ),
        );
      }
      return Center(
        child: Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: _isActingOnFriendship
                  ? null
                  : () => _respondToRequest(false),
              child: const Text('Refuser'),
            ),
            FilledButton(
              onPressed:
                  _isActingOnFriendship ? null : () => _respondToRequest(true),
              child: const Text('Accepter la demande d\'ami'),
            ),
          ],
        ),
      );
    }

    if (status == 'refusee') {
      return Center(
        child: Text('Demande refusée', style: theme.textTheme.bodySmall),
      );
    }

    // Aucune relation existante.
    return Center(
      child: Tooltip(
        message: _isEligible
            ? ''
            : 'Passez votre première commande pour utiliser cette fonction.',
        child: OutlinedButton.icon(
          onPressed: (_isEligible && !_isActingOnFriendship)
              ? _sendFriendRequest
              : null,
          icon: const Icon(Icons.person_add_alt_outlined, size: 18),
          label: const Text('Ajouter en ami'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(PublicProfilesRepo.displayName(_profile)),
        actions: widget.userId == _myId
            ? null
            : [
                IconButton(
                  tooltip: _isBlocked ? 'Débloquer' : 'Bloquer ce client',
                  icon: _isActingOnBlock
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_isBlocked
                          ? Icons.block
                          : Icons.block_outlined),
                  onPressed: _isActingOnBlock ? null : _toggleBlock,
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.all(4.w),
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: _profile?['avatar_url'] != null
                              ? NetworkImage(_profile!['avatar_url'])
                              : null,
                          child: _profile?['avatar_url'] == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                      ),
                      SizedBox(height: 1.5.h),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                PublicProfilesRepo.displayName(_profile),
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (_profile?['is_staff'] == true) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified,
                                  size: 18, color: theme.colorScheme.primary),
                            ],
                          ],
                        ),
                      ),
                      if (_sectorLabels[_profile?['client_type']] != null)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 0.5.h),
                            child: Chip(
                              label: Text(
                                  _sectorLabels[_profile?['client_type']]!),
                            ),
                          ),
                        ),
                      SizedBox(height: 1.5.h),
                      _buildFriendSection(theme),
                      if (!_isBlocked &&
                          buildWhatsAppLink(
                                  _profile?['phone'] as String?) !=
                              null) ...[
                        SizedBox(height: 1.5.h),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final link = buildWhatsAppLink(
                                  _profile?['phone'] as String?)!;
                              try {
                                await launchUrl(Uri.parse(link),
                                    mode: LaunchMode.externalApplication);
                              } catch (_) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Impossible d\'ouvrir WhatsApp.')));
                              }
                            },
                            icon: const Icon(Icons.chat_outlined,
                                color: Colors.green),
                            label: const Text('Contacter via WhatsApp'),
                          ),
                        ),
                      ],
                      SizedBox(height: 3.h),
                      Text('Publications', style: theme.textTheme.titleMedium),
                      SizedBox(height: 1.h),
                      if (_posts.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Center(
                            child: Text(
                              'Aucune publication publique.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        )
                      else
                        ..._posts.map((post) => Card(
                              margin: EdgeInsets.only(bottom: 1.5.h),
                              child: Padding(
                                padding: EdgeInsets.all(3.w),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if ((post['content'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Text(post['content']),
                                    if (post['image_url'] != null) ...[
                                      SizedBox(height: 1.h),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.network(
                                          post['image_url'],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 18.h,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}
