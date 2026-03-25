import 'package:flutter/material.dart';

import 'screens/config_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FaceAttendanceApp());
}

class FaceAttendanceApp extends StatelessWidget {
  const FaceAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FaceAttendanceRoot(),
    );
  }
}

class FaceAttendanceRoot extends StatefulWidget {
  const FaceAttendanceRoot({super.key});

  @override
  State<FaceAttendanceRoot> createState() => _FaceAttendanceRootState();
}

class _FaceAttendanceRootState extends State<FaceAttendanceRoot> {
  String? _apiBaseUrl;

  void _onConfigured(String apiBaseUrl) {
    setState(() {
      _apiBaseUrl = apiBaseUrl;
    });
  }

  void _onResetConfig() {
    setState(() {
      _apiBaseUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_apiBaseUrl == null || _apiBaseUrl!.isEmpty) {
      return ApiConfigScreen(onConfigured: _onConfigured);
    }

    return FaceAttendanceHomeScreen(
      apiBaseUrl: _apiBaseUrl!,
      onResetConfig: _onResetConfig,
    );
  }
}
