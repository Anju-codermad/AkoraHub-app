import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/push_notification_service.dart';
import '../../core/supabase/supabase_config.dart';

/// Étape de vérification par code après inscription (`auth.signUp`) —
/// nécessite que "Confirm email" soit activé côté Supabase (Authentication
/// -> Providers -> Email) ET que le template "Confirm signup" affiche
/// `{{ .Token }}` (code à 6 chiffres) plutôt qu'un simple lien, sinon le
/// client ne reçoit jamais aucun code (voir demande utilisateur du 31/07).
///
/// Le profil (type de client, société, téléphone, date de naissance) ne
/// peut être mis à jour qu'après ce succès : avant la vérification, il
/// n'y a pas encore de session (donc pas de JWT), et les policies RLS de
/// `profiles` refusent toute écriture sans session valide.
class EmailOtpVerificationScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic> pendingProfileUpdate;

  const EmailOtpVerificationScreen({
    super.key,
    required this.email,
    required this.pendingProfileUpdate,
  });

  @override
  State<EmailOtpVerificationScreen> createState() =>
      _EmailOtpVerificationScreenState();
}

class _EmailOtpVerificationScreenState
    extends State<EmailOtpVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showError('Le code doit contenir 6 chiffres.');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final response = await SupabaseConfig.client.auth.verifyOTP(
        type: OtpType.signup,
        email: widget.email,
        token: code,
      );

      final userId = response.user?.id;
      if (userId != null) {
        await SupabaseConfig.client
            .from('profiles')
            .update(widget.pendingProfileUpdate)
            .eq('id', userId);
      }

      PushNotificationService.onUserSignedIn();

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pushNamedAndRemoveUntil(
          context, '/client-home', (route) => false);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await SupabaseConfig.client.auth
          .resend(type: OtpType.signup, email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un nouveau code a été envoyé.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startCooldown();
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Impossible de renvoyer le code. Réessayez plus tard.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification de l\'email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.mark_email_read_outlined,
                  size: 48, color: theme.colorScheme.primary),
              SizedBox(height: 2.h),
              Text(
                'Un code à 6 chiffres a été envoyé à ${widget.email}. '
                'Saisissez-le ci-dessous pour activer votre compte.',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 3.h),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(letterSpacing: 8),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '000000',
                ),
                onSubmitted: (_) => _verify(),
              ),
              SizedBox(height: 3.h),
              FilledButton(
                onPressed: _isVerifying ? null : _verify,
                child: _isVerifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Vérifier'),
              ),
              SizedBox(height: 2.h),
              TextButton(
                onPressed: (_resendCooldown > 0 || _isResending)
                    ? null
                    : _resend,
                child: Text(
                  _resendCooldown > 0
                      ? 'Renvoyer le code (${_resendCooldown}s)'
                      : 'Renvoyer le code',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
