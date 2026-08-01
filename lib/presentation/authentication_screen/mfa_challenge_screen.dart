import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/supabase/supabase_config.dart';

/// Étape de vérification du second facteur (TOTP) après une connexion
/// email/mot de passe ou Google/Facebook réussie — ne s'affiche que si le
/// compte a activé la double authentification (voir
/// `client_home/settings/two_factor_setup_screen.dart`). Annuler ou
/// revenir en arrière déconnecte le compte : la connexion n'est
/// considérée complète qu'une fois le second facteur vérifié, on ne
/// laisse jamais l'app dans un état intermédiaire.
class MfaChallengeScreen extends StatefulWidget {
  final String factorId;
  const MfaChallengeScreen({super.key, required this.factorId});

  @override
  State<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends State<MfaChallengeScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    await SupabaseConfig.client.auth.signOut();
    if (mounted) Navigator.pop(context, false);
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() =>
          _error = 'Entrez les 6 chiffres affichés dans votre application.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      await SupabaseConfig.client.auth.mfa.challengeAndVerify(
        factorId: widget.factorId,
        code: code,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _error = 'Code incorrect. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vérification en deux étapes'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isVerifying ? null : _cancel,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(4.w),
            children: [
              SizedBox(height: 2.h),
              Icon(Icons.phonelink_lock,
                  size: 56, color: theme.colorScheme.primary),
              SizedBox(height: 2.h),
              Text(
                'Ouvrez votre application d\'authentification et entrez le '
                'code à 6 chiffres généré pour ce compte.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 3.h),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  border: const OutlineInputBorder(),
                  errorText: _error,
                ),
                onSubmitted: (_) => _verify(),
              ),
              SizedBox(height: 2.h),
              FilledButton(
                onPressed: _isVerifying ? null : _verify,
                child: _isVerifying
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Vérifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
