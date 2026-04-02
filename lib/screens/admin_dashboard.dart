import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/user.dart';
import '../widgets/stat_card.dart';
import '../models/issue_type.dart';
import '../models/food_report.dart';
import '../models/meal_type.dart';
import '../models/menu_item.dart';
import 'package:intl/intl.dart';
import '../models/cancellation.dart';
import '../services/cancellation_service.dart';
import 'package:file_picker/file_picker.dart';
import '../services/bulk_import_service.dart';
import 'analytics_dashboard_screen.dart';

/// Admin Dashboard Screen.
/// Includes Overview, Staff Requests, and Student Creation.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    unawaited(
      Provider.of<AppState>(
        context,
        listen: false,
      ).loadDailyMenuFromFirestore(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleLogout() {
    Provider.of<AppState>(context, listen: false).logout();
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFFE07B39),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AnalyticsDashboardScreen(
                    isAdminView: true,
                  ),
                ),
              );
            },
            tooltip: 'Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
            Tab(icon: Icon(Icons.people_outline_rounded), text: 'Staff'),
            Tab(icon: Icon(Icons.school_rounded), text: 'Students'),
            Tab(icon: Icon(Icons.feedback_outlined), text: 'Reports'),
            Tab(icon: Icon(Icons.cancel_outlined), text: 'Cancellations'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFDF6F0)),
        child: TabBarView(
          controller: _tabController,
          children: [
            const _OverviewTab(),
            const _StaffRequestsTab(),
            const _AddStudentTab(),
            const _FoodReportsTab(),
            const _CancellationsTab(),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Complaint stats
    final totalComplaints = appState.totalComplaints;
    final complaintsByType = appState.complaintsByIssueType;
    final tasteIssues = complaintsByType[IssueType.taste] ?? 0;
    final hygieneIssues = complaintsByType[IssueType.hygiene] ?? 0;
    final portionSizeIssues = complaintsByType[IssueType.portionSize] ?? 0;

    // Replacement stats
    final totalReplacements = appState.totalReplacementsIssued;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              StatCard(
                label: 'Total Complaints',
                value: '$totalComplaints',
                icon: Icons.assignment_late_outlined,
                color: Colors.redAccent,
              ),
              StatCard(
                label: 'Replacements',
                value: '$totalReplacements',
                icon: Icons.swap_horiz_rounded,
                color: Colors.blueAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Complaint Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  'Taste',
                  '$tasteIssues',
                  Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Hygiene',
                  '$hygieneIssues',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  'Portion',
                  '$portionSizeIssues',
                  Colors.purpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Overall Menu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/overall_menu'),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open Weekly Menu'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.2)),
            ),
            child: Builder(
              builder: (context) {
                final todaysMenu = appState.firestoreDailyMenu;
                if (appState.isMenuLoading) {
                  return const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (todaysMenu.isEmpty) {
                  return const Text(
                    'Today\'s Firestore menu is not available yet. Use Open Weekly Menu to verify uploaded data.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  );
                }

                final grouped = <MealType, List<MenuItem>>{};
                for (final meal in MealType.values) {
                  grouped[meal] = todaysMenu
                      .where((item) => item.mealType == meal)
                      .toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: MealType.values.map((meal) {
                    final items = grouped[meal] ?? const <MenuItem>[];
                    final itemNames = items.map((e) => e.name).join(', ');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                          children: [
                            TextSpan(
                              text: '${meal.displayName}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE07B39),
                              ),
                            ),
                            TextSpan(
                              text: itemNames.isEmpty ? '-' : itemNames,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _StaffRequestsTab extends StatelessWidget {
  const _StaffRequestsTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return StreamBuilder<List<AppUser>>(
      stream: appState.pendingStaffUsers,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading requests:\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(
                            0xFFE07B39,
                          ).withOpacity(0.1),
                          child: const Icon(
                            Icons.person_outline,
                            color: Color(0xFFE07B39),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Applied: ${user.createdAt.toString().split('.')[0]}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (user.staffId != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ID: ${user.staffId}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          user.phone.isEmpty ? 'N/A' : user.phone,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _rejectUser(context, user.uid),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _approveUser(context, user.uid),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approveUser(BuildContext context, String uid) async {
    try {
      await Provider.of<AppState>(context, listen: false).approveUser(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff approved successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectUser(BuildContext context, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: const Text(
          'Are you sure you want to reject (and delete) this request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await Provider.of<AppState>(context, listen: false).rejectUser(uid);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Request rejected')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _AddStudentTab extends StatefulWidget {
  const _AddStudentTab();

  @override
  State<_AddStudentTab> createState() => _AddStudentTabState();
}

class _AddStudentTabState extends State<_AddStudentTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub-tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _subTabController,
            indicatorColor: const Color(0xFFE07B39),
            labelColor: const Color(0xFFE07B39),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.people_rounded, size: 20),
                text: 'All Students',
              ),
              Tab(
                icon: Icon(Icons.person_add_rounded, size: 20),
                text: 'Add Student',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _AllStudentsView(
                onGoToManualAdd: () => _subTabController.animateTo(1),
              ),
              _AddStudentFormView(
                onGoToManualAdd: () => _subTabController.animateTo(1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ALL STUDENTS VIEW — Lists all students with search & edit
// ─────────────────────────────────────────────────────────────

class _AllStudentsView extends StatefulWidget {
  final VoidCallback onGoToManualAdd;
  const _AllStudentsView({required this.onGoToManualAdd});

  @override
  State<_AllStudentsView> createState() => _AllStudentsViewState();
}

class _AllStudentsViewState extends State<_AllStudentsView> {
  String _searchQuery = '';
  String _filterDept = 'All';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Column(
      children: [
        // Search & filter bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Colors.white,
          child: Row(
            children: [
              // Search field
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, or ID...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F3EE),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bulk import button
              ElevatedButton.icon(
                onPressed: () => _triggerBulkImport(
                  context,
                  onGoToManualAdd: widget.onGoToManualAdd,
                ),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Bulk Import'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07B39),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Student list
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: appState.allStudents,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE07B39)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text('Error: ${snapshot.error}'),
                    ],
                  ),
                );
              }

              final allStudents = snapshot.data ?? [];

              // Get unique departments for the filter chips
              final departments = <String>{'All'};
              for (final s in allStudents) {
                if (s.department != null && s.department!.isNotEmpty) {
                  departments.add(s.department!);
                }
              }

              // Apply search + filter
              final filtered = allStudents.where((s) {
                // Department filter
                if (_filterDept != 'All' && s.department != _filterDept) {
                  return false;
                }
                // Search filter
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery;
                  return s.name.toLowerCase().contains(q) ||
                      s.email.toLowerCase().contains(q) ||
                      (s.digitalId ?? '').toLowerCase().contains(q) ||
                      (s.rollNo ?? '').toLowerCase().contains(q);
                }
                return true;
              }).toList();

              return Column(
                children: [
                  // Department filter chips
                  if (departments.length > 2)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      color: Colors.white,
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: departments.map((dept) {
                          final isSelected = _filterDept == dept;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                dept,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _filterDept = dept),
                              selectedColor: const Color(0xFFE07B39),
                              backgroundColor: const Color(0xFFF7F3EE),
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  // Stats bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: const Color(0xFFF7F3EE),
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          '${filtered.length} student${filtered.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (_filterDept != 'All') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE07B39).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _filterDept,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFE07B39),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          'Total: ${allStudents.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: _TableHeader('Name')),
                        Expanded(flex: 2, child: _TableHeader('Department')),
                        Expanded(flex: 3, child: _TableHeader('Email')),
                        Expanded(flex: 2, child: _TableHeader('Digital ID')),
                        Expanded(flex: 2, child: _TableHeader('Phone')),
                        Expanded(flex: 2, child: _TableHeader('Mess Type')),
                        Expanded(flex: 1, child: _TableHeader('Room')),
                        SizedBox(width: 48, child: _TableHeader('Edit')),
                      ],
                    ),
                  ),
                  // Student rows
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 56,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  allStudents.isEmpty
                                      ? 'No students yet. Add or bulk import students.'
                                      : 'No students match your search.',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final student = filtered[index];
                              final isEven = index % 2 == 0;
                              return _StudentRow(
                                student: student,
                                isEven: isEven,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StudentRow extends StatelessWidget {
  final AppUser student;
  final bool isEven;

  const _StudentRow({required this.student, required this.isEven});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFCFAF8),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFE07B39).withAlpha(30),
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE07B39),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF6B7B3C).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student.department ?? '-',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7B3C),
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              student.email,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student.digitalId ?? student.rollNo ?? '-',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student.phone.isNotEmpty ? student.phone : '-',
              style: TextStyle(
                fontSize: 12,
                color: student.phone.isNotEmpty
                    ? Colors.grey[700]
                    : Colors.orange[300],
                fontStyle: student.phone.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              (student.messPlan != null && student.messPlan!.isNotEmpty)
                  ? student.messPlan!
                  : '-',
              style: TextStyle(
                fontSize: 12,
                color:
                    (student.messPlan != null && student.messPlan!.isNotEmpty)
                    ? Colors.grey[700]
                    : Colors.orange[300],
                fontStyle:
                    (student.messPlan == null || student.messPlan!.isEmpty)
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              (student.roomNo != null && student.roomNo!.isNotEmpty)
                  ? student.roomNo!
                  : '-',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                size: 18,
                color: Color(0xFFE07B39),
              ),
              tooltip: 'Edit student details',
              onPressed: () => _showEditDialog(context, student),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, AppUser student) {
    showDialog(
      context: context,
      builder: (ctx) => _EditStudentDialog(student: student),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  EDIT STUDENT DIALOG
// ─────────────────────────────────────────────────────────────

class _EditStudentDialog extends StatefulWidget {
  final AppUser student;
  const _EditStudentDialog({required this.student});

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  late TextEditingController _phoneCtrl;
  late TextEditingController _roomCtrl;
  String _selectedMessType = '';
  bool _isSaving = false;

  final _messTypes = [
    'Veg',
    'Non-Veg',
    'Special',
    'North Indian',
    'South Indian',
  ];

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.student.phone);
    _roomCtrl = TextEditingController(text: widget.student.roomNo ?? '');
    _selectedMessType = widget.student.messPlan ?? '';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await Provider.of<AppState>(context, listen: false).updateStudentDetails(
        uid: widget.student.uid,
        phone: _phoneCtrl.text.trim(),
        messPlan: _selectedMessType,
        roomNo: _roomCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student details updated successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFE07B39).withAlpha(30),
                    child: Text(
                      s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE07B39),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Read-only info chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (s.department != null && s.department!.isNotEmpty)
                    _infoChip(
                      Icons.school,
                      s.department!,
                      const Color(0xFF6B7B3C),
                    ),
                  if (s.digitalId != null && s.digitalId!.isNotEmpty)
                    _infoChip(
                      Icons.badge,
                      'ID: ${s.digitalId!}',
                      const Color(0xFF1565C0),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Update Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              // Phone
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F3EE),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Mess Type dropdown
              DropdownButtonFormField<String>(
                value: _messTypes.contains(_selectedMessType)
                    ? _selectedMessType
                    : null,
                items: _messTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMessType = v ?? ''),
                decoration: InputDecoration(
                  labelText: 'Mess Type',
                  prefixIcon: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F3EE),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Room No
              TextField(
                controller: _roomCtrl,
                decoration: InputDecoration(
                  labelText: 'Room Number',
                  prefixIcon: const Icon(Icons.meeting_room_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F3EE),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Changes',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE07B39),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  ADD STUDENT FORM VIEW (extracted from old _AddStudentTab)
// ─────────────────────────────────────────────────────────────

class _AddStudentFormView extends StatefulWidget {
  final VoidCallback onGoToManualAdd;
  const _AddStudentFormView({required this.onGoToManualAdd});

  @override
  State<_AddStudentFormView> createState() => _AddStudentFormViewState();
}

class _AddStudentFormViewState extends State<_AddStudentFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _planCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _rollCtrl.dispose();
    _roomCtrl.dispose();
    _planCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _createStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<AppState>(context, listen: false).createStudent(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        rollNo: _rollCtrl.text,
        roomNo: _roomCtrl.text,
        messPlan: _planCtrl.text,
        tempPassword: _passCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student account created successfully!')),
      );

      // Clear form
      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _rollCtrl.clear();
      _roomCtrl.clear();
      _planCtrl.clear();
      _passCtrl.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bulk Import Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE07B39).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE07B39).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.upload_file_rounded,
                    color: Color(0xFFE07B39),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Import Students',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Upload Excel/PDF to add multiple students at once',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _triggerBulkImport(
                      context,
                      onGoToManualAdd: widget.onGoToManualAdd,
                    ),
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('Import'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE07B39),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add New Student',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a student account. They can login with these credentials.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            _buildTextField(_nameCtrl, 'Full Name', Icons.person),
            const SizedBox(height: 16),
            _buildTextField(
              _emailCtrl,
              'Email',
              Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _passCtrl,
              'Temporary Password',
              Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _phoneCtrl,
              'Phone',
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(_rollCtrl, 'Roll No', Icons.badge),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(_roomCtrl, 'Room No', Icons.room),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _planCtrl,
              'Mess Plan (e.g. Veg/Non-Veg)',
              Icons.restaurant_menu,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _createStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07B39),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (val) =>
          val == null || val.isEmpty ? '$label is required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BULK IMPORT — inline file picker + dialog (no page nav)
// ─────────────────────────────────────────────────────────────

Future<void> _triggerBulkImport(
  BuildContext context, {
  VoidCallback? onGoToManualAdd,
}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx', 'xls', 'pdf'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return;

  final file = result.files.first;
  final fileBytes = file.bytes;
  if (fileBytes == null || fileBytes.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read file data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  try {
    final importService = BulkImportService.instance;
    final ext = (file.extension ?? file.name.split('.').last).toLowerCase();
    List<StudentImportRecord> records;

    if (ext == 'xlsx' || ext == 'xls') {
      records = importService.parseXlsx(fileBytes);
    } else if (ext == 'pdf') {
      records = importService.parsePdf(fileBytes);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsupported file format. Use .xlsx or .pdf'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (records.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No student records found. Ensure the file has Name, Department, Email, and Digital ID columns.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _BulkImportDialog(
          records: records,
          fileName: file.name,
          onGoToManualAdd: onGoToManualAdd,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _BulkImportDialog extends StatefulWidget {
  final List<StudentImportRecord> records;
  final String fileName;
  final VoidCallback? onGoToManualAdd;
  const _BulkImportDialog({
    required this.records,
    required this.fileName,
    this.onGoToManualAdd,
  });

  @override
  State<_BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends State<_BulkImportDialog> {
  late List<StudentImportRecord> _records;
  bool _isImporting = false;
  int _progress = 0;
  int _total = 0;
  List<Map<String, dynamic>>? _results;

  @override
  void initState() {
    super.initState();
    _records = List.from(widget.records);
  }

  void _removeRecord(int i) {
    setState(() {
      _records.removeAt(i);
      if (_records.isEmpty) Navigator.pop(context);
    });
  }

  Future<void> _doImport() async {
    final valid = _records
        .where((r) => r.email.trim().isNotEmpty && r.email.contains('@'))
        .length;
    final invalid = _records.length - valid;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirm Import'),
        content: Text(
          'Create $valid student accounts with email as login and '
          '"mess@1234" as default password.'
          '${invalid > 0 ? '\n\n$invalid record(s) with invalid emails will be skipped.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE07B39),
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() {
      _isImporting = true;
      _progress = 0;
      _total = _records.length;
    });

    try {
      final students = _records
          .map(
            (r) => {
              'name': r.name,
              'email': r.email,
              'department': r.department,
              'digitalId': r.digitalId,
            },
          )
          .toList();

      final res = await Provider.of<AppState>(context, listen: false)
          .createStudentsBulk(
            students: students,
            onProgress: (done, total) {
              if (mounted) {
                setState(() {
                  _progress = done;
                  _total = total;
                });
              }
            },
          );

      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _results = res;
      });

      final successCount = res.where((r) => r['success'] == true).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount student accounts created successfully!'),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3EB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _isImporting
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE07B39),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE07B39).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: Color(0xFFE07B39),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bulk Import Preview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_records.length} students from ${widget.fileName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isImporting && _results == null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
            // ── Table Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF7F3EE),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Department',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Digital ID',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                  SizedBox(width: 40),
                ],
              ),
            ),
            // ── Records ──
            Expanded(
              child: ListView.builder(
                itemCount: _records.length,
                itemBuilder: (ctx, i) {
                  final r = _records[i];
                  final hasResult = _results != null && i < _results!.length;
                  final success = hasResult ? _results![i]['success'] : null;
                  final invalidEmail =
                      r.email.trim().isEmpty || !r.email.contains('@');

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: hasResult
                          ? (success == true
                                ? const Color(0x0D2E7D32)
                                : const Color(0x0DD32F2F))
                          : invalidEmail
                          ? const Color(0x14FF9800)
                          : (i.isEven ? Colors.white : const Color(0xFFFCFAF8)),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            r.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            r.department,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            r.email.isEmpty ? '(no email)' : r.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: invalidEmail ? Colors.red : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            r.digitalId,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: hasResult
                              ? Icon(
                                  success == true
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: success == true
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFD32F2F),
                                  size: 18,
                                )
                              : (_isImporting
                                    ? const SizedBox.shrink()
                                    : IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                        onPressed: () => _removeRecord(i),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      )),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ── Bottom: progress / import / results ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: _isImporting
                  ? Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFFE07B39),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Creating accounts... $_progress / $_total',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _total > 0
                                  ? '${(_progress / _total * 100).toInt()}%'
                                  : '0%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE07B39),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _total > 0 ? _progress / _total : 0,
                            backgroundColor: const Color(
                              0xFFE07B39,
                            ).withAlpha(30),
                            color: const Color(0xFFE07B39),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    )
                  : _results != null
                  ? _buildResultsSection()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _doImport,
                        icon: const Icon(Icons.group_add_rounded),
                        label: Text(
                          'Import ${_records.length} Students',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE07B39),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final success = _results!.where((r) => r['success'] == true).length;
    final failed = _results!.length - success;
    final failedRows = _results!.where((r) => r['success'] != true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: failed == 0
                ? const Color(0x142E7D32)
                : const Color(0x14FF9800),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    failed == 0 ? Icons.celebration : Icons.info_outline,
                    color: failed == 0
                        ? const Color(0xFF2E7D32)
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Import Complete — $success created${failed > 0 ? ', $failed failed' : ''}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (failed > 0) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 170),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: failedRows
                            .map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '• ${r['name'] ?? r['email']}: ${r['error']}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFD32F2F),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onGoToManualAdd?.call();
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add Student Manually'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07B39),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FoodReportsTab extends StatefulWidget {
  const _FoodReportsTab();

  @override
  State<_FoodReportsTab> createState() => _FoodReportsTabState();
}

class _FoodReportsTabState extends State<_FoodReportsTab> {
  MealType? _filterMeal;
  IssueType? _filterReason;

  Future<void> _showReplaceDialog(
    BuildContext context,
    FoodReport report,
  ) async {
    final appState = Provider.of<AppState>(context, listen: false);
    String? selectedReplacementId;
    String? customName;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Propose Replacement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                decoration: const InputDecoration(
                  labelText: 'Choose from pool',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No selection'),
                  ),
                  ...appState.allReplacements.map(
                    (r) => DropdownMenuItem(value: r.name, child: Text(r.name)),
                  ),
                ],
                onChanged: (v) => selectedReplacementId = v,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Or enter custom replacement',
                ),
                onChanged: (v) => customName = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName =
                    (customName != null && customName!.trim().isNotEmpty)
                    ? customName!
                    : (selectedReplacementId ?? '');
                if (newName.isEmpty) return;
                try {
                  await appState.replaceMenuItemForToday(
                    mealType: report.mealType,
                    oldName: report.menuItemName,
                    newName: newName,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menu updated successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                } finally {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return StreamBuilder<List<FoodReport>>(
      stream: appState.foodReportsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data ?? [];

        // Count frequencies for highlighting
        final frequencyMap = <IssueType, int>{};
        for (var r in reports) {
          frequencyMap[r.reason] = (frequencyMap[r.reason] ?? 0) + 1;
        }

        final filteredReports = reports.where((r) {
          if (_filterMeal != null && r.mealType != _filterMeal) return false;
          if (_filterReason != null && r.reason != _filterReason) return false;
          return true;
        }).toList();

        return Column(
          children: [
            // Filter bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<MealType?>(
                      value: _filterMeal,
                      decoration: const InputDecoration(
                        labelText: 'Meal Type',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Meals'),
                        ),
                        ...MealType.values.map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.displayName),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _filterMeal = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<IssueType?>(
                      value: _filterReason,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Reasons'),
                        ),
                        ...IssueType.values.map(
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text(i.displayName),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _filterReason = val),
                    ),
                  ),
                ],
              ),
            ),

            // Stats summary
            if (frequencyMap.isNotEmpty) ...[
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: frequencyMap.entries
                      .map((e) => _buildReasonBadge(e.key, e.value))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],

            Expanded(
              child: filteredReports.isEmpty
                  ? const Center(
                      child: Text('No reports found matching criteria'),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Student ID')),
                            DataColumn(label: Text('Menu Item')),
                            DataColumn(label: Text('Meal')),
                            DataColumn(label: Text('Reason')),
                            DataColumn(label: Text('Comments')),
                            DataColumn(label: Text('Date/Time')),
                            DataColumn(label: Text('Action')),
                          ],
                          rows: filteredReports.map((report) {
                            final isFrequent =
                                (frequencyMap[report.reason] ?? 0) > 3;
                            return DataRow(
                              color: isFrequent
                                  ? WidgetStateProperty.all(
                                      Colors.red.withValues(alpha: 0.05),
                                    )
                                  : null,
                              cells: [
                                DataCell(
                                  Text(
                                    report.studentId.substring(0, 6) + '...',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    report.menuItemName.isEmpty
                                        ? '-'
                                        : report.menuItemName,
                                  ),
                                ),
                                DataCell(
                                  Text('${report.mealType.displayName}'),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 140,
                                    child: Row(
                                      children: [
                                        Text(report.reason.icon),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            report.reason.displayName,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isFrequent
                                                  ? Colors.red
                                                  : Colors.black,
                                              fontWeight: isFrequent
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      report.comments.isEmpty
                                          ? '-'
                                          : report.comments,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    DateFormat(
                                      'MMM d, HH:mm',
                                    ).format(report.timestamp),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(
                                          Icons.swap_horiz,
                                          size: 16,
                                        ),
                                        label: const Text('Replace'),
                                        onPressed: () =>
                                            _showReplaceDialog(context, report),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReasonBadge(IssueType type, int count) {
    bool isUrgent = count > 3;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent ? Colors.red : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(type.icon),
          const SizedBox(width: 6),
          Text(
            '${type.displayName}: $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationsTab extends StatefulWidget {
  const _CancellationsTab();

  @override
  State<_CancellationsTab> createState() => _CancellationsTabState();
}

class _CancellationsTabState extends State<_CancellationsTab> {
  final CancellationService _cancellationService = CancellationService();
  String _searchQuery = '';
  String _statusFilter = 'All';

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  void _showPdfViewer(BuildContext context, String url, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.orange.shade800,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Document — $studentName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 48,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDF document attached to this cancellation request',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text(
                        'Open PDF in Browser',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        try {
                          final bytes = base64Decode(url); // url is base64
                          final blob = html.Blob([bytes], 'application/pdf');
                          final blobUrl = html.Url.createObjectUrlFromBlob(
                            blob,
                          );
                          html.window.open(blobUrl, '_blank');
                          // Revoke URL after a delay to free memory
                          Future.delayed(const Duration(seconds: 10), () {
                            html.Url.revokeObjectUrl(blobUrl);
                          });
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error viewing PDF: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReject(Cancellation cancellation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Reject Request'),
          ],
        ),
        content: Text(
          'Reject the cancellation request from ${cancellation.studentName} '
          '(${DateFormat('MMM d').format(cancellation.absenceStartDate)} – '
          '${DateFormat('MMM d').format(cancellation.absenceEndDate)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cancellationService.updateCancellationStatus(
        cancellation.id,
        'Rejected',
        cancellation.studentId,
        cancellation.cancellationReason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by student name…',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),
        // Status filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Pending', 'Approved', 'Rejected'].map((label) {
                final isSelected = _statusFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selectedColor: label == 'Approved'
                        ? Colors.green
                        : label == 'Rejected'
                        ? Colors.red
                        : label == 'Pending'
                        ? Colors.orange
                        : Colors.orange.shade800,
                    backgroundColor: Colors.grey.shade200,
                    checkmarkColor: Colors.white,
                    onSelected: (_) => setState(() => _statusFilter = label),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Cancellation cards
        Expanded(
          child: StreamBuilder<List<Cancellation>>(
            stream: _cancellationService.getAllCancellations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final cancellations = snapshot.data ?? [];
              final filtered = cancellations.where((c) {
                final matchesSearch = c.studentName.toLowerCase().contains(
                  _searchQuery,
                );
                final matchesStatus =
                    _statusFilter == 'All' ||
                    c.status.toLowerCase() == _statusFilter.toLowerCase();
                return matchesSearch && matchesStatus;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No cancellation requests found',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final c = filtered[index];
                  final statusColor = _statusColor(c.status);
                  final isPending = c.status.toLowerCase() == 'pending';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 3,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          // Color accent bar
                          Container(
                            width: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                          ),
                          // Card content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Row 1: Name + status badge
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: statusColor
                                            .withOpacity(0.15),
                                        child: Icon(
                                          _statusIcon(c.status),
                                          color: statusColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.studentName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Submitted ${DateFormat('MMM d, yyyy').format(c.createdAt)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          c.status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  // Row 2: Date range, reason, duration
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${DateFormat('MMM d').format(c.absenceStartDate)} → ${DateFormat('MMM d').format(c.absenceEndDate)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${c.durationDays} days',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Reason
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.label_outline_rounded,
                                        size: 15,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        c.cancellationReason,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  // Row 3: Document button + Action buttons
                                  Row(
                                    children: [
                                      // View PDF button
                                      if (c.hasDocument)
                                        OutlinedButton.icon(
                                          icon: Icon(
                                            Icons.picture_as_pdf_rounded,
                                            size: 16,
                                            color: Colors.blue.shade700,
                                          ),
                                          label: Text(
                                            'View PDF',
                                            style: TextStyle(
                                              color: Colors.blue.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: Colors.blue.shade200,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                          ),
                                          onPressed: () => _showPdfViewer(
                                            context,
                                            c.documentBase64!,
                                            c.studentName,
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.description_outlined,
                                                size: 14,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'No document',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const Spacer(),
                                      // Approve / Reject buttons (only for pending)
                                      if (isPending) ...[
                                        TextButton(
                                          onPressed: () => _confirmReject(c),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'Reject',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.check_rounded,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Approve',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: () async {
                                            await _cancellationService
                                                .updateCancellationStatus(
                                                  c.id,
                                                  'Approved',
                                                  c.studentId,
                                                  c.cancellationReason,
                                                );
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Request approved',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
