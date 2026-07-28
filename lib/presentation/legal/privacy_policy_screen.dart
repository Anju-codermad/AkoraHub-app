import 'package:flutter/material.dart';

/// Politique de confidentialité — contenu statique, nécessaire pour la
/// publication sur le Google Play Store (l'app demande géolocalisation
/// et upload de photos, ce qui rend cette page obligatoire).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Politique de confidentialité')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dernière mise à jour : ${_lastUpdated}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _Paragraph(
              'AkoraHub respecte votre vie privée. Cette page explique quelles '
              'informations nous collectons, pourquoi, et comment elles sont '
              'protégées.',
            ),
            _Section(
              theme,
              title: '1. Données que nous collectons',
              body:
                  '• Informations de compte : nom, prénom, société, secteur '
                  '(hôtel/hôpital/entreprise/particulier), email, téléphone, '
                  'date de naissance (pour vérifier l\'âge minimum requis pour '
                  'l\'achat de certains produits).\n'
                  '• Localisation : adresse et, si vous l\'autorisez, votre '
                  'position GPS précise — utilisée uniquement pour calculer '
                  'les frais de livraison et faciliter la livraison de vos '
                  'commandes.\n'
                  '• Photos : avatar de profil et photos jointes à vos '
                  'publications sur le Mur communautaire, si vous choisissez '
                  'd\'en ajouter.\n'
                  '• Historique d\'activité : commandes, devis, favoris, avis '
                  'produits, messages échangés avec notre équipe.\n'
                  '• Identifiant de notification (token) : pour vous envoyer '
                  'des notifications liées à vos commandes ou messages, si '
                  'vous les avez autorisées.',
            ),
            _Section(
              theme,
              title: '2. Pourquoi nous les utilisons',
              body:
                  'Ces données servent uniquement à faire fonctionner le '
                  'service : créer votre compte, traiter vos commandes et '
                  'devis, calculer une livraison, vous contacter au sujet '
                  'd\'une commande, et afficher votre activité sur le Mur si '
                  'vous y publiez. Nous ne vendons jamais vos données à des '
                  'tiers.',
            ),
            _Section(
              theme,
              title: '3. Où sont stockées vos données',
              body:
                  'Vos données sont hébergées chez Supabase (infrastructure '
                  'basée dans l\'Union européenne), avec un accès protégé par '
                  'authentification et des règles de sécurité qui limitent '
                  'chaque client à ses propres données. Seule notre équipe '
                  '(Admin/Commercial) peut consulter les informations '
                  'nécessaires au traitement de vos commandes.',
            ),
            _Section(
              theme,
              title: '4. Vos publications sur le Mur',
              body:
                  'Les publications, commentaires et avis que vous publiez sur '
                  'le Mur communautaire sont visibles par les autres '
                  'utilisateurs de l\'app (nom, société, avatar). Vos '
                  'messages privés avec notre équipe restent, eux, '
                  'strictement confidentiels et ne sont jamais visibles par '
                  'les autres clients.',
            ),
            _Section(
              theme,
              title: '5. Vos droits',
              body:
                  'Vous pouvez à tout moment modifier vos informations depuis '
                  'votre profil, ou demander la suppression de votre compte '
                  'et de vos données personnelles (bouton "Supprimer mon '
                  'compte" dans Profil, ou en nous contactant directement).',
            ),
            _Section(
              theme,
              title: '6. Nous contacter',
              body:
                  'Pour toute question sur cette politique ou sur vos '
                  'données, contactez-nous via la messagerie intégrée à '
                  'l\'application.',
            ),
          ],
        ),
      ),
    );
  }
}

String get _lastUpdated => '28/07/2026';

class _Section extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String body;

  const _Section(this.theme, {required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }
}
