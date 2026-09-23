/// What a unit is called, what it is written as, and how a figure reaches the
/// reader's own script.
///
/// The names are words, so they are keys rather than English — the reference
/// says so itself at `context.js:1096` ("Unit names are words, so they carry
/// keys rather than English") and then ships `i18n/tools.js` with the `uc.*`
/// block in English only. All 32 names are here, in all three languages, and
/// the mapping from a [LumeUnit]'s id to its key is a switch so that a unit
/// added to the table without a name fails to compile rather than drawing its
/// own id at a reader.
///
/// **Symbols are not names.** `km` is `km` in every language; `metre` is not.
/// The one place the two meet is the gallon: the table holds two of them and
/// both are written `gal`, so the qualifier out of the unit's translated name
/// travels with the symbol wherever the symbol is shown — `gal (US)`,
/// `gal (imperial)`, `gal (امریکی)`. A bare `gal` is never drawn, which is
/// the whole of the correction the reference's `context.js:1108` needs.
library;

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../calculator/presentation/calculator_text.dart';
import '../domain/lume_ratio.dart';
import '../domain/unit_table.dart';

/// One category's name, as the chip strip reads it.
String lumeCategoryName(AppLocalizations l, LumeUnitKind kind) =>
    switch (kind) {
      LumeUnitKind.length => l.ucLength,
      // `uc.mass` is keyed on the physical quantity and worded as the reader
      // thinks of it — "Weight". The reference does the same.
      LumeUnitKind.mass => l.ucMass,
      LumeUnitKind.volume => l.ucVolume,
      LumeUnitKind.area => l.ucArea,
      LumeUnitKind.speed => l.ucSpeed,
      LumeUnitKind.data => l.ucData,
    };

/// The glyph on the category's chip — the reference's own six
/// (`context.js:1098-1115`).
String lumeCategoryIcon(LumeUnitKind kind) => switch (kind) {
  LumeUnitKind.length => LumeIcons.ruler,
  LumeUnitKind.mass => LumeIcons.scales,
  LumeUnitKind.volume => LumeIcons.droplet,
  LumeUnitKind.area => LumeIcons.grid,
  LumeUnitKind.speed => LumeIcons.navigation,
  LumeUnitKind.data => LumeIcons.download,
};

/// One unit's name, in the reader's language.
String lumeUnitName(AppLocalizations l, String id) => switch (id) {
  'm' => l.ucMetre,
  'km' => l.ucKilometre,
  'cm' => l.ucCentimetre,
  'mi' => l.ucMile,
  'ft' => l.ucFoot,
  'in' => l.ucInch,
  'kg' => l.ucKilogram,
  'g' => l.ucGram,
  'lb' => l.ucPound,
  'oz' => l.ucOunce,
  'tola' => l.ucTola,
  'L' => l.ucLitre,
  'mL' => l.ucMillilitre,
  // The two the reference collapses into one bare `gal`.
  'gal_us' => l.ucGallonUs,
  'gal_imp' => l.ucGallonImp,
  'cup_us' => l.ucCupUs,
  'm2' => l.ucSqmetre,
  'ft2' => l.ucSqfoot,
  'ac' => l.ucAcre,
  'marla' => l.ucMarla,
  'kmh' => l.ucKmh,
  'mph' => l.ucMph,
  'ms' => l.ucMs,
  // The decimal family, on decimal factors.
  'B' => l.ucByte,
  'kB' => l.ucKilobyte,
  'MB' => l.ucMegabyte,
  'GB' => l.ucGigabyte,
  'TB' => l.ucTerabyte,
  // The binary family, named. These are the factors the reference put under
  // the four names above.
  'KiB' => l.ucKibibyte,
  'MiB' => l.ucMebibyte,
  'GiB' => l.ucGibibyte,
  'TiB' => l.ucTebibyte,
  _ => throw ArgumentError.value(id, 'id', 'no name for this unit'),
};

/// The unit's symbol as it is drawn, disambiguated where the symbol alone
/// would not be.
///
/// Only the two gallons need it. The qualifier is lifted out of the unit's
/// own translated name rather than written here, so it is the reader's
/// language and not a second string to keep in step; a translation that drops
/// the brackets falls back to the whole name, which is longer and still
/// unambiguous. Nothing returns a bare `gal`.
String lumeUnitSymbol(AppLocalizations l, String id) {
  final String symbol = lumeUnit(id).symbol;
  if (id != 'gal_us' && id != 'gal_imp') return symbol;
  final String name = lumeUnitName(l, id);
  final Match? qualifier = _qualifier.firstMatch(name);
  return qualifier == null ? name : '$symbol ${qualifier.group(0)}';
}

final RegExp _qualifier = RegExp(r'\([^)]+\)');

/// What the reader typed, as an exact amount.
///
/// The reference reads its field with `Number(f.amount)` (`context.js:1134`)
/// over an `<input type="number">`, so an empty field is zero and a field the
/// browser could not read is empty. This is the same rule kept exactly: an
/// amount that is not a decimal is [LumeRatio.zero], and the screen shows a
/// zero rather than a `NaN` or an error.
///
/// It also accepts the digits the reader's own keyboard writes —
/// Arabic-Indic, Extended Arabic-Indic — and the locale's own decimal
/// separator, the way the calculator's pad does. A figure formatted for them
/// and unreadable when typed back would be half a localisation.
LumeRatio converterAmount(String typed, LumeFormatting f) =>
    LumeRatio.tryParse(converterMachine(typed, calcDecimalSeparator(f))) ??
    LumeRatio.zero;

/// A typed amount as a machine decimal — ASCII digits, one ASCII point.
String converterMachine(String typed, String separator) {
  final StringBuffer out = StringBuffer();
  bool point = false;
  for (int i = 0; i < typed.length; i++) {
    final String character = typed[i];
    final int? digit = calcDigitOf(character);
    if (digit != null) {
      out.write(digit);
      continue;
    }
    // Only the first separator is a point; the rest are noise, and dropping
    // them leaves a number rather than refusing one.
    if (!point && calcIsPointKey(character, separator)) {
      point = true;
      out.write('.');
    }
  }
  final String machine = out.toString();
  return machine.startsWith('.') ? '0$machine' : machine;
}

/// A machine decimal in the reader's own digits, grouping and separator.
///
/// The reference writes every figure through `c.num(v, { maximumFractionDigits:
/// 4 })` (`converter.tool.js:33, 38`), which is `Intl.NumberFormat`: Urdu and
/// Arabic get their own numerals and their own separators. [calcNumber] is
/// that, for a string rather than a `double` — the value has already been
/// rounded once, exactly, by [LumeRatio.toStringAsFixedMax], and never
/// becomes a `double` on the way to the screen.
///
/// The one thing it cannot do is group a whole part wider than an `int`, and
/// a converter reaches one easily: a terabyte is 10¹² bytes before the
/// reader's own amount multiplies it. Past that the digits are written one at
/// a time — ungrouped, in the reader's script, and still exact.
String converterFigure(LumeFormatting f, String machine) {
  final int point = machine.indexOf('.');
  final String whole = point < 0 ? machine : machine.substring(0, point);
  if (whole.replaceFirst('-', '').length <= _groupedDigits) {
    return calcNumber(f, machine);
  }
  final StringBuffer out = StringBuffer();
  for (final int rune in machine.runes) {
    out.write(switch (rune) {
      0x2d => calcMinusSign,
      0x2e => calcDecimalSeparator(f),
      _ => f.integer(rune - 0x30),
    });
  }
  return out.toString();
}

/// The widest whole part a 64-bit `int` holds for every value of that length.
const int _groupedDigits = 15;
