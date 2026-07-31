import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/push_notification_service.dart';
import '../../core/supabase/supabase_config.dart';

/// Dernière étape de l'inscription : vérification du numéro de téléphone
/// par SMS (après la vérification de l'email) — demandé par
/// l'utilisateur (31/07) pour limiter les faux comptes, le téléphone
/// saisi au formulaire n'étant jamais vérifié jusqu'ici.
///
/// Nécessite le provider "Phone" activé côté Supabase (Authentication ->
/// Providers -> Phone) avec un compte Twilio configuré — étape manuelle,
/// ne peut pas être faite en SQL. Sans ça, `updateUser(phone: ...)`
/// échoue et cet écran affiche une erreur au lieu d'envoyer un SMS.
///
/// Utilise le flux "changement de téléphone" de Supabase Auth
/// (`updateUser` puis `verifyOTP(type: OtpType.phoneChange)`) plutôt que
/// le flux de connexion par téléphone : l'utilisateur a déjà une session
/// (email vérifié juste avant), on ne fait qu'attacher et confirmer son
/// numéro à ce compte existant.
class PhoneOtpVerificationScreen extends StatefulWidget {
  final String phone;

  const PhoneOtpVerificationScreen({super.key, required this.phone});

  @override
  State<PhoneOtpVerificationScreen> createState() =>
      _PhoneOtpVerificationScreenState();
}

class _PhoneOtpVerificationScreenState
    extends State<PhoneOtpVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  bool _isSendingInitialCode = true;
  String? _sendError;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _sendInitialCode();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendInitialCode() async {
    setState(() {
      _isSendingInitialCode = true;
      _sendError = null;
    });
    try {
      await SupabaseConfig.client.auth
          .updateUser(UserAttributes(phone: widget.phone));
      _startCooldown();
    } on AuthException catch (e) {
      setState(() => _sendError = e.message);
    } catch (e) {
      setState(() =>
          _sendError = 'Impossible d\'envoyer le SMS pour le moment.');
    } finally {
      if (mounted) setState(() => _isSendingInitialCode = false);
    }
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
    if (code.length < 4) {
      _showError('Code invalide.');
      return;
    }

    setState(() => _isVerifying = true);
    try {
      await SupabaseConfig.client.auth.verifyOTP(
        type: OtpType.phoneChange,
        phone: widget.phone,
        token: code,
      );

      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        await SupabaseConfig.client
            .from('profiles')
            .update({'phone': widget.phone}).eq('id', userId);
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
          .resend(type: OtpType.phoneChange, phone: widget.phone);
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
      appBar: AppBar(title: const Text('Vérification du téléphone')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.sms_outlined,
                  size: 48, color: theme.colorScheme.primary),
              SizedBox(height: 2.h),
              if (_isSendingInitialCode)
                const Center(child: CircularProgressIndicator())
              else if (_sendError != null) ...[
                Text(_sendError!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error)),
                SizedBox(height: 2.h),
                OutlinedButton(
                  onPressed: _sendInitialCode,
                  child: const Text('Réessayer d\'envoyer le SMS'),
                ),
              ] else ...[
                Text(
                  'Un code a été envoyé par SMS au ${widget.phone}. '
                  'Saisissez-le ci-dessous pour terminer votre inscription.',
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: 3.h),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 8,
                  style:
                      theme.textTheme.headlineSmall?.copyWith(letterSpacing: 4),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Vérifier'),
                ),
                SizedBox(height: 2.h),
                TextButton(
                  onPressed:
                      (_resendCooldown > 0 || _isResending) ? null : _resend,
                  child: Text(
                    _resendCooldown > 0
                        ? 'Renvoyer le code (${_resendCooldown}s)'
                        : 'Renvoyer le code',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
