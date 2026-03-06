import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';
import '../models/menu_item.dart' hide MealType;
import '../models/complaint.dart' hide IssueType;
import '../models/replacement.dart' hide PoolType;
import '../models/pool_type.dart';
import '../models/week_day.dart';
import '../models/meal_type.dart';
import '../models/issue_type.dart';
import '../models/food_report.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/complaint_service.dart';
import '../services/replacement_service.dart';
import '../repositories/food_report_repository.dart';

/// Central app state managed with Provider.
class AppState extends ChangeNotifier {
  // Services
  final AuthService _authService = AuthService.instance;
  final MenuService _menuService = MenuService.instance;
  final ComplaintService _complaintService = ComplaintService.instance;
  final ReplacementService _replacementService = ReplacementService.instance;
  final FoodReportRepository _foodReportRepository =
      FoodReportRepository.instance;

  // ============== FOOD REPORTS ==============

  Stream<List<FoodReport>> get foodReportsStream =>
      _foodReportRepository.getReportsStream();

  Future<void> submitFoodReport({
    required String menuItemId,
    required String menuItemName,
    required MealType mealType,
    required DateTime mealDate,
    required IssueType reason,
    required String comments,
  }) async {
    if (_currentUser == null) throw Exception("User not logged in");

    final report = FoodReport(
      id: '', // Firestore generates ID
      studentId: _currentUser!.uid,
      studentName: _currentUser!.name,
      menuItemId: menuItemId,
      menuItemName: menuItemName,
      mealType: mealType,
      mealDate: mealDate,
      reason: reason,
      comments: comments,
      timestamp: DateTime.now(),
    );

    await _foodReportRepository.submitReport(report);
  }

  // ============== USER STATE ==============

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isStaff => _currentUser?.isStaff ?? false;
  bool get isStudent => _currentUser?.isStudent ?? false;

  fb.User? get currentFirebaseUser => _authService.currentFirebaseUser;

  // Saved admin credentials for re-authentication after creating student accounts
  String? _adminEmail;
  String? _adminPassword;

  // ============== AUTH: LOGIN ==============

  /// Login with email and password via Firebase.
  /// Returns the role string on success.
  /// Rethrows exceptions for UI to handle ('new_user', 'pending', etc).
  Future<String> loginWithEmail(String email, String password) async {
    try {
      final user = await _authService.login(email, password);
      _currentUser = user;

      // Save credentials for re-auth (admin or staff)
      if (user.isAdmin || user.isStaff) {
        _adminEmail = email;
        _adminPassword = password;
      }
      notifyListeners();
      return user.role;
    } catch (e) {
      // Propagate for UI handling
      rethrow;
    }
  }

  /// Login with Google.
  Future<String> loginWithGoogle() async {
    try {
      final user = await _authService.signInWithGoogle();
      _currentUser = user;
      // Note: We can't save password for Google Auth, so admin re-auth
      // for creating students might require manual re-login if they use Google.
      // But we can prompt them.
      notifyListeners();
      return user.role;
    } catch (e) {
      rethrow;
    }
  }

  /// Register details for a new staff user.
  Future<void> registerStaffDetails({
    required String name,
    required String phone,
    required String staffId,
  }) async {
    await _authService.registerStaffDetails(
      name: name,
      phone: phone,
      staffId: staffId,
    );
    // After registration, the user is still "pending". Logic usually logs them out
    // or shows pending screen. Since we are authenticated, we act as 'staff' (approved=false).
    // We should refresh the user profile.
    // For now, let UI handle the navigation to PendingScreen.
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _authService.signUpWithEmail(email, password);
    // This throws 'new_user' usually, caught by UI to redirect to registration form.
  }

  Future<void> signUpStaff({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String staffId,
  }) async {
    await _authService.signUpStaffWithEmail(
      name: name,
      email: email,
      password: password,
      phone: phone,
      staffId: staffId,
    );
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _adminEmail = null;
    _adminPassword = null;
    _selectedMenuItem = null;
    _selectedIssueType = null;
    _currentComplaint = null;
    notifyListeners();
  }

  // ============== AUTH: ADMIN — STAFF APPROVAL ==============

  /// Stream of pending staff users for admin dashboard.
  Stream<List<AppUser>> get pendingStaffUsers => _authService.pendingStaffUsers;

  /// Approve a pending user.
  Future<void> approveUser(String uid) async {
    await _authService.approveUser(uid);
  }

  /// Reject/Delete a pending user.
  Future<void> rejectUser(String uid) async {
    await _authService.rejectUser(uid);
  }

  // ============== AUTH: ADMIN — STUDENT CREATION ==============

  /// Create a student account (Auth + Firestore).
  Future<void> createStudent({
    required String name,
    required String email,
    required String phone,
    required String rollNo,
    required String roomNo,
    required String messPlan,
    required String tempPassword,
  }) async {
    await _authService.createStudent(
      name: name,
      email: email,
      phone: phone,
      rollNo: rollNo,
      roomNo: roomNo,
      messPlan: messPlan,
      tempPassword: tempPassword,
    );
    await _reAuthenticateAdmin();
  }

  /// Re-authenticate admin/staff after creating student accounts.
  /// Creating a Firebase Auth account signs out the current user,
  /// so we need to sign back in.
  Future<void> _reAuthenticateAdmin() async {
    if (_adminEmail != null && _adminPassword != null) {
      try {
        await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _adminEmail!,
          password: _adminPassword!,
        );
      } catch (_) {
        await logout();
        rethrow;
      }
    }
  }

  /// Create multiple student accounts in bulk (fast version).
  /// Returns a list of results (success/failure per student).
  /// Uses [onProgress] callback to report progress for each student.
  Future<List<Map<String, dynamic>>> createStudentsBulk({
    required List<Map<String, String>> students,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <Map<String, dynamic>>[];

    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      final email = (student['email'] ?? '').trim();
      final name = (student['name'] ?? '').trim();

      // Skip rows with empty or invalid email
      if (email.isEmpty || !email.contains('@')) {
        results.add({
          'email': email,
          'name': name,
          'success': false,
          'error': email.isEmpty
              ? 'Email is empty — skipped'
              : 'Invalid email format — skipped',
        });
        onProgress?.call(i + 1, students.length);
        continue;
      }

      try {
        await _authService.createStudentFast(
          name: name,
          email: email,
          tempPassword: 'mess@1234',
          department: student['department'],
          digitalId: student['digitalId'],
        );
        await _reAuthenticateAdmin();
        results.add({'email': email, 'name': name, 'success': true});
      } catch (e) {
        // Try to re-auth even on failure
        try {
          await _reAuthenticateAdmin();
        } catch (_) {}

        // Provide user-friendly error messages
        String errorMsg = e.toString();
        if (errorMsg.contains('email-already-in-use')) {
          errorMsg = 'Email already registered';
        } else if (errorMsg.contains('invalid-email')) {
          errorMsg = 'Invalid email format';
        } else if (errorMsg.contains('weak-password')) {
          errorMsg = 'Password too weak';
        } else {
          errorMsg = errorMsg.replaceAll('Exception: ', '');
        }

        results.add({
          'email': email,
          'name': name,
          'success': false,
          'error': errorMsg,
        });
      }
      onProgress?.call(i + 1, students.length);
    }

    return results;
  }

  // ============== ADMIN: STUDENT LISTING & EDITING ==============

  /// Stream of all students for the admin dashboard.
  Stream<List<AppUser>> get allStudents => _authService.allStudents;

  /// Update student details (phone, mess type, room no).
  Future<void> updateStudentDetails({
    required String uid,
    String? phone,
    String? messPlan,
    String? roomNo,
  }) async {
    await _authService.updateStudentDetails(
      uid: uid,
      phone: phone,
      messPlan: messPlan,
      roomNo: roomNo,
    );
  }

  // ============== MENU STATE ==============

  List<MenuItem> _firestoreMenu = [];
  bool _isMenuLoading = false;
  bool get isMenuLoading => _isMenuLoading;

  /// Loads the menu for the current day from Firestore
  Future<void> loadDailyMenuFromFirestore() async {
    _isMenuLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final dayName = dayNames[now.weekday - 1];

      _firestoreMenu = await _menuService.getFirestoreMenuForDay(dayName);
    } catch (e) {
      debugPrint("Error loading Firestore menu: $e");
      // Fallback to dummy if Firestore fails or is empty
      _firestoreMenu = [];
    } finally {
      _isMenuLoading = false;
      notifyListeners();
    }
  }

  /// Replace an item in today's menu (by meal type). This is used by admin
  /// to apply a confirmed replacement to the original menu stored in Firestore.
  Future<void> replaceMenuItemForToday({
    required MealType mealType,
    required String oldName,
    required String newName,
  }) async {
    final now = DateTime.now();
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayName = dayNames[now.weekday - 1];

    await _menuService.updateMenuItemForDay(
      mealType: mealType,
      dayName: dayName,
      oldName: oldName,
      newName: newName,
    );

    // Refresh local menu cache
    await loadDailyMenuFromFirestore();
  }

  List<MenuItem> get todaysMenu {
    if (_firestoreMenu.isNotEmpty) return _firestoreMenu;
    return _menuService.getTodaysMenu();
  }

  List<MenuItem> getMenuByMealType(MealType mealType) {
    if (_firestoreMenu.isNotEmpty) {
      return _firestoreMenu.where((item) => item.mealType == mealType).toList();
    }
    return _menuService.getMenuByMealType(mealType);
  }

  // ============== FEEDBACK FLOW STATE ==============

  MenuItem? _selectedMenuItem;
  MenuItem? get selectedMenuItem => _selectedMenuItem;

  IssueType? _selectedIssueType;
  IssueType? get selectedIssueType => _selectedIssueType;

  Complaint? _currentComplaint;
  Complaint? get currentComplaint => _currentComplaint;

  ReplacementItem? _selectedReplacement;
  ReplacementItem? get selectedReplacement => _selectedReplacement;

  String _replacementComments = '';
  String get replacementComments => _replacementComments;

  String? _customReplacementName;
  String? get customReplacementName => _customReplacementName;

  void selectMenuItem(MenuItem item) {
    _selectedMenuItem = item;
    notifyListeners();
  }

  void selectIssueType(IssueType issueType) {
    _selectedIssueType = issueType;
    notifyListeners();
  }

  bool submitComplaint() {
    if (_selectedMenuItem == null ||
        _selectedIssueType == null ||
        _currentUser == null) {
      return false;
    }

    _currentComplaint = _complaintService.submitComplaint(
      menuItem: _selectedMenuItem!,
      issueType: _selectedIssueType!,
      studentId: _currentUser!.uid,
    );

    notifyListeners();
    return true;
  }

  void selectReplacement(ReplacementItem? item) {
    _selectedReplacement = item;
    if (item != null) _customReplacementName = null;
    notifyListeners();
  }

  void setReplacementComments(String comments) {
    _replacementComments = comments;
    notifyListeners();
  }

  void setCustomReplacementName(String? name) {
    _customReplacementName = name;
    if (name != null) _selectedReplacement = null;
    notifyListeners();
  }

  bool confirmReplacement() {
    if (_currentComplaint == null ||
        (_selectedReplacement == null && _customReplacementName == null)) {
      return false;
    }

    final replacementId =
        _selectedReplacement?.id ??
        'custom_${DateTime.now().millisecondsSinceEpoch}';
    final replacementName =
        _selectedReplacement?.name ?? _customReplacementName!;

    _replacementService.recordUsage(replacementId);
    _complaintService.updateComplaintWithReplacement(
      _currentComplaint!.id,
      replacementId,
    );

    // In a real app, we would also store the replacementName and _replacementComments
    // associated with the complaint/replacement record in Firestore.
    debugPrint(
      "Replacement confirmed: $replacementName, Comments: $_replacementComments",
    );

    notifyListeners();
    return true;
  }

  void resetFeedbackFlow() {
    _selectedMenuItem = null;
    _selectedIssueType = null;
    _currentComplaint = null;
    _selectedReplacement = null;
    _replacementComments = '';
    _customReplacementName = null;
    notifyListeners();
  }

  // ============== REPLACEMENT POOL STATE ==============

  List<ReplacementItem> getReplacementsByPoolType(PoolType poolType) {
    final mealType = _currentComplaint?.menuItem.mealType;
    return _replacementService.getReplacementsByPoolType(
      poolType,
      mealType: mealType,
    );
  }

  List<ReplacementItem> get allReplacements =>
      _replacementService.getAllReplacements();

  // ============== ADMIN STATISTICS ==============

  int get totalComplaints => _complaintService.totalComplaints;
  List<Complaint> get allComplaints => _complaintService.complaints;
  MenuItem? get mostComplainedItem => _complaintService.getMostComplainedItem();

  Map<IssueType, int> get complaintsByIssueType =>
      _complaintService.getComplaintsByIssueType();

  Map<PoolType, int> get replacementUsageByPool =>
      _replacementService.getUsageByPoolType();

  int get totalReplacementsIssued =>
      _replacementService.totalReplacementsIssued;

  ReplacementItem? get mostUsedReplacement =>
      _replacementService.getMostUsedReplacement();
}
