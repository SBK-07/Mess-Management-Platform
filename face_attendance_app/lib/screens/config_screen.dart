import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiConfigScreen extends StatefulWidget {
  final ValueChanged<String> onConfigured;

  const ApiConfigScreen({
    super.key,
    required this.onConfigured,
  });

  @override
  State<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends State<ApiConfigScreen> {
  late TextEditingController _urlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: 'http://192.168.1.');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _saveAndProceed() async {
    final rawUrl = _urlController.text.trim();

    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the backend API URL')),
      );
      return;
    }

    if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL must start with http:// or https://')),
      );
      return;
    }

    final normalized = _normalizeBaseUrl(rawUrl);
    if (normalized == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL. Example: http://10.159.231.179:3000')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final health = await http.get(
        Uri.parse('$normalized/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      final decoded = jsonDecode(health.body);
      final isOk = health.statusCode >= 200 &&
          health.statusCode < 300 &&
          decoded is Map<String, dynamic> &&
          decoded['success'] == true;

      if (!isOk) {
        throw Exception('Health check failed (${health.statusCode}).');
      }

      widget.onConfigured(normalized);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot reach backend at $normalized. Ensure backend is running and phone/laptop are on same network.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return null;
    }

    if (!uri.hasPort || uri.port == 0) {
      return Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: 3000,
      ).toString();
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Configuration'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.settings,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Backend API Configuration',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your laptop or backend server IP address with port',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _urlController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Backend API URL',
                hintText: 'http://192.168.1.5:3000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.api),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ℹ️ How to find your laptop IP:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Windows: Open Command Prompt and run: ipconfig\n'
                    '• macOS/Linux: Open Terminal and run: ifconfig\n'
                    '• Look for IPv4 Address (e.g., 192.168.1.5)\n'
                    '• Ensure your phone is on the same WiFi network',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAndProceed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
