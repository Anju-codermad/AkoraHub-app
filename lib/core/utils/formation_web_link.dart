import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Achat de l'accès Formation : depuis le 01/08, ce n'est plus un écran
/// intégré à l'app mais une page web ouverte dans le navigateur externe
/// (voir docs/formation-access/index.html) — conformité Google Play,
/// l'app ne doit pas faire transiter un paiement hors Play Billing pour
/// débloquer du contenu numérique consommé dans l'app. Le backend
/// (validation par le staff, déblocage) est inchangé.
///
/// Hébergée via GitHub Pages (dossier /docs), et non Supabase Storage :
/// Supabase Storage force le `Content-Type` des fichiers `.html` de ses
/// buckets publics à `text/plain` (protection anti-phishing côté
/// serveur, contournée ni par les métadonnées Postgres ni par un upload
/// avec `Content-Type` explicite) — la page ne s'exécutait donc jamais
/// comme une vraie page web. GitHub Pages sert nativement du HTML actif.
const String formationPurchaseWebUrl =
    'https://anju-codermad.github.io/AkoraHub-app/formation-access/';

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
