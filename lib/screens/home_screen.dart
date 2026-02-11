import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import 'menu_screen.dart';
import 'feedback_screen.dart';
import 'login_screen.dart';

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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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
              border: Border.all(
                color: AppConstants.primaryColor,
                width: 3,
              ),
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
          Text(
            user?.name ?? 'Student',
            style: AppConstants.headingLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '@${user?.email.split('@')[0] ?? 'student'}',
            style: AppConstants.bodyMedium,
          ),
          
          const SizedBox(height: AppConstants.paddingXLarge),
          
          // Profile options
          _buildProfileOption(
            icon: Icons.history,
            title: 'My Complaints',
            subtitle: '${appState.allComplaints.where((c) => c.studentId == user?.uid).length} complaints submitted',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Complaint history feature coming soon!'),
                  duration: Duration(seconds: 1),
                ),
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
          child: Icon(
            icon,
            color: AppConstants.primaryColor,
          ),
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
