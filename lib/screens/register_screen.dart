import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';


/// Staff registration screen.
///
/// Collects name, email, phone, and staff ID, then submits a request
/// to the `staff_requests` Firestore collection. No Auth account is created.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _staffIdCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _staffIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.submitStaffRequest(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        staffId: _staffIdCtrl.text,
      );

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Request Sent'),
            ],
          ),
          content: const Text(
            'Your registration request has been sent to the administrator for approval.\n\n'
            'You will be notified once your account is approved.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to login
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _isLoading = false;
        _errorMessage = msg.startsWith('Exception: ')
            ? msg.substring(11)
            : 'Registration failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/food_background.png', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.50),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Staff Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.2,
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_add_rounded,
                                      color: Colors.white, size: 40),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Register as Staff',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Submit your details for admin approval',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  _buildField(
                                    controller: _nameCtrl,
                                    label: 'Full Name',
                                    hint: 'Enter your name',
                                    icon: Icons.person_rounded,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Name is required'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),

                                  _buildField(
                                    controller: _emailCtrl,
                                    label: 'Email',
                                    hint: 'Enter your email',
                                    icon: Icons.email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  _buildField(
                                    controller: _phoneCtrl,
                                    label: 'Phone',
                                    hint: 'Enter your phone number',
                                    icon: Icons.phone_rounded,
                                    keyboardType: TextInputType.phone,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Phone is required'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),

                                  _buildField(
                                    controller: _staffIdCtrl,
                                    label: 'Staff ID',
                                    hint: 'Enter your staff ID',
                                    icon: Icons.badge_rounded,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                            ? 'Staff ID is required'
                                            : null,
                                  ),

                                  // Error
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 24),

                                  // Submit button
                                  Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: _isLoading
                                          ? null
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFFE07B39),
                                                Color(0xFFD4582A),
                                              ],
                                            ),
                                      color: _isLoading
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : null,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: _isLoading
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: const Color(0xFFE07B39)
                                                    .withValues(alpha: 0.40),
                                                blurRadius: 16,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isLoading ? null : _handleSubmit,
                                        borderRadius: BorderRadius.circular(14),
                                        child: Center(
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : const Text(
                                                  'Submit Request',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          cursorColor: const Color(0xFFE07B39),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon,
                color: Colors.white.withValues(alpha: 0.55), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFE07B39), width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
