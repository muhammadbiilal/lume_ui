/// The recipe library — `tool-data.js` `RECIPES`, typed.
///
/// Six recipes in the order the reference lists them. Names, cuisines and tags
/// are keys, not English, so the library reads in the reader's language; the
/// figures are the reference's own.
///
/// **Dayroz obligation:** this is fixture content. A real library needs an
/// owned source, per-recipe units (§15), and ingredient lists in the reader's
/// language before it ships.
library;

import 'package:flutter/foundation.dart';

import '../../../core/widgets/lume/lume_art.dart';

enum LumeRecipeCuisine { pakistani, levantine, mediterranean, global }

enum LumeRecipeTag {
  dinner,
  spicy,
  breakfast,
  vegetarian,
  lunch,
  budget,
  light,
  noCook,
  family,
  makeAhead,
}

@immutable
class LumeRecipe {
  const LumeRecipe({
    required this.id,
    required this.cuisine,
    required this.prep,
    required this.cook,
    required this.serves,
    required this.kcal,
    required this.tone,
    required this.glyph,
    required this.tags,
    required this.ingredients,
    required this.steps,
    required this.seed,
    this.favourite = false,
  });

  /// Stable, and the key its name is written under.
  final String id;
  final LumeRecipeCuisine cuisine;

  /// Minutes.
  final int prep;
  final int cook;
  final int serves;
  final int kcal;
  final LumeArtTone tone;
  final String glyph;
  final List<LumeRecipeTag> tags;
  final int ingredients;
  final int steps;

  /// `seed: r.name.length` — the English name's length, which is what places
  /// the reference's art shapes. Held as a number so the art does not change
  /// with the reader's language.
  final int seed;
  final bool favourite;

  int get minutes => prep + cook;
}

const List<LumeRecipe> kReferenceRecipes = <LumeRecipe>[
  LumeRecipe(
    id: 'chickenKarahi',
    cuisine: LumeRecipeCuisine.pakistani,
    prep: 15,
    cook: 35,
    serves: 4,
    kcal: 520,
    tone: LumeArtTone.rose,
    glyph: '🍲',
    tags: <LumeRecipeTag>[LumeRecipeTag.dinner, LumeRecipeTag.spicy],
    ingredients: 12,
    steps: 8,
    seed: 14,
    favourite: true,
  ),
  LumeRecipe(
    id: 'shakshuka',
    cuisine: LumeRecipeCuisine.levantine,
    prep: 10,
    cook: 20,
    serves: 2,
    kcal: 310,
    tone: LumeArtTone.amber,
    glyph: '🍳',
    tags: <LumeRecipeTag>[LumeRecipeTag.breakfast, LumeRecipeTag.vegetarian],
    ingredients: 9,
    steps: 6,
    seed: 9,
  ),
  LumeRecipe(
    id: 'daalChawal',
    cuisine: LumeRecipeCuisine.pakistani,
    prep: 10,
    cook: 40,
    serves: 4,
    kcal: 430,
    tone: LumeArtTone.green,
    glyph: '🍛',
    tags: <LumeRecipeTag>[LumeRecipeTag.lunch, LumeRecipeTag.budget],
    ingredients: 8,
    steps: 5,
    seed: 11,
    favourite: true,
  ),
  LumeRecipe(
    id: 'greekSalad',
    cuisine: LumeRecipeCuisine.mediterranean,
    prep: 12,
    cook: 0,
    serves: 2,
    kcal: 220,
    tone: LumeArtTone.sky,
    glyph: '🥗',
    tags: <LumeRecipeTag>[LumeRecipeTag.light, LumeRecipeTag.noCook],
    ingredients: 7,
    steps: 3,
    seed: 11,
  ),
  LumeRecipe(
    id: 'beefPulao',
    cuisine: LumeRecipeCuisine.pakistani,
    prep: 20,
    cook: 55,
    serves: 6,
    kcal: 610,
    tone: LumeArtTone.violet,
    glyph: '🍚',
    tags: <LumeRecipeTag>[LumeRecipeTag.dinner, LumeRecipeTag.family],
    ingredients: 14,
    steps: 9,
    seed: 10,
  ),
  LumeRecipe(
    id: 'overnightOats',
    cuisine: LumeRecipeCuisine.global,
    prep: 5,
    cook: 0,
    serves: 1,
    kcal: 290,
    tone: LumeArtTone.indigo,
    glyph: '🥣',
    tags: <LumeRecipeTag>[LumeRecipeTag.breakfast, LumeRecipeTag.makeAhead],
    ingredients: 6,
    steps: 3,
    seed: 14,
  ),
];
