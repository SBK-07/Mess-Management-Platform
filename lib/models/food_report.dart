import 'package:cloud_firestore/cloud_firestore.dart';
import 'issue_type.dart';
import 'meal_type.dart';

class FoodReport {
  final String id;
  final String studentId;
  final String studentName;
  final String menuItemId;
  final String menuItemName;
  final MealType mealType;
  final DateTime mealDate;
  final IssueType reason;
  final String comments;
  final DateTime timestamp;

  FoodReport({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.menuItemId,
    required this.menuItemName,
    required this.mealType,
    required this.mealDate,
    required this.reason,
    required this.comments,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'menuItemId': menuItemId,
      'menuItemName': menuItemName,
      'mealType': mealType.name,
      'mealDate': Timestamp.fromDate(mealDate),
      'reason': reason.name,
      'comments': comments,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  static DateTime _parseDate(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback ?? DateTime.now();
  }

  factory FoodReport.fromFirestore(String id, Map<String, dynamic> data) {
    final parsedTimestamp = _parseDate(data['timestamp']);
    return FoodReport(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Anonymous',
      menuItemId: data['menuItemId'] ?? '',
      menuItemName: data['menuItemName'] ?? '',
      mealType: MealType.values.firstWhere(
        (e) => e.name == data['mealType'],
        orElse: () => MealType.breakfast,
      ),
      mealDate: _parseDate(data['mealDate'], fallback: parsedTimestamp),
      reason: IssueType.values.firstWhere(
        (e) => e.name == data['reason'],
        orElse: () => IssueType.other,
      ),
      comments: data['comments'] ?? '',
      timestamp: parsedTimestamp,
    );
  }
}
