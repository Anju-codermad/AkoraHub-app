import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../../core/localization/app_translations.dart';
import '../../../core/providers/theme_provider.dart';
import '../notification_sounds_screen.dart';
import 'help_support_screen.dart';
import 'security_settings_screen.dart';

/// Écran "Paramètres" dédié, regroupant les réglages auparavant éparpillés
/// dans le menu du Profil (Langue, Mode sombre, Sons de notification) —
/// inspiré de l'écran Paramètres de Telegram (référence fournie par
/// l'utilisateur, 30/07). Utilisé à l'identique côté Client
/// (`profile_tab.dart`) et Admin (`business_profile_settings.dart`) :
/// ces réglages sont personnels à l'utilisateur connecté, pas liés à son
/// rôle.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('Sons par type de notification'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationSoundsScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Langue / Fiteny'),
                  trailing: Text(
                    locale == 'fr' ? 'Français' : 'Malagasy',
                    style: theme.textTheme.bodyMedium,
                  ),
                  onTap: () async {
                    final selected = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Choisir la langue'),
                        children: [
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, 'fr'),
                            child: const Row(
                                children: [Text('🇫🇷 '), Text('Français')]),
                          ),
                          SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, 'mg'),
                            child: const Row(
                                children: [Text('🇲🇬 '), Text('Malagasy')]),
                          ),
                        ],
                      ),
                    );
                    if (selected != null) {
                      ref.read(localeProvider.notifier).setLocale(selected);
                    }
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Mode sombre'),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text('Confidentialité et sécurité'),
              subtitle: const Text('Mot de passe, suppression du compte'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SecuritySettingsScreen()),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Aide et support'),
              subtitle: const Text('FAQ, contacter l\'équipe, à propos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
