import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import 'two_factor_setup_screen.dart';

/// Confidentialité et sécurité : changer le mot de passe, activer la
/// double authentification, supprimer le compte. "Supprimer mon compte"
/// existait déjà dans le menu du Profil (Phase 30/07, `delete-account`
/// Edge Function) — déplacé ici, logique inchangée, pour regrouper les
/// réglages liés à la sécurité au même endroit (voir settings_screen.dart).
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isDeleting = false;
  bool _isLoadingPrivacy = true;
  bool _sharePhonePublicly = false;
  String? _myPhone;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  /// Numéro visible dans la Communauté (01/08, demande explicite) —
  /// désactivé par défaut : le numéro n'est jamais montré à d'autres
  /// clients tant que la personne n'a pas elle-même activé ce réglage
  /// (voir supabase/phase47_patch_report_and_whatsapp_contact.sql).
  Future<void> _loadPrivacySettings() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoadingPrivacy = false);
      return;
    }
    try {
      final row = await SupabaseConfig.client
          .from('profiles')
          .select('phone, share_phone_publicly')
          .eq('id', userId)
          .single();
      if (!mounted) return;
      setState(() {
        _myPhone = row['phone'] as String?;
        _sharePhonePublicly = row['share_phone_publicly'] as bool? ?? false;
        _isLoadingPrivacy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPrivacy = false);
    }
  }

  Future<void> _setSharePhonePublicly(bool value) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() => _sharePhonePublicly = value);
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'share_phone_publicly': value}).eq('id', userId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sharePhonePublicly = !value);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossible de mettre à jour ce réglage.')));
    }
  }

  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Changer le mot de passe'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Nouveau mot de passe'),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Minimum 6 caractères'
                      : null,
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirmer le mot de passe'),
                  validator: (v) => v != newPasswordController.text
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  isSaving ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => isSaving = true);
                      try {
                        await SupabaseConfig.client.auth.updateUser(
                          UserAttributes(
                              password: newPasswordController.text),
                        );
                        // Journalisation (revue de sécurité Admin) — voir
                        // supabase/phase34_patch_security_audit_log.sql.
                        // Best-effort : n'empêche jamais le changement de
                        // mot de passe lui-même si l'appel échoue.
                        try {
                          await SupabaseConfig.client.rpc(
                              'log_security_event',
                              params: {'p_event_type': 'password_changed'});
                        } catch (_) {}
                        if (context.mounted) Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Mot de passe mis à jour avec succès.')),
                          );
                        }
                      } catch (_) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Impossible de changer le mot de passe. Réessayez.')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte'),
        content: const Text(
          'Cette action est définitive et irréversible. Toutes vos '
          'données seront supprimées : profil, commandes, devis, '
          'favoris, messages et publications. Voulez-vous vraiment '
          'continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final response =
          await SupabaseConfig.client.functions.invoke('delete-account');
      if (response.status != 200) {
        throw Exception(
            (response.data is Map ? response.data['error'] : null) ??
                'Échec de la suppression');
      }
      await SupabaseConfig.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/authentication-screen',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Impossible de supprimer le compte pour le moment. Réessayez plus tard.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité et sécurité')),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Changer le mot de passe'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
          ),
          SizedBox(height: 2.h),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phonelink_lock_outlined),
              title: const Text('Double authentification'),
              subtitle: const Text('Code de vérification à chaque connexion'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TwoFactorSetupScreen()),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.chat_outlined),
              title: const Text('Numéro visible dans la Communauté'),
              subtitle: Text(_isLoadingPrivacy
                  ? 'Chargement...'
                  : (_myPhone == null || _myPhone!.trim().isEmpty)
                      ? 'Ajoutez d\'abord un numéro dans votre profil pour activer ceci'
                      : 'Permet aux autres clients de vous contacter via WhatsApp ($_myPhone)'),
              value: _sharePhonePublicly,
              onChanged: (_isLoadingPrivacy ||
                      _myPhone == null ||
                      _myPhone!.trim().isEmpty)
                  ? null
                  : _setSharePhonePublicly,
            ),
          ),
          SizedBox(height: 2.h),
          Card(
            child: ListTile(
              leading: _isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Supprimer mon compte',
                  style: TextStyle(color: Colors.red)),
              onTap: _isDeleting ? null : _confirmDeleteAccount,
            ),
          ),
        ],
      ),
    );
  }
}
