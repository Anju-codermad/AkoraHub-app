import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/global_auth_listener.dart';
import '../supabase/supabase_config.dart';

/// Vérifie au démarrage si une version plus récente de l'app existe, et
/// propose de la mettre à jour — identique côté client et admin (même
/// code d'app, juste des rôles différents).
///
/// La ligne `app_latest_version` (id=1) est alimentée par la CI à
/// chaque build réussi — voir `.github/workflows/build-apk.yml` et
/// `supabase/functions/update-latest-version`.
///
/// Deux cas depuis la publication sur le Play Store (17/11, demande
/// explicite) :
/// - app installée DEPUIS LE PLAY STORE (`installerStore` =
///   `com.android.vending`) : "Mettre à jour" ouvre la fiche AkoraHub du
///   Play Store (bouton avec le logo Google Play). Règle Google Play : une
///   app distribuée par le Play Store ne doit pas se mettre à jour par un
///   autre moyen (téléchargement d'APK) — c'était le cas avant ce
///   changement.
/// - app installée À PARTIR DE L'APK (lien direct du site) : comportement
///   d'origine, téléchargement de l'APK (`download_url`). Le Play Store ne
///   peut pas mettre à jour une app installée par APK (signature
///   différente avec la signature d'application Google Play).
class UpdateChecker {
  UpdateChecker._();

  static const _playStorePackageName = 'com.android.vending';

  /// Logo officiel Google Play (triangle multicolore), même tracé que sur
  /// groupe-akora.com — en SVG pour rester net sans fichier image.
  static const _googlePlayLogoSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 283">'
      '<path fill="#EA4335" d="M119.553 134.916L1.06 259.061a32.14 32.14 0 0 0 47.062 19.071l133.327-75.934z"/>'
      '<path fill="#FBBC04" d="M239.37 113.814L181.715 80.79l-64.898 56.95l65.162 64.28l57.216-32.67a31.345 31.345 0 0 0 0-55.537z"/>'
      '<path fill="#4285F4" d="M1.06 23.487A30.6 30.6 0 0 0 0 31.61v219.327a32.3 32.3 0 0 0 1.06 8.124l122.555-120.966z"/>'
      '<path fill="#34A853" d="m120.436 141.274l61.278-60.483L48.564 4.503A32.85 32.85 0 0 0 32.051 0C17.644-.028 4.978 9.534 1.06 23.399z"/>'
      '</svg>';

  static Future<void> checkAndPrompt() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;
      final fromPlayStore = info.installerStore == _playStorePackageName;

      final row = await SupabaseConfig.client
          .from('app_latest_version')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return;

      final latestBuild = (row['build_number'] as num?)?.toInt() ?? 0;
      final downloadUrl = (row['download_url'] as String?) ?? '';
      if (latestBuild <= currentBuild) return;
      if (!fromPlayStore && downloadUrl.isEmpty) return;

      final versionName = (row['version_name'] as String?) ?? '';

      // Le navigator peut ne pas encore être monté juste après le
      // lancement de l'app — on attend qu'un contexte soit disponible
      // plutôt que d'utiliser un délai fixe arbitraire.
      BuildContext? context;
      for (var i = 0; i < 20 && context == null; i++) {
        context = GlobalAuthListener.navigatorKey.currentContext;
        if (context == null) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      if (context == null || !context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mise à jour disponible'),
          content: Text(versionName.isEmpty
              ? 'Une nouvelle version d\'AkoraHub est disponible.'
              : 'Une nouvelle version d\'AkoraHub ($versionName) est disponible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Plus tard'),
            ),
            if (fromPlayStore)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openPlayStore(info.packageName);
                },
                icon: SvgPicture.string(
                  _googlePlayLogoSvg,
                  width: 18,
                  height: 20,
                ),
                label: const Text('Mettre à jour sur Google Play'),
              )
            else
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse(downloadUrl),
                      mode: LaunchMode.externalApplication);
                },
                child: const Text('Mettre à jour'),
              ),
          ],
        ),
      );
    } catch (_) {
      // Échec silencieux — ne doit jamais bloquer le démarrage de l'app.
    }
  }

  /// Ouvre la fiche de l'app dans l'application Play Store ; repli sur la
  /// page web du Play Store si l'application n'est pas disponible.
  static Future<void> _openPlayStore(String packageName) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse('market://details?id=$packageName'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      await launchUrl(
        Uri.parse(
            'https://play.google.com/store/apps/details?id=$packageName'),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
