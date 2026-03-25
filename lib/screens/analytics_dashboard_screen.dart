import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/analytics_service.dart';
import '../utils/constants.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final bool isAdminView;

  const AnalyticsDashboardScreen({
    super.key,
    required this.isAdminView,
  });

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  int _selectedDays = 30;
  late Future<AnalyticsSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = AnalyticsService.instance.fetchSnapshot(days: _selectedDays);
  }

  void _reload(int days) {
    setState(() {
      _selectedDays = days;
      _future = AnalyticsService.instance.fetchSnapshot(days: _selectedDays);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isAdminView
        ? 'Admin Analytics'
        : 'Staff Analytics & Reports';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.surfaceGradient),
        child: FutureBuilder<AnalyticsSnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Failed to load analytics: ${snapshot.error}',
                    style: AppConstants.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return const Center(child: Text('No analytics data found.'));
            }

            return RefreshIndicator(
              onRefresh: () async => _reload(_selectedDays),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildRangeSelector(),
                  const SizedBox(height: 16),
                  _buildKpiGrid(data),
                  const SizedBox(height: 18),
                  _buildMealAttendanceCard(data),
                  const SizedBox(height: 18),
                  _buildTrendCard(data),
                  const SizedBox(height: 18),
                  _buildIssuesCard(data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRangeSelector() {
    const options = [7, 30, 60];

    return Wrap(
      spacing: 8,
      children: options.map((days) {
        final isSelected = _selectedDays == days;
        return ChoiceChip(
          label: Text('$days days'),
          selected: isSelected,
          onSelected: (_) => _reload(days),
          selectedColor: AppConstants.primaryColor.withOpacity(0.2),
        );
      }).toList(),
    );
  }

  Widget _buildKpiGrid(AnalyticsSnapshot data) {
    final avgRatingText = data.averageRating == 0
        ? 'n/a'
        : data.averageRating.toStringAsFixed(2);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _kpiTile(
          label: 'Students',
          value: '${data.totalStudents}',
          color: AppConstants.infoColor,
          icon: Icons.groups_2_outlined,
        ),
        _kpiTile(
          label: 'Attendance Marks',
          value: '${data.totalAttendanceMarks}',
          color: AppConstants.successColor,
          icon: Icons.fact_check_outlined,
        ),
        _kpiTile(
          label: 'Reports',
          value: '${data.totalReports}',
          color: AppConstants.errorColor,
          icon: Icons.feedback_outlined,
        ),
        _kpiTile(
          label: 'Avg Rating',
          value: avgRatingText,
          color: AppConstants.warningColor,
          icon: Icons.star_outline_rounded,
        ),
      ],
    );
  }

  Widget _kpiTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppConstants.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppConstants.headingSmall.copyWith(fontSize: 20),
                ),
                Text(label, style: AppConstants.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealAttendanceCard(AnalyticsSnapshot data) {
    final mealOrder = ['breakfast', 'lunch', 'snacks', 'dinner'];
    final maxValue = data.attendanceByMeal.values.fold<int>(
      1,
      (curr, item) => item > curr ? item : curr,
    );

    return _sectionCard(
      title: 'Attendance by Meal',
      child: Column(
        children: mealOrder.map((meal) {
          final count = data.attendanceByMeal[meal] ?? 0;
          final fraction = count / maxValue;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 82,
                  child: Text(
                    _titleCase(meal),
                    style: AppConstants.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 42,
                  child: Text(
                    '$count',
                    textAlign: TextAlign.right,
                    style: AppConstants.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendCard(AnalyticsSnapshot data) {
    final recent = data.trend.length <= 7
        ? data.trend
        : data.trend.sublist(data.trend.length - 7);

    final maxMarks = recent.fold<int>(1, (curr, d) => d.mealMarks > curr ? d.mealMarks : curr);

    return _sectionCard(
      title: 'Last 7 Days Attendance Trend',
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: recent.map((day) {
            final ratio = day.mealMarks / maxMarks;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${day.mealMarks}',
                      style: AppConstants.caption,
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: AppConstants.animMedium,
                      curve: AppConstants.animCurve,
                      height: (ratio * 110).clamp(8, 110),
                      decoration: BoxDecoration(
                        color: AppConstants.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('E').format(day.date),
                      style: AppConstants.caption,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIssuesCard(AnalyticsSnapshot data) {
    final sortedEntries = data.reportByIssue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _sectionCard(
      title: 'Top Reported Issues',
      child: sortedEntries.isEmpty
          ? Text('No reports in selected range.', style: AppConstants.bodyMedium)
          : Column(
              children: sortedEntries.take(6).map((entry) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_titleCase(entry.key), style: AppConstants.bodyMedium),
                  trailing: Text(
                    '${entry.value}',
                    style: AppConstants.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppConstants.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppConstants.headingSmall.copyWith(fontSize: 17)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }
}
