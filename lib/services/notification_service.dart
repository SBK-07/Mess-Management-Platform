import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  Future<void> createNotification({
    required String studentId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        studentId: studentId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _db.collection(_collection).add(notification.toFirestore());
      debugPrint('Notification created for student: $studentId');
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String studentId) {
    return _db
        .collection(_collection)
        .where('student_id', isEqualTo: studentId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _db
          .collection(_collection)
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead(String studentId) async {
    try {
      final batch = _db.batch();
      final snapshots = await _db
          .collection(_collection)
          .where('student_id', isEqualTo: studentId)
          .where('is_read', isEqualTo: false)
          .get();

      for (var doc in snapshots.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }
}
