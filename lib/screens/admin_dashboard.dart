import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complaint.dart';
import '../models/menu_item.dart';
import '../models/replacement.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/stat_card.dart';
import '../widgets/complaint_card.dart';
import 'login_screen.dart';

/// Admin dashboard for viewing complaints and statistics.
/// 
/// Displays total complaints, most complained item, and replacement pool usage.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('📊 ', style: TextStyle(fontSize: 24)),
            Text('Admin Dashboard'),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh data (triggers rebuild)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, appState),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            _buildWelcomeHeader(user?.name ?? 'Admin'),
            const SizedBox(height: AppConstants.paddingLarge),

            // Statistics grid
            _buildSectionTitle('Overview Statistics'),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildStatisticsGrid(appState),
            const SizedBox(height: AppConstants.paddingLarge),

            // Most complained item
            _buildSectionTitle('Most Complained Item'),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildMostComplainedItem(appState),
            const SizedBox(height: AppConstants.paddingLarge),

            // Complaints by issue type
            _buildSectionTitle('Complaints by Issue Type'),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildIssueTypeBreakdown(appState),
            const SizedBox(height: AppConstants.paddingLarge),

            // Replacement pool usage
            _buildSectionTitle('Replacement Pool Usage'),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildPoolUsage(appState),
            const SizedBox(height: AppConstants.paddingLarge),

            // Recent complaints
            _buildSectionTitle('Recent Complaints'),
            const SizedBox(height: AppConstants.paddingSmall),
            _buildRecentComplaints(appState),
            
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppConstants.appGradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: AppConstants.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: const Center(
              child: Text('👨‍💼', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppConstants.headingSmall,
    );
  }

  Widget _buildStatisticsGrid(AppState appState) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppConstants.paddingSmall,
      mainAxisSpacing: AppConstants.paddingSmall,
      childAspectRatio: 1.3,
      children: [
        StatCard(
          icon: Icons.warning_amber_rounded,
          value: '${appState.totalComplaints}',
          label: 'Total Complaints',
          color: AppConstants.errorColor,
        ),
        StatCard(
          icon: Icons.swap_horiz,
          value: '${appState.totalReplacementsIssued}',
          label: 'Replacements Issued',
          color: AppConstants.successColor,
        ),
        StatCard(
          icon: Icons.restaurant,
          value: '${appState.todaysMenu.length}',
          label: 'Menu Items Today',
          color: AppConstants.primaryColor,
        ),
        StatCard(
          icon: Icons.inventory_2,
          value: '${appState.allReplacements.length}',
          label: 'Replacement Options',
          color: AppConstants.secondaryColor,
        ),
      ],
    );
  }

  Widget _buildMostComplainedItem(AppState appState) {
    final mostComplained = appState.mostComplainedItem;

    if (mostComplained == null) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('✓', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            const Expanded(
              child: Text(
                'No complaints yet! All items are satisfactory.',
                style: AppConstants.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    final complaintCount = appState.allComplaints
        .where((c) => c.menuItem.id == mostComplained.id)
        .length;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppConstants.errorColor.withOpacity(0.3)),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppConstants.errorColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                mostComplained.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mostComplained.name,
                  style: AppConstants.headingSmall,
                ),
                Text(
                  '${mostComplained.mealType.displayName} item',
                  style: AppConstants.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppConstants.errorColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$complaintCount complaints',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueTypeBreakdown(AppState appState) {
    final issueTypeCounts = appState.complaintsByIssueType;
    final total = issueTypeCounts.values.fold(0, (sum, count) => sum + count);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        children: IssueType.values.map((issueType) {
          final count = issueTypeCounts[issueType] ?? 0;
          final percentage = total > 0 ? (count / total) : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingSmall,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      issueType.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issueType.displayName,
                        style: AppConstants.bodyLarge,
                      ),
                    ),
                    Text(
                      '$count',
                      style: AppConstants.headingSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getIssueColor(issueType),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPoolUsage(AppState appState) {
    final poolUsage = appState.replacementUsageByPool;

    return Row(
      children: PoolType.values.map((poolType) {
        final count = poolUsage[poolType] ?? 0;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: poolType != PoolType.protein
                  ? AppConstants.paddingSmall
                  : 0,
            ),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: _getPoolColor(poolType).withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              border: Border.all(
                color: _getPoolColor(poolType).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  poolType.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count',
                  style: AppConstants.headingMedium.copyWith(
                    color: _getPoolColor(poolType),
                  ),
                ),
                Text(
                  poolType.displayName.replaceAll(' Pool', ''),
                  style: AppConstants.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentComplaints(AppState appState) {
    final complaints = appState.allComplaints.reversed.take(5).toList();

    if (complaints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: AppConstants.cardShadow,
        ),
        child: const Center(
          child: Column(
            children: [
              Text('🎉', style: TextStyle(fontSize: 48)),
              SizedBox(height: AppConstants.paddingSmall),
              Text(
                'No complaints yet!',
                style: AppConstants.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: complaints.map((complaint) {
        return ComplaintCard(complaint: complaint);
      }).toList(),
    );
  }

  Color _getIssueColor(IssueType issueType) {
    switch (issueType) {
      case IssueType.taste:
        return Colors.orange;
      case IssueType.hygiene:
        return Colors.red;
      case IssueType.quantity:
        return Colors.blue;
    }
  }

  Color _getPoolColor(PoolType poolType) {
    switch (poolType) {
      case PoolType.snack:
        return AppConstants.snackPoolColor;
      case PoolType.fruit:
        return AppConstants.fruitPoolColor;
      case PoolType.protein:
        return AppConstants.proteinPoolColor;
    }
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
