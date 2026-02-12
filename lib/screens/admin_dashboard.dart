import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../models/user.dart';
import '../widgets/stat_card.dart';
import '../models/issue_type.dart';
import '../models/food_report.dart';
import '../models/meal_type.dart';
import 'package:intl/intl.dart';
import '../models/cancellation.dart';
import '../services/cancellation_service.dart';

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

class _AddStudentTabState extends State<_AddStudentTab> {
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
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
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
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
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
                    child: Icon(Icons.picture_as_pdf_rounded, size: 48, color: Colors.red.shade400),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    studentName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      label: const Text('Open PDF in Browser', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        try {
                          final bytes = base64Decode(url); // url is base64
                          final blob = html.Blob([bytes], 'application/pdf');
                          final blobUrl = html.Url.createObjectUrlFromBlob(blob);
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          const SnackBar(content: Text('Request rejected'), backgroundColor: Colors.red),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
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
                    label: Text(label, style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    )),
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
                final matchesSearch = c.studentName.toLowerCase().contains(_searchQuery);
                final matchesStatus = _statusFilter == 'All' ||
                    c.status.toLowerCase() == _statusFilter.toLowerCase();
                return matchesSearch && matchesStatus;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No cancellation requests found',
                        style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final c = filtered[index];
                  final statusColor = _statusColor(c.status);
                  final isPending = c.status.toLowerCase() == 'pending';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 3,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                        backgroundColor: statusColor.withOpacity(0.15),
                                        child: Icon(_statusIcon(c.status), color: statusColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
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
                                              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${DateFormat('MMM d').format(c.absenceStartDate)} → ${DateFormat('MMM d').format(c.absenceEndDate)}',
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(6),
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
                                      Icon(Icons.label_outline_rounded, size: 15, color: Colors.grey.shade500),
                                      const SizedBox(width: 6),
                                      Text(
                                        c.cancellationReason,
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
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
                                          icon: Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.blue.shade700),
                                          label: Text('View PDF', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.blue.shade200),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          ),
                                          onPressed: () => _showPdfViewer(context, c.documentBase64!, c.studentName),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.description_outlined, size: 14, color: Colors.grey.shade400),
                                              const SizedBox(width: 6),
                                              Text('No document', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.check_rounded, size: 18),
                                          label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w600)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            elevation: 0,
                                          ),
                                          onPressed: () async {
                                            await _cancellationService.updateCancellationStatus(
                                              c.id,
                                              'Approved',
                                              c.studentId,
                                              c.cancellationReason,
                                            );
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Request approved'), backgroundColor: Colors.green),
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
