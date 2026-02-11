import 'package:cloud_firestore/cloud_firestore.dart';

class MenuRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final MenuRepository instance = MenuRepository._();
  MenuRepository._();

  /// Fetches a specific meal type's weekly menu from Firestore
  Future<Map<String, dynamic>> getMealMenu(String mealType) async {
    final doc = await _db.collection('mess_menu').doc(mealType).get();
    return doc.data() ?? {};
  }

  /// One-time setup to seed the menu data as requested
  Future<void> seedInitialMenu() async {
    final batch = _db.batch();
    final menuRef = _db.collection('mess_menu');

    // Breakfast
    batch.set(menuRef.doc('breakfast'), {
      'Monday': {
        'menu': ["Pongal", "Sambar", "Coconut Chutney", "methu vadai (1)"],
        'option': "Bread,Jam",
        'drink': "Coffee / Milk"
      },
      'Tuesday': {
        'menu': ["Idly", "Sambar", "Kara Chutney", "masal vadai (1)"],
        'option': "Bread,Jam",
        'drink': "Coffee / Milk"
      },
      'Wednesday': {
        'menu': ["Poori", "Alu Masala"],
        'option': "Bread,Jam",
        'drink': "Coffee / Milk"
      },
      'Thursday': {
        'menu': ["Varagu Pongal", "Sambar", "Coconut Chutney", "methu vadai (1)"],
        'option': "Bread,Jam",
        'drink': "Coffee / Milk"
      },
      'Friday': {
        'menu': ["Kal Dosai", "Coconut Chutney", "Sambar"],
        'option': "Bread,Jam",
        'drink': "Coffee / Milk"
      },
      'Saturday': {
        'menu': ["Poori", "Channa Masala"],
        'option': "Bread,Jam",
        'drink': "Coffee / Milk"
      },
      'Sunday': {
        'menu': ["Masala Dosai", "Sambar", "Coconut Chutney"],
        'option': "Bread,Jam",
        'drink': "Coffee / Milk"
      },
    });

    // Lunch
    batch.set(menuRef.doc('lunch'), {
      'Monday': {'items': ["Rice", "Sambar", "Rasam", "Poriyal", "Kootu", "Butter Milk", "Pappad", "Pickle"]},
      'Tuesday': {'items': ["Rice", "Vathakulambu / Karakulambu", "Rasam", "Poriyal", "Kootu", "Curd (1 Cup)", "Pappad", "Pickle"]},
      'Wednesday': {'items': ["Variety Rice (Tamarind / Tomato / Puthina/Lemon)", "Rice", "Rasam", "Potato Poriyal", "Gongura Thokku", "Curd (1Cup)", "Fryums", "Pickle"]},
      'Thursday': {'items': ["Rice", "More Kulambu", "Rasam", "Poriyal", "Kootu", "Buttermilk", "Fryums", "Pickle"]},
      'Friday': {'items': ["Rice", "Dhal", "Ghee (1 Spoon)", "Rasam", "Potato kara Curry", "Sweet Payasam", "Buttermilk", "Pappad", "Pickle"]},
      'Saturday': {'items': ["Rice", "Sambar", "Rasam", "Poriyal", "Kootu", "Curd (1Cup)", "Fryums", "Pickle"]},
      'Sunday': {'items': ["Biriyani", "NV : Chicken 65 / Veg: Gobi Manjurian + Ice cream", "Onion Raitha", "Bread Halwa", "Brinjal Gravy", "Rice", "Rasam", "Buttermilk", "Pickle"]},
    });

    // Snacks
    batch.set(menuRef.doc('snacks'), {
      'Monday': {'snack': "Tea Biscuit (3 No's)", 'drink': "Tea / Milk"},
      'Tuesday': {'snack': "Onion Samosa (1 No) Sauce", 'drink': "Tea / Milk"},
      'Wednesday': {'snack': "Pani Poori (5 No's)", 'drink': "Tea / Milk"},
      'Thursday': {'snack': "Boiled Peanuts", 'drink': "Tea / Milk"},
      'Friday': {'snack': "Veg Roll (2 No's) Sauce", 'drink': "Tea / Milk"},
      'Saturday': {'snack': "Ribbon Pakoda", 'drink': "Tea / Milk"},
      'Sunday': {'snack': "White Channa Sundal", 'drink': "Tea / Milk"},
    });

    // Dinner
    batch.set(menuRef.doc('dinner'), {
      'Monday': {'items': ["Chappathi", "Green Peas Masala", "NV-Boiled Egg", "Veg: Pineapple Pudding", "Curd Rice", "Pickle", "Banana"]},
      'Tuesday': {'items': ["Plain Dosai", "NV: Pepper Chicken Gravy", "Veg: Pepper Mushroom Gravy + Ice cream", "Plain Salna", "Curd Rice", "Pickle", "Banana"]},
      'Wednesday': {'items': ["Noodles", "Tomato Sauce", "Rice", "Rasam", "Buttermilk", "Pickle", "Banana"]},
      'Thursday': {'items': ["Chappathi", "Black Channa Kuruma", "NV: Chicken kuruma", "Veg: French Fries + Ice cream", "Rice", "Rasam", "Buttermilk", "Pickle", "Banana"]},
      'Friday': {'items': ["Veg Biriyani", "Onion Raitha", "Kuruma", "NV: Boiled egg", "Veg: Pineapple Pudding", "Curd Rice", "Pickle", "Banana"]},
      'Saturday': {'items': ["Idly", "Podi", "Gingelly oil", "Coconut Chutney", "Curd Rice", "Pickle", "Banana"]},
      'Sunday': {'items': ["Idiyappam (4 No's)", "Veg Paya", "Rice", "Rasam", "Buttermilk", "Pickle", "Banana"]},
    });

    await batch.commit();
  }
}
