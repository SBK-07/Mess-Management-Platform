import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsFilter {
  final DateTime fromDate;
  final DateTime toDate;
  final String? mealType;
  final String? issueType;

  const AnalyticsFilter({
    required this.fromDate,
    required this.toDate,
    this.mealType,
    this.issueType,
  });
}

class AttendanceDayStat {
  final DateTime date;
  final int studentsMarked;
  final int mealMarks;

  const AttendanceDayStat({
    required this.date,
    required this.studentsMarked,
    required this.mealMarks,
  });
}

class RepeatedIssueAlert {
  final String issue;
  final int count;
  final String severity;

  const RepeatedIssueAlert({
    required this.issue,
    required this.count,
    required this.severity,
  });
}

class StaffOperationsSnapshot {
  final int todayReports;
  final int todayLowRatings;
  final Map<String, int> lowRatingMeals;
  final List<RepeatedIssueAlert> repeatedIssues;

  const StaffOperationsSnapshot({
    required this.todayReports,
    required this.todayLowRatings,
    required this.lowRatingMeals,
    required this.repeatedIssues,
  });
}

class AnalyticsSnapshot {
  final AnalyticsFilter filter;
  final int totalStudents;
  final int totalReports;
  final double averageRating;
  final int totalAttendanceMarks;
  final Map<String, int> attendanceByMeal;
  final Map<String, int> reportByIssue;
  final Map<String, int> reportByMeal;
  final List<AttendanceDayStat> trend;
  final StaffOperationsSnapshot staffOps;
  final Map<String, dynamic> reportPayload;

  const AnalyticsSnapshot({
    required this.filter,
    required this.totalStudents,
    required this.totalReports,
    required this.averageRating,
    required this.totalAttendanceMarks,
    required this.attendanceByMeal,
    required this.reportByIssue,
    required this.reportByMeal,
    required this.trend,
    required this.staffOps,
    required this.reportPayload,
  });
}

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DateFormat _idFormat = DateFormat('yyyy-MM-dd');

  Future<AnalyticsSnapshot> fetchSnapshot({required AnalyticsFilter filter}) async {
    final start = DateTime(
      filter.fromDate.year,
      filter.fromDate.month,
      filter.fromDate.day,
    );
    final end = DateTime(
      filter.toDate.year,
      filter.toDate.month,
      filter.toDate.day,
      23,
      59,
      59,
      999,
    );
    final dayCount = end.difference(start).inDays + 1;

    final totalStudents = await _countStudents();

    final attendanceByMeal = <String, int>{
      'breakfast': 0,
      'lunch': 0,
      'snacks': 0,
      'dinner': 0,
    };
    final trend = <AttendanceDayStat>[];

    for (var i = 0; i < dayCount; i++) {
      final date = start.add(Duration(days: i));
      final dateId = _idFormat.format(date);
      final dayStudents = await _db
          .collection('attendance')
          .doc(dateId)
          .collection('students')
          .get();

      var studentsMarked = 0;
      var mealMarks = 0;

      for (final doc in dayStudents.docs) {
        final data = doc.data();

        final breakfast = data['breakfast'] == true;
        final lunch = data['lunch'] == true;
        final snacks = data['snacks'] == true;
        final dinner = data['dinner'] == true;

        final includeBreakfast = filter.mealType == null || filter.mealType == 'breakfast';
        final includeLunch = filter.mealType == null || filter.mealType == 'lunch';
        final includeSnacks = filter.mealType == null || filter.mealType == 'snacks';
        final includeDinner = filter.mealType == null || filter.mealType == 'dinner';

        final scopedBreakfast = includeBreakfast && breakfast;
        final scopedLunch = includeLunch && lunch;
        final scopedSnacks = includeSnacks && snacks;
        final scopedDinner = includeDinner && dinner;

        if (scopedBreakfast || scopedLunch || scopedSnacks || scopedDinner) {
          studentsMarked++;
        }
        if (scopedBreakfast) {
          attendanceByMeal['breakfast'] = (attendanceByMeal['breakfast'] ?? 0) + 1;
          mealMarks++;
        }
        if (scopedLunch) {
          attendanceByMeal['lunch'] = (attendanceByMeal['lunch'] ?? 0) + 1;
          mealMarks++;
        }
        if (scopedSnacks) {
          attendanceByMeal['snacks'] = (attendanceByMeal['snacks'] ?? 0) + 1;
          mealMarks++;
        }
        if (scopedDinner) {
          attendanceByMeal['dinner'] = (attendanceByMeal['dinner'] ?? 0) + 1;
          mealMarks++;
        }
      }

      trend.add(
        AttendanceDayStat(
          date: date,
          studentsMarked: studentsMarked,
          mealMarks: mealMarks,
        ),
      );
    }

    final reportsQuery = await _db
        .collection('food_reports')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    var ratingSum = 0.0;
    var ratingCount = 0;

    final reportByIssue = <String, int>{};
    final reportByMeal = <String, int>{};

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    var todayReports = 0;
    var todayLowRatings = 0;
    final lowRatingMeals = <String, int>{};
    final repeatedIssueCounter = <String, int>{};
    var filteredReportsCount = 0;

    for (final doc in reportsQuery.docs) {
      final data = doc.data();

      final issue = (data['issueType'] ?? data['reason'] ?? 'other').toString();
      final meal = (data['mealType'] ?? 'unknown').toString();
      final matchesMeal = filter.mealType == null || filter.mealType == meal;
      final matchesIssue = filter.issueType == null || filter.issueType == issue;
      if (!matchesMeal || !matchesIssue) {
        continue;
      }

      filteredReportsCount++;

      final ratingRaw = data['rating'];
      if (ratingRaw is num) {
        ratingSum += ratingRaw.toDouble();
        ratingCount++;

        final ts = data['timestamp'];
        if (ts is Timestamp) {
          final dt = ts.toDate();
          if (!dt.isBefore(todayStart) && dt.isBefore(todayEnd)) {
            todayReports++;
            if (ratingRaw.toDouble() <= 2.0) {
              todayLowRatings++;
              lowRatingMeals[meal] = (lowRatingMeals[meal] ?? 0) + 1;
            }
          }
        }
      }

      reportByIssue[issue] = (reportByIssue[issue] ?? 0) + 1;
      reportByMeal[meal] = (reportByMeal[meal] ?? 0) + 1;
      repeatedIssueCounter[issue] = (repeatedIssueCounter[issue] ?? 0) + 1;
    }

    final totalAttendanceMarks =
        attendanceByMeal.values.fold<int>(0, (sum, item) => sum + item);

    final repeatedIssues = repeatedIssueCounter.entries
        .where((e) => e.value >= 3)
        .map(
          (e) => RepeatedIssueAlert(
            issue: e.key,
            count: e.value,
            severity: e.value >= 8
                ? 'high'
                : (e.value >= 5 ? 'medium' : 'low'),
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final staffOps = StaffOperationsSnapshot(
      todayReports: todayReports,
      todayLowRatings: todayLowRatings,
      lowRatingMeals: lowRatingMeals,
      repeatedIssues: repeatedIssues,
    );

    final payload = <String, dynamic>{
      'generatedAt': DateTime.now().toIso8601String(),
      'filters': {
        'fromDate': start.toIso8601String(),
        'toDate': end.toIso8601String(),
        'mealType': filter.mealType,
        'issueType': filter.issueType,
      },
      'kpis': {
        'totalStudents': totalStudents,
        'totalReports': filteredReportsCount,
        'averageRating': ratingCount == 0 ? 0 : (ratingSum / ratingCount),
        'totalAttendanceMarks': totalAttendanceMarks,
      },
      'attendanceByMeal': attendanceByMeal,
      'reportByIssue': reportByIssue,
      'reportByMeal': reportByMeal,
      'trend': trend
          .map(
            (item) => {
              'date': item.date.toIso8601String(),
              'studentsMarked': item.studentsMarked,
              'mealMarks': item.mealMarks,
            },
          )
          .toList(),
      'staffOperations': {
        'todayReports': staffOps.todayReports,
        'todayLowRatings': staffOps.todayLowRatings,
        'lowRatingMeals': staffOps.lowRatingMeals,
        'repeatedIssues': staffOps.repeatedIssues
            .map(
              (issue) => {
                'issue': issue.issue,
                'count': issue.count,
                'severity': issue.severity,
              },
            )
            .toList(),
      },
    };

    return AnalyticsSnapshot(
      filter: filter,
      totalStudents: totalStudents,
      totalReports: filteredReportsCount,
      averageRating: ratingCount == 0 ? 0 : ratingSum / ratingCount,
      totalAttendanceMarks: totalAttendanceMarks,
      attendanceByMeal: attendanceByMeal,
      reportByIssue: reportByIssue,
      reportByMeal: reportByMeal,
      trend: trend,
      staffOps: staffOps,
      reportPayload: payload,
    );
  }

  Future<int> _countStudents() async {
    final users = _db.collection('users');
    final lower = await users.where('role', isEqualTo: 'student').get();
    final upper = await users.where('role', isEqualTo: 'Student').get();

    final ids = <String>{
      ...lower.docs.map((e) => e.id),
      ...upper.docs.map((e) => e.id),
    };
    return ids.length;
  }
}
