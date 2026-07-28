import 'package:flutter/material.dart';

/// Conditions générales d'utilisation — contenu statique, requis à
/// l'inscription (case à cocher) et nécessaire pour la fiche Play Store.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Conditions d\'utilisation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dernière mise à jour : 28/07/2026',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              'En créant un compte AkoraHub, vous acceptez les conditions '
              'suivantes.',
              style: theme.textTheme.bodyMedium,
            ),
            _Section(
              theme,
              title: '1. Objet',
              body:
                  'AkoraHub est la plateforme de commande et d\'échange '
                  'd\'Akora Fanadiovana, permettant de consulter le '
                  'catalogue, passer commande ou demander un devis, suivre '
                  'ses commandes, et échanger avec la communauté et notre '
                  'équipe commerciale.',
            ),
            _Section(
              theme,
              title: '2. Âge minimum',
              body:
                  'La création d\'un compte est réservée aux personnes '
                  'majeures (18 ans et plus), certains produits vendus sur la '
                  'plateforme (produits chimiques, insecticides) n\'étant pas '
                  'adaptés à un usage par des mineurs.',
            ),
            _Section(
              theme,
              title: '3. Commandes et devis',
              body:
                  'Passer une commande ou demander un devis constitue une '
                  'intention d\'achat, pas un engagement de paiement '
                  'immédiat. Le mode de paiement (espèces, Mobile Money, ou '
                  'facturation) est convenu avec notre équipe au moment de la '
                  'commande. Les prix affichés peuvent varier selon le '
                  'volume commandé (tarifs Gros/Détail).',
            ),
            _Section(
              theme,
              title: '4. Livraison',
              body:
                  'Les frais de livraison affichés dans le panier sont une '
                  'estimation basée sur la distance entre votre position et '
                  'notre dépôt. Le délai de livraison réel dépend de la '
                  'zone et de la disponibilité des produits commandés.',
            ),
            _Section(
              theme,
              title: '5. Contenu publié (Mur communautaire)',
              body:
                  'Vous êtes responsable du contenu (texte, photos, avis) que '
                  'vous publiez sur le Mur. Tout contenu injurieux, '
                  'diffamatoire ou frauduleux pourra être retiré, et le '
                  'compte concerné suspendu.',
            ),
            _Section(
              theme,
              title: '6. Compte et sécurité',
              body:
                  'Vous êtes responsable de la confidentialité de votre mot '
                  'de passe. En cas d\'usage suspect de votre compte, '
                  'contactez-nous immédiatement via la messagerie intégrée.',
            ),
            _Section(
              theme,
              title: '7. Modification des conditions',
              body:
                  'Ces conditions peuvent évoluer ; toute modification '
                  'importante vous sera signalée dans l\'application.',
            ),
          ],
        ),
      ),
    );
  }
}

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
