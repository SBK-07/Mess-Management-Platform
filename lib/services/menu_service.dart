import '../models/menu_item.dart';
import '../models/meal_type.dart';
import '../utils/dummy_data.dart';
import '../repositories/menu_repository.dart';

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

  /// Fetches the menu for a specific day from Firestore and converts to MenuItem list
  Future<List<MenuItem>> getFirestoreMenuForDay(String dayName) async {
    final repo = MenuRepository.instance;
    final List<MenuItem> items = [];

    final results = await Future.wait([
      repo.getMealMenu('breakfast'),
      repo.getMealMenu('lunch'),
      repo.getMealMenu('snacks'),
      repo.getMealMenu('dinner'),
    ]);

    final breakfastData = results[0][dayName];
    final lunchData = results[1][dayName];
    final snacksData = results[2][dayName];
    final dinnerData = results[3][dayName];

    if (breakfastData != null) {
      final List menu = breakfastData['menu'] ?? [];
      for (var name in menu) {
        items.add(MenuItem(
          id: 'fs_bf_${dayName}_$name',
          name: name,
          mealType: MealType.breakfast,
          description: breakfastData['drink'] ?? '',
        ));
      }
    }

    if (lunchData != null) {
      final List menu = lunchData['items'] ?? [];
      for (var name in menu) {
        items.add(MenuItem(
          id: 'fs_lh_${dayName}_$name',
          name: name,
          mealType: MealType.lunch,
        ));
      }
    }

    if (snacksData != null) {
      final String snack = snacksData['snack'] ?? '';
      if (snack.isNotEmpty) {
        items.add(MenuItem(
          id: 'fs_sn_${dayName}_$snack',
          name: snack,
          mealType: MealType.snacks,
          description: snacksData['drink'] ?? '',
        ));
      }
    }

    if (dinnerData != null) {
      final List menu = dinnerData['items'] ?? [];
      for (var name in menu) {
        items.add(MenuItem(
          id: 'fs_dn_${dayName}_$name',
          name: name,
          mealType: MealType.dinner,
        ));
      }
    }

    return items;
  }

  /// Get count of items for each meal type.
  Map<MealType, int> getMenuCounts() {
    return {
      MealType.breakfast: getMenuByMealType(MealType.breakfast).length,
      MealType.lunch: getMenuByMealType(MealType.lunch).length,
      MealType.snacks: getMenuByMealType(MealType.snacks).length,
      MealType.dinner: getMenuByMealType(MealType.dinner).length,
    };
  }
}
