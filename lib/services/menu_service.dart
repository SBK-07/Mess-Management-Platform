import '../models/menu_item.dart';
import '../utils/dummy_data.dart';

/// Menu service for retrieving menu data.
/// 
/// Provides access to today's menu items filtered by meal type.
class MenuService {
  // Private constructor for singleton pattern
  MenuService._();
  static final MenuService _instance = MenuService._();
  static MenuService get instance => _instance;

  /// Get all menu items for today.
  List<MenuItem> getTodaysMenu() {
    return DummyData.todaysMenu;
  }

  /// Get menu items filtered by meal type.
  /// 
  /// [mealType] - The type of meal (breakfast, lunch, dinner)
  List<MenuItem> getMenuByMealType(MealType mealType) {
    return DummyData.getMenuByMealType(mealType);
  }

  /// Get a specific menu item by ID.
  MenuItem? getMenuItemById(String id) {
    return DummyData.findMenuItemById(id);
  }

  /// Get count of items for each meal type.
  Map<MealType, int> getMenuCounts() {
    return {
      MealType.breakfast: getMenuByMealType(MealType.breakfast).length,
      MealType.lunch: getMenuByMealType(MealType.lunch).length,
      MealType.dinner: getMenuByMealType(MealType.dinner).length,
    };
  }
}
