import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_config.dart';
import 'cart_tab.dart';
import 'catalog_tab.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';

/// Espace client : accueil (catalogue), panier, commandes, profil.
/// Point d'entrée pour tout utilisateur avec le rôle "client".
///
/// Schéma de navigation : le Panier n'a plus d'onglet dans la barre du bas
/// (accessible via l'icône dans l'en-tête de l'écran Accueil, à côté des
/// notifications). L'onglet "Mur" a été retiré du menu — le mur social
/// reste dans le code (wall/wall_tab.dart) en vue de son intégration future
/// dans le Profil (voir PROJECT_CONTEXT.md, plan profil étape 3).
class ClientHome extends ConsumerStatefulWidget {
  const ClientHome({super.key});

  @override
  ConsumerState<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends ConsumerState<ClientHome> {
  // 0 = Accueil, 1 = Panier, 2 = Commandes, 3 = Profil
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Accueil',
    'Panier',
    'Commandes',
    'Profil',
  ];

  Future<void> _handleLogout() async {
    if (SupabaseConfig.isConfigured) {
      await SupabaseConfig.client.auth.signOut();
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/authentication-screen',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CatalogTab(onOpenCart: () => setState(() => _currentIndex = 1)),
      const CartTab(),
      const OrdersTab(),
      ProfileTab(onLogout: _handleLogout),
    ];

    return Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(title: Text(_titles[_currentIndex])),
      body: pages[_currentIndex],
      bottomNavigationBar: _ClientBottomNav(
        currentIndex: _currentIndex,
        onSelect: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _NavItem {
  final int pageIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.pageIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Barre de navigation du bas à 3 destinations (Accueil, Commandes, Profil).
/// Le Panier n'y figure pas : on y accède depuis l'en-tête de l'Accueil.
class _ClientBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _ClientBottomNav({required this.currentIndex, required this.onSelect});

  static const _items = [
    _NavItem(
      pageIndex: 0,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Accueil',
    ),
    _NavItem(
      pageIndex: 2,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Commandes',
    ),
    _NavItem(
      pageIndex: 3,
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              width: 0.6,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _items.map((item) {
            final selected = currentIndex == item.pageIndex;
            final color = selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant;
            return Expanded(
              child: InkWell(
                onTap: () => onSelect(item.pageIndex),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(selected ? item.selectedIcon : item.icon,
                        color: color),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
