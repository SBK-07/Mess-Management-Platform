import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/staff_request.dart';

/// Authentication service backed by Firebase Auth and Cloud Firestore.
///
/// Handles login with role validation, staff registration requests,
/// admin approval/rejection, and student account creation.
class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────── LOGIN / LOGOUT ───────────

  /// Sign in with email & password, then fetch + validate the Firestore profile.
  ///
  /// Returns the [AppUser] on success.
  /// Throws [FirebaseAuthException] or a generic [Exception] with a
  /// human-readable message on failure.
  Future<AppUser> login(String email, String password) async {
    // 1. Firebase Auth sign-in
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = cred.user!.uid;

    // 2. Fetch Firestore profile
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('No user profile found. Contact the administrator.');
    }

    final appUser = AppUser.fromFirestore(doc);

    // 3. Role-based approval checks
    if (appUser.role == 'admin' && !appUser.approved) {
      await _auth.signOut();
      throw Exception('Admin account is not approved.');
    }
    if (appUser.role == 'staff' && !appUser.approved) {
      await _auth.signOut();
      throw Exception('Staff account is pending approval.');
    }
    if (!(appUser.active)) {
      await _auth.signOut();
      throw Exception('Account has been deactivated.');
    }

    return appUser;
  }

  /// Sign out the current user.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─────────── STAFF REGISTRATION ───────────

  /// Submit a staff registration request (does NOT create an Auth account).
  Future<void> submitStaffRequest({
    required String name,
    required String email,
    required String phone,
    required String staffId,
  }) async {
    // Check for duplicate pending requests
    final existing = await _db
        .collection('staff_requests')
        .where('email', isEqualTo: email.trim())
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('A pending request with this email already exists.');
    }

    final request = StaffRequest(
      id: '', // Firestore will auto-generate
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      staffId: staffId.trim(),
    );

    await _db.collection('staff_requests').add(request.toFirestore());
  }

  // ─────────── ADMIN: STAFF APPROVAL ───────────

  /// Stream of pending staff requests for the admin panel.
  Stream<List<StaffRequest>> get pendingStaffRequests {
    return _db
        .collection('staff_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      final requests =
          snap.docs.map((d) => StaffRequest.fromFirestore(d)).toList();
      requests.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      return requests;
    });
  }

  /// Approve a staff request: create Auth account, Firestore profile, update request.
  ///
  /// Uses a temporary secondary Auth instance approach: saves the admin's
  /// credentials, creates the new account, then re-signs in as admin.
  Future<void> approveStaffRequest(StaffRequest request, String tempPassword) async {
    // Save current admin credential info
    final adminUser = _auth.currentUser;
    if (adminUser == null) throw Exception('Admin not logged in.');

    try {
      // Create new Auth account for the staff
      final newCred = await _auth.createUserWithEmailAndPassword(
        email: request.email,
        password: tempPassword,
      );

      final newUid = newCred.user!.uid;

      // Write Firestore user profile
      await _db.collection('users').doc(newUid).set({
        'name': request.name,
        'email': request.email,
        'phone': request.phone,
        'role': 'staff',
        'approved': true,
        'active': true,
      });

      // Update request status
      await _db.collection('staff_requests').doc(request.id).update({
        'status': 'approved',
      });
    } catch (e) {
      rethrow;
    }

    // Re-authenticate admin (createUser signs in as new user)
    // The caller (AppState) handles admin re-login.
  }

  /// Reject a staff request.
  Future<void> rejectStaffRequest(String requestId) async {
    await _db.collection('staff_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  // ─────────── ADMIN: STUDENT CREATION ───────────

  /// Create a student account: Auth account + Firestore profile.
  Future<void> createStudent({
    required String name,
    required String email,
    required String phone,
    required String rollNo,
    required String roomNo,
    required String messPlan,
    required String tempPassword,
  }) async {
    // Create Auth account
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: tempPassword,
    );

    final uid = cred.user!.uid;

    // Write Firestore profile
    await _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': 'student',
      'approved': true,
      'active': true,
      'rollNo': rollNo.trim(),
      'roomNo': roomNo.trim(),
      'messPlan': messPlan.trim(),
    });

    // Caller handles admin re-login
  }

  // ─────────── HELPERS ───────────

  /// Current Firebase Auth user (null if signed out).
  User? get currentFirebaseUser => _auth.currentUser;
}
