import 'package:flutter/material.dart';
import '../presentation/business_profile_settings/business_profile_settings.dart';
import '../presentation/analytics_dashboard/analytics_dashboard.dart';
import '../presentation/business_dashboard/business_dashboard.dart';
import '../presentation/campaign_management/campaign_management.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/messaging_center/messaging_center.dart';
import '../presentation/customer_management/customer_management.dart';
import '../presentation/order_management/order_management.dart';
import '../presentation/authentication_screen/authentication_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/product_catalog_management/product_catalog_management.dart';
import '../presentation/product_detail_editor/product_detail_editor.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String businessProfileSettings = '/business-profile-settings';
  static const String analyticsDashboard = '/analytics-dashboard';
  static const String businessDashboard = '/business-dashboard';
  static const String campaignManagement = '/campaign-management';
  static const String splash = '/splash-screen';
  static const String messagingCenter = '/messaging-center';
  static const String customerManagement = '/customer-management';
  static const String orderManagement = '/order-management';
  static const String authentication = '/authentication-screen';
  static const String onboardingFlow = '/onboarding-flow';
  static const String productCatalogManagement = '/product-catalog-management';
  static const String productDetailEditor = '/product-detail-editor';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    businessProfileSettings: (context) => const BusinessProfileSettings(),
    analyticsDashboard: (context) => const AnalyticsDashboard(),
    businessDashboard: (context) => const BusinessDashboard(),
    campaignManagement: (context) => const CampaignManagement(),
    splash: (context) => const SplashScreen(),
    messagingCenter: (context) => const MessagingCenter(),
    customerManagement: (context) => const CustomerManagement(),
    orderManagement: (context) => const OrderManagement(),
    authentication: (context) => const AuthenticationScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    productCatalogManagement: (context) => const ProductCatalogManagement(),
    productDetailEditor: (context) => const ProductDetailEditor(),
    // TODO: Add your other routes here
  };
}
