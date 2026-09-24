/// Small string/icon mappings for Meal Plan — no state, no logic beyond a
/// lookup.
library;

import '../../../core/icons/lume_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/mealplan_model.dart';

abstract final class MealPlanText {
  static String slot(AppLocalizations l, MealSlot s) => switch (s) {
    MealSlot.breakfast => l.mealBreakfast,
    MealSlot.lunch => l.mealLunch,
    MealSlot.dinner => l.mealDinner,
  };

  static String icon(MealSlot s) => switch (s) {
    MealSlot.breakfast => LumeIcons.sun,
    MealSlot.lunch => LumeIcons.utensils,
    MealSlot.dinner => LumeIcons.moonStar,
  };
}
