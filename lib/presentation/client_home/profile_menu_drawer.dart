import 'package:flutter/material.dart';

import '../../core/chat/unread_support_messages.dart';
import '../../core/supabase/supabase_config.dart';
import 'chat_screen.dart';
import 'community/public_profile_screen.dart';
import 'delivery_addresses/delivery_addresses_screen.dart';
import 'favorites_screen.dart';
import 'formation/my_formation_groups_screen.dart';
import 'loyalty/loyalty_screen.dart';
import 'my_contact_qr_screen.dart';
import 'my_reviews_screen.dart';
import 'recurring_orders/recurring_orders_screen.dart';
import 'settings/settings_screen.dart';
import 'usual_cart_screen.dart';

/// Menu latéral du Profil (04/08) — regroupe toutes les fonctions
/// auparavant éparpillées entre la barre de raccourcis et les cartes
/// "Mes achats"/"Communauté & Formation" de la page Profil, pour que
/// celle-ci se concentre sur l'essentiel visuel (couverture, identité,
/// publications). Les informations personnelles (nom, société,
/// téléphone...) restent volontairement hors de ce menu — uniquement
/// via "Modifier le profil" sur la page Profil elle-même (demande
/// explicite de l'utilisatrice). Autonome (charge ses propres données)
/// pour pouvoir être ouvert depuis le Scaffold partagé de ClientHome
/// sans dépendre de l'état interne de ProfileTab.
class ProfileMenuDrawer extends StatefulWidget {
  const ProfileMenuDrawer({super.key});

  @override
  State<ProfileMenuDrawer> createState() => _ProfileMenuDrawerState();
}

class _ProfileMenuDrawerState extends State<ProfileMenuDrawer> {
  int _unreadSupportCount = 0;
  int _reviewsCount = 0;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    final unread = await fetchUnreadSupportMessagesCount();
    if (userId != null) {
      try {
        final result = await SupabaseConfig.client
            .from('product_reviews')
            .select('id')
            .eq('author_id', userId)
            .count();
        if (mounted) setState(() => _reviewsCount = result.count);
      } catch (_) {}
      try {
        final data = await SupabaseConfig.client
            .from('profiles')
            .select('full_name, company_name, phone')
            .eq('id', userId)
            .maybeSingle();
        if (mounted) setState(() => _profile = data);
      } catch (_) {}
    }
    if (mounted) setState(() => _unreadSupportCount = unread);
  }

  void _open(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration:
                  BoxDecoration(color: theme.colorScheme.primaryContainer),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('Menu',
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            _sectionLabel(theme, 'Compte & Assistance'),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Paramètres'),
              onTap: () => _open(const SettingsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Assistance'),
              trailing: _unreadSupportCount > 0
                  ? _CountBadge(count: _unreadSupportCount)
                  : null,
              onTap: () => _open(const ChatScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scanner un produit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/product-scanner');
              },
            ),
            const Divider(height: 1),
            _sectionLabel(theme, 'Mes achats'),
            ListTile(
              leading: const Icon(Icons.autorenew),
              title: const Text('Commandes récurrentes'),
              onTap: () => _open(const RecurringOrdersScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Fidélité'),
              onTap: () => _open(const LoyaltyScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Adresses de livraison'),
              onTap: () => _open(const DeliveryAddressesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Mes favoris'),
              onTap: () => _open(const FavoritesScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text('Mon panier habituel'),
              onTap: () => _open(const UsualCartScreen()),
            ),
            const Divider(height: 1),
            _sectionLabel(theme, 'Communauté & Formation'),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Voir mon profil public'),
              onTap: () {
                final myId = SupabaseConfig.client.auth.currentUser?.id;
                if (myId == null) return;
                _open(PublicProfileScreen(userId: myId));
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('Ma carte de contact'),
              onTap: () => _open(MyContactQrScreen(
                fullName: _profile?['full_name'] as String?,
                companyName: _profile?['company_name'] as String?,
                phone: _profile?['phone'] as String?,
              )),
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Mes avis laissés'),
              subtitle: Text('$_reviewsCount avis'),
              onTap: () => _open(const MyReviewsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('Mes groupes Formation'),
              onTap: () => _open(const MyFormationGroupsScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: TextStyle(
          color: theme.colorScheme.onError,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
