import 'package:cloud_firestore/cloud_firestore.dart';

/// User model matching the Firestore `users` collection.
///
/// Supports three roles: admin, staff, student.
/// Student-specific fields are optional.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool approved;
  final bool active;
  final String? messname;
  final String? staffId; // Added staffId
  final DateTime? createdAt; // Added for sorting pending requests

  // Student-specific fields
  final String? rollNo;
  final String? roomNo;
  final String? messPlan;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
    this.approved = false,
    this.active = true,
    this.messname,
    this.staffId,
    this.createdAt,
    this.rollNo,
    this.roomNo,
    this.messPlan,
  });

  bool get isAdmin => role == 'admin' && approved;
  bool get isStaff => role == 'staff' && approved;
  bool get isStudent => role == 'student';

  /// Create from Firestore document snapshot.
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'student',
      approved: data['approved'] ?? false,
      active: data['active'] ?? true,
      messname: data['messname'],
      staffId: data['staffId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      rollNo: data['rollNo'],
      roomNo: data['roomNo'],
      messPlan: data['messPlan'],
    );
  }

  /// Convert to Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'approved': approved,
      'active': active,
      if (staffId != null) 'staffId': staffId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (messname != null) 'messname': messname,
      if (rollNo != null) 'rollNo': rollNo,
      if (roomNo != null) 'roomNo': roomNo,
      if (messPlan != null) 'messPlan': messPlan,
    };
    return map;
  }

  @override
  String toString() => 'AppUser(uid: $uid, name: $name, role: $role, approved: $approved)';
}
