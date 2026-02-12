import '../models/menu_item.dart';
import '../models/meal_type.dart';
import '../models/replacement.dart';
import '../models/pool_type.dart';

/// Dummy data for the mess management system prototype.
///
/// Contains hardcoded menu items and replacement pool items.
class DummyData {
  // Private constructor to prevent instantiation
  DummyData._();

  // ============== TODAY'S MENU ==============
  // Breakfast: Idli, Dosa, Sambar
  // Lunch: Rice, Dal, Sabzi, Roti
  // Dinner: Chapati, Paneer, Rice

  static final List<MenuItem> todaysMenu = [
    // Breakfast items
    MenuItem(
      id: 'menu_1',
      name: 'Idli',
      mealType: MealType.breakfast,
      description: 'Soft steamed rice cakes served with chutney',
      emoji: '🥟',
    ),
    MenuItem(
      id: 'menu_2',
      name: 'Dosa',
      mealType: MealType.breakfast,
      description: 'Crispy rice crepe with sambar',
      emoji: '🥞',
    ),
    MenuItem(
      id: 'menu_3',
      name: 'Sambar',
      mealType: MealType.breakfast,
      description: 'Spiced lentil soup with vegetables',
      emoji: '🍲',
    ),

    // Lunch items
    MenuItem(
      id: 'menu_4',
      name: 'Rice',
      mealType: MealType.lunch,
      description: 'Steamed basmati rice',
      emoji: '🍚',
    ),
    MenuItem(
      id: 'menu_5',
      name: 'Dal',
      mealType: MealType.lunch,
      description: 'Yellow lentil curry',
      emoji: '🥣',
    ),
    MenuItem(
      id: 'menu_6',
      name: 'Sabzi',
      mealType: MealType.lunch,
      description: 'Mixed vegetable curry',
      emoji: '🥗',
    ),
    MenuItem(
      id: 'menu_7',
      name: 'Roti',
      mealType: MealType.lunch,
      description: 'Fresh whole wheat flatbread',
      emoji: '🫓',
    ),

    // Snacks items
    MenuItem(
      id: 'menu_snacks_1',
      name: 'Tea & Biscuits',
      mealType: MealType.snacks,
      description: 'Hot ginger tea with crispy biscuits',
      emoji: '☕',
    ),
    MenuItem(
      id: 'menu_snacks_2',
      name: 'Samosa',
      mealType: MealType.snacks,
      description: 'Spicy potato samosa',
      emoji: '🥟',
    ),

    // Dinner items
    MenuItem(
      id: 'menu_8',
      name: 'Chapati',
      mealType: MealType.dinner,
      description: 'Soft whole wheat flatbread',
      emoji: '🫓',
    ),
    MenuItem(
      id: 'menu_9',
      name: 'Paneer',
      mealType: MealType.dinner,
      description: 'Cottage cheese in rich gravy',
      emoji: '🧀',
    ),
    MenuItem(
      id: 'menu_10',
      name: 'Rice',
      mealType: MealType.dinner,
      description: 'Steamed jeera rice',
      emoji: '🍚',
    ),
  ];

  // ============== REPLACEMENT POOLS ==============
  // 2-3 items per pool as requested

  static final List<ReplacementItem> replacementItems = [
    // Snack Pool
    ReplacementItem(
      id: 'snack_1',
      name: 'Biscuits',
      poolType: PoolType.snack,
      description: 'Crispy butter biscuits',
      emoji: '🍪',
      targetMealType: MealType.snacks,
    ),
    ReplacementItem(
      id: 'snack_2',
      name: 'Bread Toast',
      poolType: PoolType.snack,
      description: 'Crispy toasted bread',
      emoji: '🍞',
      targetMealType: MealType.breakfast,
    ),
    ReplacementItem(
      id: 'snack_3',
      name: 'Cornflakes',
      poolType: PoolType.snack,
      description: 'Bowl of flakes with milk',
      emoji: '🥣',
      targetMealType: MealType.breakfast,
    ),

    // Fruit Pool
    ReplacementItem(
      id: 'fruit_1',
      name: 'Apple',
      poolType: PoolType.fruit,
      description: 'Fresh red apple',
      emoji: '🍎',
    ),
    ReplacementItem(
      id: 'fruit_2',
      name: 'Banana',
      poolType: PoolType.fruit,
      description: 'Ripe yellow banana',
      emoji: '🍌',
    ),
    ReplacementItem(
      id: 'fruit_3',
      name: 'Curd',
      poolType: PoolType.fruit,
      description: 'Fresh bowl of curd',
      emoji: '🥛',
      targetMealType: MealType.lunch,
    ),

    // Protein Pool
    ReplacementItem(
      id: 'protein_1',
      name: 'Boiled Egg',
      poolType: PoolType.protein,
      description: 'Farm fresh boiled egg',
      emoji: '🥚',
    ),
    ReplacementItem(
      id: 'protein_2',
      name: 'Paneer Cube',
      poolType: PoolType.protein,
      description: 'Fresh protein-rich paneer',
      emoji: '🧀',
      targetMealType: MealType.dinner,
    ),
  ];

  // ============== HELPER METHODS ==============

  /// Get menu items by meal type
  static List<MenuItem> getMenuByMealType(MealType mealType) {
    return todaysMenu.where((item) => item.mealType == mealType).toList();
  }

  /// Get replacement items by pool type, optionally filtered by meal type
  static List<ReplacementItem> getReplacementsByPoolType(PoolType poolType, {MealType? mealType}) {
    return replacementItems.where((item) {
      final matchesPool = item.poolType == poolType;
      final matchesMeal = mealType == null || item.targetMealType == null || item.targetMealType == mealType;
      return matchesPool && matchesMeal;
    }).toList();
  }

  /// Find menu item by id
  static MenuItem? findMenuItemById(String id) {
    try {
      return todaysMenu.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Find replacement item by id
  static ReplacementItem? findReplacementById(String id) {
    try {
      return replacementItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}
