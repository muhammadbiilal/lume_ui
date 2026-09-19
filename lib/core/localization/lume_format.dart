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

import '../values/lume_currency.dart';
import '../values/lume_money.dart';

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
      units: units ?? unitsFor(countryCode),
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
    if (language == 'en' &&
        !americanEnglish.contains(country) &&
        !usFormEnglish.contains(country)) {
      return worldEnglish;
    }
    return intl.DateFormat.localeExists(language) ? language : 'en';
  }

  /// English locales with no CLDR data of their own that the browser still
  /// writes the American way — "Mon, Sep 7", "6:27 PM".
  ///
  /// Read off the reference's own engine, not assumed: every country's
  /// `en-XX` short date and clock, grouped by what ICU renders. Saudi Arabia,
  /// Japan and Turkey are here; Pakistan, India and Germany are not. The UAE
  /// is its own case ([dateShort]).
  static const Set<String> usFormEnglish = <String>{
    'AD', 'AF', 'AL', 'AM', 'AO', 'AR', 'AW', 'AZ', 'BA', 'BD', 'BF', 'BG', //
    'BH', 'BI', 'BJ', 'BN', 'BO', 'BR', 'BT', 'BY', 'CD', 'CF', 'CG', 'CI',
    'CL', 'CN', 'CO', 'CR', 'CU', 'CV', 'DJ', 'DO', 'DZ', 'EC', 'EE', 'EG',
    'ET', 'GA', 'GE', 'GN', 'GQ', 'GR', 'GT', 'GW', 'HN', 'HR', 'HT', 'IQ',
    'IR', 'IS', 'JO', 'JP', 'KG', 'KH', 'KM', 'KP', 'KR', 'KW', 'KZ', 'LA',
    'LB', 'LI', 'LK', 'LT', 'LU', 'LV', 'LY', 'MA', 'MC', 'MD', 'ME', 'MK',
    'ML', 'MM', 'MN', 'MR', 'MX', 'MZ', 'NE', 'NI', 'NP', 'OM', 'PA', 'PE',
    'PH', 'PS', 'PY', 'QA', 'RS', 'RU', 'SA', 'SM', 'SN', 'SO', 'SR', 'ST',
    'SV', 'SY', 'TD', 'TG', 'TH', 'TJ', 'TL', 'TM', 'TN', 'TR', 'TW', 'UA',
    'UY', 'UZ', 'VA', 'VE', 'VN', 'YE',
  };

  /// The markets that measure in feet and Fahrenheit. Everywhere else is
  /// metric, which is the automatic default rather than a guess.
  /// The units a market measures in, when the reader has not said otherwise.
  /// Public so a formatter built outside the widget tree — a notification
  /// body, composed in a repository — converts exactly as a screen does.
  static LumeUnits unitsFor(String country) =>
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
  String dateShort(DateTime d) =>
      locale.languageCode == 'en' && countryCode == 'AE'
      // `en-AE` alone writes the day first on American month names —
      // "Mon, 7 Sep" — and no locale `intl` ships does, so the skeleton is
      // spelled out over the American data.
      ? intl.DateFormat('EEE, d MMM', 'en').format(d)
      : intl.DateFormat.MMMEd(_dateTag).format(d);

  /// "7 September" — a date with its month written out.
  String dateLong(DateTime d) => intl.DateFormat.MMMMd(_dateTag).format(d);

  /// "Monday, 7 September" — the weekday too, and no year.
  ///
  /// Today's date line. The reference asks for
  /// `{weekday: 'long', day: 'numeric', month: 'long'}`, which is CLDR's
  /// `MMMMEEEEd` skeleton; the comma is the locale's, so `en_PK` keeps it and
  /// `en_GB` does not.
  String dateFull(DateTime d) => intl.DateFormat.MMMMEEEEd(_dateTag).format(d);

  /// "Wednesday" — a forecast day past tomorrow, `{weekday: 'long'}`.
  String weekdayLong(DateTime d) => intl.DateFormat.EEEE(_dateTag).format(d);

  /// "18 March 2024" — a date with its **year**.
  ///
  /// A membership date needs one: `dateFull` is weekday/day/month, so an
  /// account created in 2024 read exactly like one created today.
  String dateLongYear(DateTime d) => intl.DateFormat.yMMMMd(_dateTag).format(d);

  /// "14 Sep".
  String dateMedium(DateTime d) => intl.DateFormat.MMMd(_dateTag).format(d);

  /// "30 Aug 2020" — `{day: 'numeric', month: 'short', year: 'numeric'}`.
  String dateMediumYear(DateTime d) =>
      intl.DateFormat.yMMMd(_dateTag).format(d);

  /// "18/04/1993" — a date as a date field shows it, in the locale's order.
  String dateNumeric(DateTime d) => intl.DateFormat.yMd(_dateTag).format(d);

  /// "September 2026" — a month and its year, as a calendar titles it.
  String monthYear(DateTime d) => intl.DateFormat.yMMMM(_dateTag).format(d);

  /// `weekLabels()` — the seven narrow weekday names a week chart is labelled
  /// with, in the order the reference draws them.
  ///
  /// The reference starts the week at `new Intl.Locale(locale).weekInfo
  /// .firstDay`, falling back to Monday, and the Chrome it runs in has no
  /// `weekInfo` property: every locale starts on Monday there, Pakistan and
  /// the United States included (C65). This is that order.
  List<String> weekdayNarrowFromMonday() => <String>[
    for (int i = 0; i < 7; i++)
      intl.DateFormat('EEEEE', _dateTag).format(DateTime(2024, 1, 8 + i)),
  ];

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

  /// A whole hour of the day, in the reader's own clock — "10 pm", "22:00".
  ///
  /// Quiet hours are stored as 0–23 and shown as times, so the conversion
  /// belongs here with every other clock rather than at the screen.
  String hourLabel(int hour) => time(DateTime(2000, 1, 1, hour));

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

  /// `n.toFixed(d)` — exactly [decimals] places, "0.0" and not "0".
  String fixed(num v, int decimals) {
    final intl.NumberFormat f = intl.NumberFormat.decimalPattern(_tag)
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    return f.format(v);
  }

  String percent(num v, {int decimals = 2}) =>
      '${number(v.abs(), decimals: decimals)}%';

  /// `c.signed(n, dp)` — a change with its sign and exactly [decimals]
  /// places: "+1,162", "−0.18". The minus is U+2212, as the reference writes
  /// it, and zero carries no sign.
  String signed(num v, {int decimals = 2}) {
    final intl.NumberFormat f = intl.NumberFormat.decimalPattern(_tag)
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    final String sign = v > 0
        ? '+'
        : v < 0
        ? '−'
        : '';
    return '$sign${f.format(v.abs())}';
  }

  /// `c.pct(n, dp)` — "+0.42%", "−0.18%", "0.00%".
  String signedPercent(num v, {int decimals = 2}) =>
      '${signed(v, decimals: decimals)}%';

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

  /// `moneyRaw(v, ccy, 2)` — `Intl.NumberFormat` with only a maximum set, so
  /// the currency's own minor units are the minimum: "$22.00", and "Rs 6,226"
  /// because the running reference gives the rupee none (measured on Tip &
  /// Split, `tool_tipsplit_default_pk` and `_default_us`). `intl` gives the
  /// rupee two, so that one is taken from the measurement.
  String moneyUpTo(num value, {String? code, required int maxDecimals}) {
    final String c = code ?? currency;
    final int minor = c == 'PKR'
        ? 0
        : intl.NumberFormat.currency(locale: _tag, name: c).decimalDigits ?? 2;
    final intl.NumberFormat f =
        intl.NumberFormat.currency(
            locale: _tag,
            name: c,
            symbol: _symbol(c),
            decimalDigits: maxDecimals,
          )
          ..minimumFractionDigits = minor < maxDecimals ? minor : maxDecimals
          ..maximumFractionDigits = maxDecimals;
    return f.format(value);
  }

  /// A stored amount ([LumeMoney]) — exact, never through a `double`.
  ///
  /// At the currency's full ISO precision (`Rs 34,000.00`, `¥5,000`,
  /// `KWD 1.250`) unless [compact], which leaves the fraction out **only
  /// when every digit of it is zero** (`Rs 34,000`, but `Rs 34,000.50`):
  /// display drops zeros and never rounds. [withCode] writes the ISO code in
  /// place of a symbol, for a screen where two currencies share one. The
  /// magnitude is written; direction is the caller's words, never a sign.
  /// [isolate] wraps the result in a first-strong isolate for a sentence in
  /// either direction.
  String amount(
    LumeMoney m, {
    bool compact = false,
    bool withCode = false,
    bool isolate = false,
  }) {
    final LumeCurrency c = m.currency;
    final int abs = m.minor.abs();
    final int whole = abs ~/ c.scale;
    final int fraction = abs % c.scale;
    final int digits = c.exponent == 0 || (compact && fraction == 0)
        ? 0
        : c.exponent;
    final intl.NumberFormat f = intl.NumberFormat.currency(
      locale: _tag,
      name: c.code,
      symbol: withCode ? '${c.code}$_nb' : _symbol(c.code),
      decimalDigits: digits,
    );
    String text = f.format(whole);
    if (digits > 0) {
      // The whole part formatted with a zero fraction, then the exact
      // fraction written into it in the locale's own digits.
      final String zero = f.symbols.ZERO_DIGIT;
      final String sep = f.symbols.DECIMAL_SEP;
      final String zeros = sep + zero * digits;
      final int at = text.lastIndexOf(zeros);
      final String exact = fraction
          .toString()
          .padLeft(digits, '0')
          .split('')
          .map(
            (String d) => String.fromCharCode(
              zero.codeUnitAt(0) + d.codeUnitAt(0) - 0x30,
            ),
          )
          .join();
      if (at >= 0) {
        text =
            text.substring(0, at) +
            sep +
            exact +
            text.substring(at + zeros.length);
      }
    }
    return isolate ? '\u2068$text\u2069' : text;
  }

  /// The symbols the reference's own screens show.
  ///
  /// The space after a lettered symbol is **non-breaking**, which is what
  /// CLDR puts there and what the reference renders: measured, its fuel row
  /// is `Rs\u00a0264.61`. A breaking space lets "Rs" and the figure land on
  /// two lines, which is a price split in half.
  ///
  /// The dollar is "US$" to a world-English reader — Pakistan and the United
  /// Kingdom measure `US$2,740` — and "$" where English follows the United
  /// States or, as the UAE does, keeps the bare sign (`tool_goldrates_*`).
  /// The yen is "¥".
  String _symbol(String code) => switch (code) {
    'PKR' => 'Rs$_nb',
    'INR' => '₹',
    'GBP' => '£',
    'USD' =>
      locale.languageCode == 'en' &&
              countryCode != 'AE' &&
              !americanEnglish.contains(countryCode) &&
              !usFormEnglish.contains(countryCode)
          ? r'US$'
          : r'$',
    'JPY' => '¥',
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
