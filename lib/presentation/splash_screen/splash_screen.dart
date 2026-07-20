import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../core/supabase/supabase_config.dart';
import '../../widgets/custom_icon_widget.dart';

/// Splash Screen - Branded app launch experience
///
/// Provides professional branded launch while initializing:
/// - Subscription status verification
/// - Business profile loading
/// - Essential configuration fetching
/// - Offline data preparation
///
/// Navigation Logic:
/// - Authenticated business owners → /business-dashboard
/// - New users → /onboarding-flow
/// - Returning non-authenticated → /authentication-screen
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
      // Minimum display time for branding
      await Future.delayed(const Duration(milliseconds: 2500));

      // Simulate initialization tasks
      await _checkSubscriptionStatus();
      await _loadBusinessProfiles();
      await _fetchConfigurations();
      await _prepareCachedData();

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
        _errorMessage = 'Initialization failed. Please try again.';
      });

      // Auto-retry after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _hasError) {
          _retryInitialization();
        }
      });
    }
  }

  /// Check subscription status
  Future<void> _checkSubscriptionStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual subscription check
  }

  /// Load business profiles
  Future<void> _loadBusinessProfiles() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual profile loading
  }

  /// Fetch essential configurations
  Future<void> _fetchConfigurations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual configuration fetch
  }

  /// Prepare cached data for offline functionality
  Future<void> _prepareCachedData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Implement actual cache preparation
  }

  /// Navigate to appropriate screen based on user state
  Future<void> _navigateToNextScreen() async {
    final bool isAuthenticated = SupabaseConfig.isConfigured &&
        SupabaseConfig.client.auth.currentSession != null;

    final bool isFirstLaunch = await _isFirstLaunch();

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/business-dashboard');
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
                  'Akora Fanadiovana',
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
                  'Professional Multi-Business Platform',
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
          child: Center(
            child: CustomIconWidget(
              iconName: 'business_center',
              color: theme.colorScheme.primary,
              size: 60,
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
              'Retry',
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
          _initializationComplete ? 'Loading...' : 'Initializing services...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
