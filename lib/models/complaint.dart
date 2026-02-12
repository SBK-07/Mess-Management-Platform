import 'menu_item.dart';
import 'issue_type.dart';



/// Extension on IssueType to provide display names and icons
extension IssueTypeExtension on IssueType {
  String get displayName {
    switch (this) {
      case IssueType.taste:
        return 'Taste Issue';
      case IssueType.hygiene:
        return 'Hygiene Issue';
      case IssueType.temperature:
        return 'Temperature Issue';
      case IssueType.portionSize:
        return 'Portion Size Issue';
      case IssueType.quality:
        return 'Quality Issue';
      case IssueType.other:
        return 'Other Issue';
    }
  }

  String get icon {
    switch (this) {
      case IssueType.taste:
        return '👅';
      case IssueType.hygiene:
        return '🧹';
      case IssueType.temperature:
        return '🌡️';
      case IssueType.portionSize:
        return '⚖️';
      case IssueType.quality:
        return '🌟';
      case IssueType.other:
        return '📝';
    }
  }

  String get description {
    switch (this) {
      case IssueType.taste:
        return 'The food doesn\'t taste good';
      case IssueType.hygiene:
        return 'Hygiene standards not met';
      case IssueType.temperature:
        return 'Food was served at an incorrect temperature';
      case IssueType.portionSize:
        return 'Serving size was insufficient';
      case IssueType.quality:
        return 'Overall quality was below expectations';
      case IssueType.other:
        return 'Other feedback or issue';
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
