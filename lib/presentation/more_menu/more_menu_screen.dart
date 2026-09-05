import 'package:flutter/material.dart';

import '../../core/supabase/supabase_config.dart';
import '../client_home/client_home.dart';
import '../business_profile_settings/business_profile_settings.dart';
import '../business_units_management/business_units_management.dart';
import '../staff_management/staff_management.dart';
import '../invoicing/invoicing_screen.dart';
import '../alerts_center/alerts_center.dart';
import '../delivery_management/delivery_management.dart';
import '../flash_infos_management/flash_infos_management.dart';
import '../home_banners_management/home_banners_management.dart';
import '../notification_sounds_catalog_admin/notification_sounds_catalog_admin_screen.dart';
import '../payment_methods_management/payment_methods_management.dart';
import '../mobile_money_reconciliation/mobile_money_reconciliation_screen.dart';
import '../quotes_management/quotes_management.dart';
import '../order_management_real/order_management_real.dart';
import '../messaging_center_real/messaging_center_real.dart';
import '../security_audit_log/security_audit_log_screen.dart';
import '../raw_materials_management/formation_hub.dart';
import '../formation_groups_management/formation_groups_management.dart';
import '../client_home/settings/settings_screen.dart';
import '../post_reports_management/post_reports_management.dart';
import '../post_approval_management/post_approval_management.dart';
import '../service_catalog_management/service_catalog_management.dart';
import '../service_requests_management/service_requests_management.dart';
import '../customer_analytics/customer_analytics_dashboard.dart';
import '../website_leads_management/website_leads_management.dart';

/// Menu "Plus" de l'Admin — remplace l'ancien comportement où l'onglet
/// "More" de la barre de navigation menait directement au Profil
/// entreprise, ce qui laissait Facturation/Alertes/Piliers/Équipe/
/// Bannières/Devis accessibles uniquement depuis le bouton "+" de
/// création rapide (sémantiquement bizarre : gérer les piliers ou
/// consulter les alertes n'est pas "créer quelque chose de nouveau").
/// Ce menu les regroupe dans un vrai écran de navigation, organisé par
/// section.
///
/// Rôles Services/Livraison (Phase 166/167, 12/08) : ces deux rôles n'ont
/// volontairement accès qu'à leur propre tâche (voir RLS) — leur afficher
/// le menu complet ci-dessous n'aurait aucun sens (la plupart des écrans
/// leur renverraient des listes vides ou des erreurs). On affiche donc un
/// menu réduit selon le rôle du compte connecté, sans toucher au
/// comportement existant pour les 4 autres rôles staff.
class MoreMenuScreen extends StatefulWidget {
  const MoreMenuScreen({super.key});

  @override
  State<MoreMenuScreen> createState() => _MoreMenuScreenState();
}

class _MoreMenuScreenState extends State<MoreMenuScreen> {
  bool _loading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null || !SupabaseConfig.isConfigured) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final profile = await SupabaseConfig.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      if (!mounted) return;
      setState(() {
        _role = profile['role'] as String?;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_role == 'livraison') {
      return _RestrictedMoreMenu(
        tile: _MenuTile(
          icon: Icons.local_shipping_outlined,
          label: 'Livraisons',
          subtitle: 'Commandes à livrer, statut, position GPS',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DeliveryManagement()),
          ),
        ),
      );
    }
    if (_role == 'services') {
      return _RestrictedMoreMenu(
        tile: _MenuTile(
          icon: Icons.miscellaneous_services_outlined,
          label: 'Demandes de service',
          subtitle: 'Installations, interventions, consultations demandées',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ServiceRequestsManagement()),
          ),
        ),
      );
    }
    return _FullMoreMenu(isAdmin: _role == 'admin');
  }
}

/// Menu réduit : uniquement la tâche du rôle + Paramètres + Déconnexion.
class _RestrictedMoreMenu extends StatelessWidget {
  final Widget tile;
  const _RestrictedMoreMenu({required this.tile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          tile,
          const Divider(height: 24),
          _MenuTile(
            icon: Icons.settings_outlined,
            label: 'Paramètres',
            subtitle: 'Notifications, langue, mode sombre, sécurité, aide',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const Divider(height: 24),
          _SignOutTile(theme: theme),
        ],
      ),
    );
  }
}

class _FullMoreMenu extends StatelessWidget {
  final bool isAdmin;
  const _FullMoreMenu({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Aperçu côté client (26/08, demande explicite) : réservé au
          // rôle admin — permet de vérifier rapidement ce qui vient
          // d'être publié sans se déconnecter/reconnecter avec un autre
          // compte. Reste connecté avec la même session (pas un vrai
          // changement de compte), voir _ClientPreviewWrapper.
          if (isAdmin) ...[
            _MenuTile(
              icon: Icons.visibility_outlined,
              label: 'Aperçu côté client',
              subtitle: 'Voir l\'app comme un client, sans changer de compte',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _ClientPreviewWrapper()),
              ),
            ),
            const Divider(height: 24),
          ],
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
            icon: Icons.miscellaneous_services_outlined,
            label: 'Demandes de service',
            subtitle: 'Installations, interventions, consultations demandées',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ServiceRequestsManagement()),
            ),
          ),
          _MenuTile(
            icon: Icons.contact_page_outlined,
            label: 'Demandes du site web',
            subtitle: 'Devis et diagnostics eau demandés depuis le site',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const WebsiteLeadsManagement()),
            ),
          ),
          _MenuTile(
            icon: Icons.list_alt_outlined,
            label: 'Catalogue de services',
            subtitle: 'Activer/désactiver les services proposés aux clients',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ServiceCatalogManagement()),
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
          _MenuTile(
            icon: Icons.insights_outlined,
            label: 'Tableau de bord CRM',
            subtitle: 'Clients actifs, rétention, top clients, à relancer',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CustomerAnalyticsDashboard()),
            ),
          ),
          _MenuTile(
            icon: Icons.science_outlined,
            label: 'Formation',
            subtitle:
                'Matières (+ Académie), cours & modules, validation des achats',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FormationHub()),
            ),
          ),
          _MenuTile(
            icon: Icons.flag_outlined,
            label: 'Signalements Communauté',
            subtitle: 'Publications signalées par les clients',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PostReportsManagement()),
            ),
          ),
          _MenuTile(
            icon: Icons.rate_review_outlined,
            label: 'Publications à valider',
            subtitle: 'Nouvelles publications en attente d\'approbation',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PostApprovalManagement()),
            ),
          ),
          _MenuTile(
            icon: Icons.groups_outlined,
            label: 'Groupes Formation',
            subtitle: 'Fils par catégorie, modération (accès staff)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const FormationGroupsManagement()),
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
            icon: Icons.sms_outlined,
            label: 'Paiements Mobile Money à rapprocher',
            subtitle: 'Confirmations SMS que l\'automatisation n\'a pas '
                'su lier seule à une commande',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MobileMoneyReconciliationScreen()),
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
          _MenuTile(
            icon: Icons.settings_outlined,
            label: 'Paramètres',
            subtitle: 'Notifications, langue, mode sombre, sécurité, aide',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const Divider(height: 24),
          _SignOutTile(theme: theme),
        ],
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  final ThemeData theme;
  const _SignOutTile({required this.theme});

  @override
  Widget build(BuildContext context) {
    return _MenuTile(
      icon: Icons.logout,
      label: 'Déconnexion',
      iconColor: theme.colorScheme.error,
      labelColor: theme.colorScheme.error,
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Voulez-vous vraiment vous déconnecter ?'),
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
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/authentication-screen', (r) => false);
        }
      },
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

/// Affiche `ClientHome` telle quelle (même session admin, pas de vrai
/// changement de compte) avec un sélecteur de vue flottant en permanence
/// par-dessus — nécessaire car l'onglet Accueil de `ClientHome` n'a pas
/// d'AppBar/flèche retour (voir client_home.dart), donc rien n'indiquerait
/// autrement comment revenir à l'Admin.
///
/// Le sélecteur (28/08, demande explicite) reprend l'esprit du menu de
/// bascule entre profils de Facebook : une pastille avec la vue courante,
/// qui ouvre une petite carte listant "Vue Client"/"Vue Admin" (icône +
/// libellé + sous-titre, vue active surlignée) plutôt qu'un simple bouton
/// "Retour".
class _ClientPreviewWrapper extends StatelessWidget {
  const _ClientPreviewWrapper();

  Future<void> _openSwitcher(BuildContext context, RenderBox button) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = button.localToGlobal(Offset(0, button.size.height + 6), ancestor: overlay);
    final topRight = button.localToGlobal(Offset(button.size.width, button.size.height + 6), ancestor: overlay);
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        topLeft.dy,
        overlay.size.width - topRight.dx,
        0,
      ),
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      constraints: const BoxConstraints(minWidth: 230),
      items: [
        PopupMenuItem<String>(
          value: 'client',
          padding: EdgeInsets.zero,
          child: _SwitcherRow(
            icon: Icons.storefront_outlined,
            iconBg: const Color(0xFF1478A4),
            label: 'Vue Client',
            subtitle: 'Vous êtes ici',
            selected: true,
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'admin',
          padding: EdgeInsets.zero,
          child: _SwitcherRow(
            icon: Icons.admin_panel_settings_outlined,
            iconBg: Colors.black87,
            label: 'Vue Admin',
            subtitle: 'Retourner à la gestion',
            selected: false,
          ),
        ),
      ],
    );
    if (selected == 'admin' && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ClientHome(),
        Positioned(
          top: 8,
          right: 12,
          child: SafeArea(
            child: Builder(
              builder: (buttonContext) => Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _openSwitcher(
                    context,
                    buttonContext.findRenderObject() as RenderBox,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6, right: 10, top: 6, bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: Color(0xFF1478A4),
                          child: Icon(Icons.storefront_outlined, size: 13, color: Colors.white),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Vue Client',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87),
                        ),
                        SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitcherRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String subtitle;
  final bool selected;

  const _SwitcherRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? const Color(0xFFF0F2F5) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: iconBg, child: Icon(icon, size: 16, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
