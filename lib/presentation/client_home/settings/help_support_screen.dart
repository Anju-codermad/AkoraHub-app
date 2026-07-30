import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../chat_screen.dart';

/// Aide et support : contacter l'équipe (redirige vers la messagerie déjà
/// existante — pas de nouveau canal de support à construire), FAQ statique
/// avec des questions réelles sur le fonctionnement de l'app, À propos.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<(String, String)> _faq = [
    (
      'Comment suivre ma commande ?',
      'Ouvrez l\'onglet "Commandes" — chaque commande affiche son statut '
          '(Reçue, En préparation, Expédiée, Livrée). Une fois expédiée, '
          'un bouton "Suivre sur la carte" apparaît pour voir la position '
          'du livreur.',
    ),
    (
      'Comment demander un devis pour une grosse quantité ?',
      'Ajoutez vos produits au panier, puis choisissez "Demander un '
          'devis" au lieu de "Commander". Notre équipe vous répond avec un '
          'montant proposé, visible dans l\'onglet "Devis" — vous pouvez '
          'accepter, refuser, ou reproposer un autre montant.',
    ),
    (
      'Comment fonctionne la fidélité ?',
      'Vous gagnez automatiquement 1 point par tranche de 1000 Ar '
          'dépensée, dès qu\'une commande est marquée "Livrée". Les '
          'paliers Argent et Or donnent droit à une remise sur les frais '
          'de livraison. Voir "Fidélité" dans votre Profil.',
    ),
    (
      'Comment payer ma commande ?',
      'Le paiement en ligne dans l\'app n\'est pas encore disponible — '
          'les commandes sont réglées à la livraison ou selon les '
          'modalités convenues avec notre équipe.',
    ),
    (
      'Comment contacter l\'équipe directement ?',
      'Utilisez "Contacter le support" ci-dessus, ou l\'icône 💬 dans '
          'l\'en-tête de l\'Accueil. Vous pouvez aussi envoyer une '
          '"Demande" (ex: besoin d\'un produit en gros volume), visible '
          'uniquement par notre équipe.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Aide et support')),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Contacter le support'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatScreen())),
            ),
          ),
          SizedBox(height: 2.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Questions fréquentes', style: theme.textTheme.labelLarge),
          ),
          SizedBox(height: 1.h),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (question, answer) in _faq) ...[
                  ExpansionTile(
                    title: Text(question, style: theme.textTheme.bodyLarge),
                    childrenPadding:
                        EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
                    expandedAlignment: Alignment.topLeft,
                    children: [
                      Text(answer, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  if (question != _faq.last.$1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('À propos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'AkoraHub',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    '© ${DateTime.now().year} Akora Fanadiovana',
                children: const [
                  SizedBox(height: 12),
                  Text(
                    'Application de gestion et vente pour Akora '
                    'Fanadiovana — produits d\'entretien, hygiène et '
                    'agro-industriels.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
