import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class StaffSettingsScreen extends StatelessWidget {
  const StaffSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Settings'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppConstants.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Staff',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Security', style: AppConstants.headingSmall),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppConstants.softShadow,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppConstants.primaryColor,
                ),
                title: Text(
                  'Change Password',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Use your current password and set a new one',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const _StaffChangePasswordDialog(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffChangePasswordDialog extends StatefulWidget {
  const _StaffChangePasswordDialog();

  @override
  State<_StaffChangePasswordDialog> createState() =>
      _StaffChangePasswordDialogState();
}

class _StaffChangePasswordDialogState extends State<_StaffChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _validLength => _newCtrl.text.trim().length >= 8;
  bool get _sameAsConfirm => _newCtrl.text == _confirmCtrl.text;

  Future<void> _submit() async {
    if (_currentCtrl.text.isEmpty || !_validLength || !_sameAsConfirm) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.instance.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully. Use it on next login.'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      String message = 'Unable to change password. Try again.';
      final err = e.toString();
      if (err.contains('wrong-password') || err.contains('invalid-credential')) {
        message = 'Current password is incorrect.';
      } else if (err.contains('weak-password')) {
        message = 'New password is too weak.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Change Password',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentCtrl,
            obscureText: !_showCurrent,
            decoration: InputDecoration(
              labelText: 'Current Password',
              suffixIcon: IconButton(
                icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showCurrent = !_showCurrent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newCtrl,
            obscureText: !_showNew,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'New Password',
              helperText: 'Minimum 8 characters',
              suffixIcon: IconButton(
                icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showNew = !_showNew),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmCtrl,
            obscureText: !_showConfirm,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              suffixIcon: IconButton(
                icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showConfirm = !_showConfirm),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              !_validLength
                  ? 'New password must be at least 8 characters.'
                  : !_sameAsConfirm
                      ? 'New password and confirm password must match.'
                      : 'Password looks good.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: (!_validLength || !_sameAsConfirm)
                    ? AppConstants.errorColor
                    : AppConstants.successColor,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Password'),
        ),
      ],
    );
  }
}
