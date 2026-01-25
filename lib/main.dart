import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'utils/constants.dart';

/// Smart Mess Management System
/// 
/// A Flutter prototype for managing mess operations with features:
/// - Student login and menu viewing
/// - Dissatisfaction reporting with issue types
/// - Food replacement pool selection
/// - Admin dashboard with statistics
/// 
/// This app uses Provider for state management and follows
/// a modular architecture with separate screens, models, services, and widgets.
void main() {
  runApp(const MessManagementApp());
}

/// Root widget of the application.
/// 
/// Sets up the Provider for state management and configures
/// the MaterialApp with the food-themed color scheme.
class MessManagementApp extends StatelessWidget {
  const MessManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Create and provide the global app state
      create: (_) => AppState(),
      child: MaterialApp(
        // App configuration
        title: 'Smart Mess Management',
        debugShowCheckedModeBanner: false,
        
        // Apply the custom food-themed theme
        theme: AppTheme.lightTheme,
        
        // Start with the login screen
        home: const LoginScreen(),
      ),
    );
  }
}
