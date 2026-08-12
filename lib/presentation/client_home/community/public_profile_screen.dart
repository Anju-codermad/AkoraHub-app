import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/community/community_moderation_repo.dart';
import '../../../core/community/friends_repo.dart';
import '../../../core/constants/client_types.dart';
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

  // Amis en commun (06/08, "carte de profil") — voir
  // supabase/phase79_patch_public_profile_card_style.sql. Juste un
  // aperçu (quelques avatars + compteur), pas une liste complète.
  List<Map<String, dynamic>> _mutualFriends = [];

  // Chevauchement avatar/carte, même principe que profile_tab.dart
  // (rayon 40 + liseré 3).
  static const double _avatarOverlap = 43;

  String? get _myId => SupabaseConfig.client.auth.currentUser?.id;


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
        _fetchMutualFriends(),
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
        _mutualFriends = results[5] as List<Map<String, dynamic>>;
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

  /// Amis en commun (06/08) — voir `mutual_friends`
  /// (supabase/phase79_patch_public_profile_card_style.sql). Repli
  /// silencieux (liste vide) tant que la migration n'a pas tourné, ou si
  /// personne n'est connecté / c'est son propre profil.
  Future<List<Map<String, dynamic>>> _fetchMutualFriends() async {
    final uid = _myId;
    if (uid == null || uid == widget.userId) return [];
    try {
      final ids = await SupabaseConfig.client.rpc('mutual_friends',
          params: {'uid': uid, 'other_uid': widget.userId});
      final friendIds = List<Map<String, dynamic>>.from(ids)
          .map((r) => r['friend_id'] as String)
          .toList();
      if (friendIds.isEmpty) return [];
      final profiles = await PublicProfilesRepo.fetchByIds(friendIds);
      return [
        for (final id in friendIds)
          if (profiles.containsKey(id)) profiles[id]!,
      ];
    } catch (_) {
      return [];
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

    // Profil verrouillé (06/08, voir supabase/phase76_patch_profile_lock.sql)
    // — un visiteur qui n'est ni le propriétaire ni un ami accepté ne voit
    // que le nom et l'avatar (comme un compte privé) ; le reste (secteur,
    // WhatsApp, publications) reste masqué tant que la demande d'ami
    // n'est pas acceptée.
    final isLocked = _profile?['profile_locked'] == true;
    final isFriend = _friendship?['status'] == 'acceptee';
    final isSelf = widget.userId == _myId;
    final showFullProfile = !isLocked || isFriend || isSelf;

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
                    padding: EdgeInsets.zero,
                    children: [
                      _buildCardHeader(
                        theme: theme,
                        content: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Column(
                            children: [
                              SizedBox(height: _avatarOverlap + 1.h),
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        PublicProfilesRepo.displayName(
                                            _profile),
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    if (_profile?['is_staff'] == true) ...[
                                      const SizedBox(width: 6),
                                      Icon(Icons.verified,
                                          size: 18,
                                          color: theme.colorScheme.primary),
                                    ],
                                  ],
                                ),
                              ),
                              if (_mutualFriends.isNotEmpty) ...[
                                SizedBox(height: 1.h),
                                _buildMutualFriendsRow(theme),
                              ],
                              if (showFullProfile &&
                                  kClientTypeLabels[
                                          _profile?['client_type']] !=
                                      null)
                                Padding(
                                  padding: EdgeInsets.only(top: 0.5.h),
                                  child: Chip(
                                    label: Text(kClientTypeLabels[
                                        _profile?['client_type']]!),
                                  ),
                                ),
                              SizedBox(height: 1.5.h),
                              _buildFriendSection(theme),
                              if (showFullProfile &&
                                  !_isBlocked &&
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
                                            mode: LaunchMode
                                                .externalApplication);
                                      } catch (_) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Impossible d\'ouvrir WhatsApp.')));
                                      }
                                    },
                                    icon: const Icon(Icons.chat_outlined,
                                        color: Colors.green),
                                    label:
                                        const Text('Contacter via WhatsApp'),
                                  ),
                                ),
                              ],
                              if (!showFullProfile) ...[
                                SizedBox(height: 3.h),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.lock_outline,
                                          size: 36,
                                          color: theme.colorScheme.outline),
                                      SizedBox(height: 1.h),
                                      Text('Ce profil est privé',
                                          style: theme.textTheme.titleMedium),
                                      SizedBox(height: 0.5.h),
                                      Text(
                                        'Ajoutez ${PublicProfilesRepo.displayName(_profile)} en ami pour voir son secteur, ses coordonnées et ses publications.',
                                        style: theme.textTheme.bodySmall,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                SizedBox(height: 3.h),
                                Text('Publications',
                                    style: theme.textTheme.titleMedium),
                                SizedBox(height: 1.h),
                                if (_posts.isEmpty)
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 4.h),
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
                                            if (post['image_url'] !=
                                                null) ...[
                                              SizedBox(height: 1.h),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  post['image_url'],
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: 18.h,
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          const SizedBox
                                                              .shrink(),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    )),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Bandeau + carte blanche arrondie + avatar chevauchant (06/08, même
  /// style que "Mon profil" — voir `_buildProfileHeader` dans
  /// profile_tab.dart). Version lecture seule : pas d'upload, une seule
  /// photo de couverture (`cover_photo_url`, voir
  /// supabase/phase79_patch_public_profile_card_style.sql), repli sur un
  /// aplat de couleur si absente. L'avatar est le DERNIER enfant du
  /// Stack (peint en dernier, au premier plan), même correctif que sur
  /// "Mon profil".
  Widget _buildCardHeader({required ThemeData theme, required Widget content}) {
    final coverHeight = 15.h;
    final coverUrl = _profile?['cover_photo_url'] as String?;
    final avatarUrl = _profile?['avatar_url'] as String?;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: coverHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            image: coverUrl != null
                ? DecorationImage(
                    image: NetworkImage(coverUrl), fit: BoxFit.cover)
                : null,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: coverHeight),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: content,
          ),
        ),
        Positioned(
          top: coverHeight - _avatarOverlap,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.scaffoldBackgroundColor,
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Petite pile d'avatars superposés + compteur, façon référence
  /// partagée (06/08) — jusqu'à 3 avatars visibles, le reste compté.
  Widget _buildMutualFriendsRow(ThemeData theme) {
    final shown = _mutualFriends.take(3).toList();
    const avatarSize = 24.0;
    const overlap = 14.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: avatarSize + (shown.length - 1) * overlap,
          height: avatarSize,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * overlap,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.scaffoldBackgroundColor,
                    ),
                    child: CircleAvatar(
                      radius: avatarSize / 2 - 1.5,
                      backgroundImage: shown[i]['avatar_url'] != null
                          ? NetworkImage(shown[i]['avatar_url'])
                          : null,
                      child: shown[i]['avatar_url'] == null
                          ? const Icon(Icons.person, size: 12)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _mutualFriends.length == 1
              ? '1 ami en commun'
              : '${_mutualFriends.length} amis en commun',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
