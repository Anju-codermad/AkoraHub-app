import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/supabase/supabase_config.dart';
import 'cart_tab.dart';
import 'catalog_tab.dart';
import 'orders_tab.dart';

/// Espace client : catalogue, panier, commandes, profil.
/// Point d'entrée pour tout utilisateur avec le rôle "client".
class ClientHome extends ConsumerStatefulWidget {
  const ClientHome({super.key});

  @override
  ConsumerState<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends ConsumerState<ClientHome> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Catalogue',
    'Panier',
    'Mes commandes',
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
    final cartCount = ref.watch(cartProvider).length;

    final pages = [
      const CatalogTab(),
      const CartTab(),
      const OrdersTab(),
      _ProfileTab(onLogout: _handleLogout),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Catalogue',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$cartCount'),
              isLabelVisible: cartCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Panier',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Commandes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final VoidCallback onLogout;

  const _ProfileTab({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.isConfigured
        ? SupabaseConfig.client.auth.currentUser
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 32,
          child: Icon(Icons.person, size: 32),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 32),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Déconnexion',
              style: TextStyle(color: Colors.red)),
          onTap: onLogout,
        ),
      ],
    );
  }
}
