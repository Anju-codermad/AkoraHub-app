import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

/// Double authentification (TOTP) — application d'authentification type
/// Google Authenticator/Authy, choisie plutôt que SMS (vulnérable au
/// SIM-swap, nécessite un fournisseur payant) ou e-mail (dépend de la
/// sécurité de la boîte mail) : le code est généré localement sur
/// l'appareil, sans transiter par un réseau. Repose entièrement sur l'API
/// MFA native de Supabase Auth (`auth.mfa`), aucune infrastructure tierce
/// nécessaire. Utilisée à l'identique côté Client et Admin (réglage
/// personnel au compte connecté, pas lié au rôle — voir
/// `settings_screen.dart`).
class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  Factor? _verifiedFactor;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final factors = await SupabaseConfig.client.auth.mfa.listFactors();
      Factor? verified;
      for (final f in factors.totp) {
        if (f.status == FactorStatus.verified) {
          verified = f;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _verifiedFactor = verified;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enable() async {
    setState(() => _isProcessing = true);
    AuthMFAEnrollResponse enrollment;
    try {
      enrollment = await SupabaseConfig.client.auth.mfa
          .enroll(factorType: FactorType.totp, friendlyName: 'AkoraHub');
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Impossible de démarrer l\'activation. Réessayez.')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _isProcessing = false);

    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => _TotpEnrollScreen(enrollment: enrollment)),
    );

    if (confirmed != true) {
      // Nettoyage best-effort : un facteur créé mais jamais vérifié
      // resterait sinon orphelin côté Supabase (n'affecte pas la
      // sécurité, juste du ménage).
      try {
        await SupabaseConfig.client.auth.mfa.unenroll(enrollment.id);
      } catch (_) {}
      return;
    }

    try {
      await SupabaseConfig.client.rpc('log_security_event',
          params: {'p_event_type': 'mfa_enabled'});
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Double authentification activée avec succès.')),
    );
    _loadStatus();
  }

  Future<void> _disable() async {
    final factor = _verifiedFactor;
    if (factor == null) return;

    // Re-confirmation par mot de passe (10/08, audit de sécurité suite au
    // fix "sessions non révoquées après changement de mot de passe") :
    // désactiver le 2FA retire une couche de protection — sans ce
    // contrôle, quelqu'un ayant mis la main sur une session déjà ouverte
    // (téléphone déverrouillé, session copiée...) pourrait la retirer
    // sans jamais connaître le mot de passe du compte.
    final password = await _promptPasswordToDisable();
    if (password == null) return;

    setState(() => _isProcessing = true);
    try {
      // Passe par `hyper-endpoint` (25/08, audit de sécurité) plutôt que
      // signInWithPassword directement : un appel direct ici contournait
      // le blocage après 5 échecs en 15 minutes (voir
      // supabase/functions/hyper-endpoint/index.ts et
      // authentication_screen.dart, même flux) — quelqu'un avec une
      // session déjà ouverte aurait pu essayer le mot de passe sans
      // limite pour retirer le 2FA.
      final email = SupabaseConfig.client.auth.currentUser?.email;
      if (email == null) throw Exception('email introuvable');
      final response = await SupabaseConfig.client.functions.invoke(
        'hyper-endpoint',
        body: {'email': email, 'password': password},
      );
      final data = response.data as Map;
      if (data['ok'] != true) throw Exception('mot de passe incorrect');
      await SupabaseConfig.client.auth
          .setSession(data['refresh_token'] as String);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe incorrect.')),
      );
      return;
    }

    try {
      await SupabaseConfig.client.auth.mfa.unenroll(factor.id);
      try {
        await SupabaseConfig.client.rpc('log_security_event',
            params: {'p_event_type': 'mfa_disabled'});
      } catch (_) {}
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Double authentification désactivée.')),
      );
      _loadStatus();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de désactiver. Réessayez.')),
      );
    }
  }

  /// Dialogue de confirmation par mot de passe avant de désactiver le
  /// 2FA — voir commentaire dans `_disable`. Retourne le mot de passe
  /// saisi (à vérifier par l'appelant), ou `null` si annulé.
  Future<String?> _promptPasswordToDisable() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver la double authentification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Votre compte sera protégé uniquement par votre mot de '
                'passe. Confirmez votre mot de passe pour continuer.'),
            SizedBox(height: 2.h),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              onSubmitted: (_) =>
                  Navigator.pop(context, controller.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = _verifiedFactor != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Double authentification')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(4.w),
              children: [
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color:
                        (enabled ? Colors.green : theme.colorScheme.primary)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        enabled ? Icons.verified_user : Icons.shield_outlined,
                        color:
                            enabled ? Colors.green : theme.colorScheme.primary,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          enabled
                              ? 'Activée — un code de votre application d\'authentification sera demandé à chaque connexion.'
                              : 'Désactivée — ajoutez une couche de sécurité supplémentaire avec une application d\'authentification (Google Authenticator, Authy...).',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),
                FilledButton.icon(
                  onPressed:
                      _isProcessing ? null : (enabled ? _disable : _enable),
                  style: enabled
                      ? FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error)
                      : null,
                  icon: _isProcessing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(enabled ? Icons.lock_open : Icons.lock_outline),
                  label: Text(enabled
                      ? 'Désactiver la double authentification'
                      : 'Activer la double authentification'),
                ),
              ],
            ),
    );
  }
}

/// Écran d'activation : QR code à scanner + saisie du code à 6 chiffres
/// pour confirmer que l'application d'authentification est bien
/// configurée avant d'activer réellement la protection.
class _TotpEnrollScreen extends StatefulWidget {
  final AuthMFAEnrollResponse enrollment;
  const _TotpEnrollScreen({required this.enrollment});

  @override
  State<_TotpEnrollScreen> createState() => _TotpEnrollScreenState();
}

class _TotpEnrollScreenState extends State<_TotpEnrollScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
        factorId: widget.enrollment.id,
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
    final totp = widget.enrollment.totp;

    return Scaffold(
      appBar: AppBar(title: const Text('Scanner le QR code')),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          const Text(
            '1. Ouvrez une application d\'authentification (Google Authenticator, Authy...) et scannez ce QR code :',
          ),
          SizedBox(height: 2.h),
          if (totp != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child:
                    SvgPicture.string(totp.qrCode, width: 200, height: 200),
              ),
            ),
          SizedBox(height: 1.h),
          if (totp != null)
            Center(
              child: Column(
                children: [
                  Text(
                    'Impossible de scanner ? Entrez ce code manuellement :',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 0.5.h),
                  SelectableText(
                    totp.secret,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          SizedBox(height: 3.h),
          const Text(
              '2. Entrez le code à 6 chiffres généré par l\'application :'),
          SizedBox(height: 1.h),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(
              counterText: '',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
          ),
          SizedBox(height: 2.h),
          FilledButton(
            onPressed: _isVerifying ? null : _verify,
            child: _isVerifying
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Confirmer et activer'),
          ),
        ],
      ),
    );
  }
}
