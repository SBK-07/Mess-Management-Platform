import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';
import '../models/staff_request.dart';
import '../models/menu_item.dart';
import '../models/complaint.dart';
import '../models/replacement.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/complaint_service.dart';
import '../services/replacement_service.dart';

/// Central app state managed with Provider.
///
/// Handles Firebase authentication (login, registration, approval)
/// and retains all existing complaint/menu/replacement logic.
class AppState extends ChangeNotifier {
  // Services
  final AuthService _authService = AuthService.instance;
  final MenuService _menuService = MenuService.instance;
  final ComplaintService _complaintService = ComplaintService.instance;
  final ReplacementService _replacementService = ReplacementService.instance;

  // ============== USER STATE ==============

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isStaff => _currentUser?.isStaff ?? false;
  bool get isStudent => _currentUser?.isStudent ?? false;

  // Saved admin credentials for re-authentication after creating accounts
  String? _adminEmail;
  String? _adminPassword;

  // ============== AUTH: LOGIN ==============

  /// Login with email and password via Firebase.
  /// Returns the role string on success; throws on failure.
  Future<String> loginWithEmail(String email, String password) async {
    final user = await _authService.login(email, password);
    _currentUser = user;

    // Save admin credentials for re-auth after account creation
    if (user.isAdmin) {
      _adminEmail = email;
      _adminPassword = password;
    }

    notifyListeners();
    return user.role;
  }

  /// Logout current user.
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

  // ============== AUTH: STAFF REGISTRATION ==============

  /// Submit a staff registration request (no Auth account created).
  Future<void> submitStaffRequest({
    required String name,
    required String email,
    required String phone,
    required String staffId,
  }) async {
    await _authService.submitStaffRequest(
      name: name,
      email: email,
      phone: phone,
      staffId: staffId,
    );
  }

  // ============== AUTH: ADMIN — STAFF APPROVAL ==============

  /// Stream of pending staff requests for admin dashboard.
  Stream<List<StaffRequest>> get pendingStaffRequests =>
      _authService.pendingStaffRequests;

  /// Approve a pending staff request.
  /// Creates an Auth account + Firestore profile, then re-authenticates admin.
  Future<void> approveStaffRequest(StaffRequest request, String tempPassword) async {
    await _authService.approveStaffRequest(request, tempPassword);
    await _reAuthenticateAdmin();
  }

  /// Reject a pending staff request.
  Future<void> rejectStaffRequest(String requestId) async {
    await _authService.rejectStaffRequest(requestId);
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

  /// Re-authenticate admin after account creation switches the Auth session.
  Future<void> _reAuthenticateAdmin() async {
    if (_adminEmail != null && _adminPassword != null) {
      try {
        await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _adminEmail!,
          password: _adminPassword!,
        );
      } catch (_) {
        // If re-auth fails, force logout so the admin can log in manually
        await logout();
        rethrow;
      }
    }
  }

  // ============== MENU STATE ==============

  List<MenuItem> get todaysMenu => _menuService.getTodaysMenu();

  List<MenuItem> getMenuByMealType(MealType mealType) {
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

  void selectReplacement(ReplacementItem item) {
    _selectedReplacement = item;
    notifyListeners();
  }

  bool confirmReplacement() {
    if (_currentComplaint == null || _selectedReplacement == null) {
      return false;
    }

    _replacementService.recordUsage(_selectedReplacement!.id);
    _complaintService.updateComplaintWithReplacement(
      _currentComplaint!.id,
      _selectedReplacement!.id,
    );

    notifyListeners();
    return true;
  }

  void resetFeedbackFlow() {
    _selectedMenuItem = null;
    _selectedIssueType = null;
    _currentComplaint = null;
    _selectedReplacement = null;
    notifyListeners();
  }

  // ============== REPLACEMENT POOL STATE ==============

  List<ReplacementItem> getReplacementsByPoolType(PoolType poolType) {
    return _replacementService.getReplacementsByPoolType(poolType);
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
