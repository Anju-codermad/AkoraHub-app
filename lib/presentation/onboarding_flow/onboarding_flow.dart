import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import './widgets/onboarding_page_widget.dart';

/// Onboarding Flow Screen
/// Introduces new business owners to the super-app's comprehensive features
/// through mobile-optimized tutorial screens with swipe gestures and progress indicators
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding pages data
  final List<Map<String, dynamic>> _onboardingPages = [
    {
      "title": "Créez Votre Profil d'Entreprise",
      "description":
          "Configurez votre identité visuelle avec logo, photos et informations complètes pour attirer vos clients.",
      "semanticLabel": "Icône représentant la gestion du profil d'entreprise",
      "iconName": "business",
    },
    {
      "title": "Gérez Votre Catalogue Produits",
      "description":
          "Ajoutez vos produits avec photos, vidéos et descriptions détaillées. Organisez facilement votre inventaire.",
      "semanticLabel": "Icône représentant la gestion du catalogue produits",
      "iconName": "inventory_2",
    },
    {
      "title": "Engagez Vos Clients",
      "description":
          "Communiquez directement via WhatsApp, suivez les prospects et gérez les rendez-vous en un seul endroit.",
      "semanticLabel": "Icône représentant l'engagement client",
      "iconName": "people",
    },
    {
      "title": "Analysez Vos Performances",
      "description":
          "Suivez vos ventes, conversions et statistiques en temps réel avec des rapports détaillés exportables.",
      "semanticLabel": "Icône représentant l'analyse des performances",
      "iconName": "analytics",
    },
    {
      "title": "Développez Votre Activité",
      "description":
          "Accédez à tous les outils professionnels d'AkoraHub — catalogue, commandes, livraison et communauté — pour faire grandir votre activité au quotidien.",
      "semanticLabel": "Icône représentant la croissance de l'activité",
      "iconName": "trending_up",
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    HapticFeedback.selectionClick();
  }

  void _nextPage() {
    if (_currentPage < _onboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() {
    HapticFeedback.mediumImpact();
    Navigator.pushReplacementNamed(context, '/authentication-screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  ),
                  child: Text(
                    'Passer',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(
                    pageData: _onboardingPages[index],
                  );
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _onboardingPages.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: theme.colorScheme.primary,
                  dotColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                  dotHeight: 1.h,
                  dotWidth: 2.w,
                  expansionFactor: 3,
                  spacing: 1.w,
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  // Previous button (hidden on first page)
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Précédent',
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                    ),

                  if (_currentPage > 0) SizedBox(width: 3.w),

                  // Next/Get Started button
                  Expanded(
                    flex: _currentPage > 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _currentPage == _onboardingPages.length - 1
                            ? 'Commencer'
                            : 'Suivant',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }
}
