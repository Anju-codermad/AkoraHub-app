import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/global_auth_listener.dart';
import '../supabase/supabase_config.dart';

/// Vérifie au démarrage si une version plus récente de l'app existe, et
/// propose de la télécharger — identique côté client et admin (même
/// code d'app, juste des rôles différents). Nécessaire en attendant la
/// publication sur le Play Store : pas de mise à jour automatique
/// native tant qu'on distribue par GitHub Releases/Firebase App
/// Distribution (04/08).
///
/// La ligne `app_latest_version` (id=1) est alimentée par la CI à
/// chaque build réussi — voir `.github/workflows/build-apk.yml` et
/// `supabase/functions/update-latest-version`.
class UpdateChecker {
  UpdateChecker._();

  static Future<void> checkAndPrompt() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final row = await SupabaseConfig.client
          .from('app_latest_version')
          .select()
          .eq('id', 1)
          .maybeSingle();
      if (row == null) return;

      final latestBuild = (row['build_number'] as num?)?.toInt() ?? 0;
      final downloadUrl = (row['download_url'] as String?) ?? '';
      if (latestBuild <= currentBuild || downloadUrl.isEmpty) return;

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
}
