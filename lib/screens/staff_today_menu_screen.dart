import 'package:flutter/material.dart';
import 'menu_screen.dart';
import '../utils/constants.dart';

class StaffTodayMenuScreen extends StatelessWidget {
  const StaffTodayMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Mess Menu"),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const MenuScreen(),
    );
  }
}
