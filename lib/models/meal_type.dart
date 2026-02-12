enum MealType {
  breakfast,
  lunch,
  snacks,
  dinner;

  String get displayName {
    switch (this) {
      case MealType.breakfast: return 'Breakfast';
      case MealType.lunch: return 'Lunch';
      case MealType.snacks: return 'Snacks';
      case MealType.dinner: return 'Dinner';
    }
  }
}
