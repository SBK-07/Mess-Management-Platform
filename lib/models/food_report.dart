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

  factory FoodReport.fromFirestore(String id, Map<String, dynamic> data) {
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
      mealDate: (data['mealDate'] as Timestamp).toDate(),
      reason: IssueType.values.firstWhere(
        (e) => e.name == data['reason'],
        orElse: () => IssueType.other,
      ),
      comments: data['comments'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
