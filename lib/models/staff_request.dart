import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the Firestore `staff_requests` collection.
///
/// Represents a staff member's registration request that awaits
/// admin approval before a Firebase Auth account is created.
class StaffRequest {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String staffId;
  final String status; // "pending", "approved", "rejected"
  final DateTime requestedAt;

  StaffRequest({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.staffId,
    this.status = 'pending',
    DateTime? requestedAt,
  }) : requestedAt = requestedAt ?? DateTime.now();

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  /// Create from Firestore document snapshot.
  factory StaffRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StaffRequest(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      staffId: data['staffId'] ?? '',
      status: data['status'] ?? 'pending',
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore-compatible map (for creating new requests).
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'staffId': staffId,
      'status': status,
      'requestedAt': FieldValue.serverTimestamp(),
    };
  }
}
