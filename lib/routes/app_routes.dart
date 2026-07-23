import 'package:flutter/material.dart';
import '../presentation/business_profile_settings/business_profile_settings.dart';
import '../presentation/analytics_dashboard_real/analytics_dashboard_real.dart';
import '../presentation/business_dashboard/business_dashboard.dart';
import '../presentation/campaign_management/campaign_management.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/messaging_center/messaging_center.dart';
import '../presentation/customer_management/customer_management.dart';
import '../presentation/order_management/order_management.dart';
import '../presentation/authentication_screen/authentication_screen.dart';
import '../presentation/onboarding_flow/onboarding_flow.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/business_units_management/business_units_management.dart';
import '../presentation/staff_management/staff_management.dart';
import '../presentation/product_management_real/product_management_real.dart';
import '../presentation/invoicing/invoicing_screen.dart';
import '../presentation/alerts_center/alerts_center.dart';
import '../presentation/order_management_real/order_management_real.dart';
import '../presentation/customer_management_real/customer_management_real.dart';
import '../presentation/client_home/client_home.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String registration = '/registration-screen';
  static const String businessUnitsManagement = '/business-units-management';
  static const String staffManagement = '/staff-management';
  static const String productManagementReal = '/product-management-real';
  static const String invoicing = '/invoicing';
  static const String alerts = '/alerts-center';
  static const String orderManagementReal = '/order-management-real';
  static const String customerManagementReal = '/customer-management-real';
  static const String clientHome = '/client-home';
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

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    businessProfileSettings: (context) => const BusinessProfileSettings(),
    analyticsDashboard: (context) => const AnalyticsDashboardReal(),
    businessDashboard: (context) => const BusinessDashboard(),
    campaignManagement: (context) => const CampaignManagement(),
    splash: (context) => const SplashScreen(),
    messagingCenter: (context) => const MessagingCenter(),
    customerManagement: (context) => const CustomerManagement(),
    orderManagement: (context) => const OrderManagement(),
    authentication: (context) => const AuthenticationScreen(),
    onboardingFlow: (context) => const OnboardingFlow(),
    registration: (context) => const RegistrationScreen(),
    businessUnitsManagement: (context) => const BusinessUnitsManagement(),
    staffManagement: (context) => const StaffManagement(),
    productManagementReal: (context) => const ProductManagementReal(),
    invoicing: (context) => const InvoicingScreen(),
    alerts: (context) => const AlertsCenter(),
    orderManagementReal: (context) => const OrderManagementReal(),
    customerManagementReal: (context) => const CustomerManagementReal(),
    clientHome: (context) => const ClientHome(),
    // TODO: Add your other routes here
  };
}
