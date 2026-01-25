import '../models/user.dart';
import '../models/menu_item.dart';
import '../models/replacement.dart';

/// Dummy data for the mess management system prototype.
/// 
/// Contains hardcoded users, menu items, and replacement pool items.
class DummyData {
  // Private constructor to prevent instantiation
  DummyData._();

  // ============== USERS ==============
  // 3 Students: Bala, Dhanush, Vishnu
  // 1 Admin: admin
  
  static final List<User> users = [
    User(
      id: 'student_1',
      name: 'Bala',
      username: 'bala',
      password: '1234',
      isAdmin: false,
    ),
    User(
      id: 'student_2',
      name: 'Dhanush',
      username: 'dhanush',
      password: '1234',
      isAdmin: false,
    ),
    User(
      id: 'student_3',
      name: 'Vishnu',
      username: 'vishnu',
      password: '1234',
      isAdmin: false,
    ),
    User(
      id: 'admin_1',
      name: 'Administrator',
      username: 'admin',
      password: 'admin',
      isAdmin: true,
    ),
  ];

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
    // Snack Pool (3 items)
    ReplacementItem(
      id: 'snack_1',
      name: 'Biscuits',
      poolType: PoolType.snack,
      description: 'Crispy butter biscuits',
      emoji: '🍪',
    ),
    ReplacementItem(
      id: 'snack_2',
      name: 'Samosa',
      poolType: PoolType.snack,
      description: 'Crispy potato filled pastry',
      emoji: '🥟',
    ),
    ReplacementItem(
      id: 'snack_3',
      name: 'Puff',
      poolType: PoolType.snack,
      description: 'Flaky vegetable puff',
      emoji: '🥐',
    ),

    // Fruit Pool (3 items)
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
      name: 'Orange',
      poolType: PoolType.fruit,
      description: 'Juicy citrus orange',
      emoji: '🍊',
    ),

    // Protein Pool (2 items)
    ReplacementItem(
      id: 'protein_1',
      name: 'Boiled Egg',
      poolType: PoolType.protein,
      description: 'Farm fresh boiled egg',
      emoji: '🥚',
    ),
    ReplacementItem(
      id: 'protein_2',
      name: 'Milk',
      poolType: PoolType.protein,
      description: 'Fresh cold milk (200ml)',
      emoji: '🥛',
    ),
  ];

  // ============== HELPER METHODS ==============

  /// Get menu items by meal type
  static List<MenuItem> getMenuByMealType(MealType mealType) {
    return todaysMenu.where((item) => item.mealType == mealType).toList();
  }

  /// Get replacement items by pool type
  static List<ReplacementItem> getReplacementsByPoolType(PoolType poolType) {
    return replacementItems.where((item) => item.poolType == poolType).toList();
  }

  /// Find user by username
  static User? findUserByUsername(String username) {
    try {
      return users.firstWhere(
        (user) => user.username.toLowerCase() == username.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
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
