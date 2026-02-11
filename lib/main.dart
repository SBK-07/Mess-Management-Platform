import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'utils/constants.dart';

/// Smart Mess Management System
///
/// A Flutter app for managing mess operations with Firebase backend.
/// Uses Firebase Auth for authentication and Cloud Firestore for data.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MessManagementApp());
}

/// Root widget of the application.
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
        home: const LoginScreen(),
      ),
    );
  }
}
