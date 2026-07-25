import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/push_notification_service.dart';
import '../../core/supabase/supabase_config.dart';

/// Écran d'inscription pour les clients (hôtel, hôpital, entreprise, particulier).
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  DateTime? _birthDate;
  bool _acceptedTerms = false;

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
    _fullNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Valide un numéro malgache : doit commencer par un préfixe d'opérateur
  /// réel (Telma 034/038, Orange 032, Yas ex-Airtel 033), avec ou sans le
  /// +261, et contenir le bon nombre de chiffres.
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le téléphone est obligatoire';
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    // Normalise en retirant l'indicatif pays (261) s'il est présent.
    final local = digitsOnly.startsWith('261')
        ? '0${digitsOnly.substring(3)}'
        : digitsOnly;

    const validPrefixes = ['032', '033', '034', '038'];
    final hasValidPrefix =
        validPrefixes.any((prefix) => local.startsWith(prefix));

    if (!hasValidPrefix || local.length != 10) {
      return 'Numéro invalide (ex: 034 XX XXX XX)';
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final birthDateError = _validateBirthDate();
    if (birthDateError != null) {
      _showError(birthDateError);
      return;
    }
    if (!_acceptedTerms) {
      _showError('Vous devez accepter les conditions d\'utilisation');
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      _showError('Connexion au serveur indisponible. Réessayez plus tard.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {'full_name': _fullNameController.text.trim()},
      );

      final userId = response.user?.id;
      if (userId != null) {
        // Complète le profil créé automatiquement par le trigger SQL
        // avec le type de client, le nom de société et le téléphone.
        await SupabaseConfig.client.from('profiles').update({
          'client_type': _clientType,
          'company_name': _companyNameController.text.trim().isEmpty
              ? null
              : _companyNameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          'birth_date': _birthDate?.toIso8601String().split('T').first,
        }).eq('id', userId);
      }

      if (!mounted) return;
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
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          child: Form(
            key: _formKey,
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

                TextFormField(
                  controller: _fullNameController,
                  decoration:
                      const InputDecoration(labelText: 'Nom complet'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                SizedBox(height: 2.h),

                if (_clientType != 'particulier') ...[
                  TextFormField(
                    controller: _companyNameController,
                    decoration: InputDecoration(
                      labelText: _clientType == 'hotel'
                          ? 'Nom de l\'hôtel'
                          : _clientType == 'hopital'
                              ? 'Nom de l\'hôpital / établissement'
                              : 'Nom de l\'entreprise',
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],

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

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: '034 XX XXX XX',
                  ),
                  validator: _validatePhone,
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
                  style:
                      ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 2.h)),
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
                SizedBox(height: 2.h),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Déjà un compte ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
