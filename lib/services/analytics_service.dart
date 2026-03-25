import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

class AnalyticsSnapshot {
  final int days;
  final int totalStudents;
  final int totalReports;
  final double averageRating;
  final int totalAttendanceMarks;
  final Map<String, int> attendanceByMeal;
  final Map<String, int> reportByIssue;
  final Map<String, int> reportByMeal;
  final List<AttendanceDayStat> trend;

  const AnalyticsSnapshot({
    required this.days,
    required this.totalStudents,
    required this.totalReports,
    required this.averageRating,
    required this.totalAttendanceMarks,
    required this.attendanceByMeal,
    required this.reportByIssue,
    required this.reportByMeal,
    required this.trend,
  });
}

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DateFormat _idFormat = DateFormat('yyyy-MM-dd');

  Future<AnalyticsSnapshot> fetchSnapshot({required int days}) async {
    final normalizedDays = days <= 0 ? 7 : days;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: normalizedDays - 1));

    final totalStudents = await _countStudents();

    final attendanceByMeal = <String, int>{
      'breakfast': 0,
      'lunch': 0,
      'snacks': 0,
      'dinner': 0,
    };
    final trend = <AttendanceDayStat>[];

    for (var i = 0; i < normalizedDays; i++) {
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

        if (breakfast || lunch || snacks || dinner) {
          studentsMarked++;
        }
        if (breakfast) {
          attendanceByMeal['breakfast'] = (attendanceByMeal['breakfast'] ?? 0) + 1;
          mealMarks++;
        }
        if (lunch) {
          attendanceByMeal['lunch'] = (attendanceByMeal['lunch'] ?? 0) + 1;
          mealMarks++;
        }
        if (snacks) {
          attendanceByMeal['snacks'] = (attendanceByMeal['snacks'] ?? 0) + 1;
          mealMarks++;
        }
        if (dinner) {
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
        .get();

    var ratingSum = 0.0;
    var ratingCount = 0;

    final reportByIssue = <String, int>{};
    final reportByMeal = <String, int>{};

    for (final doc in reportsQuery.docs) {
      final data = doc.data();

      final ratingRaw = data['rating'];
      if (ratingRaw is num) {
        ratingSum += ratingRaw.toDouble();
        ratingCount++;
      }

      final issue = (data['issueType'] ?? data['reason'] ?? 'other').toString();
      final meal = (data['mealType'] ?? 'unknown').toString();

      reportByIssue[issue] = (reportByIssue[issue] ?? 0) + 1;
      reportByMeal[meal] = (reportByMeal[meal] ?? 0) + 1;
    }

    final totalAttendanceMarks =
        attendanceByMeal.values.fold<int>(0, (sum, item) => sum + item);

    return AnalyticsSnapshot(
      days: normalizedDays,
      totalStudents: totalStudents,
      totalReports: reportsQuery.size,
      averageRating: ratingCount == 0 ? 0 : ratingSum / ratingCount,
      totalAttendanceMarks: totalAttendanceMarks,
      attendanceByMeal: attendanceByMeal,
      reportByIssue: reportByIssue,
      reportByMeal: reportByMeal,
      trend: trend,
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
