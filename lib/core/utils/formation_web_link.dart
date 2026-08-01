import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Achat de l'accès Formation : depuis le 01/08, ce n'est plus un écran
/// intégré à l'app mais une page web ouverte dans le navigateur externe
/// (voir supabase/phase49_patch_formation_web_bucket.sql et
/// web/formation-access/index.html) — conformité Google Play, l'app ne
/// doit pas faire transiter un paiement hors Play Billing pour débloquer
/// du contenu numérique consommé dans l'app. Le backend (validation par
/// le staff, déblocage) est inchangé.
/// Nom de fichier `app.html` (et non `index.html`) : le premier upload
/// avait été mis en cache par Cloudflare (CDN devant Supabase Storage)
/// avec un mauvais `Content-Type` (text/plain), et ce cache ignore les
/// paramètres de requête (`?v=...`) — reprendre une adresse jamais
/// servie était le seul moyen fiable d'obtenir une version fraîche.
const String formationPurchaseWebUrl =
    'https://lmnprtwelmmoiuygvgmf.supabase.co/storage/v1/object/public/formation-web/app.html';

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
