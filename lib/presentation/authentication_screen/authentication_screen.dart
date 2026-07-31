import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/push_notification_service.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/supabase/auth_helpers.dart';
import './recent_accounts_store.dart';
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
  bool _rememberMe = true;
  List<RecentAccount> _recentAccounts = [];
  bool _showManualForm = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadRecentAccounts();

    // Écoute centralisée des connexions réussies (email/mot de passe ET
    // Google/Facebook) : une connexion OAuth se termine par une redirection
    // depuis le navigateur externe, sans jamais repasser par
    // `_handleLogin()` — ce flux d'évènements est le seul point commun aux
    // deux méthodes de connexion.
    if (SupabaseConfig.isConfigured) {
      _authStateSubscription =
          SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          _onAuthenticated();
        }
      });
    }
  }

  Future<void> _loadRecentAccounts() async {
    final accounts = await RecentAccountsStore.load();
    if (!mounted) return;
    setState(() {
      _recentAccounts = accounts;
      _showManualForm = accounts.isEmpty;
    });
  }

  void _pickRecentAccount(RecentAccount account) {
    setState(() {
      _emailController.text = account.email;
      _showManualForm = true;
    });
  }

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
    _authStateSubscription?.cancel();
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
        // Passe par l'Edge Function `hyper-endpoint` (nom imposé par le
        // Dashboard Supabase lors du déploiement via l'éditeur en ligne —
        // le contenu correspond à ce qu'on appelle "secure-login" dans le
        // code source, voir supabase/functions/hyper-endpoint/index.ts)
        // plutôt que d'appeler signInWithPassword directement : elle seule
        // permet de bloquer un compte après 5 échecs en 15 minutes (voir
        // supabase/phase35_patch_login_rate_limit.sql — le hook officiel
        // Supabase Auth équivalent est réservé aux plans Team/Enterprise).
        final response = await SupabaseConfig.client.functions.invoke(
          'hyper-endpoint',
          body: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );
        final data = response.data as Map;
        if (data['ok'] == true) {
          await SupabaseConfig.client.auth
              .setSession(data['refresh_token'] as String);
          // `setSession` restaure une session existante : GoTrue émet
          // `tokenRefreshed`, jamais `signedIn` — l'écoute `onAuthStateChange`
          // posée dans `initState()` (qui ne réagit qu'à `signedIn`, pour la
          // connexion OAuth) ne se déclenche donc pas ici. On appelle la
          // suite directement.
          if (mounted) await _onAuthenticated();
        } else {
          errorMessage =
              data['error'] as String? ?? 'Email ou mot de passe incorrect';
        }
      } catch (e) {
        errorMessage = 'Une erreur est survenue. Réessayez.';
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    // Le cas de succès email/mot de passe est déjà géré ci-dessus (appel
    // direct à `_onAuthenticated()`). Pour Google/Facebook (voir
    // `_handleSocialLogin`), c'est l'écoute `onAuthStateChange` posée dans
    // `initState()` qui s'en charge — ce flux-là se termine par une
    // redirection externe et émet bien `signedIn`.
  }

  /// Suite commune à toute connexion réussie (email/mot de passe ou
  /// OAuth) : mémorisation du compte, association du token de
  /// notifications, message de succès, puis routage vers l'accueil selon
  /// le rôle.
  Future<void> _onAuthenticated() async {
    if (!mounted) return;

    HapticFeedback.mediumImpact();

    // Mémorise ce compte pour un accès rapide au prochain lancement
    // (pré-remplit l'email, ne stocke jamais le mot de passe) —
    // seulement si "Se souvenir de moi" est coché (utile pour ne pas
    // laisser un compte visible sur un appareil partagé/public).
    if (_rememberMe) {
      try {
        final user = SupabaseConfig.client.auth.currentUser;
        if (user != null) {
          final profile = await SupabaseConfig.client
              .from('profiles')
              .select('full_name, avatar_url')
              .eq('id', user.id)
              .single();
          await RecentAccountsStore.remember(RecentAccount(
            email: user.email ?? _emailController.text.trim(),
            fullName: profile['full_name'] as String?,
            avatarUrl: profile['avatar_url'] as String?,
          ));
        }
      } catch (_) {
        // Non bloquant : la connexion a déjà réussi.
      }
    }

    // Associe le token FCM de cet appareil au compte qui vient de se
    // connecter (sinon les notifications resteraient liées au compte
    // précédent utilisé sur ce même téléphone, le cas échéant).
    PushNotificationService.onUserSignedIn();

    if (!mounted) return;
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
  }

  Future<void> _handleSocialLogin(String provider) async {
    HapticFeedback.selectionClick();

    final oauthProvider = switch (provider) {
      'google' => OAuthProvider.google,
      'facebook' => OAuthProvider.facebook,
      _ => null,
    };
    if (oauthProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Connexion $provider bientôt disponible. Utilisez votre email pour l\'instant.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connexion au serveur indisponible. Réessayez.')),
      );
      return;
    }

    try {
      // Ouvre le navigateur externe pour l'écran de consentement
      // Google/Facebook ; Supabase gère la redirection et émet
      // `AuthChangeEvent.signedIn` (capté par l'écoute posée dans
      // `initState()`) une fois la connexion terminée — pas de résultat
      // direct à traiter ici.
      await SupabaseConfig.client.auth.signInWithOAuth(
        oauthProvider,
        redirectTo: 'io.supabase.akorahub://login-callback/',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Impossible de lancer la connexion $provider.')),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    HapticFeedback.selectionClick();

    final controller =
        TextEditingController(text: _emailController.text.trim());

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentTranslations['forgot_password']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrez votre email — nous vous enverrons un lien pour réinitialiser votre mot de passe.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty || !mounted) return;

    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connexion au serveur indisponible. Réessayez.')),
      );
      return;
    }

    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.akorahub://login-callback/',
      );
      // Journalisation (revue de sécurité Admin) — voir
      // supabase/phase34_patch_security_audit_log.sql. Best-effort :
      // n'affecte jamais l'envoi de l'email lui-même si l'appel échoue.
      // Non authentifié à ce stade (auth.uid() sera null côté serveur),
      // ce qui est normal — la fonction journalise quand même l'événement.
      try {
        await SupabaseConfig.client.rpc('log_security_event',
            params: {'p_event_type': 'password_reset_requested'});
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Un email a été envoyé à $email avec les instructions de réinitialisation.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur lors de l\'envoi. Vérifiez l\'adresse email.')),
      );
    }
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

                // Comptes récents : accès rapide façon Facebook (pré-remplit
                // l'email au tap, le mot de passe reste toujours requis).
                if (_recentAccounts.isNotEmpty && !_showManualForm) ...[
                  ..._recentAccounts.map((account) => Card(
                        margin: EdgeInsets.only(bottom: 1.5.h),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: account.avatarUrl != null
                                ? NetworkImage(account.avatarUrl!)
                                : null,
                            child: account.avatarUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            (account.fullName == null ||
                                    account.fullName!.trim().isEmpty)
                                ? account.email
                                : account.fullName!,
                          ),
                          subtitle: (account.fullName == null ||
                                  account.fullName!.trim().isEmpty)
                              ? null
                              : Text(account.email),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Oublier ce compte',
                            onPressed: () async {
                              await RecentAccountsStore.forget(account.email);
                              _loadRecentAccounts();
                            },
                          ),
                          onTap: () => _pickRecentAccount(account),
                        ),
                      )),
                  OutlinedButton(
                    onPressed: () => setState(() => _showManualForm = true),
                    child: const Text('Utiliser un autre compte'),
                  ),
                  SizedBox(height: 3.h),
                ] else ...[
                  if (_recentAccounts.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _showManualForm = false),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Comptes récents'),
                      ),
                    ),

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
                ],

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
