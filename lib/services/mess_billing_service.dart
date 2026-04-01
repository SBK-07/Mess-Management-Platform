import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

class StudentMonthlyBill {
  final String studentId;
  final String studentName;
  final int chargedDays;
  final int amount;
  final bool isPaid;
  final DateTime? paidAt;

  const StudentMonthlyBill({
    required this.studentId,
    required this.studentName,
    required this.chargedDays,
    required this.amount,
    required this.isPaid,
    this.paidAt,
  });
}

class StudentBillSummary {
  final int chargedDays;
  final int amount;
  final bool isPaid;
  final DateTime? paidAt;

  const StudentBillSummary({
    required this.chargedDays,
    required this.amount,
    required this.isPaid,
    this.paidAt,
  });
}

class BillMonthOption {
  final int year;
  final int month;
  final String label;

  const BillMonthOption({
    required this.year,
    required this.month,
    required this.label,
  });
}

class MessBillingService {
  MessBillingService._();
  static final MessBillingService instance = MessBillingService._();

  static const int dailyCharge = 120;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _payments =>
      _db.collection('mess_bill_payments');

  Future<StudentBillSummary> getStudentBillForMonth({
    required String studentId,
    required int year,
    required int month,
  }) async {
    if (studentId.trim().isEmpty) {
      return const StudentBillSummary(chargedDays: 0, amount: 0, isPaid: false);
    }

    final chargedDayCounts = await _getChargedDayCountsForMonth(
      year: year,
      month: month,
    );
    final payment = await _getStudentPaymentForMonth(
      studentId: studentId,
      year: year,
      month: month,
    );

    final chargedDays = chargedDayCounts[studentId] ?? 0;
    return StudentBillSummary(
      chargedDays: chargedDays,
      amount: chargedDays * dailyCharge,
      isPaid: payment?.isPaid ?? false,
      paidAt: payment?.paidAt,
    );
  }

  Future<StudentBillSummary> getStudentBillForFebruary({
    required String studentId,
    int? year,
  }) {
    return getStudentBillForMonth(
      studentId: studentId,
      year: year ?? DateTime.now().year,
      month: DateTime.february,
    );
  }

  Future<List<StudentMonthlyBill>> getAllStudentBillsForMonth({
    required int year,
    required int month,
  }) async {
    final chargedDayCounts = await _getChargedDayCountsForMonth(
      year: year,
      month: month,
    );
    final paymentStatuses = await _getPaymentStatusesForMonth(
      year: year,
      month: month,
    );

    final studentsSnap = await _db
        .collection('users')
        .where('role', whereIn: ['student', 'Student'])
        .get();

    final bills = studentsSnap.docs.map((doc) {
      final user = AppUser.fromFirestore(doc);
      final chargedDays = chargedDayCounts[user.uid] ?? 0;
      final paymentStatus = paymentStatuses[user.uid];
      return StudentMonthlyBill(
        studentId: user.uid,
        studentName: user.name,
        chargedDays: chargedDays,
        amount: chargedDays * dailyCharge,
        isPaid: paymentStatus?.isPaid ?? false,
        paidAt: paymentStatus?.paidAt,
      );
    }).toList();

    bills.sort((a, b) {
      final amountCompare = b.amount.compareTo(a.amount);
      if (amountCompare != 0) {
        return amountCompare;
      }
      return a.studentName.toLowerCase().compareTo(b.studentName.toLowerCase());
    });

    return bills;
  }

  Future<List<StudentMonthlyBill>> getAllStudentBillsForFebruary({int? year}) {
    return getAllStudentBillsForMonth(
      year: year ?? DateTime.now().year,
      month: DateTime.february,
    );
  }

  Future<void> markBillAsPaid({
    required String studentId,
    required String studentName,
    required int year,
    required int month,
    required int amount,
  }) async {
    final key = _paymentDocId(studentId: studentId, year: year, month: month);
    await _payments.doc(key).set({
      'studentId': studentId,
      'studentName': studentName,
      'year': year,
      'month': month,
      'amount': amount,
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<BillMonthOption> monthOptions({int? year}) {
    final selectedYear = year ?? DateTime.now().year;
    return [
      BillMonthOption(
        year: selectedYear,
        month: DateTime.february,
        label: 'February',
      ),
      BillMonthOption(
        year: selectedYear,
        month: DateTime.march,
        label: 'March',
      ),
    ];
  }

  String monthLabel(int month) {
    if (month == DateTime.february) {
      return 'February';
    }
    if (month == DateTime.march) {
      return 'March';
    }
    return 'Month $month';
  }

  Future<_PaymentStatus?> _getStudentPaymentForMonth({
    required String studentId,
    required int year,
    required int month,
  }) async {
    final key = _paymentDocId(studentId: studentId, year: year, month: month);
    final doc = await _payments.doc(key).get();
    if (!doc.exists) {
      return null;
    }
    return _PaymentStatus.fromMap(doc.data() ?? const <String, dynamic>{});
  }

  Future<Map<String, _PaymentStatus>> _getPaymentStatusesForMonth({
    required int year,
    required int month,
  }) async {
    final snap = await _payments
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .get();

    final statuses = <String, _PaymentStatus>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final studentId = (data['studentId'] as String?)?.trim();
      if (studentId == null || studentId.isEmpty) {
        continue;
      }
      statuses[studentId] = _PaymentStatus.fromMap(data);
    }
    return statuses;
  }

  String _paymentDocId({
    required String studentId,
    required int year,
    required int month,
  }) {
    final normalizedStudent = studentId.trim();
    return '${normalizedStudent}_${year.toString().padLeft(4, '0')}${month.toString().padLeft(2, '0')}';
  }

  Future<Map<String, int>> _getChargedDayCountsForMonth({
    required int year,
    required int month,
  }) async {
    final chargedDaysByStudent = <String, int>{};

    final firstDay = DateTime(year, month, 1);
    final nextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final dayCount = nextMonth.difference(firstDay).inDays;

    for (var day = 1; day <= dayCount; day++) {
      final dateId =
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

      final studentsSnap = await _db
          .collection('attendance')
          .doc(dateId)
          .collection('students')
          .get();

      for (final doc in studentsSnap.docs) {
        final data = doc.data();
        final hadMeal =
            data['breakfast'] == true ||
            data['lunch'] == true ||
            data['dinner'] == true;

        if (!hadMeal) {
          continue;
        }

        final studentId =
            (data['studentId'] as String?)?.trim().isNotEmpty == true
            ? (data['studentId'] as String).trim()
            : doc.id;

        chargedDaysByStudent[studentId] =
            (chargedDaysByStudent[studentId] ?? 0) + 1;
      }
    }

    return chargedDaysByStudent;
  }
}

class _PaymentStatus {
  final bool isPaid;
  final DateTime? paidAt;

  const _PaymentStatus({required this.isPaid, this.paidAt});

  factory _PaymentStatus.fromMap(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase();
    final paidAtRaw = data['paidAt'];
    return _PaymentStatus(
      isPaid: status == 'paid',
      paidAt: paidAtRaw is Timestamp ? paidAtRaw.toDate() : null,
    );
  }
}
