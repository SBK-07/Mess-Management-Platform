import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mess_management/firebase_options.dart';

enum AttendanceProfile { high, medium, low, irregular }

const int _batchLimit = 450;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeederApp());
}

class SeederApp extends StatelessWidget {
  const SeederApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SeederStatusScreen(),
    );
  }
}

class SeederStatusScreen extends StatefulWidget {
  const SeederStatusScreen({super.key});

  @override
  State<SeederStatusScreen> createState() => _SeederStatusScreenState();
}

class _SeederStatusScreenState extends State<SeederStatusScreen> {
  bool _running = true;
  bool _success = false;
  final List<String> _logs = <String>[];

  @override
  void initState() {
    super.initState();
    _runSeeder();
  }

  Future<void> _runSeeder() async {
    setState(() {
      _running = true;
      _success = false;
      _logs.clear();
      _logs.add('Initializing Firebase...');
    });

    try {
      await Firebase.initializeApp(options: _resolveFirebaseOptions());
      _append('Firebase initialized.');

      await _ensureSignedIn();
      final user = FirebaseAuth.instance.currentUser;
      _append('Signed in as: ${user?.email ?? user?.uid ?? 'unknown'}');

      final studentIds = await fetchStudentIds();
      _append('Students fetched: ${studentIds.length}');
      if (studentIds.isEmpty) {
        _append('No students found. Nothing to generate.');
        setState(() {
          _running = false;
          _success = true;
        });
        return;
      }

      // Keep this safely under the free-tier daily write limit.
      const maxTotalWrites = 18000;

      final now = DateTime.now();
      final rangeStart = DateTime(now.year, 3, 26);
      final rangeEnd = DateTime(now.year, 4, 3);

      _append('Generating attendance data...');
      final attendanceWrites = await generateAttendanceData(
        studentIds: studentIds,
        startDate: rangeStart,
        endDate: rangeEnd,
        maxWrites: maxTotalWrites - 3000,
      );
      _append('Attendance window: ${DateFormat('yyyy-MM-dd').format(rangeStart)} to ${DateFormat('yyyy-MM-dd').format(rangeEnd)}');
      _append('Attendance writes: $attendanceWrites');

      _append('Generating feedback data...');
      final feedbackWrites = await generateFeedbackData(
        studentIds: studentIds,
        days: 60,
        maxWrites: maxTotalWrites - attendanceWrites,
      );
      _append('Feedback writes: $feedbackWrites');
      _append('Total writes: ${attendanceWrites + feedbackWrites}');

      // ignore: avoid_print
      print('Synthetic generation complete.');
      // ignore: avoid_print
      print('Attendance writes: $attendanceWrites');
      // ignore: avoid_print
      print('Feedback writes: $feedbackWrites');
      // ignore: avoid_print
      print('Total writes: ${attendanceWrites + feedbackWrites}');

      setState(() {
        _running = false;
        _success = true;
      });
    } catch (e) {
      _append('Failed: $e');
      setState(() {
        _running = false;
        _success = false;
      });
    }
  }

  void _append(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _logs.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _running
        ? 'Seeder Running...'
        : (_success ? 'Seeder Completed' : 'Seeder Failed');
    final titleColor = _running
        ? Colors.orange.shade800
        : (_success ? Colors.green.shade700 : Colors.red.shade700);

    return Scaffold(
      appBar: AppBar(title: const Text('Synthetic Data Seeder')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text('${index + 1}. ${_logs[index]}'),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_running)
              ElevatedButton(
                onPressed: _runSeeder,
                child: const Text('Run Again'),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _ensureSignedIn() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) {
    return;
  }

  const email = String.fromEnvironment('SEEDER_EMAIL');
  const password = String.fromEnvironment('SEEDER_PASSWORD');

  if (email.isEmpty || password.isEmpty) {
    throw Exception(
      'Not signed in. Run with --dart-define=SEEDER_EMAIL=... and '
      '--dart-define=SEEDER_PASSWORD=... for an approved admin/staff account.',
    );
  }

  await auth.signInWithEmailAndPassword(email: email, password: password);
}

FirebaseOptions _resolveFirebaseOptions() {
  try {
    return DefaultFirebaseOptions.currentPlatform;
  } catch (_) {
    // Fallback allows running from environments without desktop firebase setup.
    return DefaultFirebaseOptions.android;
  }
}

Future<List<String>> fetchStudentIds() async {
  final usersRef = FirebaseFirestore.instance.collection('users');

  final roleStudent = await usersRef.where('role', isEqualTo: 'student').get();
  final roleStudentUpper = await usersRef.where('role', isEqualTo: 'Student').get();

  final ids = <String>{
    ...roleStudent.docs.map((d) => d.id.trim()).where((e) => e.isNotEmpty),
    ...roleStudentUpper.docs.map((d) => d.id.trim()).where((e) => e.isNotEmpty),
  };

  return ids.toList()..sort();
}

Future<int> generateAttendanceData({
  required List<String> studentIds,
  int days = 60,
  int maxWrites = 15000,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  if (studentIds.isEmpty || maxWrites <= 0) {
    return 0;
  }

  final db = FirebaseFirestore.instance;
  final rng = Random();
  final formatter = DateFormat('yyyy-MM-dd');
  final normalizedStart = startDate == null
      ? null
      : DateTime(startDate.year, startDate.month, startDate.day);
  final normalizedEnd = endDate == null
      ? null
      : DateTime(endDate.year, endDate.month, endDate.day);

  if (normalizedStart != null && normalizedEnd != null && normalizedStart.isAfter(normalizedEnd)) {
    throw ArgumentError('startDate must be on or before endDate');
  }

  if (normalizedStart == null && normalizedEnd == null && days <= 0) {
    return 0;
  }

  final profileByStudent = <String, AttendanceProfile>{
    for (final id in studentIds) id: _randomProfile(rng),
  };
  final variationByStudent = <String, _StudentVariation>{
    for (final id in studentIds) id: _buildStudentVariation(rng),
  };

  var batch = db.batch();
  var pendingInBatch = 0;
  var totalWrites = 0;

  Future<void> flushBatch() async {
    if (pendingInBatch == 0) {
      return;
    }
    await batch.commit();
    totalWrites += pendingInBatch;
    batch = db.batch();
    pendingInBatch = 0;
  }

  final dateSequence = _resolveAttendanceDays(
    days: days,
    startDate: normalizedStart,
    endDate: normalizedEnd,
  );

  for (final day in dateSequence) {
    if (totalWrites >= maxWrites) {
      break;
    }

    final dateId = formatter.format(day);

    final studentsRef = db.collection('attendance').doc(dateId).collection('students');

    final existingSnapshot = await studentsRef.get();
    final existingIds = existingSnapshot.docs.map((d) => d.id).toSet();

    for (final studentId in studentIds) {
      if (totalWrites + pendingInBatch >= maxWrites) {
        break;
      }
      if (existingIds.contains(studentId)) {
        continue;
      }

      final profile = profileByStudent[studentId] ?? AttendanceProfile.irregular;
      final variation = variationByStudent[studentId] ?? _buildStudentVariation(rng);
      final generated = _generateAttendanceForDay(
        profile,
        rng,
        variation,
        day,
      );

      final hasAnyMeal = generated.breakfast || generated.lunch || generated.dinner;
      if (!hasAnyMeal) {
        continue;
      }

      final lastMarked = _randomMarkedTime(day, generated, rng);

      final docRef = studentsRef.doc(studentId);
      batch.set(
        docRef,
        {
          'studentId': studentId,
          'breakfast': generated.breakfast,
          'lunch': generated.lunch,
          'dinner': generated.dinner,
          'lastMarked': Timestamp.fromDate(lastMarked),
        },
        SetOptions(merge: true),
      );

      pendingInBatch++;
      if (pendingInBatch >= _batchLimit) {
        await flushBatch();
      }
    }
  }

  await flushBatch();
  return totalWrites;
}

Future<int> generateFeedbackData({
  required List<String> studentIds,
  int days = 60,
  int maxWrites = 3000,
}) async {
  if (studentIds.isEmpty || maxWrites <= 0 || days <= 0) {
    return 0;
  }

  final db = FirebaseFirestore.instance;
  final rng = Random();
  final now = DateTime.now();

  var batch = db.batch();
  var pendingInBatch = 0;
  var totalWrites = 0;

  Future<void> flushBatch() async {
    if (pendingInBatch == 0) {
      return;
    }
    await batch.commit();
    totalWrites += pendingInBatch;
    batch = db.batch();
    pendingInBatch = 0;
  }

  for (final studentId in studentIds) {
    if (totalWrites >= maxWrites) {
      break;
    }

    final entriesForStudent = 3 + rng.nextInt(3); // 3 to 5

    for (var i = 0; i < entriesForStudent; i++) {
      if (totalWrites + pendingInBatch >= maxWrites) {
        break;
      }

      final timestamp = _randomTimeInRange(now.subtract(Duration(days: days)), now, rng);
      final mealType = _mealTypes[rng.nextInt(_mealTypes.length)];
      final rating = _biasedRating(rng);
      final issueType = _issueTypes[rng.nextInt(_issueTypes.length)];
      final comment = _buildComment(mealType: mealType, issueType: issueType, rating: rating, rng: rng);

      final reportRef = db.collection('food_reports').doc();
      batch.set(reportRef, {
        'studentId': studentId,
        'mealType': mealType,
        'issueType': issueType,
        'rating': rating,
        'comment': comment,
        'timestamp': Timestamp.fromDate(timestamp),
      });

      pendingInBatch++;
      if (pendingInBatch >= _batchLimit) {
        await flushBatch();
      }
    }
  }

  await flushBatch();
  return totalWrites;
}

AttendanceProfile _randomProfile(Random rng) {
  final roll = rng.nextInt(100);
  if (roll < 35) {
    return AttendanceProfile.high;
  }
  if (roll < 70) {
    return AttendanceProfile.medium;
  }
  if (roll < 90) {
    return AttendanceProfile.low;
  }
  return AttendanceProfile.irregular;
}

List<DateTime> _resolveAttendanceDays({
  required int days,
  DateTime? startDate,
  DateTime? endDate,
}) {
  if (startDate != null && endDate != null) {
    final result = <DateTime>[];
    var day = startDate;
    while (!day.isAfter(endDate)) {
      result.add(day);
      day = day.add(const Duration(days: 1));
    }
    return result;
  }

  final today = DateTime.now();
  return List<DateTime>.generate(
    days,
    (index) => DateTime(today.year, today.month, today.day).subtract(Duration(days: index)),
  );
}

_StudentVariation _buildStudentVariation(Random rng) {
  return _StudentVariation(
    breakfastBias: _randInRange(-0.28, 0.22, rng),
    lunchBias: _randInRange(-0.18, 0.28, rng),
    dinnerBias: _randInRange(-0.24, 0.20, rng),
    weekendPenalty: _randInRange(0.0, 0.35, rng),
    dailyVolatility: _randInRange(0.03, 0.28, rng),
    periodicAmplitude: _randInRange(0.04, 0.22, rng),
    periodicPhase: _randInRange(0.0, pi * 2, rng),
    weekdayOffsets: List<double>.generate(7, (_) => _randInRange(-0.14, 0.14, rng)),
  );
}

_AttendanceDay _generateAttendanceForDay(
  AttendanceProfile profile,
  Random rng,
  _StudentVariation variation,
  DateTime day,
) {
  final base = switch (profile) {
    AttendanceProfile.high => _randInRange(0.80, 1.00, rng),
    AttendanceProfile.medium => _randInRange(0.50, 0.80, rng),
    AttendanceProfile.low => _randInRange(0.20, 0.50, rng),
    AttendanceProfile.irregular => _randInRange(0.10, 0.95, rng),
  };

  final dayOfYear = DateTime(day.year, day.month, day.day).difference(DateTime(day.year, 1, 1)).inDays + 1;
  final weekdayDelta = variation.weekdayOffsets[day.weekday % 7];
  final periodic = sin((dayOfYear / 3.4) + variation.periodicPhase) * variation.periodicAmplitude;
  final weekendDrop = (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday)
      ? variation.weekendPenalty
      : 0.0;

  final breakfastP = _clampProbability(
    base + variation.breakfastBias + weekdayDelta + periodic - weekendDrop + _randInRange(-variation.dailyVolatility, variation.dailyVolatility, rng),
  );
  final lunchP = _clampProbability(
    base + variation.lunchBias + weekdayDelta + periodic - (weekendDrop * 0.6) + _randInRange(-variation.dailyVolatility, variation.dailyVolatility, rng),
  );
  final dinnerP = _clampProbability(
    base + variation.dinnerBias + weekdayDelta + periodic - (weekendDrop * 0.8) + _randInRange(-variation.dailyVolatility, variation.dailyVolatility, rng),
  );

  bool breakfast = rng.nextDouble() < breakfastP;
  bool lunch = rng.nextDouble() < lunchP;
  bool dinner = rng.nextDouble() < dinnerP;

  final pattern = rng.nextInt(100);

  if (pattern < 12) {
    breakfast = true;
    lunch = true;
    dinner = true;
  } else if (pattern < 25) {
    breakfast = false;
    lunch = rng.nextDouble() < _clampProbability(lunchP + 0.12);
    dinner = rng.nextDouble() < _clampProbability(dinnerP + 0.08);
  } else if (pattern < 40) {
    breakfast = rng.nextDouble() < _clampProbability(breakfastP + 0.10);
    lunch = true;
    dinner = false;
  } else if (pattern < 55) {
    breakfast = false;
    lunch = true;
    dinner = true;
  } else if (pattern < 65) {
    breakfast = false;
    lunch = false;
    dinner = true;
  } else if (pattern < 75) {
    breakfast = true;
    lunch = false;
    dinner = false;
  }

  if (profile == AttendanceProfile.high && !breakfast && !lunch && !dinner) {
    lunch = true;
  }

  return _AttendanceDay(breakfast: breakfast, lunch: lunch, dinner: dinner);
}

DateTime _randomMarkedTime(DateTime day, _AttendanceDay dayData, Random rng) {
  final mealTimes = <DateTime>[];
  if (dayData.breakfast) {
    mealTimes.add(DateTime(day.year, day.month, day.day, 7 + rng.nextInt(2), rng.nextInt(60)));
  }
  if (dayData.lunch) {
    mealTimes.add(DateTime(day.year, day.month, day.day, 12 + rng.nextInt(2), rng.nextInt(60)));
  }
  if (dayData.dinner) {
    mealTimes.add(DateTime(day.year, day.month, day.day, 18 + rng.nextInt(4), rng.nextInt(60)));
  }
  mealTimes.sort();
  return mealTimes.isEmpty ? day : mealTimes.last;
}

DateTime _randomTimeInRange(DateTime start, DateTime end, Random rng) {
  final diffSeconds = end.difference(start).inSeconds;
  final add = diffSeconds <= 0 ? 0 : rng.nextInt(diffSeconds + 1);
  return start.add(Duration(seconds: add));
}

double _clampProbability(double value) {
  return value.clamp(0.0, 1.0).toDouble();
}

double _randInRange(double minValue, double maxValue, Random rng) {
  return minValue + (maxValue - minValue) * rng.nextDouble();
}

int _biasedRating(Random rng) {
  final roll = rng.nextInt(100);
  if (roll < 7) {
    return 1;
  }
  if (roll < 18) {
    return 2;
  }
  if (roll < 45) {
    return 3;
  }
  if (roll < 75) {
    return 4;
  }
  return 5;
}

String _buildComment({
  required String mealType,
  required String issueType,
  required int rating,
  required Random rng,
}) {
  final positive = <String>[
    'The $mealType was good today, especially the taste.',
    'Overall satisfied with $mealType quality and quantity.',
    'Food quality was decent and service was smooth during $mealType.',
    'Good experience for $mealType, keep it consistent.',
  ];

  final neutral = <String>[
    '$mealType was average; could improve in $issueType.',
    'Not bad, but there is room to improve $issueType in $mealType.',
    'The meal was okay, minor improvements needed for $issueType.',
  ];

  final negative = <String>[
    '$mealType had issues with $issueType today.',
    'Need immediate improvement in $issueType for $mealType service.',
    'I was not satisfied with $mealType due to $issueType concerns.',
  ];

  if (rating >= 4) {
    return positive[rng.nextInt(positive.length)];
  }
  if (rating == 3) {
    return neutral[rng.nextInt(neutral.length)];
  }
  return negative[rng.nextInt(negative.length)];
}

const List<String> _mealTypes = ['breakfast', 'lunch', 'dinner'];
const List<String> _issueTypes = [
  'taste',
  'hygiene',
  'quantity',
  'temperature',
  'freshness',
  'service',
];

class _AttendanceDay {
  final bool breakfast;
  final bool lunch;
  final bool dinner;

  const _AttendanceDay({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });
}

class _StudentVariation {
  final double breakfastBias;
  final double lunchBias;
  final double dinnerBias;
  final double weekendPenalty;
  final double dailyVolatility;
  final double periodicAmplitude;
  final double periodicPhase;
  final List<double> weekdayOffsets;

  const _StudentVariation({
    required this.breakfastBias,
    required this.lunchBias,
    required this.dinnerBias,
    required this.weekendPenalty,
    required this.dailyVolatility,
    required this.periodicAmplitude,
    required this.periodicPhase,
    required this.weekdayOffsets,
  });
}
