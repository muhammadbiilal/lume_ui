/// Daily Duas' own UI chrome, in the reader's language — a dua's descriptive
/// title and its category's label. Neither is scripture: the reference's
/// `title` and `DUA_CATEGORIES[].label` are its own English copy, translated
/// here the way every other tool's chrome is (C77). The dua's Arabic, its
/// English rendering and its citation are never touched by this file — they
/// come from `duas_fixtures.dart` exactly as the reference gives them.
library;

import '../../../l10n/app_localizations.dart';
import '../domain/duas_model.dart';

abstract final class LumeDuasStrings {
  /// A dua's own descriptive title — the reference's `title`, by
  /// [LumeDua.id].
  static String title(AppLocalizations l, String id) => switch (id) {
    'morningRemembrance' => l.duaTitleMorningRemembrance,
    'travel' => l.duaTitleTravel,
    'anxiety' => l.duaTitleAnxiety,
    'beforeEating' => l.duaTitleBeforeEating,
    'beforeSleeping' => l.duaTitleBeforeSleeping,
    _ => id,
  };

  /// A category's own label — the reference's `DUA_CATEGORIES[].label`.
  static String category(AppLocalizations l, LumeDuaCategory c) => switch (c) {
    LumeDuaCategory.morning => l.duaCategoryMorning,
    LumeDuaCategory.daily => l.duaCategoryDaily,
    LumeDuaCategory.travel => l.duaCategoryTravel,
    LumeDuaCategory.distress => l.duaCategoryDistress,
    LumeDuaCategory.food => l.duaCategoryFood,
    LumeDuaCategory.sleep => l.duaCategorySleep,
  };
}
