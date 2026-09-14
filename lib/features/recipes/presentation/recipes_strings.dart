/// The recipe library, in the reader's language.
library;

import '../../../l10n/app_localizations.dart';
import '../data/recipe_fixtures.dart';

abstract final class LumeRecipesStrings {
  static String name(AppLocalizations l, String id) => switch (id) {
    'chickenKarahi' => l.recipeNameChickenKarahi,
    'shakshuka' => l.recipeNameShakshuka,
    'daalChawal' => l.recipeNameDaalChawal,
    'greekSalad' => l.recipeNameGreekSalad,
    'beefPulao' => l.recipeNameBeefPulao,
    'overnightOats' => l.recipeNameOvernightOats,
    _ => id,
  };

  static String cuisine(AppLocalizations l, LumeRecipeCuisine c) => switch (c) {
    LumeRecipeCuisine.pakistani => l.recipeCuisinePakistani,
    LumeRecipeCuisine.levantine => l.recipeCuisineLevantine,
    LumeRecipeCuisine.mediterranean => l.recipeCuisineMediterranean,
    LumeRecipeCuisine.global => l.recipeCuisineGlobal,
  };

  static String tag(AppLocalizations l, LumeRecipeTag t) => switch (t) {
    LumeRecipeTag.dinner => l.recipeTagDinner,
    LumeRecipeTag.spicy => l.recipeTagSpicy,
    LumeRecipeTag.breakfast => l.recipeTagBreakfast,
    LumeRecipeTag.vegetarian => l.recipeTagVegetarian,
    LumeRecipeTag.lunch => l.recipeTagLunch,
    LumeRecipeTag.budget => l.recipeTagBudget,
    LumeRecipeTag.light => l.recipeTagLight,
    LumeRecipeTag.noCook => l.recipeTagNoCook,
    LumeRecipeTag.family => l.recipeTagFamily,
    LumeRecipeTag.makeAhead => l.recipeTagMakeAhead,
  };
}
