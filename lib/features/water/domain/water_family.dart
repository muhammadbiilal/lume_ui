/// Water on the record layer — `record-schemas.js:600-645`, plus the one
/// field the reference's own schema is missing.
///
/// A drink is how much, what it was, and when. The reference stores `ml`,
/// `kind` and `at` — and nothing that says *which day*. Its screen then calls
/// the sum of every stored drink "today", which is true only until midnight:
/// a reader who logs a glass on Monday and another on Tuesday is shown three
/// on Tuesday. So `date` is added here, required, written by the two add
/// buttons and by the form. That is a correction to the model, not a
/// decoration on it, and every figure the tool shows depends on it.
///
/// **The daily goal is not in this file.** It is a record of its own, in its
/// own collection — see `water_goal.dart`. Nothing here knows what the goal
/// is; the arithmetic below takes it as an argument, so the only target any
/// figure is ever measured against is the one the reader is currently on.
///
/// What is dropped from the reference, and why:
///
/// * **`streak: 6`** (`context.js:1633`) — a literal. Nothing in the store
///   counts consecutive days, and a six the reader did not earn is a
///   fabrication. The summary's third figure is instead how many drinks were
///   actually logged today.
/// * **the week chart** — `week: [1800, 2100, 1650, 2000, 1900, 2200, 1250]`
///   (`context.js:1642`), seven constants under day labels M T W T F S S with
///   the last bar highlighted. The store holds no week, so no week is drawn.
/// * **`ml / 29.574`** (`context.js:1626`) — a truncated fluid ounce.
///   [LumeWaterVolume] uses the exact 29.5735295625 ml.
///
/// What the record's own detail corrects, measured against the reference's
/// (`tool_water_default_pk_detail_390x844_light_en`):
///
/// * it lists **two** facts, Drink and Time, and never states the amount —
///   the one number the record exists to hold. [LumeWaterFamily.facts] states
///   it.
/// * it has no date, because its schema has none. This one does.
/// * its Time fact and its hero caption print the bare stored `08:10`, while
///   the timeline three sections above prints `8:10 am` for the same record.
///   Both read the reader's clock here.
///
/// Nothing here classifies the reader, compares them to anybody, or says
/// anything about health. A figure is a sum of what they logged.
library;

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../converter/domain/lume_ratio.dart';
import '../../records/data/record_seeds.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_schema.dart';
import '../../records/presentation/record_family.dart';

/// `options.kinds` — the two the reference offers, and no more.
enum LumeDrinkKind {
  water('@water.kindWater'),
  tea('@water.kindTea');

  const LumeDrinkKind(this.legacy);

  /// What `record-schemas.js:610-611` stores: a translation key. The seeds
  /// in this build store the plain id, and both are read.
  final String legacy;

  static LumeDrinkKind? byId(Object? v) {
    for (final LumeDrinkKind k in values) {
      if (v == k.name || v == k.legacy) return k;
    }
    return null;
  }

  String label(AppLocalizations l) => switch (this) {
    water => l.waterKindWater,
    tea => l.waterKindTea,
  };
}

/// One logged drink.
class LumeDrink extends LumeFamilyRecord {
  const LumeDrink(
    super.record, {
    required this.ml,
    required this.kind,
    required this.at,
    required this.date,
  });

  /// A whole, positive count of millilitres — `null` when what is stored is
  /// not one. A stored `0`, a negative, a word or a fraction of a millilitre
  /// is not a reading that can be added up, so it is left out of every total
  /// rather than rounded into one.
  final int? ml;

  /// The reference falls back to Water for a kind it cannot read
  /// (`record-schemas.js:616`), and so does this: the kind is a label on the
  /// drink, never part of a sum.
  final LumeDrinkKind kind;

  /// `(hour, minute)` on the reader's clock, or `null` when unreadable.
  final (int, int)? at;

  /// The calendar day it was logged for. Required by the schema; `null` only
  /// for a record whose stored day cannot be read.
  final DateTime? date;

  /// Whether this drink can be counted towards a day's total at all.
  bool get countable => ml != null && at != null && date != null;

  /// For ordering within a day.
  int get minuteOfDay => at == null ? 0 : at!.$1 * 60 + at!.$2;
}

/// How much, in the reader's own units.
///
/// The symbols are the international ones and are not translated, which is
/// the policy `converter/domain/unit_table.dart` states for every unit in the
/// app. The reference reaches for `t('unit.litre')` and `t('unit.floz')`
/// (`context.js:1626-1627`); this tool's approved string set has no unit
/// words, and inventing two would be inventing translations.
abstract final class LumeWaterVolume {
  /// The US fluid ounce, exactly: 29.5735295625 ml. The reference divides by
  /// `29.574` (`context.js:1626`), which is 0.0016 % out — small, but there
  /// is no reason to carry a wrong constant when an exact one costs nothing.
  ///
  /// It is parsed here rather than added to `unit_table.dart`, which belongs
  /// to Unit Converter and has no fluid ounce in it.
  static final LumeRatio flOz = LumeRatio.parse('29.5735295625');

  static final LumeRatio _thousand = LumeRatio.parse('1000');

  /// A total, the way the reference writes one: litres to one decimal
  /// ("1.3 L"), or whole fluid ounces.
  ///
  /// The rounding is half away from zero, as `toFixed` is — 1250 ml is
  /// "1.3 L", not "1.2 L" — and the digits are then the reader's own, which
  /// the reference's `toFixed` never gives them.
  static String total(LumeRecordContext c, int ml) {
    if (c.f.units == LumeUnits.imperial) return _ounces(c, ml);
    final String rounded = (LumeRatio.whole(ml) / _thousand).toStringAsFixedMax(
      1,
    );
    return '${c.f.fixed(num.parse(rounded), 1)} L';
  }

  /// One drink, or one button's step. Millilitres for a metric reader —
  /// "250 ml", as the reference's own buttons and toast are written — and
  /// fluid ounces for an imperial one, where "0.3 L" would say less than
  /// nothing.
  static String amount(LumeRecordContext c, int ml) =>
      c.f.units == LumeUnits.imperial
      ? _ounces(c, ml)
      : '${c.f.integer(ml)} ml';

  static String _ounces(LumeRecordContext c, int ml) {
    final String whole = (LumeRatio.whole(ml) / flOz).toStringAsFixedMax(0);
    return '${c.f.integer(int.parse(whole))} fl oz';
  }
}

class LumeWaterFamily extends LumeRecordFamily<LumeDrink> {
  const LumeWaterFamily();

  /// `record-schemas.js:602-606`, with `date` added — see the library
  /// comment. `ml` keeps the reference's `positive` rule.
  static const LumeRecordSchema kSchema = LumeRecordSchema(
    collection: 'water',
    fields: <LumeRecordField>[
      LumeRecordField(
        name: 'ml',
        kind: LumeRecordFieldKind.number,
        required: true,
        rule: LumeFieldRule.positive,
      ),
      LumeRecordField(name: 'kind', kind: LumeRecordFieldKind.select),
      LumeRecordField(
        name: 'at',
        kind: LumeRecordFieldKind.time,
        required: true,
      ),
      LumeRecordField(
        name: 'date',
        kind: LumeRecordFieldKind.date,
        required: true,
      ),
    ],
  );

  /// `Math.round(s.ml / 250)` — the reference's own rule, and the only
  /// meaning "glasses" has here: a unit of 250 ml, not a recommendation to
  /// drink one.
  static const int glassMl = 250;

  @override
  LumeRecordSchema get schema => kSchema;

  @override
  String get icon => LumeIcons.droplet;

  @override
  String noun(AppLocalizations l) => l.recWaterNoun;
  @override
  String nounPlural(AppLocalizations l) => l.recWaterNounPlural;
  @override
  String emptyTitle(AppLocalizations l) => l.recWaterEmptyTitle;
  @override
  String emptyText(AppLocalizations l) => l.recWaterEmptyText;

  /// A whole, positive number of millilitres, or `null`.
  static int? readMl(Object? v) {
    final num? n = v is num ? v : num.tryParse('${v ?? ''}'.trim());
    if (n == null || !n.isFinite || n <= 0 || n != n.roundToDouble()) {
      return null;
    }
    return n.toInt();
  }

  @override
  LumeDrink read(LumeRecord r, LumeRecordContext c) => LumeDrink(
    r,
    ml: readMl(r['ml']),
    kind: LumeDrinkKind.byId(r['kind']) ?? LumeDrinkKind.water,
    at: LumeFamilyText.clock(r['at']),
    date: LumeFamilyText.day(r['date']),
  );

  /// Today, and the time now — but only where the reader's day is known. A
  /// drink dated on another zone's day would be counted into the wrong one.
  @override
  Map<String, Object?> defaults(LumeRecordContext c) => <String, Object?>{
    'kind': LumeDrinkKind.water.name,
    'at': c.dayKnown
        ? LumeFamilyText.isoClock(c.local.hour, c.local.minute)
        : '',
    'date': c.dayKnown ? lumeIsoDay(c.today, 0) : '',
  };

  @override
  Map<String, Object?> editValues(LumeDrink x) => <String, Object?>{
    'ml': x.ml ?? '',
    'kind': x.kind.name,
    'at': x.at == null ? '' : LumeFamilyText.isoClock(x.at!.$1, x.at!.$2),
    'date': x.date == null ? '' : lumeIsoDay(x.date!, 0),
  };

  /// The stored time on the reader's clock. The reference prints the raw
  /// `08:10` in the row and a formatted clock in the timeline
  /// (`record-schemas.js:618` against `context.js:1637`); both are formatted
  /// here, so a 12-hour reader is never shown one of each.
  String time(LumeDrink x, LumeRecordContext c) => x.at == null
      ? ''
      : LumeFamilyText.showClock(
          c,
          LumeFamilyText.isoClock(x.at!.$1, x.at!.$2),
        );

  String volume(LumeDrink x, LumeRecordContext c) =>
      x.ml == null ? '—' : LumeWaterVolume.amount(c, x.ml!);

  /// The reference's row subtitle is the bare time, which is enough only
  /// because its schema cannot tell two days apart. With a day on the record,
  /// the row says which day as well.
  @override
  LumeFamilyRow row(LumeDrink x, LumeRecordContext c) => LumeFamilyRow(
    title: x.kind.label(c.l),
    subtitle: <String>[
      LumeFamilyText.when(c, x.date),
      time(x, c),
    ].where((String p) => p.isNotEmpty).join(' · '),
    value: volume(x, c),
  );

  @override
  LumeFamilyHero hero(LumeDrink x, LumeRecordContext c) => LumeFamilyHero(
    kicker: x.kind.label(c.l),
    value: volume(x, c),
    caption: <String>[
      LumeFamilyText.when(c, x.date),
      time(x, c),
    ].where((String p) => p.isNotEmpty).join(' · '),
    gradient: (g) => g.sky,
  );

  @override
  List<LumeFact> facts(LumeDrink x, LumeRecordContext c) => <LumeFact>[
    LumeFact(label: c.l.recFieldDrink, value: x.kind.label(c.l)),
    LumeFact(
      label: c.l.recFieldAmountMl,
      value: x.ml == null ? '—' : c.f.integer(x.ml!),
    ),
    LumeFact(
      label: c.l.recFieldTime,
      value: time(x, c).isEmpty ? c.l.recNoTime : time(x, c),
    ),
    LumeFact(
      label: c.l.commonDate,
      value: x.date == null ? '—' : c.f.dateShort(x.date!),
    ),
  ];

  @override
  List<LumeFamilyField> fields(LumeRecordContext c) => <LumeFamilyField>[
    LumeFamilyField(name: 'ml', label: c.l.recFieldAmountMl),
    LumeFamilyField(
      name: 'kind',
      label: c.l.recFieldDrink,
      options: <LumeFamilyOption>[
        for (final LumeDrinkKind k in LumeDrinkKind.values)
          LumeFamilyOption(k.name, k.label(c.l)),
      ],
    ),
    LumeFamilyField(name: 'at', label: c.l.recFieldTime),
    LumeFamilyField(name: 'date', label: c.l.commonDate),
  ];

  // **No filter chips**, deliberately. Water/Tea chips were written here
  // and taken out again: the rule in this build is that a family's chips
  // are its reference schema's `filters`, and Water has none — measured,
  // `tool_water_default_pk_390x844_light_en` reports `"chips": []`. Shopping
  // and To-dos draw chips because their schemas declare them; Events and
  // Notes draw none for the same reason. A chip row Water alone invented
  // would also add a row to the record list that the reference does not
  // have, and every figure below it would sit lower than the cell it is
  // compared against — a product addition paid for out of the parity
  // comparison.

  // ---- the arithmetic, which is all of it ---------------------------------

  /// [today]'s drinks, earliest first. A drink missing an amount, a time or a
  /// day is not one of them.
  ///
  /// Two drinks at the same minute keep the order they were written in — a
  /// reader logging two glasses at once must not see them swap on the next
  /// rebuild. `List.sort` is not stable, so the order is decided rather than
  /// left to it: the time, then when the record was made, then its position
  /// in [all], which the store keeps newest first.
  static List<LumeDrink> today(Iterable<LumeDrink> all, DateTime today) {
    final DateTime day = DateTime(today.year, today.month, today.day);
    final List<(int, LumeDrink)> mine = <(int, LumeDrink)>[];
    int i = 0;
    for (final LumeDrink x in all) {
      if (x.countable && x.date! == day) mine.add((i, x));
      i++;
    }
    mine.sort(((int, LumeDrink) a, (int, LumeDrink) b) {
      final int byTime = a.$2.minuteOfDay.compareTo(b.$2.minuteOfDay);
      if (byTime != 0) return byTime;
      final int byMade = a.$2.record.createdAt.compareTo(b.$2.record.createdAt);
      if (byMade != 0) return byMade;
      return b.$1.compareTo(a.$1);
    });
    return <LumeDrink>[for (final (int, LumeDrink) x in mine) x.$2];
  }

  /// What [today]'s drinks add up to, in millilitres.
  static int totalMl(Iterable<LumeDrink> all, DateTime today) {
    int sum = 0;
    for (final LumeDrink x in LumeWaterFamily.today(all, today)) {
      sum += x.ml!;
    }
    return sum;
  }

  /// `Math.round(ml / 250)` (`context.js:1633`) — 250 ml to a glass, half
  /// away from zero, so 125 ml is one glass and 124 is none.
  static int glasses(int ml) => (ml / glassMl).round();

  /// What is left of the goal, never below zero — `Math.max(0, target - ml)`.
  static int remaining(int ml, int target) {
    final int left = target - ml;
    return left < 0 ? 0 : left;
  }

  /// The ring's share, `Math.min(1, ml / target)`. For the ring only: the
  /// figures beside it say the same thing in words, and a goal of nothing
  /// fills nothing rather than dividing by zero.
  static double fraction(int ml, int target) {
    if (target <= 0 || ml <= 0) return 0;
    final double share = ml / target;
    return share > 1 ? 1 : share;
  }

  /// The whole per cent the ring announces, rounded half **up** as the
  /// reference's `Math.round` does: 1250 of 2000 is 63, not 62. Integer
  /// arithmetic, so no binary fraction can move it either way.
  static int percent(int ml, int target) {
    if (target <= 0 || ml <= 0) return 0;
    final int pct = (ml * 200 + target) ~/ (target * 2);
    return pct > 100 ? 100 : pct;
  }
}
