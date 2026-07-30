import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

/// Confidentialité et sécurité : changer le mot de passe, supprimer le
/// compte. "Supprimer mon compte" existait déjà dans le menu du Profil
/// (Phase 30/07, `delete-account` Edge Function) — déplacé ici, logique
/// inchangée, pour regrouper les réglages liés à la sécurité au même
/// endroit (voir settings_screen.dart).
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() =>
      _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isDeleting = false;

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
