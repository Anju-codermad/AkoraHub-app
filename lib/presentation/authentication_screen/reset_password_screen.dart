import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/auth_helpers.dart';
import '../../core/supabase/supabase_config.dart';
import './widgets/password_input_widget.dart';

/// Écran affiché après ouverture du lien "Mot de passe oublié" reçu par
/// email — à ce stade, Supabase a déjà établi une session temporaire pour
/// l'utilisateur via le lien de récupération (voir `GlobalAuthListener`,
/// qui pousse cet écran sur `AuthChangeEvent.passwordRecovery`), il ne
/// reste qu'à définir le nouveau mot de passe.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _passwordError;
  String? _confirmError;
  bool _isLoading = false;

  static const _translations = {
    'password_label': 'Nouveau mot de passe',
    'password_hint': '••••••••',
  };
  static const _confirmTranslations = {
    'password_label': 'Confirmez le mot de passe',
    'password_hint': '••••••••',
  };

  Future<void> _submit() async {
    setState(() {
      _passwordError = _passwordController.text.length < 8
          ? 'Le mot de passe doit contenir au moins 8 caractères'
          : null;
      _confirmError = _confirmController.text != _passwordController.text
          ? 'Les mots de passe ne correspondent pas'
          : null;
    });
    if (_passwordError != null || _confirmError != null) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour avec succès.')),
      );
      final route = await AuthRouting.homeRouteForCurrentUser();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Impossible de mettre à jour le mot de passe. Le lien a peut-être expiré, refaites une demande.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mot de passe')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choisissez un nouveau mot de passe pour votre compte.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 3.h),
              PasswordInputWidget(
                controller: _passwordController,
                errorText: _passwordError,
                onChanged: (_) {},
                translations: _translations,
              ),
              SizedBox(height: 2.h),
              PasswordInputWidget(
                controller: _confirmController,
                errorText: _confirmError,
                onChanged: (_) {},
                translations: _confirmTranslations,
              ),
              SizedBox(height: 3.h),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Valider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
