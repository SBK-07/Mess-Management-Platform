import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../utils/payload_download.dart';
import '../widgets/analytics_dashboard_widgets.dart';

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
  DateTimeRange? _selectedDateRange;
  String? _selectedMealType;
  String? _selectedIssueType;

  double _repeatMinThreshold = 3;
  double _mediumSeverityThreshold = 5;
  double _highSeverityThreshold = 8;

  late Future<AnalyticsSnapshot> _future;

  static const List<String> _mealTypes = <String>[
    'breakfast',
    'lunch',
    'snacks',
    'dinner',
  ];

  static const List<String> _issueTypes = <String>[
    'taste',
    'hygiene',
    'temperature',
    'portionSize',
    'quality',
    'other',
    'quantity',
    'freshness',
    'service',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: _selectedDays - 1)),
      end: DateTime(now.year, now.month, now.day),
    );
    _reload();
  }

  AnalyticsFilter get _activeFilter {
    final now = DateTime.now();
    final fallback = DateTimeRange(
      start: DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: _selectedDays - 1)),
      end: DateTime(now.year, now.month, now.day),
    );
    final range = _selectedDateRange ?? fallback;

    return AnalyticsFilter(
      fromDate: range.start,
      toDate: range.end,
      mealType: _selectedMealType,
      issueType: _selectedIssueType,
    );
  }

  void _reload() {
    setState(() {
      _future = AnalyticsService.instance.fetchSnapshot(filter: _activeFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isAdminView
        ? 'Admin Analytics'
        : 'Staff Analytics & Reports';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<AnalyticsSnapshot>(
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
            onRefresh: () async => _reload(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final kpiColumns = width >= 1280
                    ? 4
                    : (width >= 900 ? 3 : (width >= 620 ? 2 : 1));

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 12),
                    _buildFilterSection(),
                    const SizedBox(height: 12),
                    _buildKpiSection(data, kpiColumns),
                    const SizedBox(height: 12),
                    _buildAttendanceByMealSection(data),
                    const SizedBox(height: 12),
                    _buildTrendSection(data),
                    const SizedBox(height: 12),
                    _buildTopIssuesSection(data),
                    if (!widget.isAdminView) ...[
                      const SizedBox(height: 12),
                      _buildStaffOperationsPanel(data),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    final range = _selectedDateRange;
    final label = range == null
        ? 'Select Date Range'
        : '${DateFormat('dd MMM').format(range.start)} - ${DateFormat('dd MMM').format(range.end)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE07B39), Color(0xFFC8602E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE07B39).withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isAdminView
                      ? 'Admin Analytics'
                      : 'Staff Analytics & Reports',
                  style: AppConstants.headingMedium.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Overview of attendance and food feedback insights',
                  style: AppConstants.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _pickDateRange,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppConstants.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return SectionContainer(
      title: 'Filters',
      icon: Icons.tune_rounded,
      trailing: Wrap(
        spacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: _downloadPayload,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Download'),
          ),
          OutlinedButton.icon(
            onPressed: _exportPayload,
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Copy JSON'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final days in const [7, 30, 60])
                FilterChip(
                  label: Text('$days days'),
                  selected: _selectedDays == days,
                  onSelected: (_) {
                    final now = DateTime.now();
                    _selectedDays = days;
                    _selectedDateRange = DateTimeRange(
                      start: DateTime(now.year, now.month, now.day)
                          .subtract(Duration(days: days - 1)),
                      end: DateTime(now.year, now.month, now.day),
                    );
                    _reload();
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _choiceDropdown(
                title: 'Meal',
                value: _selectedMealType,
                allLabel: 'All Meals',
                options: _mealTypes,
                onChanged: (value) {
                  setState(() => _selectedMealType = value);
                  _reload();
                },
              ),
              _choiceDropdown(
                title: 'Issue',
                value: _selectedIssueType,
                allLabel: 'All Issues',
                options: _issueTypes,
                onChanged: (value) {
                  setState(() => _selectedIssueType = value);
                  _reload();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _choiceDropdown({
    required String title,
    required String? value,
    required String allLabel,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String?>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: title,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: [
          DropdownMenuItem<String?>(value: null, child: Text(allLabel)),
          ...options.map(
            (item) => DropdownMenuItem<String?>(
              value: item,
              child: Text(_titleCase(item)),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildKpiSection(AnalyticsSnapshot data, int crossAxisCount) {
    final avgRatingText = data.averageRating == 0
        ? 'n/a'
        : data.averageRating.toStringAsFixed(2);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.25,
      children: [
        KpiCard(
          label: 'Total Students',
          value: '${data.totalStudents}',
          icon: Icons.groups_rounded,
          accent: const Color(0xFFE07B39),
        ),
        KpiCard(
          label: 'Total Attendance Marks',
          value: '${data.totalAttendanceMarks}',
          icon: Icons.fact_check_rounded,
          accent: const Color(0xFF1E88E5),
        ),
        KpiCard(
          label: 'Total Reports',
          value: '${data.totalReports}',
          icon: Icons.assignment_late_rounded,
          accent: const Color(0xFF2E7D32),
        ),
        KpiCard(
          label: 'Average Rating',
          value: avgRatingText,
          icon: Icons.star_rate_rounded,
          accent: const Color(0xFFFB8C00),
        ),
      ],
    );
  }

  Widget _buildAttendanceByMealSection(AnalyticsSnapshot data) {
    final breakfast = data.attendanceByMeal['breakfast'] ?? 0;
    final lunch = data.attendanceByMeal['lunch'] ?? 0;
    final dinner = data.attendanceByMeal['dinner'] ?? 0;
    final snacks = data.attendanceByMeal['snacks'] ?? 0;

    final total = breakfast + lunch + dinner + snacks;
    final base = total == 0 ? 1 : total;

    return SectionContainer(
      title: 'Attendance by Meal',
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          MealBarRow(
            label: 'Breakfast',
            count: breakfast,
            fraction: breakfast / base,
            color: const Color(0xFFF57C00),
          ),
          MealBarRow(
            label: 'Lunch',
            count: lunch,
            fraction: lunch / base,
            color: const Color(0xFF1E88E5),
          ),
          MealBarRow(
            label: 'Dinner',
            count: dinner,
            fraction: dinner / base,
            color: const Color(0xFF43A047),
          ),
          if (snacks > 0)
            MealBarRow(
              label: 'Snacks',
              count: snacks,
              fraction: snacks / base,
              color: const Color(0xFF8E24AA),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendSection(AnalyticsSnapshot data) {
    final trend = data.trend.length <= 7
        ? data.trend
        : data.trend.sublist(data.trend.length - 7);

    final spots = <FlSpot>[];
    double maxY = 1;

    for (var i = 0; i < trend.length; i++) {
      final y = trend[i].mealMarks.toDouble();
      spots.add(FlSpot(i.toDouble(), y));
      if (y > maxY) {
        maxY = y;
      }
    }

    return SectionContainer(
      title: 'Attendance Trend (Last 7 Days)',
      icon: Icons.show_chart_rounded,
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.2,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY / 4).clamp(1, 9999),
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
                right: BorderSide.none,
                top: BorderSide.none,
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (items) {
                  return items.map((item) {
                    final index = item.x.toInt();
                    final label = index >= 0 && index < trend.length
                        ? DateFormat('EEE').format(trend[index].date)
                        : 'Day';
                    return LineTooltipItem(
                      '$label\n${item.y.toStringAsFixed(0)} marks',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: (maxY / 4).clamp(1, 9999),
                  getTitlesWidget: (value, _) => Text(
                    value.toInt().toString(),
                    style: AppConstants.caption,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= trend.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('E').format(trend[index].date),
                        style: AppConstants.caption,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: const Color(0xFF1E88E5),
                barWidth: 3,
                dotData: const FlDotData(show: true),
                spots: spots,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E88E5).withOpacity(0.25),
                      const Color(0xFF1E88E5).withOpacity(0.03),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopIssuesSection(AnalyticsSnapshot data) {
    final entries = data.reportByIssue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SectionContainer(
      title: 'Top Reported Issues',
      icon: Icons.report_problem_rounded,
      child: entries.isEmpty
          ? Text('No reports in selected range.', style: AppConstants.bodyMedium)
          : Column(
              children: entries.take(6).map((entry) {
                final severity = _severityByThreshold(entry.value);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: IssueInsightCard(
                    icon: _issueIcon(entry.key),
                    title: _titleCase(entry.key),
                    count: entry.value,
                    severity: severity,
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildStaffOperationsPanel(AnalyticsSnapshot data) {
    final ops = data.staffOps;
    final lowRatingMeals = ops.lowRatingMeals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final repeatedIssues = ops.repeatedIssues
+        .where((item) => item.count >= _repeatMinThreshold.toInt())
         .map(
           (item) => RepeatedIssueAlert(
             issue: item.issue,
             count: item.count,
             severity: _severityByThreshold(item.count),
           ),
         )
         .toList()
       ..sort((a, b) => b.count.compareTo(a.count));

    return SectionContainer(
      title: 'Staff Operations Panel',
      icon: Icons.auto_graph_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _opsSummary('Today Alerts', '${ops.todayReports}', AppConstants.infoColor),
              _opsSummary(
                'Low Ratings Today',
                '${ops.todayLowRatings}',
                AppConstants.errorColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _thresholdSliders(),
          const SizedBox(height: 12),
          Text(
            'Low-rating meals',
            style: AppConstants.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (lowRatingMeals.isEmpty)
            Text('No low-rating meals for the selected filters.', style: AppConstants.bodySmall)
          else
            ...lowRatingMeals.take(4).map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restaurant_menu_rounded, size: 18),
                    title: Text(_titleCase(item.key), style: AppConstants.bodyMedium),
                    trailing: Text('${item.value}', style: AppConstants.bodyLarge),
                  ),
                ),
          const SizedBox(height: 10),
          Text(
            'Repeated issue detection',
            style: AppConstants.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (repeatedIssues.isEmpty)
            Text('No repeated issue spikes detected.', style: AppConstants.bodySmall)
          else
            ...repeatedIssues.take(5).map(
                  (issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: IssueInsightCard(
                      icon: _issueIcon(issue.issue),
                      title: _titleCase(issue.issue),
                      count: issue.count,
                      severity: issue.severity,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _thresholdSliders() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Severity Threshold Settings', style: AppConstants.bodyMedium),
          const SizedBox(height: 6),
          _thresholdSlider(
            label: 'Repeat alert minimum',
            value: _repeatMinThreshold,
            min: 2,
            max: 12,
            onChanged: (v) {
              setState(() {
                _repeatMinThreshold = v;
                if (_mediumSeverityThreshold < _repeatMinThreshold) {
                  _mediumSeverityThreshold = _repeatMinThreshold;
                }
                if (_highSeverityThreshold <= _mediumSeverityThreshold) {
                  _highSeverityThreshold = (_mediumSeverityThreshold + 1).clamp(3, 15);
                }
              });
            },
          ),
          _thresholdSlider(
            label: 'Medium severity from',
            value: _mediumSeverityThreshold,
            min: _repeatMinThreshold,
            max: 14,
            onChanged: (v) {
              setState(() {
                _mediumSeverityThreshold = v;
                if (_highSeverityThreshold <= _mediumSeverityThreshold) {
                  _highSeverityThreshold = (_mediumSeverityThreshold + 1).clamp(3, 15);
                }
              });
            },
          ),
          _thresholdSlider(
            label: 'High severity from',
            value: _highSeverityThreshold,
            min: _mediumSeverityThreshold + 1,
            max: 15,
            onChanged: (v) {
              setState(() => _highSeverityThreshold = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _thresholdSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final safeValue = value.clamp(min, max).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${safeValue.toInt()}', style: AppConstants.caption),
        Slider(
          value: safeValue,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _opsSummary(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppConstants.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: AppConstants.bodySmall),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange,
    );

    if (picked == null) {
      return;
    }

    final days = picked.end
            .difference(DateTime(picked.start.year, picked.start.month, picked.start.day))
            .inDays +
        1;

    setState(() {
      _selectedDateRange = picked;
      _selectedDays = days;
    });
    _reload();
  }

  Future<void> _exportPayload() async {
    try {
      final snapshot =
          await AnalyticsService.instance.fetchSnapshot(filter: _activeFilter);
      final payload =
          const JsonEncoder.withIndent('  ').convert(snapshot.reportPayload);
      await Clipboard.setData(ClipboardData(text: payload));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export payload copied to clipboard.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _downloadPayload() async {
    try {
      final snapshot =
          await AnalyticsService.instance.fetchSnapshot(filter: _activeFilter);
      final payload =
          const JsonEncoder.withIndent('  ').convert(snapshot.reportPayload);
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'analytics_export_$ts.json';

      if (kIsWeb) {
        downloadJsonPayload(fileName: fileName, jsonContent: payload);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded $fileName')),
        );
        return;
      }

      await Clipboard.setData(ClipboardData(text: payload));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Web download unavailable here. JSON copied instead.'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  IconData _issueIcon(String issue) {
    switch (issue) {
      case 'taste':
        return Icons.sentiment_dissatisfied_rounded;
      case 'hygiene':
        return Icons.clean_hands_rounded;
      case 'temperature':
        return Icons.thermostat_rounded;
      case 'portionSize':
      case 'quantity':
        return Icons.scale_rounded;
      case 'freshness':
        return Icons.eco_rounded;
      case 'quality':
        return Icons.verified_rounded;
      case 'service':
        return Icons.room_service_rounded;
      default:
        return Icons.report_gmailerrorred_rounded;
    }
  }

  String _severityByThreshold(int count) {
    if (count >= _highSeverityThreshold.toInt()) {
      return 'high';
    }
    if (count >= _mediumSeverityThreshold.toInt()) {
      return 'medium';
    }
    return 'low';
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
