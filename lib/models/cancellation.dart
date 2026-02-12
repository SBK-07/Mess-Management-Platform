import 'package:cloud_firestore/cloud_firestore.dart';

class Cancellation {
  final String id;
  final String studentId;
  final String studentName;
  final DateTime absenceStartDate;
  final DateTime absenceEndDate;
  final String cancellationReason;
  final String? documentBase64;
  final String? documentName;
  final String status;
  final DateTime createdAt;

  Cancellation({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.absenceStartDate,
    required this.absenceEndDate,
    required this.cancellationReason,
    this.documentBase64,
    this.documentName,
    required this.status,
    required this.createdAt,
  });

  factory Cancellation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Cancellation(
      id: doc.id,
      studentId: data['student_id'] ?? '',
      studentName: data['student_name'] ?? '',
      absenceStartDate: (data['absence_start_date'] as Timestamp).toDate(),
      absenceEndDate: (data['absence_end_date'] as Timestamp).toDate(),
      cancellationReason: data['cancellation_reason'] ?? '',
      documentBase64: data['document_base64'],
      documentName: data['document_name'],
      status: data['status'] ?? 'Pending',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'student_id': studentId,
      'student_name': studentName,
      'absence_start_date': Timestamp.fromDate(absenceStartDate),
      'absence_end_date': Timestamp.fromDate(absenceEndDate),
      'cancellation_reason': cancellationReason,
      'document_base64': documentBase64,
      'document_name': documentName,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  bool get hasDocument => documentBase64 != null && documentBase64!.isNotEmpty;

  int get durationDays => absenceEndDate.difference(absenceStartDate).inDays + 1;
}
