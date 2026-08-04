import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_translations.dart';
import '../../core/offline/connectivity_provider.dart';
import '../../core/offline/offline_order_queue.dart';
import 'cart_tab.dart';
import 'catalog_tab.dart';
import 'floating_chat_bubble.dart';
import 'formation/formation_hub_screen.dart';
import 'orders_tab.dart';
import 'profile_tab.dart';
import 'service_requests_tab.dart';

/// Espace client : accueil (catalogue), panier, commandes, Académie,
/// profil. Point d'entrée pour tout utilisateur avec le rôle "client".
///
/// Schéma de navigation : le Panier n'a pas d'onglet dans la barre du bas
/// (accessible via l'icône dans l'en-tête de l'écran Accueil, à côté des
/// notifications). L'onglet "Communauté" (ex-"Mur", renommé 01/08) a été
/// retiré du menu — le code reste dans wall/wall_tab.dart en vue de son
/// intégration future dans le Profil (voir PROJECT_CONTEXT.md, plan profil
/// étape 3).
/// **Académie** (01/08) : 4ᵉ onglet, regroupe en un seul point d'accès
/// les catégories de cours AkoraFormation et la base de matières
/// premières (voir `formation/formation_hub_screen.dart`).
/// **Services** (03/08) : 5ᵉ onglet, demande de service (installation,
/// intervention, consultation...) traitée manuellement par le staff —
/// distinct d'une commande de produit ou d'un devis (voir
/// `service_requests_tab.dart`).
class ClientHome extends ConsumerStatefulWidget {
  const ClientHome({super.key});

  @override
  ConsumerState<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends ConsumerState<ClientHome> {
  // 0 = Accueil, 1 = Panier, 2 = Commandes, 3 = Profil, 4 = Académie,
  // 5 = Services
  int _currentIndex = 0;
  bool? _wasOnline;

  @override
  void initState() {
    super.initState();
    // Tente d'envoyer les commandes/devis en attente dès l'ouverture de
    // l'app (utile si la connexion est revenue pendant que l'app était
    // fermée) — le listener de connectivité ci-dessous prend le relais
    // pour les changements pendant que l'app est ouverte.
    OfflineOrderQueue.trySync();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final titles = [
      AppTranslations.t('nav_home', locale),
      AppTranslations.t('nav_cart', locale),
      AppTranslations.t('nav_orders', locale),
      AppTranslations.t('nav_profile', locale),
      'Académie',
      AppTranslations.t('nav_services', locale),
    ];
    final pages = [
      CatalogTab(
        onOpenCart: () => setState(() => _currentIndex = 1),
        onOpenProfile: () => setState(() => _currentIndex = 3),
      ),
      const CartTab(),
      const OrdersTab(),
      const ProfileTab(),
      const FormationHubScreen(),
      const ServiceRequestsTab(),
    ];

    final connectivity = ref.watch(connectivityProvider);
    final isOnline = connectivity.value ?? true;

    // Dès qu'on repasse en ligne (après avoir été hors-ligne), on tente
    // d'envoyer automatiquement les commandes/devis en attente.
    if (_wasOnline == false && isOnline) {
      OfflineOrderQueue.trySync().then((sentCount) {
        if (sentCount > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                sentCount == 1
                    ? '1 commande en attente a été envoyée.'
                    : '$sentCount commandes en attente ont été envoyées.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
    _wasOnline = isOnline;

    return FloatingChatBubble(
      child: Scaffold(
      appBar: _currentIndex == 0
          ? null
          : AppBar(title: Text(titles[_currentIndex])),
      // SafeArea(bottom: false) car la barre de navigation du bas gère déjà
      // sa propre zone de sécurité. Nécessaire notamment pour l'onglet
      // Accueil (index 0) qui n'a pas d'AppBar et affichait sinon son
      // en-tête (avatar, nom "AkoraHub", panier, notifications) trop près
      // de l'heure/batterie/réseau du système.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                color: Colors.orange.shade700,
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Mode hors-ligne — vos commandes seront envoyées dès le retour du réseau',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            Expanded(child: pages[_currentIndex]),
          ],
        ),
      ),
      bottomNavigationBar: _ClientBottomNav(
        currentIndex: _currentIndex,
        onSelect: (index) => setState(() => _currentIndex = index),
      ),
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

/// Barre de navigation du bas à 5 destinations (Accueil, Commandes,
/// Académie, Services, Profil). Le Panier n'y figure pas : on y accède
/// depuis l'en-tête de l'Accueil.
class _ClientBottomNav extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const _ClientBottomNav({required this.currentIndex, required this.onSelect});

  List<_NavItem> _items(String locale) => [
        _NavItem(
          pageIndex: 0,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: AppTranslations.t('nav_home', locale),
        ),
        _NavItem(
          pageIndex: 2,
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: AppTranslations.t('nav_orders', locale),
        ),
        const _NavItem(
          pageIndex: 4,
          icon: Icons.school_outlined,
          selectedIcon: Icons.school,
          label: 'Académie',
        ),
        _NavItem(
          pageIndex: 5,
          icon: Icons.miscellaneous_services_outlined,
          selectedIcon: Icons.miscellaneous_services,
          label: AppTranslations.t('nav_services', locale),
        ),
        _NavItem(
          pageIndex: 3,
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: AppTranslations.t('nav_profile', locale),
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final items = _items(locale);
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
          children: items.map((item) {
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
