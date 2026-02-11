import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

/// Authentication service backed by Firebase Auth and Cloud Firestore.
///
/// Handles login with role validation, Google Sign-In, and user registration.
class AuthService {
  AuthService._();
  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─────────── LOGIN / SIGN UP ───────────

  /// Sign in with email & password.
  ///
  /// Returns the [AppUser] if profile exists and represents a valid session.
  /// Throws specific exceptions for UI handling:
  /// - 'new_user': Authenticated but no Firestore profile (needs registration).
  /// - 'pending': Profile exists but not approved (needs wait).
  Future<AppUser> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _fetchAndValidateUser(cred.user!);
  }

  /// Sign in with Google.
  Future<AppUser> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Sign in aborted by user');
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the credential
    final UserCredential cred = await _auth.signInWithCredential(credential);
    return _fetchAndValidateUser(cred.user!);
  }

  /// Sign up with email & password (creates Auth account only).
  Future<AppUser> signUpWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // New user won't have a profile yet, so this will likely throw 'new_user'
    return _fetchAndValidateUser(cred.user!);
  }
  
  /// Sign up a staff member with full details.
  Future<void> signUpStaffWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String staffId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    
    final appUser = AppUser(
      uid: cred.user!.uid,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: 'staff',
      approved: false, // Needs admin approval
      active: true,
      staffId: staffId.trim(),
      createdAt: DateTime.now(),
    );
    
    await _db.collection('users').doc(cred.user!.uid).set(appUser.toFirestore());
  }

  /// Helper to fetch Firestore profile and validate status.
  Future<AppUser> _fetchAndValidateUser(User firebaseUser) async {
    final doc = await _db.collection('users').doc(firebaseUser.uid).get();

    if (!doc.exists) {
      // Throw special exception to trigger Registration Screen
      throw Exception('new_user'); 
    }

    final appUser = AppUser.fromFirestore(doc);

    if (appUser.role == 'admin') {
      if (!appUser.approved) throw Exception('Admin account is not approved.');
      return appUser;
    }

    if (appUser.role == 'staff') {
      if (!appUser.approved) {
        // Throw special exception to trigger Pending Screen
        throw Exception('pending');
      }
      if (!appUser.active) throw Exception('Account has been deactivated.');
      return appUser;
    }

    if (appUser.role == 'student') {
      return appUser;
    }

    throw Exception('Unknown role.');
  }

  /// Sign out.
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─────────── REGISTRATION (FIRESTORE) ───────────

  /// Register details for a new staff user (creates Firestore doc).
  Future<void> registerStaffDetails({
    required String name,
    required String phone,
    required String staffId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated.');

    final appUser = AppUser(
      uid: user.uid,
      name: name.trim(),
      email: user.email ?? '',
      phone: phone.trim(),
      role: 'staff',
      approved: false,
      active: true,
      staffId: staffId.trim(),
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(user.uid).set(appUser.toFirestore());
  }

  // ─────────── ADMIN: PENDING USERS ───────────

  /// Stream of pending staff users for admin approval.
  Stream<List<AppUser>> get pendingStaffUsers {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'staff')
        .where('approved', isEqualTo: false)
        .snapshots()
        .map((snap) {
          final users = snap.docs.map((d) => AppUser.fromFirestore(d)).toList();
          // Sort by createdAt descending (newest first)
          users.sort((a, b) {
             final t1 = b.createdAt ?? DateTime(2000);
             final t2 = a.createdAt ?? DateTime(2000);
             return t1.compareTo(t2);
          });
          return users;
        });
  }

  /// Approve a pending user.
  Future<void> approveUser(String uid) async {
    await _db.collection('users').doc(uid).update({'approved': true});
  }

  /// Reject/Delete a pending user.
  Future<void> rejectUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ─────────── ADMIN: CREATE STUDENT ───────────

  Future<void> createStudent({
    required String name,
    required String email,
    required String phone,
    required String rollNo,
    required String roomNo,
    required String messPlan,
    required String tempPassword,
  }) async {
    // This creates an Auth account, which logs the current admin out momentarily
    // AppState handles re-login using preserved credentials if needed.
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: tempPassword,
    );
    
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': 'student',
      'approved': true,
      'active': true,
      'rollNo': rollNo.trim(),
      'roomNo': roomNo.trim(),
      'messPlan': messPlan.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  User? get currentFirebaseUser => _auth.currentUser;
}
