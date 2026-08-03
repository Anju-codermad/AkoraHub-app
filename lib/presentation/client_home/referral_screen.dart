import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/services/referral_repo.dart';

/// Programme de parrainage — code personnel + liste des filleuls. Pas de
/// récompense automatique (voir supabase/phase67_patch_referral_program.sql),
/// juste un suivi ; le staff décide manuellement quoi offrir.
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  String? _code;
  List<Map<String, dynamic>> _referrals = [];
  bool _isLoading = true;
  final _dateFormat = DateFormat('d MMM yyyy', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final code = await ReferralRepo.fetchMyCode();
    final referrals = await ReferralRepo.fetchMyReferrals();
    if (!mounted) return;
    setState(() {
      _code = code;
      _referrals = referrals;
      _isLoading = false;
    });
  }

  void _copyCode() {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copié.')),
    );
  }

  void _shareCode() {
    if (_code == null) return;
    SharePlus.instance.share(ShareParams(
      text: 'Rejoins-moi sur AkoraHub ! Utilise mon code de parrainage '
          '$_code à l\'inscription.',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Parrainage')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.all(4.w),
                children: [
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Column(
                        children: [
                          Icon(Icons.card_giftcard_outlined,
                              size: 40, color: theme.colorScheme.primary),
                          SizedBox(height: 1.h),
                          Text(
                            'Invite tes proches sur AkoraHub',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'Partage ton code : quand quelqu\'un s\'inscrit '
                            'avec, il apparaît dans ta liste de filleuls '
                            'ci-dessous.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 2.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 1.5.h),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: theme.colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _code ?? '—',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _copyCode,
                                icon: const Icon(Icons.copy_outlined, size: 18),
                                label: const Text('Copier'),
                              ),
                              SizedBox(width: 3.w),
                              FilledButton.icon(
                                onPressed: _shareCode,
                                icon:
                                    const Icon(Icons.share_outlined, size: 18),
                                label: const Text('Partager'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mes filleuls (${_referrals.length})',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  if (_referrals.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Center(
                        child: Text(
                          'Personne ne s\'est encore inscrit avec ton code.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (var i = 0; i < _referrals.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            Builder(builder: (context) {
                              final r = _referrals[i];
                              final createdAt = DateTime.tryParse(
                                  r['created_at']?.toString() ?? '');
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: r['avatar_url'] != null
                                      ? NetworkImage(r['avatar_url'])
                                      : null,
                                  child: r['avatar_url'] == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                    r['full_name'] ?? r['company_name'] ?? ''),
                                subtitle: createdAt != null
                                    ? Text(
                                        'Inscrit le ${_dateFormat.format(createdAt)}')
                                    : null,
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
