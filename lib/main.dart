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
import 'screens/staff_student_management_screen.dart';
import 'screens/home_screen.dart'; // Student Home
import 'screens/overall_menu_screen.dart';
import 'screens/mess_cancellation_screen.dart';
import 'utils/upload_menu.dart';
import 'utils/constants.dart'; // AppTheme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Temporary seed call as requested
  await MenuUploader.uploadMenu();

  runApp(const MessManagementApp());
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
          '/staff/students': (context) => const StaffStudentManagementScreen(),
          '/home': (context) => const HomeScreen(),
          '/overall_menu': (context) => const OverallMenuScreen(),
          '/mess_cancellation': (context) => const MessCancellationScreen(),
        },
      ),
    );
  }
}
