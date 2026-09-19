/// Events on the record layer — `record-schemas.js` `events`.
///
/// An event is a title, a day, an optional time, a place, how many are
/// going and notes. Guide: "date and recurrence" · "timezone and
/// permissions". There is no reminder, repeat or alert field, and nothing
/// here schedules or delivers a notification; the detail says which clock
/// the time is on — the reader's zone, never a fixed offset (§16).
library;

import '../../../core/icons/lume_icons.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/data/record_seeds.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_schema.dart';
import '../../records/presentation/record_family.dart';

class LumeEvent extends LumeFamilyRecord {
  const LumeEvent(
    super.record, {
    required this.title,
    required this.date,
    required this.at,
    required this.where,
    required this.people,
    required this.notes,
  });

  final String title;

  /// Required by the schema; `null` only for a record whose stored day
  /// cannot be read.
  final DateTime? date;

  /// `(hour, minute)`, or `null` — the reference lets a time be emptied.
  final (int, int)? at;

  final String where;

  /// A positive whole number, or `null`.
  final int? people;

  final String notes;

  /// When it starts, on the reader's calendar — for ordering.
  DateTime? get starts => date == null
      ? null
      : DateTime(date!.year, date!.month, date!.day, at?.$1 ?? 0, at?.$2 ?? 0);
}

class LumeEventFamily extends LumeRecordFamily<LumeEvent> {
  const LumeEventFamily();

  static const LumeRecordSchema kSchema = LumeRecordSchema(
    collection: 'events',
    fields: <LumeRecordField>[
      LumeRecordField(
        name: 'title',
        kind: LumeRecordFieldKind.text,
        required: true,
      ),
      LumeRecordField(
        name: 'date',
        kind: LumeRecordFieldKind.date,
        required: true,
      ),
      LumeRecordField(name: 'at', kind: LumeRecordFieldKind.time),
      LumeRecordField(
        name: 'where',
        kind: LumeRecordFieldKind.text,
        optional: true,
      ),
      LumeRecordField(
        name: 'people',
        kind: LumeRecordFieldKind.number,
        optional: true,
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
  String get icon => LumeIcons.calendar;

  @override
  String noun(AppLocalizations l) => l.recEventsNoun;
  @override
  String nounPlural(AppLocalizations l) => l.recEventsNounPlural;
  @override
  String emptyTitle(AppLocalizations l) => l.recEventsEmptyTitle;
  @override
  String emptyText(AppLocalizations l) => l.recEventsEmptyText;

  static String seeded(AppLocalizations l, String key) => switch (key) {
    'eventsSeedE2' => l.eventsSeedE2,
    'eventsSeedE3' => l.eventsSeedE3,
    'eventsSeedW2' => l.eventsSeedW2,
    'eventsSeedW3' => l.eventsSeedW3,
    _ => '@$key',
  };

  static int? _count(Object? v) {
    final num? n = v is num ? v : num.tryParse('${v ?? ''}'.trim());
    if (n == null || n <= 0 || n != n.roundToDouble()) return null;
    return n.toInt();
  }

  @override
  LumeEvent read(LumeRecord r, LumeRecordContext c) {
    String text(String name) =>
        LumeFamilyText.resolve(r, name, (String k) => seeded(c.l, k));
    return LumeEvent(
      r,
      title: text('title'),
      date: LumeFamilyText.day(r['date']),
      at: LumeFamilyText.clock(r['at']),
      where: text('where'),
      people: _count(r['people']),
      notes: text('notes'),
    );
  }

  /// `defaultFor(f)` — today, and the time now.
  @override
  Map<String, Object?> defaults(LumeRecordContext c) => <String, Object?>{
    'date': lumeIsoDay(c.now, 0),
    'at': LumeFamilyText.isoClock(c.now.hour, c.now.minute),
  };

  @override
  Map<String, Object?> editValues(LumeEvent x) => <String, Object?>{
    'title': x.title,
    'date': x.date == null ? '' : lumeIsoDay(x.date!, 0),
    'at': x.at == null ? '' : LumeFamilyText.isoClock(x.at!.$1, x.at!.$2),
    'where': x.where,
    'people': x.people ?? '',
    'notes': x.notes,
  };

  String time(LumeEvent x, LumeRecordContext c) => x.at == null
      ? ''
      : LumeFamilyText.showClock(
          c,
          LumeFamilyText.isoClock(x.at!.$1, x.at!.$2),
        );

  @override
  LumeFamilyRow row(LumeEvent x, LumeRecordContext c) {
    final String t = time(x, c);
    return LumeFamilyRow(
      title: x.title,
      subtitle: <String>[
        LumeFamilyText.when(c, x.date),
        if (x.where.isNotEmpty) x.where,
      ].join(' · '),
      value: t.isEmpty ? null : t,
    );
  }

  @override
  LumeFamilyHero hero(LumeEvent x, LumeRecordContext c) => LumeFamilyHero(
    kicker: LumeFamilyText.when(c, x.date),
    value: x.title,
    title: x.where.isEmpty ? null : x.where,
    caption: time(x, c).isEmpty ? null : time(x, c),
    gradient: (g) => g.night,
  );

  @override
  List<LumeFact> facts(LumeEvent x, LumeRecordContext c) => <LumeFact>[
    LumeFact(
      label: c.l.commonDate,
      value: x.date == null ? '—' : c.f.dateShort(x.date!),
    ),
    LumeFact(
      label: c.l.recFieldTime,
      value: time(x, c).isEmpty ? c.l.recNoTime : time(x, c),
    ),
    LumeFact(label: c.l.recFieldWhere, value: x.where.isEmpty ? '—' : x.where),
    LumeFact(
      label: c.l.recFieldPeople,
      value: x.people == null ? '—' : c.f.integer(x.people!),
    ),
    // §16 — a time-sensitive record says which clock it is on.
    LumeFact(label: c.l.recFieldTimezone, value: c.zoneId),
    LumeFact(
      label: c.l.recFieldNotes,
      value: x.notes.isEmpty ? c.l.recNone : x.notes,
    ),
  ];

  @override
  List<LumeFamilyField> fields(LumeRecordContext c) => <LumeFamilyField>[
    LumeFamilyField(
      name: 'title',
      label: c.l.recFieldTitle,
      placeholder: c.l.recEventsPh,
    ),
    LumeFamilyField(name: 'date', label: c.l.recFieldDate),
    LumeFamilyField(name: 'at', label: c.l.recFieldTime),
    LumeFamilyField(name: 'where', label: c.l.recFieldWhere),
    LumeFamilyField(name: 'people', label: c.l.recFieldPeople),
    LumeFamilyField(name: 'notes', label: c.l.recFieldNotes),
  ];
}
