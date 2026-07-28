import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/supabase/auth_helpers.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/custom_image_widget.dart';

/// Splash Screen - écran de lancement de marque
///
/// Affiche brièvement le logo pendant que l'app vérifie si l'utilisateur
/// est déjà connecté, puis redirige vers le bon écran :
/// - Utilisateur connecté → tableau de bord Admin ou accueil client
///   selon son rôle (voir AuthRouting.homeRouteForCurrentUser)
/// - Premier lancement, jamais vu l'onboarding → /onboarding-flow
/// - Non connecté (hors premier lancement) → /authentication-screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _initializationComplete = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Setup logo animations - scale and fade effects
  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  /// Initialize app services and determine navigation path
  Future<void> _initializeApp() async {
    try {
      // Court affichage du logo (branding), le temps que l'animation se joue
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      setState(() {
        _initializationComplete = true;
      });

      // Determine navigation path
      await _navigateToNextScreen();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = 'Échec de l\'initialisation. Réessaie.';
      });

      // Auto-retry after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _hasError) {
          _retryInitialization();
        }
      });
    }
  }

  /// Navigate to appropriate screen based on user state
  Future<void> _navigateToNextScreen() async {
    final bool isAuthenticated = SupabaseConfig.isConfigured &&
        SupabaseConfig.client.auth.currentSession != null;

    final bool isFirstLaunch = await _isFirstLaunch();

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    if (isAuthenticated) {
      final route = await AuthRouting.homeRouteForCurrentUser();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, route);
    } else if (isFirstLaunch) {
      Navigator.pushReplacementNamed(context, '/onboarding-flow');
    } else {
      Navigator.pushReplacementNamed(context, '/authentication-screen');
    }
  }

  /// Vérifie (via shared_preferences) si c'est le tout premier lancement
  /// de l'app, pour n'afficher l'onboarding qu'une seule fois.
  Future<bool> _isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    if (!seen) {
      await prefs.setBool('onboarding_seen', true);
      return true;
    }
    return false;
  }

  /// Retry initialization on error
  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _initializationComplete = false;
    });
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: theme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated Logo Section
              _buildAnimatedLogo(theme),

              const SizedBox(height: 24),

              // App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'AkoraHub',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Votre plateforme multi-activités',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 2),

              // Loading Indicator or Error Message
              _buildBottomSection(theme),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  /// Build animated logo with scale and fade effects
  Widget _buildAnimatedLogo(ThemeData theme) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: CustomImageWidget(
              imageUrl: 'assets/images/img_app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  /// Build bottom section with loading indicator or error message
  Widget _buildBottomSection(ThemeData theme) {
    if (_hasError) {
      return Column(
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryInitialization,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Réessayer',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _initializationComplete ? 'Chargement...' : 'Initialisation...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
