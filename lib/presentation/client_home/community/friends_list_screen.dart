import 'package:flutter/material.dart';

import '../../../core/community/friends_repo.dart';
import 'friend_chat_screen.dart';
import 'public_profiles_repo.dart';

/// Liste des amis + demandes reçues/envoyées (voir
/// supabase/phase48_patch_friends_and_private_chat.sql). Point d'entrée
/// unique pour gérer ses relations et accéder aux conversations privées
/// — accessible depuis l'icône dédiée dans l'AppBar de la Communauté.
class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _received = [];
  List<Map<String, dynamic>> _sent = [];
  Map<String, Map<String, dynamic>> _profiles = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait<dynamic>([
      FriendsRepo.fetchFriends(),
      FriendsRepo.fetchPendingReceived(),
      FriendsRepo.fetchPendingSent(),
    ]);
    final friends = results[0] as List<Map<String, dynamic>>;
    final received = results[1] as List<Map<String, dynamic>>;
    final sent = results[2] as List<Map<String, dynamic>>;

    final otherIds = {
      ...friends.map(FriendsRepo.otherUserId),
      ...received.map(FriendsRepo.otherUserId),
      ...sent.map(FriendsRepo.otherUserId),
    };
    final profiles = await PublicProfilesRepo.fetchByIds(otherIds);

    if (!mounted) return;
    setState(() {
      _friends = friends;
      _received = received;
      _sent = sent;
      _profiles = profiles;
      _isLoading = false;
    });
  }

  Future<void> _accept(Map<String, dynamic> f) async {
    await FriendsRepo.acceptRequest(f['id']);
    _load();
  }

  Future<void> _refuse(Map<String, dynamic> f) async {
    await FriendsRepo.refuseRequest(f['id']);
    _load();
  }

  Future<void> _cancel(Map<String, dynamic> f) async {
    await FriendsRepo.removeFriendship(f['id']);
    _load();
  }

  Widget _tile(
    Map<String, dynamic> f, {
    required List<Widget> actions,
    VoidCallback? onTap,
  }) {
    final otherId = FriendsRepo.otherUserId(f);
    final profile = _profiles[otherId];
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: profile?['avatar_url'] != null
            ? NetworkImage(profile!['avatar_url'])
            : null,
        child: profile?['avatar_url'] == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(PublicProfilesRepo.displayName(profile)),
      trailing:
          actions.isEmpty ? null : Row(mainAxisSize: MainAxisSize.min, children: actions),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Amis'),
            Tab(
                text: _received.isEmpty
                    ? 'Reçues'
                    : 'Reçues (${_received.length})'),
            const Tab(text: 'Envoyées'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _friends.isEmpty
                      ? const Center(child: Text('Aucun ami pour le moment.'))
                      : ListView(
                          children: _friends
                              .map((f) => _tile(
                                    f,
                                    actions: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.person_remove_outlined,
                                            size: 20),
                                        tooltip: 'Retirer',
                                        onPressed: () => _cancel(f),
                                      ),
                                    ],
                                    onTap: () {
                                      final otherId =
                                          FriendsRepo.otherUserId(f);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FriendChatScreen(
                                            otherUserId: otherId,
                                            otherUserName:
                                                PublicProfilesRepo
                                                    .displayName(
                                                        _profiles[otherId]),
                                          ),
                                        ),
                                      );
                                    },
                                  ))
                              .toList(),
                        ),
                  _received.isEmpty
                      ? const Center(child: Text('Aucune demande reçue.'))
                      : ListView(
                          children: _received
                              .map((f) => _tile(
                                    f,
                                    actions: [
                                      IconButton(
                                        icon:
                                            const Icon(Icons.close, size: 20),
                                        tooltip: 'Refuser',
                                        onPressed: () => _refuse(f),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check,
                                            color: Colors.green, size: 20),
                                        tooltip: 'Accepter',
                                        onPressed: () => _accept(f),
                                      ),
                                    ],
                                  ))
                              .toList(),
                        ),
                  _sent.isEmpty
                      ? const Center(child: Text('Aucune demande envoyée.'))
                      : ListView(
                          children: _sent
                              .map((f) => _tile(
                                    f,
                                    actions: [
                                      TextButton(
                                        onPressed: () => _cancel(f),
                                        child: const Text('Annuler'),
                                      ),
                                    ],
                                  ))
                              .toList(),
                        ),
                ],
              ),
            ),
    );
  }
}
