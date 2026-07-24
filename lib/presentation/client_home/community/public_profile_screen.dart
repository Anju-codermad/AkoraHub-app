import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/supabase/supabase_config.dart';
import 'public_profiles_repo.dart';

/// Profil public "léger" d'un autre client, consultable en tapant sur son
/// nom/avatar dans le Mur. N'affiche que des infos non sensibles (nom,
/// société, secteur, avatar) via la vue `public_profiles`
/// (supabase/phase9_patch_public_profiles.sql), plus ses publications
/// publiques récentes. Aucune info de contact (téléphone, localisation
/// précise) n'est montrée ici.
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
      final profiles = await PublicProfilesRepo.fetchByIds([widget.userId]);
      final posts = await SupabaseConfig.client
          .from('posts')
          .select()
          .eq('author_id', widget.userId)
          .eq('visibility', 'public')
          .order('created_at', ascending: false)
          .limit(20);
      if (!mounted) return;
      setState(() {
        _profile = profiles[widget.userId];
        _posts = List<Map<String, dynamic>>.from(posts);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(PublicProfilesRepo.displayName(_profile)),
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
                        child: Text(
                          PublicProfilesRepo.displayName(_profile),
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
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
