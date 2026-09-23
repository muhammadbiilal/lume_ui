/// The units Unit Converter knows, and the exact factor of each.
///
/// The reference's table is `context.js:1096-1118`: six categories, 25 units,
/// every imperial constant truncated to six significant figures, digital
/// storage on **binary factors under decimal names**, and one bare `gal` that
/// is a US gallon shown to every reader on earth. `ROLLOUT_WAVE_4.md` §3 is
/// the approved policy that settles it, and this file is that policy written
/// out so it can be checked against the standards that define the units:
///
/// * **Decimal names take decimal factors.** kB is 1,000 bytes, MB 10⁶, GB
///   10⁹, TB 10¹². The reference's GB is 1024 MB and its TB 1024² MB, which
///   overstate by 2.4 % and 4.9 %.
/// * **Binary units are named.** KiB, MiB, GiB, TiB — the IEC names — carry
///   the powers of 1,024. No binary factor appears under a decimal name.
/// * **Gallons are separated.** `gal (US)` is 3.785411784 L and `gal (imp)`
///   is 4.54609 L. The reference's bare `gal` tells a UK reader 16.7 % too
///   little. Nothing here is ever labelled only `gal`.
/// * **Factors are the defined values**, exactly, as [LumeRatio] — a mile is
///   1609.344 m and a pound 0.45359237 kg, not `1609.34` and `0.453592`.
///
/// **What is not here.** The reference has no temperature category, and one
/// is not added: °C to °F is an affine conversion, not a ratio, and adding a
/// category the reference does not have is a product decision rather than a
/// conversion. It is recorded as deferred in `ROLLOUT_WAVE_4.md` §7 rather
/// than taken quietly.
///
/// Each category's first unit is its base, and every factor is *base units
/// per one of this unit*, so a conversion is `value × from ÷ to` and is exact
/// at every step.
library;

import 'package:flutter/foundation.dart';

import 'lume_ratio.dart';

enum LumeUnitKind { length, mass, volume, area, speed, data }

@immutable
class LumeUnit {
  const LumeUnit({
    required this.id,
    required this.kind,
    required this.symbol,
    required this.factor,
  });

  /// Stable, and the key its name is looked up by. Never shown.
  final String id;

  final LumeUnitKind kind;

  /// The short form on the big figure — `km`, `GiB`, `gal (US)`. Symbols are
  /// the international ones and are not translated; a disambiguating word in
  /// brackets is, and is added by the presentation layer.
  final String symbol;

  /// Base units per one of this unit.
  final LumeRatio factor;

  @override
  String toString() => id;
}

/// A conversion, worked out exactly.
///
/// Both units must share a [LumeUnitKind]; a screen that offers units from
/// one category at a time cannot produce a mismatch, and the assertion says
/// so rather than returning a plausible wrong number.
LumeRatio lumeConvert(LumeRatio amount, LumeUnit from, LumeUnit to) {
  assert(from.kind == to.kind, 'cannot convert ${from.id} to ${to.id}');
  if (identical(from, to) || from.id == to.id) return amount;
  return amount * from.factor / to.factor;
}

LumeRatio _f(String decimal) => LumeRatio.parse(decimal);

/// Every unit, in the order each category shows them.
final List<LumeUnit> kLumeUnits = <LumeUnit>[
  // ---- length, base metre -------------------------------------------
  LumeUnit(
    id: 'm',
    kind: LumeUnitKind.length,
    symbol: 'm',
    factor: LumeRatio.one,
  ),
  LumeUnit(
    id: 'km',
    kind: LumeUnitKind.length,
    symbol: 'km',
    factor: _f('1000'),
  ),
  LumeUnit(
    id: 'cm',
    kind: LumeUnitKind.length,
    symbol: 'cm',
    factor: _f('0.01'),
  ),
  // 1609.344 exactly — the international mile, 1760 yards of 0.9144 m.
  LumeUnit(
    id: 'mi',
    kind: LumeUnitKind.length,
    symbol: 'mi',
    factor: _f('1609.344'),
  ),
  LumeUnit(
    id: 'ft',
    kind: LumeUnitKind.length,
    symbol: 'ft',
    factor: _f('0.3048'),
  ),
  LumeUnit(
    id: 'in',
    kind: LumeUnitKind.length,
    symbol: 'in',
    factor: _f('0.0254'),
  ),

  // ---- mass, base kilogram ------------------------------------------
  LumeUnit(
    id: 'kg',
    kind: LumeUnitKind.mass,
    symbol: 'kg',
    factor: LumeRatio.one,
  ),
  LumeUnit(id: 'g', kind: LumeUnitKind.mass, symbol: 'g', factor: _f('0.001')),
  // 0.45359237 exactly — the international avoirdupois pound.
  LumeUnit(
    id: 'lb',
    kind: LumeUnitKind.mass,
    symbol: 'lb',
    factor: _f('0.45359237'),
  ),
  // A sixteenth of that pound, exactly.
  LumeUnit(
    id: 'oz',
    kind: LumeUnitKind.mass,
    symbol: 'oz',
    factor: _f('0.028349523125'),
  ),
  // The South Asian tola: three eighths of a troy ounce, 11.6638038 g.
  LumeUnit(
    id: 'tola',
    kind: LumeUnitKind.mass,
    symbol: 'tola',
    factor: _f('0.0116638038'),
  ),

  // ---- volume, base litre -------------------------------------------
  LumeUnit(
    id: 'L',
    kind: LumeUnitKind.volume,
    symbol: 'L',
    factor: LumeRatio.one,
  ),
  LumeUnit(
    id: 'mL',
    kind: LumeUnitKind.volume,
    symbol: 'mL',
    factor: _f('0.001'),
  ),
  // Named, both of them. 231 cubic inches, and the 1985 Imperial gallon.
  LumeUnit(
    id: 'gal_us',
    kind: LumeUnitKind.volume,
    symbol: 'gal',
    factor: _f('3.785411784'),
  ),
  LumeUnit(
    id: 'gal_imp',
    kind: LumeUnitKind.volume,
    symbol: 'gal',
    factor: _f('4.54609'),
  ),
  // The US *legal* cup, 240 mL — which is the reference's 0.24, stated.
  LumeUnit(
    id: 'cup_us',
    kind: LumeUnitKind.volume,
    symbol: 'cup',
    factor: _f('0.24'),
  ),

  // ---- area, base square metre --------------------------------------
  LumeUnit(
    id: 'm2',
    kind: LumeUnitKind.area,
    symbol: 'm²',
    factor: LumeRatio.one,
  ),
  // 0.3048² exactly.
  LumeUnit(
    id: 'ft2',
    kind: LumeUnitKind.area,
    symbol: 'ft²',
    factor: _f('0.09290304'),
  ),
  // 4840 square yards, exactly.
  LumeUnit(
    id: 'ac',
    kind: LumeUnitKind.area,
    symbol: 'ac',
    factor: _f('4046.8564224'),
  ),
  // 272.25 ft², the standard marla, exactly: 272.25 × 0.09290304.
  LumeUnit(
    id: 'marla',
    kind: LumeUnitKind.area,
    symbol: 'marla',
    factor: _f('25.29285264'),
  ),

  // ---- speed, base kilometre per hour --------------------------------
  LumeUnit(
    id: 'kmh',
    kind: LumeUnitKind.speed,
    symbol: 'km/h',
    factor: LumeRatio.one,
  ),
  LumeUnit(
    id: 'mph',
    kind: LumeUnitKind.speed,
    symbol: 'mph',
    factor: _f('1.609344'),
  ),
  LumeUnit(
    id: 'ms',
    kind: LumeUnitKind.speed,
    symbol: 'm/s',
    factor: _f('3.6'),
  ),

  // ---- data, base byte ------------------------------------------------
  // The base is the byte, not the reference's megabyte, so that both
  // families hang off one unambiguous unit.
  LumeUnit(
    id: 'B',
    kind: LumeUnitKind.data,
    symbol: 'B',
    factor: LumeRatio.one,
  ),
  LumeUnit(id: 'kB', kind: LumeUnitKind.data, symbol: 'kB', factor: _f('1000')),
  LumeUnit(
    id: 'MB',
    kind: LumeUnitKind.data,
    symbol: 'MB',
    factor: _f('1000000'),
  ),
  LumeUnit(
    id: 'GB',
    kind: LumeUnitKind.data,
    symbol: 'GB',
    factor: _f('1000000000'),
  ),
  LumeUnit(
    id: 'TB',
    kind: LumeUnitKind.data,
    symbol: 'TB',
    factor: _f('1000000000000'),
  ),
  LumeUnit(
    id: 'KiB',
    kind: LumeUnitKind.data,
    symbol: 'KiB',
    factor: _f('1024'),
  ),
  LumeUnit(
    id: 'MiB',
    kind: LumeUnitKind.data,
    symbol: 'MiB',
    factor: _f('1048576'),
  ),
  LumeUnit(
    id: 'GiB',
    kind: LumeUnitKind.data,
    symbol: 'GiB',
    factor: _f('1073741824'),
  ),
  LumeUnit(
    id: 'TiB',
    kind: LumeUnitKind.data,
    symbol: 'TiB',
    factor: _f('1099511627776'),
  ),
];

/// The units of one category, in order.
List<LumeUnit> lumeUnitsOf(LumeUnitKind kind) =>
    kLumeUnits.where((LumeUnit u) => u.kind == kind).toList(growable: false);

LumeUnit lumeUnit(String id) =>
    kLumeUnits.firstWhere((LumeUnit u) => u.id == id);

/// The pair a category opens on.
///
/// The reference has no picker at all: `from` is always the category's first
/// unit and `to` is its second — or its **fourth** for a reader on imperial
/// units, which serves ounces for mass, cups for volume and, for area,
/// *marlas* (`context.js:1130`). A marla is a Pakistani land unit; serving it
/// to a reader in Ohio because it happens to sit at index 3 is the index
/// heuristic showing through the screen. So the opening pair is **named**
/// here, per category, and does not move with the reader's unit system —
/// both units are chosen on the screen, which is where that choice belongs.
///
/// The five pairs the reference's own rule produces for a metric reader are
/// kept as they are (`m → km`, `kg → g`, `L → mL`, `m² → ft²`, `km/h → mph`,
/// measured on `tool_converter_default_pk_390x844_light_en`).
///
/// **Data is the one that moves**, for a reason that is about the screen
/// rather than the table. The reference bases the category on the megabyte
/// and opens `MB → GB`; this table bases it on the byte, so that the decimal
/// and the binary family hang off one unambiguous unit. Opening on `B → kB`
/// was tried and looks wrong: at the display's four decimals, one byte in
/// megabytes, gigabytes, terabytes, mebibytes, gibibytes and tebibytes all
/// round to **0**, so six of the nine rows under the card read zero and the
/// category's whole point is invisible. `GB → MB` opens on the one line that
/// states the correction — **1 GB is 1,000 MB**, where the reference says
/// 1024 — with 1 GiB reading 953.6743 MiB two rows below it. Recorded in
/// C100.
const Map<LumeUnitKind, (String, String)> kLumeUnitDefaults =
    <LumeUnitKind, (String, String)>{
      LumeUnitKind.length: ('m', 'km'),
      LumeUnitKind.mass: ('kg', 'g'),
      LumeUnitKind.volume: ('L', 'mL'),
      LumeUnitKind.area: ('m2', 'ft2'),
      LumeUnitKind.speed: ('kmh', 'mph'),
      LumeUnitKind.data: ('GB', 'MB'),
    };

/// The amount the screen opens with — `fieldsFor('converter', { amount: 1 })`.
const String kLumeConverterOpeningAmount = '1';
