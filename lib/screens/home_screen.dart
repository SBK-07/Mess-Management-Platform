import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'menu_screen.dart';
import 'feedback_screen.dart';
import 'login_screen.dart';
import '../models/meal_type.dart';
import '../utils/mess_timings.dart';
import 'my_complaints_screen.dart';
import '../services/auth_service.dart';
import 'student_pending_bills_screen.dart';

/// Home screen with bottom navigation for students.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MenuScreen(),
    const FeedbackScreen(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppConstants.headerGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x30E07B39),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🍽️', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hello, ${user?.name ?? 'Student'}!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'What\'s cooking today?',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notifications
                  StreamBuilder<List<NotificationModel>>(
                    stream: NotificationService().getUserNotifications(
                      user?.uid ?? '',
                    ),
                    builder: (context, snapshot) {
                      final notifications = snapshot.data ?? [];
                      final unreadCount = notifications
                          .where((n) => !n.isRead)
                          .length;

                      return PopupMenuButton<String>(
                        icon: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE07B39),
                                      width: 1.5,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        itemBuilder: (context) {
                          if (notifications.isEmpty) {
                            return [
                              PopupMenuItem(
                                enabled: false,
                                child: Text(
                                  'No notifications',
                                  style: GoogleFonts.poppins(
                                    color: AppConstants.textMuted,
                                  ),
                                ),
                              ),
                            ];
                          }

                          return notifications.map((notification) {
                            return PopupMenuItem<String>(
                              value: notification.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (!notification.isRead)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE07B39),
                                            shape: BoxShape.circle,
                                          ),
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: GoogleFonts.poppins(
                                            fontWeight: notification.isRead
                                                ? FontWeight.normal
                                                : FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppConstants.textMuted,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Divider(height: 16),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        onSelected: (id) {
                          NotificationService().markAsRead(id);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu_outlined),
                activeIcon: Icon(Icons.restaurant_menu),
                label: 'Menu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.feedback_outlined),
                activeIcon: Icon(Icons.feedback),
                label: 'Report',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile tab showing user info and logout option.
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Profile card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppConstants.headerGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE07B39).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'S',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Student',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildProfileOption(
            icon: Icons.receipt_long_rounded,
            title: 'View Pending Bills',
            subtitle: 'See month-wise bills and pay online',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentPendingBillsScreen(
                    studentId: user?.uid ?? '',
                    studentName: user?.name ?? 'Student',
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Section header
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Quick Actions', style: AppConstants.headingSmall),
          ),
          const SizedBox(height: 12),

          // Profile options
          _buildProfileOption(
            icon: Icons.calendar_month_outlined,
            title: 'Overall Menu',
            subtitle: 'View full weekly mess menu',
            onTap: () => Navigator.pushNamed(context, '/overall_menu'),
          ),

          _buildProfileOption(
            icon: Icons.access_time_filled_rounded,
            title: 'Mess Timings',
            subtitle: 'Breakfast, lunch & dinner times',
            onTap: () => _showTimingsDialog(context),
          ),

          _buildProfileOption(
            icon: Icons.cancel_schedule_send_outlined,
            title: 'Mess Cancellation',
            subtitle: 'Pre-inform absence to reduce waste',
            onTap: () => Navigator.pushNamed(context, '/mess_cancellation'),
          ),

          _buildProfileOption(
            icon: Icons.history_rounded,
            title: 'My Complaints',
            subtitle:
                '${appState.allComplaints.where((c) => c.studentId == user?.uid).length} complaints submitted',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyComplaintsScreen()),
              );
            },
          ),

          _buildProfileOption(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Security and app preferences',
            onTap: () => _showSettingsSheet(context),
          ),

          _buildProfileOption(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'FAQs and contact',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Logout button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(context, appState);
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.errorColor,
                side: BorderSide(
                  color: AppConstants.errorColor.withOpacity(0.3),
                ),
                backgroundColor: AppConstants.errorColor.withOpacity(0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showTimingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time_filled,
                      color: AppConstants.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Mess Timings',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTimingTable(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.infoColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppConstants.infoColor.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppConstants.infoColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Timings may vary during special events or holidays.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimingTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.05),
          ),
          children: const [
            _PaddingText('Meal', bold: true, size: 12),
            _PaddingText('Working Days', bold: true, size: 12),
            _PaddingText('Saturday', bold: true, size: 12),
            _PaddingText('Sun/Hol', bold: true, size: 12),
          ],
        ),
        for (var meal in MealType.values)
          TableRow(
            children: [
              _PaddingText(
                meal.displayName,
                bold: true,
                size: 12,
                color: AppConstants.primaryColor,
              ),
              _PaddingText(
                MessTimings.timings[meal]![DayType.workingDays]!,
                size: 12,
              ),
              _PaddingText(
                MessTimings.timings[meal]![DayType.saturday]!,
                size: 12,
              ),
              _PaddingText(
                MessTimings.timings[meal]![DayType.sundayHolidays]!,
                size: 12,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppConstants.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: AppConstants.primaryColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppConstants.bodyLarge.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppConstants.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppConstants.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppConstants.primaryColor,
                  ),
                  title: Text(
                    'Change Password',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Update password for your next login',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => const _ChangePasswordDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppConstants.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppConstants.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              appState.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaddingText extends StatelessWidget {
  final String text;
  final bool bold;
  final double size;
  final Color? color;
  const _PaddingText(
    this.text, {
    this.bold = false,
    this.size = 11,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          fontSize: size,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CHANGE PASSWORD DIALOG
// ─────────────────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  String get _pw => _newPwCtrl.text;
  bool get _hasMinLength => _pw.length >= 8;
  bool get _hasUppercase => _pw.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _pw.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _pw.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _pw.contains(RegExp(r'[!@#\$%\^&\*\(\),.?":{}|<>_\-\+=\[\]\\/~`]'));
  bool get _passwordsMatch => _pw.isNotEmpty && _pw == _confirmPwCtrl.text;
  bool get _allMet =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecial &&
      _passwordsMatch;

  int get _strengthLevel {
    int s = 0;
    if (_hasMinLength) s++;
    if (_hasUppercase) s++;
    if (_hasLowercase) s++;
    if (_hasNumber) s++;
    if (_hasSpecial) s++;
    return s;
  }

  Color get _strengthColor {
    switch (_strengthLevel) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber.shade700;
      case 4:
        return Colors.lightGreen;
      case 5:
        return const Color(0xFF2E7D32);
      default:
        return Colors.grey;
    }
  }

  String get _strengthLabel {
    switch (_strengthLevel) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _newPwCtrl.addListener(() => setState(() {}));
    _confirmPwCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_allMet || _currentPwCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.changePassword(
        currentPassword: _currentPwCtrl.text,
        newPassword: _pw,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password changed successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String msg = 'Failed to change password';
        final err = e.toString();
        if (err.contains('wrong-password') ||
            err.contains('invalid-credential')) {
          msg = 'Current password is incorrect';
        } else if (err.contains('weak-password')) {
          msg = 'Password is too weak. Try a stronger one.';
        } else if (err.contains('requires-recent-login')) {
          msg =
              'Please logout and login again, then try changing your password.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppConstants.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Change Password',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        Text(
                          'Update your account password',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Current Password ──
              _buildPasswordField(
                controller: _currentPwCtrl,
                label: 'Current Password',
                icon: Icons.lock_rounded,
                show: _showCurrent,
                onToggle: () => setState(() => _showCurrent = !_showCurrent),
              ),
              const SizedBox(height: 20),

              // ── New Password ──
              _buildPasswordField(
                controller: _newPwCtrl,
                label: 'New Password',
                icon: Icons.lock_open_rounded,
                show: _showNew,
                onToggle: () => setState(() => _showNew = !_showNew),
              ),
              const SizedBox(height: 14),

              // ── Strength Bar + Constraints ──
              if (_pw.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _strengthLevel / 5,
                          backgroundColor: Colors.grey.shade200,
                          color: _strengthColor,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _strengthLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _strengthColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _constraintRow(_hasMinLength, 'At least 8 characters'),
                _constraintRow(
                  _hasUppercase,
                  'Contains uppercase letter (A-Z)',
                ),
                _constraintRow(
                  _hasLowercase,
                  'Contains lowercase letter (a-z)',
                ),
                _constraintRow(_hasNumber, 'Contains a number (0-9)'),
                _constraintRow(
                  _hasSpecial,
                  'Contains special character (!@#\$%...)',
                ),
                const SizedBox(height: 12),
              ],

              // ── Confirm Password ──
              _buildPasswordField(
                controller: _confirmPwCtrl,
                label: 'Confirm New Password',
                icon: Icons.check_circle_outline_rounded,
                show: _showConfirm,
                onToggle: () => setState(() => _showConfirm = !_showConfirm),
                errorText: _confirmPwCtrl.text.isNotEmpty && !_passwordsMatch
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 28),

              // ── Submit Button ──
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (_allMet && _currentPwCtrl.text.isNotEmpty && !_isLoading)
                      ? _submit
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _allMet ? 2 : 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Update Password',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool show,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: AppConstants.primaryColor.withOpacity(0.7),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 20,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF7F3EE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        errorText: errorText,
        errorStyle: GoogleFonts.poppins(fontSize: 11),
      ),
    );
  }

  Widget _constraintRow(bool met, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: met ? AppConstants.successColor : Colors.transparent,
              border: Border.all(
                color: met ? AppConstants.successColor : Colors.grey.shade400,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: met
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: met
                    ? AppConstants.successColor
                    : AppConstants.textSecondary,
                fontWeight: met ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
