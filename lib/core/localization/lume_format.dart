/// Locale-aware formatting — the one place a number becomes text.
///
/// §13 of the brief: *"Do not hard-code English/US formatting globally."* Every
/// date, time, temperature, amount and percentage on a destination goes through
/// here, so the locale, the country, the unit system and the clock preference
/// are read once rather than at each call site.
///
/// Four dimensions, and none of them derived from another (§66):
///
/// * **language** decides the words and the digit shapes — `en`, `ur`, `ar`.
/// * **country** decides the currency and, until the user says otherwise, the
///   unit system and the clock.
/// * **units** are automatic until overridden.
/// * **clock** is 12- or 24-hour, likewise.
///
/// The reference reads the last three off `profile`, and so does this — through
/// [LumeFormatting], which is constructed from the profile by whoever draws.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

/// Which unit system a figure is expressed in.
enum LumeUnits { metric, imperial }

/// Formatting for one user, in one locale.
@immutable
class LumeFormatting {
  const LumeFormatting({
    required this.locale,
    this.countryCode = 'PK',
    this.units = LumeUnits.metric,
    this.hour12 = false,
    this.currencyCode,
  });

  /// The locale in the widget tree, plus the user's country. `en` in Pakistan
  /// is `en_PK`, which is a different set of formats from `en_US` — a
  /// distinction §13 names explicitly.
  factory LumeFormatting.of(
    BuildContext context, {
    String countryCode = 'PK',
    LumeUnits? units,
    bool? hour12,
    String? currencyCode,
  }) {
    final Locale locale =
        Localizations.maybeLocaleOf(context) ?? const Locale('en');
    return LumeFormatting(
      locale: locale,
      countryCode: countryCode,
      units: units ?? _unitsFor(countryCode),
      hour12: hour12 ?? _hour12For(countryCode),
      currencyCode: currencyCode,
    );
  }

  final Locale locale;
  final String countryCode;
  final LumeUnits units;
  final bool hour12;

  /// `null` means "the country's".
  final String? currencyCode;

  String get _tag => '${locale.languageCode}_$countryCode';

  /// The locale `intl` will actually format *dates* with.
  ///
  /// `intl` ships a subset of CLDR, and falls back from a tag it does not
  /// have straight to the bare language — whose English *is* American
  /// English. So `en_PK`, which it does not have, was writing a Karachi
  /// reader's date as "Mon, Sep 7" and their clock as "6:27 PM".
  ///
  /// CLDR does not inherit that way. Every English locale outside the United
  /// States and its territories inherits `en-001`, world English, which
  /// writes "Mon, 7 Sept" and "6:27 pm" — and that is what the reference
  /// renders, because a browser carries the whole of CLDR. `intl` has no
  /// `en_001`, so the nearest shipped locale on that branch stands in for it.
  ///
  /// Numbers keep [_tag]: grouping and separators are a *different* CLDR
  /// dimension, and borrowing a stand-in for them would import its digit
  /// grouping along with its month names.
  String get _dateTag => dateLocale(locale.languageCode, countryCode);

  /// CLDR's `en-001` in the form `intl` actually has: same order, same
  /// month abbreviations, same lower-case day period.
  static const String worldEnglish = 'en_IN';

  /// The English locales that follow the United States rather than the world.
  static const Set<String> americanEnglish = <String>{
    'US',
    'AS',
    'GU',
    'MH',
    'MP',
    'PR',
    'UM',
    'VI',
  };

  /// See [_dateTag]. Exposed so a test can assert the resolution itself.
  static String dateLocale(String language, String country) {
    final String exact = '${language}_$country';
    if (intl.DateFormat.localeExists(exact)) return exact;
    if (language == 'en' && !americanEnglish.contains(country)) {
      return worldEnglish;
    }
    return intl.DateFormat.localeExists(language) ? language : 'en';
  }

  /// The markets that measure in feet and Fahrenheit. Everywhere else is
  /// metric, which is the automatic default rather than a guess.
  static LumeUnits _unitsFor(String country) =>
      const <String>{'US', 'LR', 'MM'}.contains(country)
      ? LumeUnits.imperial
      : LumeUnits.metric;

  /// Markets that write the clock with an am/pm.
  static bool _hour12For(String country) => const <String>{
    'US',
    'GB',
    'PK',
    'IN',
    'BD',
    'AU',
    'CA',
    'NZ',
    'PH',
    'EG',
    'SA',
    'AE',
  }.contains(country);

  /// The currency this user's amounts are in.
  String get currency =>
      currencyCode ??
      switch (countryCode) {
        'PK' => 'PKR',
        'IN' => 'INR',
        'GB' => 'GBP',
        'US' => 'USD',
        'AE' => 'AED',
        'SA' => 'SAR',
        'BD' => 'BDT',
        'TR' => 'TRY',
        'ID' => 'IDR',
        'MY' => 'MYR',
        'JP' => 'JPY',
        'CN' => 'CNY',
        'NG' => 'NGN',
        'ZA' => 'ZAR',
        'BR' => 'BRL',
        'CA' => 'CAD',
        'AU' => 'AUD',
        _ => 'USD',
      };

  // ---- dates and times ---------------------------------------------------

  /// `dateShort` — "Mon, 7 Sept". The header carries the city too, so the long
  /// form would wrap onto a second line at 390.
  ///
  /// `MMMEd` and not `MEd`: the reference asks for `{weekday:'short',
  /// day:'numeric', month:'short'}`, which is a month *name*. `MEd` is the
  /// numeric skeleton and renders "Mon, 9/7" — a date that reads as 9 July in
  /// half the world.
  String dateShort(DateTime d) => intl.DateFormat.MMMEd(_dateTag).format(d);

  /// "7 September" — a date with its month written out.
  String dateLong(DateTime d) => intl.DateFormat.MMMMd(_dateTag).format(d);

  /// "Monday, 7 September" — the weekday too, and no year.
  ///
  /// Today's date line. The reference asks for
  /// `{weekday: 'long', day: 'numeric', month: 'long'}`, which is CLDR's
  /// `MMMMEEEEd` skeleton; the comma is the locale's, so `en_PK` keeps it and
  /// `en_GB` does not.
  String dateFull(DateTime d) => intl.DateFormat.MMMMEEEEd(_dateTag).format(d);

  /// "18 March 2024" — a date with its **year**.
  ///
  /// A membership date needs one: `dateFull` is weekday/day/month, so an
  /// account created in 2024 read exactly like one created today.
  String dateLongYear(DateTime d) => intl.DateFormat.yMMMMd(_dateTag).format(d);

  /// "14 Sep".
  String dateMedium(DateTime d) => intl.DateFormat.MMMd(_dateTag).format(d);

  /// The clock, in the user's preference.
  ///
  /// CLDR puts a narrow no-break space before the am/pm marker. Plus Jakarta
  /// Sans has no glyph for U+202F, so it rendered as nothing at all and the
  /// time read "6:27PM"; it is normalised to an ordinary space, which the face
  /// does have and which no layout depends on being unbreakable here.
  ///
  /// The pattern is spelled out rather than taken from the `jm` skeleton,
  /// because a skeleton carries the locale's *own* hour cycle: `jm` in
  /// `en_GB` is 24-hour, so asking for a 12-hour clock there quietly returned
  /// one that was not. The day period still comes from the locale.
  String time(DateTime d) => intl.DateFormat(
    hour12 ? 'h:mm a' : 'HH:mm',
    _dateTag,
  ).format(d).replaceAll(' ', ' ').replaceAll(' ', ' ');

  /// A countdown as `h:mm:ss` — the hero's live pill.
  static String countdown(Duration d) {
    final int total = d.isNegative ? 0 : d.inSeconds;
    final String mm = (total % 3600 ~/ 60).toString().padLeft(2, '0');
    final String ss = (total % 60).toString().padLeft(2, '0');
    return '${total ~/ 3600}:$mm:$ss';
  }

  /// A countdown as `h:mm` — the context strip.
  static String shortCountdown(Duration d) {
    final int minutes = d.isNegative ? 0 : d.inMinutes;
    return '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';
  }

  // ---- numbers -----------------------------------------------------------

  String number(num v, {int? decimals}) => intl.NumberFormat.decimalPattern(
    _tag,
  ).format(decimals == null ? v : num.parse(v.toStringAsFixed(decimals)));

  /// A whole number with no grouping — a count, a percentage.
  String integer(num v) =>
      intl.NumberFormat.decimalPattern(_tag).format(v.round());

  String percent(num v, {int decimals = 2}) =>
      '${number(v.abs(), decimals: decimals)}%';

  /// An amount already expressed in the local currency — a published pump
  /// price, a bill. `moneyRaw`: formatted, never converted.
  String money(num value, {String? code, int decimals = 0}) {
    final intl.NumberFormat f = intl.NumberFormat.currency(
      locale: _tag,
      name: code ?? currency,
      symbol: _symbol(code ?? currency),
      decimalDigits: decimals,
    );
    return f.format(value);
  }

  /// The symbols the reference's own screens show.
  ///
  /// The space after a lettered symbol is **non-breaking**, which is what
  /// CLDR puts there and what the reference renders: measured, its fuel row
  /// is `Rs\u00a0264.61`. A breaking space lets "Rs" and the figure land on
  /// two lines, which is a price split in half.
  static String _symbol(String code) => switch (code) {
    'PKR' => 'Rs$_nb',
    'INR' => '₹',
    'GBP' => '£',
    'USD' => r'$',
    'AED' => 'AED$_nb',
    'SAR' => 'SAR$_nb',
    _ => '$code$_nb',
  };

  static const String _nb = '\u00a0';

  /// A published timetable time — `22:00`.
  ///
  /// **Not [time], and deliberately not the reader's clock preference.** A
  /// railway publishes its timetable in 24-hour form and Lume prints those
  /// strings exactly as the operator wrote them: `trains.screen.js` renders
  /// `esc(train.dep)` straight out of the roster, so a 12-hour market still
  /// reads 22:00. The minutes are kept as numbers so the roster can be sorted
  /// and compared; this is only how they are written down.
  String timetable(int minuteOfDay) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${two(minuteOfDay ~/ 60)}:${two(minuteOfDay % 60)}';
  }

  /// The Pakistani rupee sign the fuel row uses — `₨`, which is the sign
  /// rather than the abbreviation.
  String rupeeSign(num value, {int decimals = 2}) =>
      '₨ ${number(value, decimals: decimals)}';

  // ---- units -------------------------------------------------------------

  /// A temperature, converted where the market measures in Fahrenheit.
  String temperature(int celsius) => units == LumeUnits.imperial
      ? '${(celsius * 9 / 5 + 32).round()}°'
      : '$celsius°';

  /// A number of degrees exactly as written, with no unit conversion.
  ///
  /// For a figure that is *copy* rather than a measurement — the Discover
  /// weather card's, which `home.screen.js` prints as the literal `34°` in
  /// every market and never passes through `L.temp()`. Converting it would
  /// apply a unit system to a string that was never a reading: the reference
  /// shows 34° in New York, not 93°.
  String degreesAsWritten(int degrees) => '$degrees°';

  String speed(int kph) =>
      units == LumeUnits.imperial ? '${(kph * 0.621).round()}' : '$kph';

  /// The number a temperature shows, without its degree sign.
  ///
  /// For a figure the design sets in two faces — `.weather__temp` puts the
  /// sign in a raised `<sup>` — so the conversion has to happen before the
  /// two halves are drawn separately.
  int degreesValue(int celsius) =>
      units == LumeUnits.imperial ? (celsius * 9 / 5 + 32).round() : celsius;

  /// A duration in whole hours, for a schedule slot.
  static int wholeHours(Duration d) => d.inMinutes ~/ 60;
}
