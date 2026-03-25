import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../utils/payload_download.dart';

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
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildRangeSelector(),
                  const SizedBox(height: 16),
                  _buildFiltersCard(),
                  const SizedBox(height: 16),
                  _buildKpiGrid(data),
                  const SizedBox(height: 18),
                  _buildMealAttendanceCard(data),
                  const SizedBox(height: 18),
                  _buildTrendCard(data),
                  const SizedBox(height: 18),
                  _buildIssuesCard(data),
                  if (!widget.isAdminView) ...[
                    const SizedBox(height: 18),
                    _buildStaffOperationsPanel(data),
                  ],
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
          selectedColor: AppConstants.primaryColor.withOpacity(0.2),
        );
      }).toList(),
    );
  }

  Widget _buildFiltersCard() {
    final range = _selectedDateRange;
    final rangeLabel = range == null
        ? 'Choose Date Range'
        : '${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}';

    return _sectionCard(
      title: 'Filters & Export',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(rangeLabel),
                  onPressed: _pickDateRange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Meal Type',
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Meals'),
                    ),
                    ..._mealTypes.map(
                      (meal) => DropdownMenuItem<String?>(
                        value: meal,
                        child: Text(_titleCase(meal)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMealType = value;
                    });
                    _reload();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _selectedIssueType,
                  decoration: const InputDecoration(
                    labelText: 'Issue Type',
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Issues'),
                    ),
                    ..._issueTypes.map(
                      (issue) => DropdownMenuItem<String?>(
                        value: issue,
                        child: Text(_titleCase(issue)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedIssueType = value;
                    });
                    _reload();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _downloadPayload,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Download JSON'),
                ),
                OutlinedButton.icon(
                  onPressed: _exportPayload,
                  icon: const Icon(Icons.content_copy_outlined),
                  label: const Text('Copy JSON'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final current = _selectedDateRange;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: current,
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
      final snapshot = await AnalyticsService.instance.fetchSnapshot(filter: _activeFilter);
      final prettyPayload = const JsonEncoder.withIndent('  ').convert(snapshot.reportPayload);
      await Clipboard.setData(ClipboardData(text: prettyPayload));
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
      final snapshot = await AnalyticsService.instance.fetchSnapshot(filter: _activeFilter);
      final prettyPayload = const JsonEncoder.withIndent('  ').convert(snapshot.reportPayload);
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'analytics_export_$ts.json';

      if (kIsWeb) {
        downloadJsonPayload(fileName: fileName, jsonContent: prettyPayload);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded $fileName')),
        );
        return;
      }

      await Clipboard.setData(ClipboardData(text: prettyPayload));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Web download is unavailable on this platform. JSON copied instead.'),
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

  Widget _buildStaffOperationsPanel(AnalyticsSnapshot data) {
    final ops = data.staffOps;
    final lowRatingMeals = ops.lowRatingMeals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final repeatedIssues = ops.repeatedIssues
        .where((issue) => issue.count >= _repeatMinThreshold.toInt())
        .map(
          (issue) => RepeatedIssueAlert(
            issue: issue.issue,
            count: issue.count,
            severity: _severityByThreshold(issue.count),
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return _sectionCard(
      title: 'Staff Operations Panel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Severity Threshold Settings', style: AppConstants.bodyLarge),
          const SizedBox(height: 8),
          _thresholdSlider(
            label: 'Repeat Alert Minimum',
            value: _repeatMinThreshold,
            min: 2,
            max: 12,
            onChanged: (v) {
              setState(() {
                _repeatMinThreshold = v;
                if (_mediumSeverityThreshold < _repeatMinThreshold) {
                  _mediumSeverityThreshold = _repeatMinThreshold;
                }
                if (_highSeverityThreshold < _mediumSeverityThreshold + 1) {
                  _highSeverityThreshold = (_mediumSeverityThreshold + 1).clamp(3, 15);
                }
              });
            },
          ),
          _thresholdSlider(
            label: 'Medium Severity From',
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
            label: 'High Severity From',
            value: _highSeverityThreshold,
            min: _mediumSeverityThreshold + 1,
            max: 15,
            onChanged: (v) {
              setState(() {
                _highSeverityThreshold = v;
              });
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _opsPill(
                label: 'Today Reports',
                value: '${ops.todayReports}',
                color: AppConstants.infoColor,
              ),
              _opsPill(
                label: 'Today Low Ratings',
                value: '${ops.todayLowRatings}',
                color: AppConstants.errorColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Low-Rating Meals', style: AppConstants.bodyLarge),
          const SizedBox(height: 6),
          if (lowRatingMeals.isEmpty)
            Text('No low-rating meals in this filter.', style: AppConstants.bodySmall)
          else
            ...lowRatingMeals.take(4).map(
                  (entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(_titleCase(entry.key), style: AppConstants.bodyMedium),
                    trailing: Text('${entry.value}', style: AppConstants.bodyLarge),
                  ),
                ),
          const SizedBox(height: 12),
          Text('Repeated Issues Detection', style: AppConstants.bodyLarge),
          const SizedBox(height: 6),
          if (repeatedIssues.isEmpty)
            Text('No repeated issue spikes detected.', style: AppConstants.bodySmall)
          else
            ...repeatedIssues.take(5).map(
                  (issue) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: _severityDot(issue.severity),
                    title: Text(_titleCase(issue.issue), style: AppConstants.bodyMedium),
                    subtitle: Text('Severity: ${_titleCase(issue.severity)}', style: AppConstants.caption),
                    trailing: Text('${issue.count}', style: AppConstants.bodyLarge),
                  ),
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
        Text('$label: ${safeValue.toInt()}', style: AppConstants.bodySmall),
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

  Widget _opsPill({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppConstants.headingSmall.copyWith(color: color)),
          Text(label, style: AppConstants.bodySmall),
        ],
      ),
    );
  }

  Widget _severityDot(String severity) {
    final color = switch (severity) {
      'high' => AppConstants.errorColor,
      'medium' => AppConstants.warningColor,
      _ => AppConstants.infoColor,
    };

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
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
