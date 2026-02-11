import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/menu_repository.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';

class OverallMenuScreen extends StatefulWidget {
  const OverallMenuScreen({super.key});

  @override
  State<OverallMenuScreen> createState() => _OverallMenuScreenState();
}

class _OverallMenuScreenState extends State<OverallMenuScreen> {
  final MenuRepository _repo = MenuRepository.instance;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _breakfast;
  Map<String, dynamic>? _lunch;
  Map<String, dynamic>? _snacks;
  Map<String, dynamic>? _dinner;

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    try {
      final results = await Future.wait([
        _repo.getMealMenu('breakfast'),
        _repo.getMealMenu('lunch'),
        _repo.getMealMenu('snacks'),
        _repo.getMealMenu('dinner'),
      ]);

      setState(() {
        _breakfast = results[0];
        _lunch = results[1];
        _snacks = results[2];
        _dinner = results[3];
        
        // If everything is empty, suggest seeding
        if (_breakfast!.isEmpty && _lunch!.isEmpty) {
           _error = "Menu not found in Firestore. Please ask admin to seed data.";
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Mess Menu'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchMenu();
            },
          ),
          // Tool for the user to seed data easily if they haven't yet
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Seed Initial Data',
            onPressed: () => _confirmSeed(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ))
              : _buildMenuTable(),
    );
  }

  Widget _buildMenuTable() {
    final currentDay = _getCurrentDayName();
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: DataTable(
                dataRowMinHeight: 100,
                dataRowMaxHeight: 250, // Increased to prevent overflow for long menus
                columnSpacing: 40,
                horizontalMargin: 24,
                headingRowColor: WidgetStateProperty.all(AppConstants.primaryColor.withValues(alpha: 0.03)),
                columns: const [
                  DataColumn(label: Text('DAY', style: TextStyle(fontWeight: FontWeight.w900, color: AppConstants.primaryColor, letterSpacing: 1.2))),
                  DataColumn(label: Text('BREAKFAST', style: TextStyle(fontWeight: FontWeight.w900, color: AppConstants.primaryColor, letterSpacing: 1.2))),
                  DataColumn(label: Text('LUNCH', style: TextStyle(fontWeight: FontWeight.w900, color: AppConstants.primaryColor, letterSpacing: 1.2))),
                  DataColumn(label: Text('SNACKS', style: TextStyle(fontWeight: FontWeight.w900, color: AppConstants.primaryColor, letterSpacing: 1.2))),
                  DataColumn(label: Text('DINNER', style: TextStyle(fontWeight: FontWeight.w900, color: AppConstants.primaryColor, letterSpacing: 1.2))),
                ],
                rows: _days.map((day) => _buildDataRow(day, day == currentDay)).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Interactive Weekly Schedule. Highlighted row indicates current day.',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (Provider.of<AppState>(context, listen: false).currentUser?.role != 'staff') ...[
            const SizedBox(height: 8),
            const Text(
              'ℹ️ Tap on any item to report an issue',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ],
        ],
      ),
    );
  }

  String _getCurrentDayName() {
    final now = DateTime.now();
    return _days[now.weekday - 1];
  }

  DataRow _buildDataRow(String day, bool isToday) {
    return DataRow(
      color: isToday ? WidgetStateProperty.all(AppConstants.primaryColor.withValues(alpha: 0.08)) : null,
      cells: [
        DataCell(
          Row(
            children: [
              if (isToday)
                Container(
                  width: 4,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Text(day, style: TextStyle(
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                color: isToday ? AppConstants.primaryColor : Colors.black87,
              )),
            ],
          ),
        ),
        DataCell(_buildBreakfastCell(day, isToday)),
        DataCell(_buildLunchCell(day, isToday)),
        DataCell(_buildSnacksCell(day, isToday)),
        DataCell(_buildDinnerCell(day, isToday)),
      ],
    );
  }

  Widget _buildBreakfastCell(String day, bool isToday) {
    final data = _breakfast?[day];
    if (data == null) return const Text('-');
    final List menu = data['menu'] ?? [];
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(menu.join(', '), style: TextStyle(
            fontSize: 13, 
            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black87,
          )),
          if (data['option'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('Opt: ${data['option']}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
            ),
          if (data['drink'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(data['drink'], style: const TextStyle(fontSize: 11, color: AppConstants.primaryColor, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }

  Widget _buildLunchCell(String day, bool isToday) {
    final data = _lunch?[day];
    if (data == null) return const Text('-');
    final List items = data['items'] ?? [];
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      alignment: Alignment.centerLeft,
      child: Text(items.join(', '), style: TextStyle(
        fontSize: 13,
        fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
        color: Colors.black87,
      )),
    );
  }

  Widget _buildSnacksCell(String day, bool isToday) {
    final data = _snacks?[day];
    if (data == null) return const Text('-');
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data['snack'] ?? '', style: TextStyle(
            fontSize: 13,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black87,
          )),
          if (data['drink'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(data['drink'], style: const TextStyle(fontSize: 11, color: Colors.brown, fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }

  Widget _buildDinnerCell(String day, bool isToday) {
    final data = _dinner?[day];
    if (data == null) return const Text('-');
    final List items = data['items'] ?? [];
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      alignment: Alignment.centerLeft,
      child: Text(items.join(', '), style: TextStyle(
        fontSize: 13,
        fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
        color: Colors.black87,
      )),
    );
  }

  Future<void> _confirmSeed(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed Database?'),
        content: const Text('This will populate the "mess_menu" collection with the initial weekly menu data. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Seed Now')),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      try {
        await _repo.seedInitialMenu();
        await _fetchMenu();
        messenger.showSnackBar(const SnackBar(content: Text('Menu seeded successfully!')));
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = "Seeding failed: $e";
          _isLoading = false;
        });
      }
    }
  }
}
