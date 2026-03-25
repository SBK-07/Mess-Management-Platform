import 'package:flutter/material.dart';

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
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the backend API URL')),
      );
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL must start with http:// or https://')),
      );
      return;
    }

    setState(() => _isLoading = true);
    widget.onConfigured(url);
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
