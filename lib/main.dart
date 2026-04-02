import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/register_screen.dart'; // Registration/Profile Completion
import 'screens/pending_screen.dart'; // Pending Approval
import 'screens/admin_dashboard.dart';
import 'screens/staff_home_screen.dart';
import 'screens/staff_settings_screen.dart';
import 'screens/staff_student_management_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/home_screen.dart'; // Student Home
import 'screens/overall_menu_screen.dart';
import 'screens/mess_cancellation_screen.dart';
import 'utils/upload_menu.dart';
import 'utils/constants.dart'; // AppTheme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase initialization failed: $e');
    debugPrintStack(stackTrace: st);
  }

  runApp(const MessManagementApp());

  // Do not block first render on data seeding. If this fails, login screen still loads.
  unawaited(_seedMenuSafely());
}

Future<void> _seedMenuSafely() async {
  if (Firebase.apps.isEmpty) return;

  try {
    await MenuUploader.uploadMenu();
  } catch (e, st) {
    debugPrint('Menu seed skipped: $e');
    debugPrintStack(stackTrace: st);
  }
}

class MessManagementApp extends StatelessWidget {
  const MessManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Smart Mess Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // Define named routes for navigation
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/signup': (context) => const EmailSignUpScreen(),
          '/register': (context) => const RegisterScreen(),
          '/pending': (context) => const PendingScreen(),
          '/admin': (context) => const AdminDashboard(),
          '/staff': (context) => const StaffHomeScreen(),
          '/staff/settings': (context) => const StaffSettingsScreen(),
          '/staff/students': (context) => const StaffStudentManagementScreen(),
          '/analytics': (context) => const AnalyticsDashboardScreen(
                isAdminView: false,
              ),
          '/home': (context) => const HomeScreen(),
          '/overall_menu': (context) => const OverallMenuScreen(),
          '/mess_cancellation': (context) => const MessCancellationScreen(),
        },
      ),
    );
  }
}
