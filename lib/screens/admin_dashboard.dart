import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/complaint.dart';
import '../models/menu_item.dart';
import '../models/replacement.dart';
import '../models/staff_request.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/stat_card.dart';
import '../widgets/complaint_card.dart';
import 'login_screen.dart';

/// Admin dashboard with statistics, staff approval, and student creation.
///
/// Contains a tab bar with three sections:
/// 1. Overview — complaints & statistics (original)
/// 2. Staff Requests — approve/reject pending staff registration requests
/// 3. Add Student — form to create student accounts
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, appState),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Overview'),
            Tab(icon: Icon(Icons.person_add_rounded, size: 20), text: 'Staff'),
            Tab(icon: Icon(Icons.school_rounded, size: 20), text: 'Students'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(appState: appState, userName: user?.name ?? 'Admin'),
          const _StaffRequestsTab(),
          const _AddStudentTab(),
        ],
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
            onPressed: () async {
              await appState.logout();
              if (!context.mounted) return;
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

// ═══════════════════════════════════════════════════
//  TAB 1 — OVERVIEW (original statistics dashboard)
// ═══════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  final AppState appState;
  final String userName;

  const _OverviewTab({required this.appState, required this.userName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(userName),
          const SizedBox(height: AppConstants.paddingLarge),
          _sectionTitle('Overview Statistics'),
          const SizedBox(height: AppConstants.paddingSmall),
          _buildStatisticsGrid(),
          const SizedBox(height: AppConstants.paddingLarge),
          _sectionTitle('Most Complained Item'),
          const SizedBox(height: AppConstants.paddingSmall),
          _buildMostComplainedItem(),
          const SizedBox(height: AppConstants.paddingLarge),
          _sectionTitle('Complaints by Issue Type'),
          const SizedBox(height: AppConstants.paddingSmall),
          _buildIssueTypeBreakdown(),
          const SizedBox(height: AppConstants.paddingLarge),
          _sectionTitle('Replacement Pool Usage'),
          const SizedBox(height: AppConstants.paddingSmall),
          _buildPoolUsage(),
          const SizedBox(height: AppConstants.paddingLarge),
          _sectionTitle('Recent Complaints'),
          const SizedBox(height: AppConstants.paddingSmall),
          _buildRecentComplaints(),
          const SizedBox(height: AppConstants.paddingLarge),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: AppConstants.headingSmall);

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
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: const Center(child: Text('👨‍💼', style: TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                Text(name,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppConstants.paddingSmall,
      mainAxisSpacing: AppConstants.paddingSmall,
      childAspectRatio: 1.3,
      children: [
        StatCard(icon: Icons.warning_amber_rounded, value: '${appState.totalComplaints}', label: 'Total Complaints', color: AppConstants.errorColor),
        StatCard(icon: Icons.swap_horiz, value: '${appState.totalReplacementsIssued}', label: 'Replacements Issued', color: AppConstants.successColor),
        StatCard(icon: Icons.restaurant, value: '${appState.todaysMenu.length}', label: 'Menu Items Today', color: AppConstants.primaryColor),
        StatCard(icon: Icons.inventory_2, value: '${appState.allReplacements.length}', label: 'Replacement Options', color: AppConstants.secondaryColor),
      ],
    );
  }

  Widget _buildMostComplainedItem() {
    final item = appState.mostComplainedItem;
    if (item == null) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: AppConstants.cardShadow,
        ),
        child: const Row(children: [
          Text('✓', style: TextStyle(fontSize: 24)),
          SizedBox(width: AppConstants.paddingMedium),
          Expanded(child: Text('No complaints yet!', style: AppConstants.bodyMedium)),
        ]),
      );
    }

    final count = appState.allComplaints.where((c) => c.menuItem.id == item.id).length;
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: AppConstants.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppConstants.errorColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: AppConstants.paddingMedium),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: AppConstants.headingSmall),
          Text('${item.mealType.displayName} item', style: AppConstants.bodySmall),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppConstants.errorColor, borderRadius: BorderRadius.circular(20)),
          child: Text('$count complaints', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _buildIssueTypeBreakdown() {
    final counts = appState.complaintsByIssueType;
    final total = counts.values.fold(0, (s, c) => s + c);
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        children: IssueType.values.map((t) {
          final c = counts[t] ?? 0;
          final pct = total > 0 ? (c / total) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
            child: Column(children: [
              Row(children: [
                Text(t.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(child: Text(t.displayName, style: AppConstants.bodyLarge)),
                Text('$c', style: AppConstants.headingSmall),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(_issueColor(t)),
                  minHeight: 8,
                ),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPoolUsage() {
    final usage = appState.replacementUsageByPool;
    return Row(
      children: PoolType.values.map((p) {
        final c = usage[p] ?? 0;
        final color = _poolColor(p);
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: p != PoolType.protein ? AppConstants.paddingSmall : 0),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Text(p.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text('$c', style: AppConstants.headingMedium.copyWith(color: color)),
              Text(p.displayName.replaceAll(' Pool', ''), style: AppConstants.bodySmall, textAlign: TextAlign.center),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentComplaints() {
    final list = appState.allComplaints.reversed.take(5).toList();
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(color: AppConstants.cardColor, borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium), boxShadow: AppConstants.cardShadow),
        child: const Center(child: Column(children: [
          Text('🎉', style: TextStyle(fontSize: 48)),
          SizedBox(height: AppConstants.paddingSmall),
          Text('No complaints yet!', style: AppConstants.bodyMedium),
        ])),
      );
    }
    return Column(children: list.map((c) => ComplaintCard(complaint: c)).toList());
  }

  Color _issueColor(IssueType t) {
    switch (t) { case IssueType.taste: return Colors.orange; case IssueType.hygiene: return Colors.red; case IssueType.quantity: return Colors.blue; }
  }

  Color _poolColor(PoolType p) {
    switch (p) { case PoolType.snack: return AppConstants.snackPoolColor; case PoolType.fruit: return AppConstants.fruitPoolColor; case PoolType.protein: return AppConstants.proteinPoolColor; }
  }
}

// ═══════════════════════════════════════════
//  TAB 2 — STAFF REQUESTS (approve / reject)
// ═══════════════════════════════════════════

class _StaffRequestsTab extends StatelessWidget {
  const _StaffRequestsTab();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return StreamBuilder<List<StaffRequest>>(
      stream: appState.pendingStaffRequests,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Error loading requests:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppConstants.errorColor),
              ),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 64, color: AppConstants.successColor.withValues(alpha: 0.6)),
                const SizedBox(height: 16),
                const Text('No pending requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('All staff requests have been processed',
                    style: TextStyle(color: AppConstants.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          itemCount: requests.length,
          itemBuilder: (context, i) => _StaffRequestCard(request: requests[i]),
        );
      },
    );
  }
}

class _StaffRequestCard extends StatefulWidget {
  final StaffRequest request;
  const _StaffRequestCard({required this.request});

  @override
  State<_StaffRequestCard> createState() => _StaffRequestCardState();
}

class _StaffRequestCardState extends State<_StaffRequestCard> {
  bool _processing = false;

  Future<void> _approve() async {
    // Show password dialog
    final passwordCtrl = TextEditingController(text: 'mess@1234');
    final password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Temporary Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Account will be created for:\n${widget.request.email}'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(
                labelText: 'Temporary Password',
                hintText: 'Min 6 characters',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, passwordCtrl.text),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );

    if (password == null || password.length < 6) {
      if (password != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters')),
        );
      }
      return;
    }

    setState(() => _processing = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.approveStaffRequest(widget.request, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${widget.request.name} approved successfully'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppConstants.errorColor),
      );
      setState(() => _processing = false);
    }
  }

  Future<void> _reject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Request'),
        content: Text('Reject the request from ${widget.request.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.errorColor),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _processing = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.rejectStaffRequest(widget.request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${widget.request.name} rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppConstants.errorColor),
      );
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: AppConstants.cardShadow,
      ),
      child: _processing
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.15),
                      child: Text(
                        req.name.isNotEmpty ? req.name[0].toUpperCase() : 'S',
                        style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(req.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(req.email, style: AppConstants.bodySmall),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Pending',
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Details
                Row(children: [
                  const Icon(Icons.phone, size: 14, color: AppConstants.textSecondary),
                  const SizedBox(width: 6),
                  Text(req.phone, style: AppConstants.bodySmall),
                  const SizedBox(width: 16),
                  const Icon(Icons.badge, size: 14, color: AppConstants.textSecondary),
                  const SizedBox(width: 6),
                  Text('ID: ${req.staffId}', style: AppConstants.bodySmall),
                ]),
                const SizedBox(height: 14),

                // Action buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reject,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.errorColor,
                        side: const BorderSide(color: AppConstants.errorColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _approve,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.successColor,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════
//  TAB 3 — ADD STUDENT
// ═══════════════════════════════════════

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
  final _messPlanCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: 'mess@1234');

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _rollCtrl.dispose();
    _roomCtrl.dispose();
    _messPlanCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.createStudent(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        rollNo: _rollCtrl.text,
        roomNo: _roomCtrl.text,
        messPlan: _messPlanCtrl.text,
        tempPassword: _passwordCtrl.text,
      );

      if (!mounted) return;

      // Clear form
      _nameCtrl.clear();
      _emailCtrl.clear();
      _phoneCtrl.clear();
      _rollCtrl.clear();
      _roomCtrl.clear();
      _messPlanCtrl.clear();
      _passwordCtrl.text = 'mess@1234';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Student account created successfully'),
          backgroundColor: AppConstants.successColor,
        ),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _isLoading = false;
        _errorMessage = msg.startsWith('Exception: ') ? msg.substring(11) : msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
              ),
              child: const Column(
                children: [
                  Icon(Icons.school_rounded, color: Colors.white, size: 36),
                  SizedBox(height: 8),
                  Text('Create Student Account',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Fill in the details below to register a new student',
                      style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _field(_nameCtrl, 'Full Name', Icons.person_rounded,
                validator: _required('Name is required')),
            _field(_emailCtrl, 'Email Address', Icons.email_rounded,
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                }),
            _field(_phoneCtrl, 'Phone Number', Icons.phone_rounded,
                keyboard: TextInputType.phone,
                validator: _required('Phone is required')),
            _field(_rollCtrl, 'Roll Number', Icons.numbers_rounded,
                validator: _required('Roll number is required')),
            _field(_roomCtrl, 'Room Number', Icons.meeting_room_rounded,
                validator: _required('Room number is required')),
            _field(_messPlanCtrl, 'Mess Plan', Icons.restaurant_rounded,
                hint: 'e.g. Veg / Non-Veg / Special',
                validator: _required('Mess plan is required')),
            _field(_passwordCtrl, 'Temporary Password', Icons.lock_rounded,
                hint: 'Min 6 characters',
                validator: (v) {
                  if (v == null || v.length < 6) return 'Min 6 characters';
                  return null;
                }),

            // Error
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: AppConstants.errorColor, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createStudent,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.person_add_rounded),
                label: Text(_isLoading ? 'Creating...' : 'Create Student Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {
    String? hint,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  String? Function(String?) _required(String msg) => (v) =>
      (v == null || v.trim().isEmpty) ? msg : null;
}
