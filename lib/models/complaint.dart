import 'menu_item.dart';

/// Enum representing different types of issues that can be reported.
enum IssueType {
  taste,
  hygiene,
  quantity,
}

/// Extension on IssueType to provide display names and icons
extension IssueTypeExtension on IssueType {
  String get displayName {
    switch (this) {
      case IssueType.taste:
        return 'Taste Issue';
      case IssueType.hygiene:
        return 'Hygiene Issue';
      case IssueType.quantity:
        return 'Quantity Issue';
    }
  }

  String get icon {
    switch (this) {
      case IssueType.taste:
        return '👅';
      case IssueType.hygiene:
        return '🧹';
      case IssueType.quantity:
        return '📏';
    }
  }

  String get description {
    switch (this) {
      case IssueType.taste:
        return 'The food doesn\'t taste good';
      case IssueType.hygiene:
        return 'Hygiene standards not met';
      case IssueType.quantity:
        return 'Serving size was insufficient';
    }
  }
}

/// Complaint model representing a dissatisfaction report from a student.
/// 
/// Stores the menu item, issue type, and timestamp of the complaint.
class Complaint {
  final String id;
  final MenuItem menuItem;
  final IssueType issueType;
  final DateTime timestamp;
  final String studentId;
  final String? replacementId;

  Complaint({
    required this.id,
    required this.menuItem,
    required this.issueType,
    required this.timestamp,
    required this.studentId,
    this.replacementId,
  });

  /// Create a copy of this complaint with optional field updates
  Complaint copyWith({
    String? id,
    MenuItem? menuItem,
    IssueType? issueType,
    DateTime? timestamp,
    String? studentId,
    String? replacementId,
  }) {
    return Complaint(
      id: id ?? this.id,
      menuItem: menuItem ?? this.menuItem,
      issueType: issueType ?? this.issueType,
      timestamp: timestamp ?? this.timestamp,
      studentId: studentId ?? this.studentId,
      replacementId: replacementId ?? this.replacementId,
    );
  }

  @override
  String toString() =>
      'Complaint(id: $id, menuItem: ${menuItem.name}, issueType: ${issueType.displayName})';
}
