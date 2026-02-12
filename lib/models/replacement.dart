import 'pool_type.dart';
import 'meal_type.dart';

/// Enum representing different replacement pool types.


/// Extension on PoolType to provide display names and colors
extension PoolTypeExtension on PoolType {
  String get displayName {
    switch (this) {
      case PoolType.snack:
        return 'Snack Pool';
      case PoolType.fruit:
        return 'Fruit Pool';
      case PoolType.protein:
        return 'Protein Pool';
    }
  }

  String get icon {
    switch (this) {
      case PoolType.snack:
        return '🍪';
      case PoolType.fruit:
        return '🍎';
      case PoolType.protein:
        return '🥚';
    }
  }

  String get description {
    switch (this) {
      case PoolType.snack:
        return 'Light snacks and munchies';
      case PoolType.fruit:
        return 'Fresh fruits';
      case PoolType.protein:
        return 'Protein-rich alternatives';
    }
  }
}

/// ReplacementItem model representing an item in the replacement pool.
/// 
/// Students can choose from these items when they report dissatisfaction.
class ReplacementItem {
  final String id;
  final String name;
  final PoolType poolType;
  final String description;
  final String emoji;
  final MealType? targetMealType; // null means available for all meals

  ReplacementItem({
    required this.id,
    required this.name,
    required this.poolType,
    this.description = '',
    this.emoji = '🍴',
    this.targetMealType,
  });

  /// Factory constructor to create a ReplacementItem from a Map
  factory ReplacementItem.fromMap(Map<String, dynamic> map) {
    return ReplacementItem(
      id: map['id'] as String,
      name: map['name'] as String,
      poolType: PoolType.values[map['poolType'] as int],
      description: map['description'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🍴',
      targetMealType: map['targetMealType'] != null 
          ? MealType.values[map['targetMealType'] as int] 
          : null,
    );
  }

  /// Convert ReplacementItem to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'poolType': poolType.index,
      'description': description,
      'emoji': emoji,
      'targetMealType': targetMealType?.index,
    };
  }

  @override
  String toString() => 'ReplacementItem(id: $id, name: $name, poolType: ${poolType.displayName})';
}
