import 'package:flutter/material.dart';
import 'package:safetrack/utils/app_colors.dart';

import 'screens/auth/role_selection_screen.dart';
import 'screens/admin/login/admin_login_screen.dart';
import 'screens/admin/dashboard/dashboard.dart';
import 'screens/admin/sideBar/live_tracking.dart';
import 'screens/admin/AdminProfile/adminProfile.dart';
import 'screens/admin/sideBar/history.dart';
import 'screens/admin/sideBar/responders.dart';
import 'screens/admin/sideBar/incidents.dart';

import 'screens/responder/login/responder_login_screen.dart';
import 'screens/responder/login/responder_signup_screen.dart';
import 'screens/reporter/login/reporter_login_screen.dart';
import 'screens/reporter/login/reporter_signup_screen.dart';
import 'screens/reporter/home/home.dart';

import 'screens/reporter/bottomNav/report.dart';
import 'screens/reporter/bottomNav/track.dart';
import 'screens/reporter/bottomNav/history.dart';
import 'screens/reporter/profile/profile.dart';

import 'screens/responder/home/respenderhome.dart';
import 'screens/responder/responderProfile/responderProfile.dart';
import 'screens/responder/responderBottom/incidents.dart';
import 'screens/responder/responderBottom/nagivation.dart';


// Admin Theme Wrapper
class AdminThemeWrapper extends StatelessWidget {
  final Widget child;
  const AdminThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.darkPrimary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.darkPrimary,
          primary: AppColors.darkPrimary,
          secondary: AppColors.darkSecondary,
          surface: AppColors.darkCardBg,
          background: AppColors.darkBackground,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCardBg,
        dividerColor: AppColors.darkTextSecondary.withOpacity(0.2),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
          bodyMedium: TextStyle(color: AppColors.darkTextPrimary),
          titleLarge: TextStyle(color: AppColors.darkTextPrimary),
        ),
        useMaterial3: true,
      ),
      child: child,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SafeTrackApp());
}

class SafeTrackApp extends StatelessWidget {
  const SafeTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.cardBg,
          background: AppColors.background,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.cardBg,
        dividerColor: AppColors.textSecondary.withOpacity(0.2),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textPrimary),
          titleLarge: TextStyle(color: AppColors.textPrimary),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',

      routes: {
        // COMMON
        '/': (context) => const RoleSelectionScreen(),

        // ADMIN
        '/admin-login':
            (context) => const AdminThemeWrapper(child: AdminLoginScreen()),
        '/admin-dashboard':
            (context) => const AdminThemeWrapper(child: AdminDashboard()),
        '/admin-profile':
            (context) => const AdminThemeWrapper(child: AdminProfilePage()),
        '/admin-live-tracking':
            (context) => const AdminThemeWrapper(child: LiveTrackingPage()),
        '/admin-history':
            (context) =>
                const AdminThemeWrapper(child: IncidentHistoryScreen()),
        '/admin-responders':
            (context) =>
                const AdminThemeWrapper(child: ResponderManagementPage()),
        '/admin-incidents':
            (context) =>
                const AdminThemeWrapper(child: IncidentManagementPage()),

        //RESPONDER
        '/responder-login': (context) => const ResponderLoginScreen(),
        '/responder-signup': (context) => const ResponderSignupPage(),
        '/responder-home': (context) => const ResponderHome(),
        '/responder-profile': (context) => const ResponderProfilePage(),
        '/responder-incidents': (context) => const ResponderIncidentsPage(),
        '/responder-navigation': (context) => const Trackreporter(),

        //  REPORTER
        '/reporter-login': (context) => const LoginScreen(),
        '/reporter-signup': (context) => const SignupScreen(),
        '/reporter-home': (context) => const ReporterHome(),

        // Reporter bottom nav
        '/home': (context) => const ReporterHome(),
        '/report': (context) => const ReportIncidentScreen(),
        '/track': (context) => const TrackResponder(),
        '/history': (context) => const ResponderHistory(),
        '/profile': (context) => const ReporterProfile(),
      },
    );
  }
}
