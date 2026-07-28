import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

/// Écran "À propos" — identité de l'app, version, et accès aux pages
/// légales. Accessible depuis le menu Profil (client) et le menu Plus
/// (Admin), pour donner à l'app une vitrine plus professionnelle que de
/// simples boutons épars.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: CustomImageWidget(
                    imageUrl: 'assets/images/img_app_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AkoraHub',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version $appVersion',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AkoraHub est la plateforme de commande et d\'échange d\'Akora '
            'Fanadiovana (produits d\'entretien, hygiène et agro-industriels, '
            'ainsi qu\'ARCA PAINTS et AkoraFormation). Consultez le '
            'catalogue, commandez ou demandez un devis, suivez vos '
            'livraisons et échangez avec notre équipe et la communauté.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Politique de confidentialité'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Conditions d\'utilisation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TermsOfServiceScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Nous contacter'),
                  subtitle:
                      const Text('Via la messagerie intégrée de l\'app'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© ${DateTime.now().year} Akora Fanadiovana',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
