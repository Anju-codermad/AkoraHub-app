import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Achat de l'accès Formation : depuis le 01/08, ce n'est plus un écran
/// intégré à l'app mais une page web ouverte dans le navigateur externe
/// (source dans docs/formation-access/formation.html, mais hébergée
/// séparément — voir ci-dessous) — conformité Google Play, l'app ne
/// doit pas faire transiter un paiement hors Play Billing pour débloquer
/// du contenu numérique consommé dans l'app. Le backend (validation par
/// le staff, déblocage) est inchangé.
///
/// Hébergée sur Cloudflare Pages (site "Akora Fanadiovana", 25/08),
/// pas Supabase Storage ni GitHub Pages :
/// - Supabase Storage force le `Content-Type` des fichiers `.html` de
///   ses buckets publics à `text/plain` (protection anti-phishing
///   côté serveur, incontournable) — la page ne s'exécutait jamais
///   comme une vraie page web.
/// - GitHub Pages n'est disponible gratuitement que pour les dépôts
///   publics ; celui-ci doit rester privé (coordonnées bancaires dans
///   payment_methods.dart).
/// Cloudflare Pages est branché directement sur ce dépôt GitHub
/// (Compute -> Workers & Pages -> akorahub) : toute mise à jour de
/// docs/formation-access/ se redéploie automatiquement à chaque push
/// sur main, sans étape manuelle (remplace Netlify, qui a fini par
/// bloquer tous les déploiements pour dépassement de quota le 24/08).
const String formationPurchaseWebUrl =
    'https://groupe-akora.com/formation.html';

Future<void> openFormationPurchaseWeb(BuildContext context) async {
  try {
    await launchUrl(
      Uri.parse(formationPurchaseWebUrl),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Impossible d\'ouvrir la page d\'achat.')));
  }
}
