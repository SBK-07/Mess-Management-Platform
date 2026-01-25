import '../models/complaint.dart';
import '../models/menu_item.dart';

/// Complaint service for managing dissatisfaction reports.
/// 
/// Handles complaint submission and statistics retrieval.
class ComplaintService {
  // Private constructor for singleton pattern
  ComplaintService._();
  static final ComplaintService _instance = ComplaintService._();
  static ComplaintService get instance => _instance;

  // In-memory storage for complaints
  final List<Complaint> _complaints = [];

  /// Get all complaints.
  List<Complaint> get complaints => List.unmodifiable(_complaints);

  /// Submit a new complaint.
  /// 
  /// Returns the created complaint.
  Complaint submitComplaint({
    required MenuItem menuItem,
    required IssueType issueType,
    required String studentId,
  }) {
    final complaint = Complaint(
      id: 'complaint_${DateTime.now().millisecondsSinceEpoch}',
      menuItem: menuItem,
      issueType: issueType,
      timestamp: DateTime.now(),
      studentId: studentId,
    );

    _complaints.add(complaint);
    return complaint;
  }

  /// Update complaint with replacement selection.
  void updateComplaintWithReplacement(String complaintId, String replacementId) {
    final index = _complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      _complaints[index] = _complaints[index].copyWith(
        replacementId: replacementId,
      );
    }
  }

  /// Get total complaints count.
  int get totalComplaints => _complaints.length;

  /// Get most complained food item.
  /// 
  /// Returns the menu item with most complaints, or null if no complaints.
  MenuItem? getMostComplainedItem() {
    if (_complaints.isEmpty) return null;

    // Count complaints per menu item
    final Map<String, int> complaintCounts = {};
    for (var complaint in _complaints) {
      final itemId = complaint.menuItem.id;
      complaintCounts[itemId] = (complaintCounts[itemId] ?? 0) + 1;
    }

    // Find item with max complaints
    String? maxItemId;
    int maxCount = 0;
    complaintCounts.forEach((itemId, count) {
      if (count > maxCount) {
        maxCount = count;
        maxItemId = itemId;
      }
    });

    if (maxItemId == null) return null;

    // Return the menu item
    return _complaints
        .firstWhere((c) => c.menuItem.id == maxItemId)
        .menuItem;
  }

  /// Get complaint counts by issue type.
  Map<IssueType, int> getComplaintsByIssueType() {
    final Map<IssueType, int> counts = {
      IssueType.taste: 0,
      IssueType.hygiene: 0,
      IssueType.quantity: 0,
    };

    for (var complaint in _complaints) {
      counts[complaint.issueType] = (counts[complaint.issueType] ?? 0) + 1;
    }

    return counts;
  }

  /// Get complaints for a specific menu item.
  List<Complaint> getComplaintsForMenuItem(String menuItemId) {
    return _complaints
        .where((c) => c.menuItem.id == menuItemId)
        .toList();
  }

  /// Get complaints submitted by a specific student.
  List<Complaint> getComplaintsByStudent(String studentId) {
    return _complaints
        .where((c) => c.studentId == studentId)
        .toList();
  }

  /// Clear all complaints (for testing purposes).
  void clearComplaints() {
    _complaints.clear();
  }
}
