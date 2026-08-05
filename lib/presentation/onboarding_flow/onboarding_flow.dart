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

  // Onboarding pages data — texte neutre (04/08) : AkoraHub est l'app
  // dédiée d'Akora Fanadiovana, pas une plateforme où chaque utilisateur
  // crée sa propre entreprise/catalogue. L'ancien texte ("Créez Votre
  // Profil d'Entreprise", "Gérez Votre Catalogue"...) laissait croire à
  // un onboarding multi-commerces façon SaaS — corrigé pour décrire ce
  // que l'app fait réellement, pour tout nouvel utilisateur (client ou
  // staff), avant même le choix du rôle à la connexion.
  final List<Map<String, dynamic>> _onboardingPages = [
    {
      "title": "Bienvenue sur AkoraHub",
      "description":
          "L'application d'Akora Fanadiovana : produits d'hygiène, peinture ARCA et formations professionnelles, réunis au même endroit.",
      "semanticLabel": "Icône représentant AkoraHub",
      "iconName": "business",
    },
    {
      "title": "Parcourez le Catalogue",
      "description":
          "Découvrez nos produits avec photos, prix détail et prix gros, et commandez en quelques clics.",
      "semanticLabel": "Icône représentant le catalogue de produits",
      "iconName": "inventory_2",
    },
    {
      "title": "Échangez Facilement",
      "description":
          "Contactez notre équipe par messagerie ou WhatsApp, et retrouvez la communauté AkoraHub.",
      "semanticLabel": "Icône représentant l'échange avec l'équipe et la communauté",
      "iconName": "people",
    },
    {
      "title": "Suivez Vos Commandes",
      "description":
          "Consultez l'état de vos commandes et devis, de la validation jusqu'à la livraison.",
      "semanticLabel": "Icône représentant le suivi des commandes",
      "iconName": "analytics",
    },
    {
      "title": "Formez-Vous avec Akora",
      "description":
          "Accédez à l'Académie AkoraHub pour développer vos compétences et suivre nos dernières nouveautés.",
      "semanticLabel": "Icône représentant l'Académie AkoraHub",
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
