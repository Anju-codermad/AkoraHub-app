import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../../core/chat/chat_bubble_settings_repo.dart';
import '../../../core/chat/chat_bubble_style.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/supabase/supabase_config.dart';
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

  /// Même logique que more_menu_screen.dart (côté Admin) — indépendante
  /// d'un éventuel callback passé par l'écran appelant, pour que cet
  /// écran partagé (Profil client comme Admin, voir doc de la classe)
  /// reste autonome.
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (SupabaseConfig.isConfigured) {
      await SupabaseConfig.client.auth.signOut();
    }
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
          '/authentication-screen', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final bubbleStyle = ref.watch(chatBubbleStyleProvider);
    final email = SupabaseConfig.isConfigured
        ? SupabaseConfig.client.auth.currentUser?.email
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          const _PasswordAutofillHintBanner(),
          if (email != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Compte'),
                subtitle: Text(email),
              ),
            ),
            SizedBox(height: 2.h),
          ],
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
                  leading: const Icon(Icons.translate),
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
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Style des messages'),
                  trailing: Text(
                    bubbleStyle.label,
                    style: theme.textTheme.bodyMedium,
                  ),
                  onTap: () async {
                    final selected = await showDialog<ChatBubbleStyle>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Style des messages'),
                        children: ChatBubbleStyle.values.map((style) {
                          return SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, style),
                            child: Row(
                              children: [
                                if (style == bubbleStyle)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(Icons.check, size: 18),
                                  )
                                else
                                  const SizedBox(width: 26),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(style.label,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text(style.description,
                                          style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                    if (selected != null) {
                      ref
                          .read(chatBubbleStyleProvider.notifier)
                          .setStyle(selected);
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
                const Divider(height: 1),
                const _ChatBubbleVisibilityTile(),
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
          SizedBox(height: 2.h),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('Déconnexion',
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Réglage personnel (03/08, voir supabase/phase68_patch_chat_bubble_toggle.sql)
/// — masque la bulle de chat flottante juste pour l'utilisateur connecté,
/// indépendamment du réglage global admin (`business_profile_settings.dart`).
/// Widget à part (plutôt que dans `SettingsScreen`, un `ConsumerWidget`
/// sans état) pour porter son propre chargement/écriture.
class _ChatBubbleVisibilityTile extends StatefulWidget {
  const _ChatBubbleVisibilityTile();

  @override
  State<_ChatBubbleVisibilityTile> createState() =>
      _ChatBubbleVisibilityTileState();
}

class _ChatBubbleVisibilityTileState
    extends State<_ChatBubbleVisibilityTile> {
  bool _hidden = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hidden = await ChatBubbleSettingsRepo.isHiddenByClient();
    if (mounted) setState(() {
      _hidden = hidden;
      _isLoading = false;
    });
  }

  Future<void> _toggle(bool showBubble) async {
    final hidden = !showBubble;
    setState(() => _hidden = hidden);
    try {
      await ChatBubbleSettingsRepo.setHiddenByClient(hidden);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hidden = !hidden);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de modifier ce réglage.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.chat_bubble_outline),
      title: const Text('Bulle de chat flottante'),
      subtitle: const Text('Afficher le raccourci vers l\'assistance sur toutes les pages'),
      value: !_hidden,
      onChanged: _isLoading ? null : _toggle,
    );
  }
}

/// Rappel "enregistrez votre mot de passe" (12/08, demande explicite) —
/// le popup système Android/iOS n'est jamais reprogrammable par l'app une
/// fois refusé (décision volontaire de Google/Apple), donc ce bandeau
/// interne guide manuellement vers les réglages du téléphone à la place.
/// Réapparaît une fois par mois si fermé, indéfiniment tant que
/// l'utilisateur ne l'a jamais fermé.
class _PasswordAutofillHintBanner extends StatefulWidget {
  const _PasswordAutofillHintBanner();

  @override
  State<_PasswordAutofillHintBanner> createState() =>
      _PasswordAutofillHintBannerState();
}

class _PasswordAutofillHintBannerState
    extends State<_PasswordAutofillHintBanner> {
  static const _prefsKey = 'password_autofill_hint_dismissed_at';
  static const _cooldown = Duration(days: 30);
  bool _checked = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedAtMs = prefs.getInt(_prefsKey);
    final shouldShow = dismissedAtMs == null ||
        DateTime.now().difference(
                DateTime.fromMillisecondsSinceEpoch(dismissedAtMs)) >
            _cooldown;
    if (!mounted) return;
    setState(() {
      _visible = shouldShow;
      _checked = true;
    });
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, DateTime.now().millisecondsSinceEpoch);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || !_visible) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Card(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, color: theme.colorScheme.primary),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connexion plus rapide',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Activez l\'enregistrement automatique du mot de '
                      'passe dans les paramètres de votre téléphone '
                      '(Google → Mots de passe et comptes) pour vous '
                      'connecter en un geste la prochaine fois.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Fermer',
                onPressed: _dismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
