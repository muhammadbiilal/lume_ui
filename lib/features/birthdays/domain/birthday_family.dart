/// Birthdays & Anniversaries on the record layer — `record-schemas.js`
/// `birthdays` (749-811).
///
/// A date is a name, whether it is a birthday or an anniversary, the day it
/// first happened — with its year — and notes. The year is the whole of the
/// arithmetic: the day that recurs is the stored month and day, and the age
/// or the count of years is the difference between the year of the next
/// occurrence and the year stored.
///
/// The tool module the reference ships does none of that. `context.js`
/// 1581-1589 hands `birthdays.tool.js` four people whose countdowns
/// (`days: 4/18/51/88`), ages (`turning: 29/6/5/61`) and `thisMonth: 2` are
/// constants, set beside dates they are not derived from. The same
/// reference's own record schema computes both properly, from `nextOn`, and
/// that schema is what is ported here — onto a `today` passed in, never the
/// wall clock, so a test and a screen agree on which day it is.
///
/// The detail carries a defect of its own, measured
/// (`measurements/tool_birthdays_default_pk_detail_390x844_light_en.json`).
/// Ayesha's stored date is `1997-09-11`, a Thursday; her next birthday is
/// `2026-09-11`, a Friday. The reference's Date fact reads "Thu, 11 Sept" —
/// the weekday of a year it never names, beside a Next one that reads
/// "Friday, 11 September". The one fact that exists to show what the reader
/// stored hides the year that Turning is counted from. Here Date carries
/// its year.
///
/// Nothing here schedules or delivers a notification: the record is a date
/// the reader can look at, and that is all it is.
library;

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_gradients.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/data/record_seeds.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_schema.dart';
import '../../records/presentation/record_family.dart';

/// `options.kinds` — the two occasions the schema offers.
///
/// The reference reads the stored value straight into a key,
/// `c.t('birthdays.' + (r.kind || 'birthday'))`, so anything but the two it
/// writes would ask for a string that does not exist. [byId] makes the same
/// default total instead.
enum LumeOccasion {
  birthday,
  anniversary;

  static LumeOccasion byId(Object? v) =>
      v == anniversary.name ? anniversary : birthday;

  String label(AppLocalizations l) => switch (this) {
    birthday => l.birthdaysBirthday,
    anniversary => l.birthdaysAnniversary,
  };

  /// The figure on its own, for a stat or a fact: a birthday is an age and
  /// reads as a number, an anniversary is a span of years and says so. An
  /// anniversary does not turn an age, and "Turning 6" of a marriage would
  /// be saying it does.
  String figure(AppLocalizations l, LumeFormatting f, int n) => switch (this) {
    birthday => f.integer(n),
    anniversary => l.birthdaysYears(n),
  };

  /// The same figure in a line of metadata beside a date —
  /// `birthdays.turns` for a birthday, the years for an anniversary.
  String count(AppLocalizations l, int n) => switch (this) {
    birthday => l.birthdaysTurns(n),
    anniversary => l.birthdaysYears(n),
  };
}

class LumeBirthday extends LumeFamilyRecord {
  const LumeBirthday(
    super.record, {
    required this.name,
    required this.kind,
    required this.date,
    required this.notes,
  });

  /// Whose day it is — the reader's own words.
  final String name;

  final LumeOccasion kind;

  /// The day it happened, **with its year**: the year is what the age is
  /// counted from. Required by the schema; `null` only for a record whose
  /// stored day cannot be read.
  final DateTime? date;

  final String notes;
}

class LumeBirthdayFamily extends LumeRecordFamily<LumeBirthday> {
  const LumeBirthdayFamily();

  static const LumeRecordSchema kSchema = LumeRecordSchema(
    collection: 'birthdays',
    fields: <LumeRecordField>[
      LumeRecordField(
        name: 'name',
        kind: LumeRecordFieldKind.text,
        required: true,
      ),
      LumeRecordField(name: 'kind', kind: LumeRecordFieldKind.select),
      LumeRecordField(
        name: 'date',
        kind: LumeRecordFieldKind.date,
        required: true,
        // The day it happened, which for a grandparent is a century ago.
        // The host's fixed fifty-year floor could not reach a birth year
        // before 1976 from a field that opens on today (C100).
        yearsBack: 130,
        // A date the reader is remembering, not planning: far enough ahead
        // to enter next month's anniversary, no further.
        yearsAhead: 2,
      ),
      LumeRecordField(
        name: 'notes',
        kind: LumeRecordFieldKind.textarea,
        optional: true,
        wide: true,
      ),
    ],
  );

  @override
  LumeRecordSchema get schema => kSchema;

  @override
  String get icon => LumeIcons.cake;

  @override
  String noun(AppLocalizations l) => l.recBirthdaysNoun;
  @override
  String nounPlural(AppLocalizations l) => l.recBirthdaysNounPlural;
  @override
  String emptyTitle(AppLocalizations l) => l.recBirthdaysEmptyTitle;
  @override
  String emptyText(AppLocalizations l) => l.recBirthdaysEmptyText;

  static String seeded(AppLocalizations l, String key) => switch (key) {
    'recSeedOurAnniversary' => l.recSeedOurAnniversary,
    _ => '@$key',
  };

  // ------------------------------------------------------------ arithmetic
  //
  // Static and pure, so what the screen shows can be checked without one.

  /// `nextOn(r)` — the next time the stored month and day come round
  /// (`record-schemas.js:767-774`), counted from [today] rather than from
  /// `new Date()`. Today's own date is today, not a year away: the
  /// reference's `next < today` is a strict comparison and this keeps it.
  ///
  /// **29 February.** `DateTime(2027, 2, 29)` is 1 March 2027 — Dart rolls a
  /// day past the end of a month into the next one, and so does the
  /// reference's `new Date(y, 1, 29)`. That roll is kept deliberately: in a
  /// year with no 29 February the day is observed on 1 March, the later of
  /// the two conventions, so the countdown never names a day that has
  /// already gone. In a leap year the 29th is itself.
  ///
  /// The following year is computed from the **stored** month and day, not
  /// from the rolled value. The reference adds a year to what it has already
  /// rolled (`next.setFullYear(next.getFullYear() + 1)`,
  /// `record-schemas.js:772`), which fixes a 29 February onto 1 March even
  /// when the year it lands in is a leap year and has a 29th of its own.
  /// That is a defect in the reference, and it is not reproduced.
  static DateTime? nextOn(DateTime? born, DateTime today) {
    if (born == null) return null;
    final DateTime next = DateTime(today.year, born.month, born.day);
    if (next.isBefore(today)) {
      return DateTime(today.year + 1, born.month, born.day);
    }
    return next;
  }

  /// Calendar days from [today] to the next occurrence — dates counted as
  /// dates, never as elapsed hours, so a daylight-saving change cannot move
  /// a birthday in or out of a day.
  static int? daysUntil(DateTime? born, DateTime today) =>
      LumeFamilyText.daysFrom(nextOn(born, today), today);

  /// `next.getFullYear() - born.getFullYear()` (`record-schemas.js:794`) —
  /// the age being reached, or the years being counted. `null` where the
  /// date could not be read, or where the answer is not a positive number:
  /// a year still to come gives nothing to count, and a date stored in this
  /// year's own calendar turns nobody.
  static int? turning(DateTime? born, DateTime? next) {
    if (born == null || next == null) return null;
    final int n = next.year - born.year;
    return n > 0 ? n : null;
  }

  /// Whether the next occurrence falls inside [today]'s own calendar month —
  /// what the reference writes as the constant `thisMonth: 2`.
  static bool inMonthOf(DateTime? born, DateTime today) {
    final DateTime? next = nextOn(born, today);
    return next != null && next.year == today.year && next.month == today.month;
  }

  // ---------------------------------------------------------------- words

  /// The countdown the schema's own row writes
  /// (`record-schemas.js:783`): Today, else "in n days". `null` when there
  /// is no reader's day to count from, or no readable date — the reference
  /// reaches neither state.
  String? countdown(LumeRecordContext c, DateTime? next) {
    if (!c.dayKnown || next == null) return null;
    final int n = LumeFamilyText.daysFrom(next, c.today)!;
    return n == 0 ? c.l.commonToday : c.l.commonInDays(n);
  }

  /// The date a row leads with: the next occurrence where the reader's day
  /// is known, and otherwise the stored day itself, with its year. Nothing
  /// that depends on which day it is may be drawn on a day that is not the
  /// reader's.
  String? dateLine(LumeBirthday x, LumeRecordContext c) {
    if (x.date == null) return null;
    if (!c.dayKnown) return c.f.dateMediumYear(x.date!);
    return c.f.dateShort(nextOn(x.date, c.today)!);
  }

  // --------------------------------------------------------------- reading

  @override
  LumeBirthday read(LumeRecord r, LumeRecordContext c) {
    String text(String name) =>
        LumeFamilyText.resolve(r, name, (String k) => seeded(c.l, k));
    return LumeBirthday(
      r,
      name: text('name'),
      kind: LumeOccasion.byId(r['kind']),
      date: LumeFamilyText.day(r['date']),
      notes: text('notes'),
    );
  }

  /// `defaultFor(f)` — the occasion the reference falls back to, and nothing
  /// else. A new date deliberately opens with no day: a birth date is almost
  /// never today, and offering today as the answer invites saving it.
  @override
  Map<String, Object?> defaults(LumeRecordContext c) => <String, Object?>{
    'kind': LumeOccasion.birthday.name,
  };

  @override
  Map<String, Object?> editValues(LumeBirthday x) => <String, Object?>{
    'name': x.name,
    'kind': x.kind.name,
    'date': x.date == null ? '' : lumeIsoDay(x.date!, 0),
    'notes': x.notes,
  };

  @override
  LumeFamilyRow row(LumeBirthday x, LumeRecordContext c) {
    final String? on = dateLine(x, c);
    return LumeFamilyRow(
      title: x.name,
      // Measured: "Birthday · Fri, 11 Sept" — the occasion, then the day,
      // the weekday included. Nothing is bidi-isolated: both halves are
      // words the locale wrote, and `isolate` is for identifiers.
      subtitle: <String>[x.kind.label(c.l), ?on].join(' · '),
      value: countdown(c, nextOn(x.date, c.today)),
    );
  }

  @override
  LumeFamilyHero hero(LumeBirthday x, LumeRecordContext c) {
    final DateTime? next = nextOn(x.date, c.today);
    return LumeFamilyHero(
      kicker: x.kind.label(c.l),
      value: x.name,
      // `tone: 'night'`, and `c.dateLong(next)` — measured as
      // "Friday, 11 September", which is this build's `dateFull`.
      caption: c.dayKnown && next != null ? c.f.dateFull(next) : null,
      gradient: (LumeGradients g) => g.night,
    );
  }

  /// The reference's own five (`record-schemas.js:795-801`).
  @override
  List<LumeFact> facts(LumeBirthday x, LumeRecordContext c) {
    final DateTime? next = nextOn(x.date, c.today);
    final int? n = c.dayKnown ? turning(x.date, next) : null;
    return <LumeFact>[
      LumeFact(label: c.l.recFieldOccasion, value: x.kind.label(c.l)),
      LumeFact(
        label: c.l.commonDate,
        // "11 Sept 1997". The reference shows the stored day through
        // `showDate`, which is `dateShort` and drops the year
        // (`record-schemas.js:86-90`) — so this fact prints the weekday of
        // an unnamed year beside a Next one that is the same day and month,
        // and the year that Turning is counted from is nowhere on the
        // screen. `dateMediumYear` is the year-bearing form of that same
        // short date; the weekday goes, because the weekday of a birth year
        // is not what this fact is for.
        value: x.date == null ? '—' : c.f.dateMediumYear(x.date!),
      ),
      LumeFact(
        label: c.l.recNextOne,
        // Measured: "Friday, 11 September".
        value: c.dayKnown && next != null ? c.f.dateFull(next) : '—',
      ),
      LumeFact(
        label: c.l.recTurning,
        value: n == null ? '—' : x.kind.figure(c.l, c.f, n),
      ),
      LumeFact(
        label: c.l.recFieldNotes,
        value: x.notes.isEmpty ? c.l.recNone : x.notes,
      ),
    ];
  }

  @override
  List<LumeFamilyField> fields(LumeRecordContext c) => <LumeFamilyField>[
    LumeFamilyField(
      name: 'name',
      label: c.l.commonName,
      placeholder: c.l.recBirthdaysPh,
    ),
    LumeFamilyField(
      name: 'kind',
      label: c.l.recFieldOccasion,
      options: <LumeFamilyOption>[
        for (final LumeOccasion o in LumeOccasion.values)
          LumeFamilyOption(o.name, o.label(c.l)),
      ],
    ),
    LumeFamilyField(name: 'date', label: c.l.recFieldDate),
    LumeFamilyField(name: 'notes', label: c.l.recFieldNotes),
  ];
}
