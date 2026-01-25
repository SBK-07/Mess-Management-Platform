import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/menu_item.dart';
import '../models/complaint.dart';
import '../models/replacement.dart';
import '../services/auth_service.dart';
import '../services/menu_service.dart';
import '../services/complaint_service.dart';
import '../services/replacement_service.dart';

/// Central app state managed with Provider.
/// 
/// This ChangeNotifier manages all global state including:
/// - Current logged in user
/// - Complaints list
/// - Selected items during feedback flow
/// - Replacement usage tracking
class AppState extends ChangeNotifier {
  // Services
  final AuthService _authService = AuthService.instance;
  final MenuService _menuService = MenuService.instance;
  final ComplaintService _complaintService = ComplaintService.instance;
  final ReplacementService _replacementService = ReplacementService.instance;

  // ============== USER STATE ==============
  
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Login user with credentials.
  /// Returns true if login successful, false otherwise.
  bool login(String username, String password) {
    final user = _authService.login(username, password);
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Logout current user.
  void logout() {
    _currentUser = null;
    _selectedMenuItem = null;
    _selectedIssueType = null;
    _currentComplaint = null;
    notifyListeners();
  }

  // ============== MENU STATE ==============
  
  /// Get today's menu items.
  List<MenuItem> get todaysMenu => _menuService.getTodaysMenu();

  /// Get menu items by meal type.
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

  /// Select a menu item for complaint.
  void selectMenuItem(MenuItem item) {
    _selectedMenuItem = item;
    notifyListeners();
  }

  /// Select issue type for complaint.
  void selectIssueType(IssueType issueType) {
    _selectedIssueType = issueType;
    notifyListeners();
  }

  /// Submit complaint with selected menu item and issue type.
  /// Returns true if successful.
  bool submitComplaint() {
    if (_selectedMenuItem == null || _selectedIssueType == null || _currentUser == null) {
      return false;
    }

    _currentComplaint = _complaintService.submitComplaint(
      menuItem: _selectedMenuItem!,
      issueType: _selectedIssueType!,
      studentId: _currentUser!.id,
    );

    notifyListeners();
    return true;
  }

  /// Select a replacement item.
  void selectReplacement(ReplacementItem item) {
    _selectedReplacement = item;
    notifyListeners();
  }

  /// Confirm replacement selection.
  /// Records usage and updates complaint.
  bool confirmReplacement() {
    if (_currentComplaint == null || _selectedReplacement == null) {
      return false;
    }

    // Record replacement usage
    _replacementService.recordUsage(_selectedReplacement!.id);

    // Update complaint with replacement
    _complaintService.updateComplaintWithReplacement(
      _currentComplaint!.id,
      _selectedReplacement!.id,
    );

    notifyListeners();
    return true;
  }

  /// Reset feedback flow state.
  void resetFeedbackFlow() {
    _selectedMenuItem = null;
    _selectedIssueType = null;
    _currentComplaint = null;
    _selectedReplacement = null;
    notifyListeners();
  }

  // ============== REPLACEMENT POOL STATE ==============
  
  /// Get replacement items by pool type.
  List<ReplacementItem> getReplacementsByPoolType(PoolType poolType) {
    return _replacementService.getReplacementsByPoolType(poolType);
  }

  /// Get all replacement items.
  List<ReplacementItem> get allReplacements => _replacementService.getAllReplacements();

  // ============== ADMIN STATISTICS ==============
  
  /// Get total complaints count.
  int get totalComplaints => _complaintService.totalComplaints;

  /// Get all complaints.
  List<Complaint> get allComplaints => _complaintService.complaints;

  /// Get most complained food item.
  MenuItem? get mostComplainedItem => _complaintService.getMostComplainedItem();

  /// Get complaint counts by issue type.
  Map<IssueType, int> get complaintsByIssueType => 
      _complaintService.getComplaintsByIssueType();

  /// Get replacement usage by pool type.
  Map<PoolType, int> get replacementUsageByPool =>
      _replacementService.getUsageByPoolType();

  /// Get total replacements issued.
  int get totalReplacementsIssued => _replacementService.totalReplacementsIssued;

  /// Get most used replacement item.
  ReplacementItem? get mostUsedReplacement => 
      _replacementService.getMostUsedReplacement();
}
