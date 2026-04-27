import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:device_preview/device_preview.dart';
import 'package:safetrack/utils/app_colors.dart';
import 'services/google_auth_service.dart';

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

  // 🔐 Restore Google auth session from secure storage (auto-login)
  await GoogleAuthService().init();

  runApp(
    DevicePreview(
      // ✅ Enabled ONLY in debug/development — disabled automatically in release
      enabled: kDebugMode,

      // 📸 Optional: capture screenshots per device
      // tools: const [...DevicePreview.defaultTools],

      builder: (context) => const SafeTrackApp(),
    ),
  );
}

class SafeTrackApp extends StatelessWidget {
  const SafeTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ─── DevicePreview hooks ───────────────────────────────
      // Makes the app respond to DevicePreview's simulated locale
      locale: DevicePreview.locale(context),
      // Injects the simulated device's MediaQuery (screen size, pixel ratio…)
      builder: DevicePreview.appBuilder,
      // ──────────────────────────────────────────────────────

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
        '/': (context) => const _SplashRouter(),
        '/role-selection': (context) => const RoleSelectionScreen(),

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

// ─────────────────────────────────────────────────────────────
// SplashRouter — Handles auto-login on app startup
// ─────────────────────────────────────────────────────────────
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final googleAuth = GoogleAuthService();

    // Verify whether the stored JWT is still valid
    final bool valid = await googleAuth.verifyStoredToken();

    if (!mounted) return;

    if (valid && googleAuth.currentUser != null) {
      final role = googleAuth.currentUser!.role;

      // Route to the correct home screen based on role
      switch (role) {
        case 'responder':
          Navigator.pushReplacementNamed(context, '/responder-home');
          break;
        case 'reporter':
        default:
          Navigator.pushReplacementNamed(context, '/reporter-home');
          break;
      }
    } else {
      // No valid session — show role selection
      Navigator.pushReplacementNamed(context, '/role-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Brief loading screen while session is verified
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading SafeTrack...'),
          ],
        ),
      ),
    );
  }
}
