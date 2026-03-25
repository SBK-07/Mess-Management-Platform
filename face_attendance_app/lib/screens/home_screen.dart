import 'package:flutter/material.dart';

import 'camera_screen.dart';

class FaceAttendanceHomeScreen extends StatefulWidget {
  final String apiBaseUrl;
  final VoidCallback onResetConfig;

  const FaceAttendanceHomeScreen({
    super.key,
    required this.apiBaseUrl,
    required this.onResetConfig,
  });

  @override
  State<FaceAttendanceHomeScreen> createState() => _FaceAttendanceHomeScreenState();
}

class _FaceAttendanceHomeScreenState extends State<FaceAttendanceHomeScreen> {
  final TextEditingController _studentIdCtrl = TextEditingController();

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    super.dispose();
  }

  void _openRegistration() {
    final studentId = _studentIdCtrl.text.trim();
    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter studentId for face registration.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          apiBaseUrl: widget.apiBaseUrl,
          mode: CameraFlowMode.registerFace,
          studentId: studentId,
        ),
      ),
    );
  }

  void _openAttendanceMarking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          apiBaseUrl: widget.apiBaseUrl,
          mode: CameraFlowMode.markAttendance,
        ),
      ),
    );
  }

  void _changeBackendUrl() {
    widget.onResetConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Attendance'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Settings'),
                onTap: _changeBackendUrl,
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // API URL Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✓ Backend Connected',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.apiBaseUrl,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Student ID Input
            const Text('Student ID (required for registration)'),
            const SizedBox(height: 8),
            TextField(
              controller: _studentIdCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. STU001',
              ),
            ),
            const SizedBox(height: 16),

            // Register Face Button
            ElevatedButton(
              onPressed: _openRegistration,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.face),
                  SizedBox(width: 8),
                  Text('Register Face'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Mark Attendance Button
            ElevatedButton(
              onPressed: _openAttendanceMarking,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle),
                  SizedBox(width: 8),
                  Text('Mark Attendance'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
