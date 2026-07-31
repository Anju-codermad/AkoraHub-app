import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../business_profile_settings/business_profile_settings.dart';
import '../business_units_management/business_units_management.dart';
import '../staff_management/staff_management.dart';
import '../invoicing/invoicing_screen.dart';
import '../alerts_center/alerts_center.dart';
import '../flash_infos_management/flash_infos_management.dart';
import '../home_banners_management/home_banners_management.dart';
import '../notification_sounds_catalog_admin/notification_sounds_catalog_admin_screen.dart';
import '../payment_methods_management/payment_methods_management.dart';
import '../quotes_management/quotes_management.dart';
import '../order_management_real/order_management_real.dart';
import '../messaging_center_real/messaging_center_real.dart';
import '../security_audit_log/security_audit_log_screen.dart';

/// Menu "Plus" de l'Admin — remplace l'ancien comportement où l'onglet
/// "More" de la barre de navigation menait directement au Profil
/// entreprise, ce qui laissait Facturation/Alertes/Piliers/Équipe/
/// Bannières/Devis accessibles uniquement depuis le bouton "+" de
/// création rapide (sémantiquement bizarre : gérer les piliers ou
/// consulter les alertes n'est pas "créer quelque chose de nouveau").
/// Ce menu les regroupe dans un vrai écran de navigation, organisé par
/// section.
class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Gestion'),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            label: 'Commandes',
            subtitle: 'Suivre et gérer toutes les commandes',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const OrderManagementReal()),
            ),
          ),
          _MenuTile(
            icon: Icons.request_quote_outlined,
            label: 'Devis',
            subtitle: 'Devis clients en attente ou traités',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuotesManagement()),
            ),
          ),
          _MenuTile(
            icon: Icons.receipt_outlined,
            label: 'Facturation',
            subtitle: 'Factures et paiements',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InvoicingScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.notifications_active_outlined,
            label: 'Alertes',
            subtitle: 'Stock bas, commandes en attente...',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsCenter()),
            ),
          ),
          _MenuTile(
            icon: Icons.chat_bubble_outline,
            label: 'Messagerie',
            subtitle: 'Conversations avec les clients',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MessagingCenterReal()),
            ),
          ),
          const Divider(height: 24),
          _SectionHeader('Entreprise'),
          _MenuTile(
            icon: Icons.business_outlined,
            label: 'Piliers d\'entreprise',
            subtitle: 'Créer, activer/désactiver un pilier et ses catégories',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BusinessUnitsManagement()),
            ),
          ),
          _MenuTile(
            icon: Icons.groups_outlined,
            label: 'Équipe & rôles',
            subtitle: 'Membres du staff et leurs permissions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffManagement()),
            ),
          ),
          _MenuTile(
            icon: Icons.add_photo_alternate_outlined,
            label: 'Bannière hero — Accueil',
            subtitle: 'Image mise en avant sur l\'accueil client',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const HomeBannersManagement()),
            ),
          ),
          _MenuTile(
            icon: Icons.campaign_outlined,
            label: 'Flash infos — Accueil',
            subtitle: 'Annonces courtes affichées sur l\'accueil client',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const FlashInfosManagement()),
            ),
          ),
          _MenuTile(
            icon: Icons.payments_outlined,
            label: 'Modes de paiement',
            subtitle: 'Activer/désactiver chaque mode de paiement au checkout',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PaymentMethodsManagement()),
            ),
          ),
          _MenuTile(
            icon: Icons.music_note_outlined,
            label: 'Sons de notification',
            subtitle: 'Réordonner/masquer les sons proposés à tous',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSoundsCatalogAdminScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.security_outlined,
            label: 'Journal de sécurité',
            subtitle: 'Connexions, changements de mot de passe et de rôle',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SecurityAuditLogScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.storefront_outlined,
            label: 'Profil entreprise',
            subtitle: 'Coordonnées, logo, réseaux sociaux, horaires',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BusinessProfileSettings()),
            ),
          ),
          const Divider(height: 24),
          _MenuTile(
            icon: Icons.logout,
            label: 'Déconnexion',
            iconColor: theme.colorScheme.error,
            labelColor: theme.colorScheme.error,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Déconnexion'),
                  content:
                      const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Déconnexion'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              if (SupabaseConfig.isConfigured) {
                await SupabaseConfig.client.auth.signOut();
              }
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/authentication-screen', (r) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.iconColor,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(
        label,
        style: labelColor != null ? TextStyle(color: labelColor) : null,
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: labelColor == null
          ? const Icon(Icons.chevron_right, size: 20)
          : null,
      onTap: onTap,
    );
  }
}
