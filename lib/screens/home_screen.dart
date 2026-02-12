import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../models/menu_item.dart';
import 'menu_screen.dart';
import 'feedback_screen.dart';
import 'login_screen.dart';
import '../models/meal_type.dart';
import '../utils/mess_timings.dart';
import 'my_complaints_screen.dart';

/// Home screen with bottom navigation for students.
///
/// Contains tabs for Menu, Report (feedback), and Profile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Tab screens
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
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🍽️ ', style: TextStyle(fontSize: 24)),
            Text(
              'Hello, ${user?.name ?? 'Student'}!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications (placeholder)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
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
          const SizedBox(height: AppConstants.paddingLarge),

          // Profile avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppConstants.primaryColor, width: 3),
            ),
            child: Center(
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'S',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // User name
          Text(user?.name ?? 'Student', style: AppConstants.headingLarge),
          const SizedBox(height: 4),
          Text(
            '@${user?.email.split('@')[0] ?? 'student'}',
            style: AppConstants.bodyMedium,
          ),

          const SizedBox(height: AppConstants.paddingXLarge),

          // Profile options
          _buildProfileOption(
            icon: Icons.calendar_month_outlined,
            title: 'Overall Menu',
            subtitle: 'View full weekly mess menu',
            onTap: () => Navigator.pushNamed(context, '/overall_menu'),
          ),

          _buildProfileOption(
            icon: Icons.access_time_filled,
            title: 'Mess Timings',
            subtitle: 'View breakfast, lunch, and dinner times',
            onTap: () => _showTimingsDialog(context),
          ),

          _buildProfileOption(
            icon: Icons.history,
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
            subtitle: 'App preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),

          _buildProfileOption(
            icon: Icons.help_outline,
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

          const SizedBox(height: AppConstants.paddingLarge),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutDialog(context, appState);
              },
              icon: const Icon(Icons.logout, color: AppConstants.errorColor),
              label: const Text(
                'Logout',
                style: TextStyle(color: AppConstants.errorColor),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConstants.errorColor),
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time_filled,
                      color: AppConstants.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Mess Timings',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTimingTable(),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Note: Timings may vary slightly during special events or holidays.',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
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
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.05),
          ),
          children: const [
            _PaddingText('Meal', bold: true, size: 14),
            _PaddingText('Working Days', bold: true, size: 14),
            _PaddingText('Saturday', bold: true, size: 14),
            _PaddingText('Sun/Hol', bold: true, size: 14),
          ],
        ),
        // Rows
        for (var meal in MealType.values)
          TableRow(
            children: [
              _PaddingText(
                meal.displayName,
                bold: true,
                size: 13,
                color: AppConstants.primaryColor,
              ),
              _PaddingText(
                MessTimings.timings[meal]![DayType.workingDays]!,
                size: 13,
              ),
              _PaddingText(
                MessTimings.timings[meal]![DayType.saturday]!,
                size: 13,
              ),
              _PaddingText(
                MessTimings.timings[meal]![DayType.sundayHolidays]!,
                size: 13,
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
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: AppConstants.cardShadow,
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Icon(icon, color: AppConstants.primaryColor),
        ),
        title: Text(title, style: AppConstants.bodyLarge),
        subtitle: Text(subtitle, style: AppConstants.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            ),
            child: const Text('Logout'),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: size,
          color: color,
        ),
      ),
    );
  }
}
