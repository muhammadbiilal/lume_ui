/// Daily Duas, as `tool-data.js` `DUA_CATEGORIES` and `DUAS` hold them, and
/// the day's choice `context.js` `dayIndex` makes.
///
/// A dua is religious text: its Arabic, its rendering into English and its
/// citation are kept exactly as the reference gives them. Unlike Hadith
/// (`hadith_fixtures.dart`), the reference's own `DUAS` array carries a real
/// original — `ar` is the dua as it is prayed, not a machine translation —
/// so it is recorded as [LumeDua.arabic] and resolved as an *original*, not
/// invented here (C82). Its English (`tr`) is still only a rendering the
/// reference credits to itself, never a verified translation, on the same
/// footing as Hadith's fixture English (C77, C82).
///
/// **The reference inflates its own category counts.** `DUA_CATEGORIES`
/// states `morning: 12, daily: 18, travel: 6, distress: 9, food: 5, sleep: 7`
/// — headline figures for a fuller library that was never built. The `DUAS`
/// array actually holds five duas in total, one in each of five categories,
/// and *none* filed under `daily` at all. Tellingly, the reference's own
/// `build()` never reads `DUA_CATEGORIES[].n` for the tile it draws; it
/// counts `DUAS.filter(d => d.cat === x.id).length` itself, live. This build
/// does the same — `LumeDuaFixtures.countOf` computes a category's count from
/// the actual fixture list, never copied from the reference's own inflated
/// figure — so `daily`'s tile honestly reads zero rather than eighteen, the
/// same correction Meal Plan's "18 planned" received.
///
/// **Dayroz obligation:** a licensed dua source — with the fuller library
/// the reference's own category figures imply, verified translations beyond
/// English, a verified Urdu rendering, licences and attribution recorded.
/// None of that exists in the reference this build converts.
library;

import 'package:flutter/foundation.dart';

import '../../hadith/domain/religious_content.dart';

/// The category a dua is filed under, as the reference's tile names it.
///
/// A category's own icon is never translated — an icon has no language — but
/// its label is UI chrome, not scripture, so it is localized through
/// `LumeDuasStrings.category` rather than carried on the enum. Its real count
/// — how many of the five actual duas carry it — is computed over
/// `LumeDuaFixtures.all` by `LumeDuaFixtures.countOf`, in the data layer
/// where that list lives, rather than on the enum itself (see the library
/// doc comment for why it must be computed rather than copied).
enum LumeDuaCategory {
  morning('sun'),
  daily('home'),
  travel('plane'),
  distress('heart'),
  food('utensils'),
  sleep('moon');

  const LumeDuaCategory(this.icon);

  /// The reference's own tile glyph for this category (`i-sun` → `sun`, and
  /// so on).
  final String icon;
}

/// Who the English rendering of every dua is credited to: the web
/// reference, not a verified translation.
const String kLumeDuaEdition = 'Lume web reference English (unverified)';

/// Where every fixture came from. No licence: a release must not ship it.
const LumeContentAttribution kLumeDuaAttribution = LumeContentAttribution(
  publisher: 'Lume web reference fixture',
  sourceVersion: 'tool-data.js DUAS',
);

/// One dua, as the reference's `DUAS` array holds it.
class LumeDua {
  const LumeDua({
    required this.id,
    required this.category,
    required this.arabic,
    required this.translation,
    required this.citation,
  });

  /// A stable identity across languages — there is one dua per id, not one
  /// per language. Also the key [LumeDuasStrings.title] looks its translated
  /// title up by.
  final String id;

  final LumeDuaCategory category;

  /// The dua exactly as it is prayed — the reference's `ar`. A real original,
  /// never produced here.
  final String arabic;

  /// A rendering of it into English, credited to the reference and not a
  /// verified translation (the reference's `tr`) — same footing as Hadith's
  /// fixture English (C77, C82).
  final String translation;

  /// "Sahih Muslim 2723" — the reference's `src`, kept exactly as cited, in
  /// every language (C82).
  final String citation;

  /// This dua in the religious-content contract (C82): one identity, its
  /// citation as the reference cites it, and its real Arabic recorded as the
  /// original rather than as an unverified fallback — the one place this
  /// build's Islamic fixtures actually have an original to record. The
  /// attribution records that it is a fixture with no licence.
  LumeDuaRecord get record => LumeDuaRecord(
    id: id,
    citation: citation,
    originalLanguage: LumeContentLanguage.arabic,
    originalText: arabic,
    fallback: LumeVerifiedTranslation(
      language: LumeContentLanguage.english,
      text: translation,
      translator: kLumeDuaEdition,
    ),
    attribution: kLumeDuaAttribution,
  );
}

/// One dua, in the same shape `religious_content.dart` gives Hadith
/// (`LumeHadithRecord`): one identity, a citation kept as cited, an original
/// where one is verified, and a fallback labelled honestly when it is shown
/// in place of the reader's own language (C82).
@immutable
class LumeDuaRecord {
  const LumeDuaRecord({
    required this.id,
    required this.citation,
    required this.attribution,
    this.originalLanguage,
    this.originalText,
    this.translations = const <LumeVerifiedTranslation>[],
    this.fallback,
  });

  /// One identity across every language this dua is held in.
  final String id;

  /// The citation, as cited: "Sahih Muslim 2723".
  final String citation;

  /// The original, only where the source holds it — Duas' own `arabic`.
  final LumeContentLanguage? originalLanguage;
  final String? originalText;

  final List<LumeVerifiedTranslation> translations;

  /// The verified text shown when no translation into the reader's language
  /// exists — the reference's English in this build.
  final LumeVerifiedTranslation? fallback;

  final LumeContentAttribution attribution;

  /// What to show a reader of [language], and whether it is in that
  /// language — identical algorithm to [LumeHadithRecord.resolve]: the
  /// original first, then a verified translation, then the labelled
  /// fallback. An Arabic reader is shown the real Arabic (step one finds an
  /// original this time, where Hadith never can); every other reader is
  /// shown the reference's English, labelled as a fallback unless they read
  /// English themselves.
  LumeResolvedPassage? resolve(LumeContentLanguage language) {
    if (originalLanguage == language && originalText != null) {
      return LumeResolvedPassage(
        text: originalText!,
        language: language,
        isFallback: false,
      );
    }
    for (final LumeVerifiedTranslation t in translations) {
      if (t.language == language) {
        return LumeResolvedPassage(
          text: t.text,
          language: t.language,
          isFallback: false,
        );
      }
    }
    final LumeVerifiedTranslation? f = fallback;
    if (f == null) return null;
    return LumeResolvedPassage(
      text: f.text,
      language: f.language,
      isFallback: f.language != language,
    );
  }
}
