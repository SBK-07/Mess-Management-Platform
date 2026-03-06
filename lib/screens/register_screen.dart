import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Staff Registration Screen (Profile Completion).
///
/// Shown to users who have authenticated (Google/Email) but have no profile.
/// Collects details and creates a 'pending' staff account.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _staffIdCtrl = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    final user = Provider.of<AppState>(context, listen: false).currentFirebaseUser;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _phoneCtrl.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _staffIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<AppState>(context, listen: false).registerStaffDetails(
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        staffId: _staffIdCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/pending');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: const Color(0xFF6B5B50),
        fontSize: 14,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(icon, color: const Color(0xFFE07B39), size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      filled: true,
      fillColor: const Color(0xFFF7F3EE),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE07B39), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/food_background.png',
            fit: BoxFit.cover,
            colorBlendMode: BlendMode.darken,
            color: Colors.black.withOpacity(0.15),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE07B39).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 36,
                                color: Color(0xFFE07B39),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Complete Registration',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D1810),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Fill in your details to complete\nyour staff registration',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF6B5B50),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 28),

                            TextFormField(
                              controller: _nameCtrl,
                              style: GoogleFonts.poppins(fontSize: 14),
                              decoration: _inputDecoration('Full Name', Icons.person_outline_rounded),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _staffIdCtrl,
                              style: GoogleFonts.poppins(fontSize: 14),
                              decoration: _inputDecoration('Staff ID', Icons.badge_outlined),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.poppins(fontSize: 14),
                              decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE07B39),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(0xFFE07B39).withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.send_rounded, size: 18),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Submit Request',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
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
    );
  }
}
