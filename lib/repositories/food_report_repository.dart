import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food_report.dart';

class FoodReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String collection = 'food_reports';

  // Singleton
  FoodReportRepository._();
  static final FoodReportRepository instance = FoodReportRepository._();

  Future<void> submitReport(FoodReport report) async {
    await _db.collection(collection).add(report.toFirestore());
  }

  Stream<List<FoodReport>> getReportsStream() {
    return _db
        .collection(collection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FoodReport.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> updateReportStatus({
    required String reportId,
    required FoodReportStatus status,
  }) async {
    await _db.collection(collection).doc(reportId).update({
      'status': status.name,
      'resolvedAt': status == FoodReportStatus.resolved
          ? FieldValue.serverTimestamp()
          : null,
    });
  }
}
