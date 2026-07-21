import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/supabase/auth_helpers.dart';
import './widgets/app_logo_widget.dart';
import './widgets/email_input_widget.dart';
import './widgets/language_selector_widget.dart';
import './widgets/password_input_widget.dart';
import './widgets/social_login_widget.dart';

/// Authentication screen for business owner login
/// Supports multi-language interface and biometric authentication
class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _currentLanguage = 'fr';
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  bool _rememberMe = false;

  // Multi-language translations
  final Map<String, Map<String, String>> _translations = {
    'fr': {
      'welcome_back': 'Bon retour',
      'login_subtitle': 'Connectez-vous à votre compte professionnel',
      'email_label': 'Email',
      'email_hint': 'votre@email.com',
      'password_label': 'Mot de passe',
      'password_hint': '••••••••',
      'forgot_password': 'Mot de passe oublié?',
      'remember_me': 'Se souvenir de moi',
      'login_button': 'Se connecter',
      'or_continue_with': 'Ou continuer avec',
      'new_business': 'Nouvelle entreprise?',
      'register': 'S\'inscrire',
      'invalid_email': 'Adresse email invalide',
      'invalid_password': 'Le mot de passe doit contenir au moins 8 caractères',
      'invalid_credentials': 'Email ou mot de passe incorrect',
      'subscription_expired': 'Votre abonnement a expiré',
      'account_pending': 'Votre compte est en attente de vérification',
      'login_success': 'Connexion réussie!',
    },
    'mg': {
      'welcome_back': 'Tonga soa indray',
      'login_subtitle': 'Midira amin\'ny kaontinao',
      'email_label': 'Email',
      'email_hint': 'ny@email.com',
      'password_label': 'Teny miafina',
      'password_hint': '••••••••',
      'forgot_password': 'Adino ny teny miafina?',
      'remember_me': 'Tadidio aho',
      'login_button': 'Hiditra',
      'or_continue_with': 'Na tohizana amin\'ny',
      'new_business': 'Orinasa vaovao?',
      'register': 'Hisoratra anarana',
      'invalid_email': 'Email tsy mety',
      'invalid_password':
          'Ny teny miafina dia tokony hanana litera 8 farafahakeliny',
      'invalid_credentials': 'Email na teny miafina diso',
      'subscription_expired': 'Tapitra ny famandrihana',
      'account_pending': 'Mbola miandry fanamarinana ny kaontinao',
      'login_success': 'Tafiditra soa aman-tsara!',
    },
    'en': {
      'welcome_back': 'Welcome Back',
      'login_subtitle': 'Sign in to your business account',
      'email_label': 'Email',
      'email_hint': 'your@email.com',
      'password_label': 'Password',
      'password_hint': '••••••••',
      'forgot_password': 'Forgot Password?',
      'remember_me': 'Remember me',
      'login_button': 'Sign In',
      'or_continue_with': 'Or continue with',
      'new_business': 'New Business?',
      'register': 'Register',
      'invalid_email': 'Invalid email address',
      'invalid_password': 'Password must be at least 8 characters',
      'invalid_credentials': 'Invalid email or password',
      'subscription_expired': 'Your subscription has expired',
      'account_pending': 'Your account is pending verification',
      'login_success': 'Login successful!',
    },
    'ar': {
      'welcome_back': 'مرحبا بعودتك',
      'login_subtitle': 'تسجيل الدخول إلى حساب عملك',
      'email_label': 'البريد الإلكتروني',
      'email_hint': 'your@email.com',
      'password_label': 'كلمة المرور',
      'password_hint': '••••••••',
      'forgot_password': 'نسيت كلمة المرور؟',
      'remember_me': 'تذكرني',
      'login_button': 'تسجيل الدخول',
      'or_continue_with': 'أو المتابعة مع',
      'new_business': 'عمل جديد؟',
      'register': 'تسجيل',
      'invalid_email': 'عنوان بريد إلكتروني غير صالح',
      'invalid_password': 'يجب أن تكون كلمة المرور 8 أحرف على الأقل',
      'invalid_credentials': 'البريد الإلكتروني أو كلمة المرور غير صحيحة',
      'subscription_expired': 'انتهت صلاحية اشتراكك',
      'account_pending': 'حسابك في انتظار التحقق',
      'login_success': 'تم تسجيل الدخول بنجاح!',
    },
  };

  Map<String, String> get _currentTranslations =>
      _translations[_currentLanguage]!;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 8;
  }

  void _validateInputs() {
    setState(() {
      _emailError = null;
      _passwordError = null;

      if (_emailController.text.isEmpty ||
          !_validateEmail(_emailController.text)) {
        _emailError = _currentTranslations['invalid_email'];
      }

      if (_passwordController.text.isEmpty ||
          !_validatePassword(_passwordController.text)) {
        _passwordError = _currentTranslations['invalid_password'];
      }
    });
  }

  Future<void> _handleLogin() async {
    _validateInputs();

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? errorMessage;

    if (!SupabaseConfig.isConfigured) {
      errorMessage =
          'Connexion au serveur indisponible. Vérifiez votre connexion internet.';
    } else {
      try {
        await SupabaseConfig.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } on AuthException catch (e) {
        errorMessage = e.message;
      } catch (e) {
        errorMessage = 'Une erreur est survenue. Réessayez.';
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (errorMessage == null) {
      // Haptic feedback on success
      HapticFeedback.mediumImpact();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_currentTranslations['login_success']!),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to the right home screen depending on role
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final route = await AuthRouting.homeRouteForCurrentUser();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleSocialLogin(String provider) async {
    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider login will be implemented with native SDKs'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleForgotPassword() {
    HapticFeedback.selectionClick();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentTranslations['forgot_password']!),
        content: Text('Password reset functionality will be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleRegister() {
    HapticFeedback.selectionClick();
    Navigator.pushNamed(context, '/registration-screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = _currentLanguage == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 2.h),

                // Language selector
                Align(
                  alignment:
                      isRTL ? Alignment.centerLeft : Alignment.centerRight,
                  child: LanguageSelectorWidget(
                    currentLanguage: _currentLanguage,
                    onLanguageChanged: (language) {
                      setState(() {
                        _currentLanguage = language;
                      });
                    },
                  ),
                ),

                SizedBox(height: 4.h),

                // App logo
                const AppLogoWidget(),

                SizedBox(height: 4.h),

                // Welcome text
                Text(
                  _currentTranslations['welcome_back']!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 1.h),

                Text(
                  _currentTranslations['login_subtitle']!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 4.h),

                // Email input
                EmailInputWidget(
                  controller: _emailController,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() {
                        _emailError = null;
                      });
                    }
                  },
                  translations: _currentTranslations,
                ),

                SizedBox(height: 2.h),

                // Password input
                PasswordInputWidget(
                  controller: _passwordController,
                  errorText: _passwordError,
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() {
                        _passwordError = null;
                      });
                    }
                  },
                  translations: _currentTranslations,
                ),

                SizedBox(height: 2.h),

                // Remember me and forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          _currentTranslations['remember_me']!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _handleForgotPassword,
                      child: Text(
                        _currentTranslations['forgot_password']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 3.h),

                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
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
                      : Text(_currentTranslations['login_button']!),
                ),

                SizedBox(height: 3.h),

                // Social login
                SocialLoginWidget(
                  onSocialLogin: _handleSocialLogin,
                  translations: _currentTranslations,
                ),

                SizedBox(height: 4.h),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentTranslations['new_business']!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: _handleRegister,
                      child: Text(
                        _currentTranslations['register']!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
