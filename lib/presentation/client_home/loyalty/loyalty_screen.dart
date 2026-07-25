import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/supabase/supabase_config.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

/// Un palier = (nom, seuil minimum de points, couleur, avantage annoncé).
/// Purement informatif pour l'instant (pas de remise automatique) — les
/// avantages concrets par palier restent à définir avec l'utilisateur.
class _Tier {
  final String name;
  final int minPoints;
  final Color color;
  final String perk;

  const _Tier(this.name, this.minPoints, this.color, this.perk);
}

const _tiers = [
  _Tier('Bronze', 0, Color(0xFFCD7F32), 'Membre AkoraHub'),
  _Tier('Argent', 1000, Color(0xFFA8A9AD), 'Client régulier reconnu'),
  _Tier('Or', 5000, Color(0xFFD4AF37), 'Client fidèle privilégié'),
];

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  int _points = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = SupabaseConfig.isConfigured
        ? SupabaseConfig.client.auth.currentUser?.id
        : null;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select('loyalty_points')
          .eq('id', userId)
          .single();
      setState(() {
        _points = (data['loyalty_points'] ?? 0) as int;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  _Tier get _currentTier {
    _Tier result = _tiers.first;
    for (final tier in _tiers) {
      if (_points >= tier.minPoints) result = tier;
    }
    return result;
  }

  _Tier? get _nextTier {
    for (final tier in _tiers) {
      if (tier.minPoints > _points) return tier;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _currentTier;
    final next = _nextTier;
    final progress = next == null
        ? 1.0
        : (_points - current.minPoints) /
            (next.minPoints - current.minPoints).clamp(1, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Fidélité')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                Container(
                  padding: EdgeInsets.all(5.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        current.color,
                        current.color.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Palier ${current.name}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          )),
                      SizedBox(height: 0.5.h),
                      Text(current.perk,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70)),
                      SizedBox(height: 2.h),
                      Text('$_points points',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),
                if (next != null) ...[
                  Text(
                    'Encore ${next.minPoints - _points} points pour le palier ${next.name}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 1.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: current.color,
                    ),
                  ),
                  SizedBox(height: 3.h),
                ] else
                  Padding(
                    padding: EdgeInsets.only(bottom: 3.h),
                    child: Text(
                      'Vous avez atteint le palier le plus élevé !',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                Text('Comment gagner des points ?',
                    style: theme.textTheme.titleMedium),
                SizedBox(height: 1.h),
                Text(
                  '1 point est crédité automatiquement pour chaque tranche de 1 000 Ar dépensée, dès qu\'une commande est marquée "Livrée".',
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: 3.h),
                Text('Tous les paliers', style: theme.textTheme.titleMedium),
                SizedBox(height: 1.h),
                ..._tiers.map((tier) {
                  final reached = _points >= tier.minPoints;
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: reached
                            ? tier.color
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.emoji_events,
                          color: reached ? Colors.white : theme.colorScheme.outline,
                        ),
                      ),
                      title: Text(tier.name),
                      subtitle:
                          Text('${tier.minPoints}+ points · ${tier.perk}'),
                      trailing: reached
                          ? Icon(Icons.check_circle, color: tier.color)
                          : null,
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
