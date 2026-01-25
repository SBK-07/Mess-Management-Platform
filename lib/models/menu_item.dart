/// Enum representing different meal types in a day.
enum MealType {
  breakfast,
  lunch,
  dinner,
}

/// Extension on MealType to provide display names
extension MealTypeExtension on MealType {
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
    }
  }

  /// Get icon for each meal type
  String get icon {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
    }
  }
}

/// MenuItem model representing a food item in the menu.
/// 
/// Each menu item belongs to a specific meal type (breakfast, lunch, or dinner).
class MenuItem {
  final String id;
  final String name;
  final MealType mealType;
  final String description;
  final String emoji;

  MenuItem({
    required this.id,
    required this.name,
    required this.mealType,
    this.description = '',
    this.emoji = '🍽️',
  });

  /// Factory constructor to create a MenuItem from a Map
  factory MenuItem.fromMap(Map<String, dynamic> map) {
    return MenuItem(
      id: map['id'] as String,
      name: map['name'] as String,
      mealType: MealType.values[map['mealType'] as int],
      description: map['description'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🍽️',
    );
  }

  /// Convert MenuItem to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mealType': mealType.index,
      'description': description,
      'emoji': emoji,
    };
  }

  @override
  String toString() => 'MenuItem(id: $id, name: $name, mealType: ${mealType.displayName})';
}
