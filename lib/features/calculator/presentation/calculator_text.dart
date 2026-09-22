/// The calculator's numbers, in the reader's own script — and the reader's
/// own digits, read back.
///
/// **Defect 4.** The reference writes the readout with `out.textContent =
/// toolCalc.b` (`tool.screen.js:907`): a raw JavaScript number string. Every
/// reader, in every language, gets ASCII digits and an ASCII `.`, on a screen
/// whose every other figure has gone through `Intl`. Here the readout, the
/// expression line and every history row are formatted through
/// [LumeFormatting] — Arabic-Indic digits where the locale writes them, the
/// locale's decimal separator, the locale's grouping.
///
/// Reading *back* is the same problem in the other direction: a reader typing
/// on a physical keyboard types their own digits. [calcDigitOf] accepts
/// Arabic-Indic (U+0660–0669) and Urdu (U+06F0–06F9) digits alongside ASCII,
/// and [calcIsPointKey] accepts U+066B and the locale's own separator, the
/// way `ledgerParseAmount` does.
library;

import '../../../core/localization/lume_format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/calculator_engine.dart';

/// U+2212, the typographic minus — what `LumeFormatting.signed` writes and
/// what the reference's own minus key is.
const String calcMinusSign = '\u2212';

/// The glyphs on the pad. Mathematical operators, not words: they are the
/// same in every language the product ships, and they are what the reference
/// draws.
const String calcTimesSign = '\u00d7';
const String calcDivideSign = '\u00f7';
const String calcPlusSign = '+';
const String calcPerCentSign = '%';
const String calcEqualsSign = '=';

/// Left-to-right isolate and pop, for a run of arithmetic inside a
/// right-to-left paragraph. A row's label is a `String`, so the isolation has
/// to travel with the text; a widget that can carry `Directionality` uses
/// `LumeNumerals` instead.
String calcIsolate(String text) => '\u2066$text\u2069';

/// The locale's decimal separator, read out of [LumeFormatting] rather than
/// assumed — `.` in English, U+066B in Arabic, and so on.
String calcDecimalSeparator(LumeFormatting f) {
  final String probe = f.number(1.5, decimals: 1);
  return probe.replaceAll(f.integer(1), '').replaceAll(f.integer(5), '');
}

/// A machine decimal — `-1234.50`, `0.011`, `1.` — in the reader's digits,
/// with the locale's grouping and separator.
///
/// A trailing separator is kept: while somebody is typing `1.`, the point
/// they have just pressed has to be on the screen.
String calcNumber(LumeFormatting f, String machine) {
  String s = machine;
  final bool negative = s.startsWith('-');
  if (negative) s = s.substring(1);
  final bool trailingPoint = s.endsWith('.');
  if (trailingPoint) s = s.substring(0, s.length - 1);
  final int point = s.indexOf('.');
  final String whole = point < 0 ? s : s.substring(0, point);
  final String fraction = point < 0 ? '' : s.substring(point + 1);

  final StringBuffer out = StringBuffer();
  if (negative) out.write(calcMinusSign);
  out.write(f.integer(int.parse(whole.isEmpty ? '0' : whole)));
  if (fraction.isNotEmpty || trailingPoint) {
    out.write(calcDecimalSeparator(f));
    // Digit by digit, so a fraction's own zeros survive: a formatter given
    // `0.011` as a number would be free to drop them.
    for (final int c in fraction.runes) {
      out.write(f.integer(c - 0x30));
    }
  }
  return out.toString();
}

/// The glyph one operator is drawn and spoken beside.
String calcOperatorSign(LumeCalcOp op) => switch (op) {
  LumeCalcOp.add => calcPlusSign,
  LumeCalcOp.subtract => calcMinusSign,
  LumeCalcOp.multiply => calcTimesSign,
  LumeCalcOp.divide => calcDivideSign,
};

/// What a screen reader says for one operator.
String calcOperatorName(AppLocalizations l, LumeCalcOp op) => switch (op) {
  LumeCalcOp.add => l.calcPlus,
  LumeCalcOp.subtract => l.calcMinus,
  LumeCalcOp.multiply => l.calcTimes,
  LumeCalcOp.divide => l.calcDivide,
};

/// An expression, as one line: `2 + 3 x 4 =`.
///
/// Built left to right whatever the page's direction, because this is
/// arithmetic and not prose. The caller isolates it — with `LumeNumerals`
/// where it is a widget, with [calcIsolate] where it is a row's label.
String calcExpressionText(LumeFormatting f, List<LumeCalcToken> tokens) =>
    tokens
        .map(
          (LumeCalcToken t) => t.equals
              ? calcEqualsSign
              : t.op != null
              ? calcOperatorSign(t.op!)
              : calcNumber(f, t.number!),
        )
        .join(' ');

/// What the reader is told when a key cannot do what it was asked.
String calcErrorText(AppLocalizations l, LumeCalcError e) => switch (e) {
  LumeCalcError.divideByZero => l.calcErrDivZero,
  LumeCalcError.overflow => l.calcErrOverflow,
  LumeCalcError.precision => l.calcErrPrecision,
  LumeCalcError.tooLong => l.calcErrTooLong,
};

/// The digit [character] stands for, in the reader's own script, or `null`.
int? calcDigitOf(String character) {
  if (character.length != 1) return null;
  final int r = character.codeUnitAt(0);
  if (r >= 0x30 && r <= 0x39) return r - 0x30;
  // Arabic-Indic.
  if (r >= 0x0660 && r <= 0x0669) return r - 0x0660;
  // Extended Arabic-Indic, which is what Urdu writes.
  if (r >= 0x06f0 && r <= 0x06f9) return r - 0x06f0;
  return null;
}

/// Whether [character] is the reader's decimal point: an ASCII point, a
/// comma where a keyboard's numeric pad writes one, U+066B, or whatever
/// [separator] the locale itself uses.
bool calcIsPointKey(String character, String separator) =>
    character == '.' ||
    character == ',' ||
    character == '\u066b' ||
    (separator.isNotEmpty && character == separator);
