/// The duas the reader browses — `tool-data.js` `DUAS`, and the day's choice
/// `context.js` `dayIndex` makes.
///
/// Five duas, ported exactly as `tool-data.js` gives them: Arabic verbatim,
/// English as the reference's own unverified rendering, and each citation
/// exactly as cited. See `duas_model.dart`'s library comment for what the
/// reference's own category figures claim and what this build corrects.
library;

import '../../hadith/domain/religious_content.dart' show LumeContentAttribution;
import '../domain/duas_model.dart';

abstract final class LumeDuaFixtures {
  /// Who the English is credited to: the web reference, not a verified
  /// translation. Re-exported from `duas_model.dart` so callers reading this
  /// fixture file (the way `hadith_fixtures.dart`'s reader would expect) find
  /// it here too.
  static const String edition = kLumeDuaEdition;

  /// Where every fixture came from. No licence: a release must not ship it.
  static const LumeContentAttribution attribution = kLumeDuaAttribution;

  /// `DUAS`, in the reference's order.
  static const List<LumeDua> all = <LumeDua>[
    LumeDua(
      id: 'morningRemembrance',
      category: LumeDuaCategory.morning,
      arabic: 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ',
      translation:
          'We have entered the morning and the dominion belongs to God.',
      citation: 'Sahih Muslim 2723',
    ),
    LumeDua(
      id: 'travel',
      category: LumeDuaCategory.travel,
      arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَٰذَا',
      translation: 'Glory to Him who has subjected this to us.',
      citation: 'Az-Zukhruf 13',
    ),
    LumeDua(
      id: 'anxiety',
      category: LumeDuaCategory.distress,
      arabic: 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ',
      translation: 'O God, I seek refuge in You from anxiety and sorrow.',
      citation: 'Sahih al-Bukhari 6369',
    ),
    LumeDua(
      id: 'beforeEating',
      category: LumeDuaCategory.food,
      arabic: 'بِسْمِ اللَّهِ',
      translation: 'In the name of God.',
      citation: 'Sunan Abi Dawud 3767',
    ),
    LumeDua(
      id: 'beforeSleeping',
      category: LumeDuaCategory.sleep,
      arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      translation: 'In Your name, O God, I die and I live.',
      citation: 'Sahih al-Bukhari 6324',
    ),
  ];

  /// `dayIndex(n)` — `(year × 372 + month × 31 + date) % n`, with the month
  /// counted from zero as JavaScript counts it. Identical to Hadith's own
  /// (`hadith_fixtures.dart`), because it is the same reference function.
  static int dayIndex(DateTime day, int n) =>
      (day.year * 372 + (day.month - 1) * 31 + day.day) % n;

  /// The dua of [day].
  static LumeDua of(DateTime day) => all[dayIndex(day, all.length)];

  /// How many of the five real duas actually carry [category] — computed the
  /// way the reference's own `build()` computes its tile count
  /// (`DUAS.filter(d => d.cat === x.id).length`), never the reference's
  /// separately-declared, inflated `DUA_CATEGORIES[].n` (see `duas_model.dart`
  /// for what that figure claims and why it is not ported).
  static int countOf(LumeDuaCategory category) =>
      all.where((LumeDua d) => d.category == category).length;

  /// A category, then a search through the title, the translation, the
  /// Arabic and the citation — the reference's own `build()` searches only
  /// `title + tr`; this also matches the citation and the Arabic, the way
  /// Hadith's own `shown()` matches every fixture-held field rather than a
  /// subset of them.
  ///
  /// [titleOf] is the title as the reader sees it — it is translated, so the
  /// screen supplies it; without it only the fixture-held fields are
  /// searched.
  static List<LumeDua> shown({
    LumeDuaCategory? category,
    String query = '',
    String Function(LumeDua d)? titleOf,
  }) {
    final String q = query.trim().toLowerCase();
    return <LumeDua>[
      for (final LumeDua d in all)
        if ((category == null || d.category == category) &&
            (q.isEmpty ||
                '${titleOf?.call(d) ?? ''} ${d.arabic} ${d.translation} '
                        '${d.citation}'
                    .toLowerCase()
                    .contains(q)))
          d,
    ];
  }
}
