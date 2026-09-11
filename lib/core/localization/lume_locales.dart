/// The languages Lume ships, and what each one implies.
///
/// Three, and only three. The reference declares eight in `ALL_LANGS` but
/// exports only the ones that have a dictionary — `SHIPPED = LANGS.filter(l =>
/// DICTS[l.code])` — so the language picker offers English, Urdu and Arabic and
/// nothing else. Shipping an empty ARB for French would put a fourth row in
/// that list that does nothing when chosen.
///
/// Adding a language is: an ARB with full key parity, a row here, and nothing
/// else. Every string in the product already comes from the ARB.
library;

import 'package:flutter/widgets.dart';

/// One shipped language.
@immutable
class LumeLanguage {
  const LumeLanguage({
    required this.code,
    required this.native,
    required this.english,
    required this.direction,
  });

  /// ISO 639-1.
  final String code;

  /// The language's name in itself. What the picker shows — a person looking
  /// for Urdu is looking for "اردو", not for "Urdu".
  final String native;

  /// The English name, shown as a subtitle where the native name would not be
  /// recognised by someone browsing in another script.
  final String english;

  final TextDirection direction;

  Locale get locale => Locale(code);

  bool get isRtl => direction == TextDirection.rtl;
}

/// The shipped set.
abstract final class LumeLocales {
  static const LumeLanguage english = LumeLanguage(
    code: 'en',
    native: 'English',
    english: 'English',
    direction: TextDirection.ltr,
  );

  static const LumeLanguage urdu = LumeLanguage(
    code: 'ur',
    native: 'اردو',
    english: 'Urdu',
    direction: TextDirection.rtl,
  );

  static const LumeLanguage arabic = LumeLanguage(
    code: 'ar',
    native: 'العربية',
    english: 'Arabic',
    direction: TextDirection.rtl,
  );

  /// In the order the picker lists them.
  static const List<LumeLanguage> all = <LumeLanguage>[english, urdu, arabic];

  static const List<Locale> supported = <Locale>[
    Locale('en'),
    Locale('ur'),
    Locale('ar'),
  ];

  /// The language for a code, or English when the code is not one we ship.
  static LumeLanguage forCode(String code) {
    for (final LumeLanguage l in all) {
      if (l.code == code) return l;
    }
    return english;
  }

  /// The direction a locale reads in.
  static TextDirection directionOf(Locale locale) =>
      forCode(locale.languageCode).direction;

  /// Whether a locale reads right to left.
  static bool isRtl(Locale locale) => directionOf(locale) == TextDirection.rtl;

  /// Resolve the device's preferred locales against what we ship.
  ///
  /// Language code only: Lume ships one Urdu, not `ur-PK` and `ur-IN`, and a
  /// device asking for either should get it rather than falling back to
  /// English. **Language is not read from country** — a device in Pakistan set
  /// to English gets English, which is the invariant the whole personalisation
  /// model rests on.
  static Locale resolve(List<Locale>? preferred, Iterable<Locale> supported) {
    if (preferred != null) {
      for (final Locale want in preferred) {
        for (final Locale have in supported) {
          if (have.languageCode == want.languageCode) return have;
        }
      }
    }
    return const Locale('en');
  }
}
