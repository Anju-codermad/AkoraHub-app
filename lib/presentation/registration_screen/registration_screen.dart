import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/push_notification_service.dart';
import '../../core/services/referral_repo.dart';
import '../../core/supabase/supabase_config.dart';
import './email_otp_verification_screen.dart';

/// Écran d'inscription pour les clients (hôtel, hôpital, entreprise,
/// particulier), en 2 étapes :
/// 1) Identité (secteur, nom, prénom, société, date de naissance)
/// 2) Coordonnées (email, téléphone, mot de passe, conditions)
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _showPassword = false;
  DateTime? _birthDate;
  bool _acceptedTerms = false;
  String _phoneCountryIso = 'MG';

  String _clientType = 'particulier';
  bool _isLoading = false;

  final List<Map<String, String>> _clientTypes = const [
    {'value': 'particulier', 'label': 'Particulier'},
    {'value': 'hotel', 'label': 'Hôtel'},
    {'value': 'hopital', 'label': 'Hôpital'},
    {'value': 'entreprise', 'label': 'Entreprise'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  /// Valide un numéro malgache : doit commencer par un préfixe d'opérateur
  /// réel (Telma 034/038, Orange 032, Yas ex-Airtel 033), avec ou sans le
  /// +261, et contenir le bon nombre de chiffres. Pour tout autre pays
  /// choisi dans le menu déroulant, on applique juste une validation
  /// générique par longueur.
  String? _validatePhone(String? value, String countryIso) {
    if (value == null || value.trim().isEmpty) {
      return 'Le téléphone est obligatoire';
    }
    final trimmed = value.trim();
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');

    if (countryIso == 'MG') {
      final local = digitsOnly.startsWith('261')
          ? '0${digitsOnly.substring(3)}'
          : digitsOnly;
      const validPrefixes = ['032', '033', '034', '038'];
      final isValidMalagasy =
          validPrefixes.any((p) => local.startsWith(p)) && local.length == 10;
      if (!isValidMalagasy) {
        return 'Numéro invalide (ex: 034 XX XXX XX)';
      }
      return null;
    }

    if (digitsOnly.length < 4 || digitsOnly.length > 14) {
      return 'Numéro invalide';
    }
    return null;
  }

  /// Vérifie que la date de naissance correspond à un âge d'au moins 18
  /// ans — l'app vend des produits chimiques/insecticides, une
  /// vérification d'âge minimale est raisonnable pour la création de
  /// compte.
  String? _validateBirthDate() {
    if (_birthDate == null) return 'La date de naissance est obligatoire';
    final now = DateTime.now();
    var age = now.year - _birthDate!.year;
    final hasHadBirthdayThisYear = (now.month > _birthDate!.month) ||
        (now.month == _birthDate!.month && now.day >= _birthDate!.day);
    if (!hasHadBirthdayThisYear) age--;
    if (age < 18) return 'Vous devez avoir au moins 18 ans';
    return null;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Date de naissance',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _goToStep2() {
    if (!_step1FormKey.currentState!.validate()) return;
    final birthDateError = _validateBirthDate();
    if (birthDateError != null) {
      _showError(birthDateError);
      return;
    }
    setState(() => _currentStep = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _goToStep1() {
    setState(() => _currentStep = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleRegister() async {
    if (!_step2FormKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      _showError('Vous devez accepter les conditions d\'utilisation');
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      _showError('Connexion au serveur indisponible. Réessayez plus tard.');
      return;
    }

    // Résolution du code de parrainage (optionnel) avant la création du
    // compte — un code saisi mais invalide bloque l'inscription plutôt
    // que d'être ignoré silencieusement.
    String? referredBy;
    final referralCode = _referralCodeController.text.trim();
    if (referralCode.isNotEmpty) {
      referredBy = await ReferralRepo.resolveCode(referralCode);
      if (referredBy == null) {
        _showError('Code de parrainage invalide.');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name':
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
                  .trim()
        },
      );

      // Champs du profil à appliquer une fois une session établie —
      // impossible de le faire tout de suite si la confirmation par email
      // est activée (pas encore de session -> RLS refuse l'écriture).
      final pendingProfileUpdate = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'client_type': _clientType,
        'company_name': _companyNameController.text.trim().isEmpty
            ? null
            : _companyNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'birth_date': _birthDate?.toIso8601String().split('T').first,
        if (referredBy != null) 'referred_by': referredBy,
      };

      if (!mounted) return;

      if (response.session == null) {
        // "Confirm email" activé côté Supabase : aucune session tant que
        // le code reçu par email n'est pas saisi.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailOtpVerificationScreen(
              email: _emailController.text.trim(),
              pendingProfileUpdate: pendingProfileUpdate,
            ),
          ),
        );
        return;
      }

      // Confirmation par email désactivée côté Supabase : session déjà
      // active, comportement inchangé (connexion immédiate).
      final userId = response.user?.id;
      if (userId != null) {
        await SupabaseConfig.client
            .from('profiles')
            .update(pendingProfileUpdate)
            .eq('id', userId);
      }

      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé avec succès ! Vous êtes connecté.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      PushNotificationService.onUserSignedIn();

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/client-home');
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep == 1) {
              _goToStep1();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Barre de progression : étape 1 sur 2 / 2 sur 2 ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStep == 0
                        ? 'Étape 1 sur 2 — Identité'
                        : 'Étape 2 sur 2 — Coordonnées',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _currentStep == 0 ? 0.5 : 1.0,
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(theme),
                  _buildStep2(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bienvenue sur AkoraHub',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Créez votre compte pour commander et échanger avec la communauté',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),

            // Type de client
            Text('Je suis un(e)...', style: theme.textTheme.labelLarge),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: _clientTypes.map((type) {
                final selected = _clientType == type['value'];
                return ChoiceChip(
                  label: Text(type['label']!),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _clientType = type['value']!);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 3.h),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            TextFormField(
              controller: _companyNameController,
              decoration: InputDecoration(
                labelText: _clientType == 'hotel'
                    ? 'Nom de l\'hôtel'
                    : _clientType == 'hopital'
                        ? 'Nom de l\'hôpital / établissement'
                        : _clientType == 'entreprise'
                            ? 'Nom de l\'entreprise'
                            : 'Entreprise (si vous achetez pour '
                                'un compte professionnel)',
              ),
              validator: _clientType != 'particulier'
                  ? (v) => (v == null || v.trim().isEmpty)
                      ? 'Requis pour un compte professionnel'
                      : null
                  : null,
            ),
            SizedBox(height: 2.h),

            InkWell(
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de naissance',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _birthDate == null
                      ? 'Sélectionner une date'
                      : _formatDate(_birthDate!),
                  style: _birthDate == null
                      ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
                      : null,
                ),
              ),
            ),
            SizedBox(height: 3.h),

            ElevatedButton(
              onPressed: _goToStep2,
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h)),
              child: const Text('Suivant'),
            ),
            SizedBox(height: 2.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Déjà un compte ? Se connecter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vos coordonnées',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Pour te connecter et te contacter au sujet de tes commandes',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requis';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            SizedBox(height: 2.h),

            IntlPhoneField(
              initialCountryCode: 'MG',
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                counterText: '',
              ),
              disableLengthCheck: true,
              dropdownIconPosition: IconPosition.trailing,
              onChanged: (phone) {
                _phoneController.text = phone.completeNumber;
                _phoneCountryIso = phone.countryISOCode;
              },
              onCountryChanged: (country) {
                _phoneCountryIso = country.code;
              },
              validator: (phone) =>
                  _validatePhone(phone?.completeNumber, _phoneCountryIso),
            ),
            SizedBox(height: 2.h),

            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(_showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 8) {
                  return 'Au moins 8 caractères';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),

            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showPassword,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
              ),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),

            TextFormField(
              controller: _referralCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Code de parrainage (optionnel)',
                hintText: 'ex: A1B2C3',
              ),
            ),
            SizedBox(height: 1.h),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: (v) =>
                      setState(() => _acceptedTerms = v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 1.5.h),
                    child: Text(
                      'J\'accepte les conditions d\'utilisation et la '
                      'politique de confidentialité d\'AkoraHub',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h)),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Text('Créer mon compte'),
            ),
            SizedBox(height: 1.5.h),
            TextButton(
              onPressed: _goToStep1,
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
