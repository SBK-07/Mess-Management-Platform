import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cancellation.dart';

import '../services/notification_service.dart';

class CancellationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'mess_cancellation_requests';
  final NotificationService _notificationService = NotificationService();

  Future<void> addCancellation(Cancellation cancellation) async {
    try {
      debugPrint('Saving cancellation to Firestore...');
      await _db.collection(_collection).add(cancellation.toFirestore());
      debugPrint('Cancellation saved successfully');
    } catch (e) {
      debugPrint('ERROR SAVING CANCELLATION: $e');
      rethrow;
    }
  }

  Stream<List<Cancellation>> getStudentCancellations(String studentId) {
    return _db
        .collection(_collection)
        .where('student_id', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
            .map((doc) => Cancellation.fromFirestore(doc))
            .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<Cancellation>> getAllCancellations() {
    return _db
        .collection(_collection)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Cancellation.fromFirestore(doc))
            .toList());
  }

  Future<void> updateCancellationStatus(
      String id, String status, String studentId, String reason) async {
    await _db.collection(_collection).doc(id).update({'status': status});
    
    // Trigger notification
    await _notificationService.createNotification(
      studentId: studentId,
      title: 'Cancellation Request $status',
      message: 'Your request for "$reason" has been $status.',
      type: 'cancellation',
    );
  }
}
