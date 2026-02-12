import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String studentId;
  final String title;
  final String message;
  final String type; // 'cancellation', 'general', etc.
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.studentId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      studentId: data['student_id'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      isRead: data['is_read'] ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'student_id': studentId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
