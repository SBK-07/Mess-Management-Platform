import '../models/meal_type.dart';

enum DayType { workingDays, saturday, sundayHolidays }

class MessTimings {
  static const Map<MealType, Map<DayType, String>> timings = {
    MealType.breakfast: {
      DayType.workingDays: "6.50 am – 7.50 am",
      DayType.saturday: "7.00 am – 9.00 am",
      DayType.sundayHolidays: "7.30 am – 9.00 am",
    },
    MealType.lunch: {
      DayType.workingDays: "11.30 am – 1.30 pm",
      DayType.saturday: "11.30 am – 1.30 pm",
      DayType.sundayHolidays: "12.00 pm – 1.30 pm",
    },
    MealType.snacks: {
      DayType.workingDays: "03.40 pm – 5.00 pm",
      DayType.saturday: "03.40 pm – 6.00 pm",
      DayType.sundayHolidays: "04.00 pm – 5.00 pm",
    },
    MealType.dinner: {
      DayType.workingDays: "7.00 pm – 8.30 pm",
      DayType.saturday: "7.00 pm – 8.30 pm",
      DayType.sundayHolidays: "7.00 pm – 8.30 pm",
    },
  };

  static DayType getDayType(DateTime dateTime) {
    if (dateTime.weekday == DateTime.saturday) return DayType.saturday;
    if (dateTime.weekday == DateTime.sunday) return DayType.sundayHolidays;
    return DayType.workingDays;
  }

  static String getTiming(MealType mealType, DateTime dateTime) {
    final dayType = getDayType(dateTime);
    return timings[mealType]?[dayType] ?? "N/A";
  }
}
