/// What a record family is to a screen — the typed half of
/// `record-schemas.js` that the CRUD engine reads.
///
/// The store keeps a record as an id, its fields and its bookkeeping
/// ([LumeRecord]), one shape for every family. A family reads that into its
/// own typed value — a note, a task, an event, a shopping item — and says how
/// the value is listed, shown, edited and filtered. The host
/// (`record_tool.dart`) draws list, detail, form and delete from this and
/// never learns what a due date or an aisle is.
library;

import 'package:flutter/widgets.dart';

import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_gradients.dart';
import '../../../core/time/lume_time_zone.dart';
import '../../../core/time/lume_zone.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/record_model.dart';
import '../domain/record_schema.dart';

/// What every reading needs: the words, the formats, the day, and which
/// clock the reader is on.
///
/// **The reader's day.** A due date or an event's date is a calendar date
/// with no zone of its own, so "today" is the reader's calendar date: the
/// injected instant read on the clock of the reader's zone ([zoneId],
/// through [LumeZoneDatabase]). Every day count — overdue, "in 3 days",
/// To-dos' Week — counts calendar dates from [today], never elapsed hours,
/// so a daylight-saving change cannot move a task in or out of a day. A zone
/// the database cannot read falls back to the device's own calendar date,
/// and [zoneKnown] says so.
@immutable
class LumeRecordContext {
  factory LumeRecordContext({
    required AppLocalizations l,
    required LumeFormatting f,
    required DateTime now,
    required String zoneId,
    required String currency,
    LumeZoneDatabase zones = const LumeRuleTableZones(),
  }) {
    final LumeZone? zone = zones.zoneFor(zoneId);
    return LumeRecordContext._(
      l: l,
      f: f,
      now: now,
      zoneId: zoneId,
      currency: currency,
      zoneKnown: zone != null,
      local: zone?.wallClockAt(now) ?? now,
    );
  }

  const LumeRecordContext._({
    required this.l,
    required this.f,
    required this.now,
    required this.zoneId,
    required this.currency,
    required this.zoneKnown,
    required this.local,
  });

  final AppLocalizations l;
  final LumeFormatting f;

  /// The instant, from the injected clock — never the device's directly.
  final DateTime now;

  /// The reader's IANA zone — their own choice, or their country's.
  final String zoneId;

  /// The reader's currency code; empty when the country has none on file.
  final String currency;

  /// Whether [zoneId] was read; if not, [local] is the device's own clock.
  final bool zoneKnown;

  /// [now] on the reader's wall clock.
  final DateTime local;

  /// The reader's calendar date.
  DateTime get today => DateTime(local.year, local.month, local.day);
}

/// One record, read by its family. [record] keeps the store's bookkeeping —
/// id, version, when made and changed, sample or the reader's, queued.
abstract class LumeFamilyRecord {
  const LumeFamilyRecord(this.record);

  final LumeRecord record;

  String get id => record.id;
  int get version => record.version;
}

/// `schema.row(r)`.
@immutable
class LumeFamilyRow {
  const LumeFamilyRow({
    required this.title,
    this.subtitle,
    this.meta,
    this.value,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final List<String>? meta;
  final String? value;
  final LumeBadge? badge;

  /// Search looks through what the row shows (`matches()`).
  String get searchable => <String?>[
    title,
    subtitle,
    ...?meta,
    value,
  ].whereType<String>().join(' ').toLowerCase();
}

/// `schema.hero(r)`.
@immutable
class LumeFamilyHero {
  const LumeFamilyHero({
    required this.value,
    this.kicker,
    this.title,
    this.caption,
    this.gradient,
  });

  final String value;
  final String? kicker;
  final String? title;
  final String? caption;

  /// `tone`, resolved against the theme.
  final LumeGradient Function(LumeGradients g)? gradient;
}

/// `schema.filters()` — one chip beside All.
@immutable
class LumeFamilyFilter<T> {
  const LumeFamilyFilter(this.value, this.label, this.test);

  final String value;
  final String label;
  final bool Function(T x) test;
}

/// `schema.bulk` — the family's one many-record write, confirmed first and
/// never undoable.
@immutable
class LumeFamilyBulk<T> {
  const LumeFamilyBulk({
    required this.test,
    required this.label,
    required this.confirm,
  });

  final bool Function(T x) test;
  final String Function(int n) label;
  final String Function(int n) confirm;
}

/// One choice of a select field: what is stored, and what is read.
@immutable
class LumeFamilyOption {
  const LumeFamilyOption(this.value, this.label);

  final String value;
  final String label;
}

/// How one schema field is drawn in the form.
@immutable
class LumeFamilyField {
  const LumeFamilyField({
    required this.name,
    required this.label,
    this.placeholder,
    this.options = const <LumeFamilyOption>[],
    this.clearLabel,
  });

  final String name;
  final String label;
  final String? placeholder;

  /// What the Clear under an optional date or time says it clears — "Clear
  /// due date", "Clear event time" — so a screen reader hears which one.
  final String? clearLabel;

  /// For a select.
  final List<LumeFamilyOption> options;
}

abstract class LumeRecordFamily<T extends LumeFamilyRecord> {
  const LumeRecordFamily();

  LumeRecordSchema get schema;

  String get collection => schema.collection;

  /// `schema.icon`.
  String get icon;

  String noun(AppLocalizations l);
  String nounPlural(AppLocalizations l);
  String emptyTitle(AppLocalizations l);
  String emptyText(AppLocalizations l);

  /// The typed record, every sample string in the reader's language.
  T read(LumeRecord r, LumeRecordContext c);

  /// `defaultFor(f)` for each field a new record opens with.
  Map<String, Object?> defaults(LumeRecordContext c);

  /// What an edit form opens with — the words as the reader now reads them,
  /// so saving a sample record keeps what it said.
  Map<String, Object?> editValues(T x);

  LumeFamilyRow row(T x, LumeRecordContext c);
  LumeFamilyHero hero(T x, LumeRecordContext c);
  List<LumeFact> facts(T x, LumeRecordContext c);

  /// In schema order.
  List<LumeFamilyField> fields(LumeRecordContext c);

  List<LumeFamilyFilter<T>> filters(LumeRecordContext c) =>
      <LumeFamilyFilter<T>>[];

  /// The check a family logs from its row, or `null` where there is none.
  String? checkLabel(AppLocalizations l) => null;

  bool checked(T x) => false;

  /// The fields a tick writes. Only the tick: no words, so a sample record
  /// stays a sample record.
  Map<String, Object?> toggled(T x, LumeRecordContext c) =>
      const <String, Object?>{};

  LumeFamilyBulk<T>? bulk(AppLocalizations l) => null;

  bool matches(T x, String query, LumeRecordContext c) {
    final String q = query.trim().toLowerCase();
    return q.isEmpty || row(x, c).searchable.contains(q);
  }
}

/// Helpers every family shares.
abstract final class LumeFamilyText {
  /// `txt(t, v)` over `resolve()`: a sample record's `@key` in the reader's
  /// language; a record the reader wrote, as written.
  static String resolve(
    LumeRecord r,
    String name,
    String Function(String key) seeded,
  ) {
    final Object? v = r[name];
    if (v == null) return '';
    final String s = '$v';
    if (r.seeded && s.startsWith('@')) return seeded(s.substring(1));
    return s;
  }

  static String initial(String title) {
    final String t = title.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  /// `sentence(lang, s)` — a noun raised at the head of a line.
  static String sentence(String s) => s.isEmpty
      ? s
      : s.characters.first.toUpperCase() + s.characters.skip(1).string;

  /// An ISO calendar day, or `null`.
  static DateTime? day(Object? v) {
    if (v is! String || v.length != 10) return null;
    final DateTime? d = DateTime.tryParse(v);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  /// `relDays(v)`.
  static int? daysFrom(DateTime? d, DateTime now) {
    if (d == null) return null;
    return DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  }

  /// `whenLabel(c, v)` — Today, Tomorrow, Yesterday, in n days, n days ago,
  /// or the short date beyond a month either way.
  static String when(LumeRecordContext c, DateTime? d) {
    if (d == null) return '—';
    final int n = daysFrom(d, c.today)!;
    if (n == 0) return c.l.commonToday;
    if (n == 1) return c.l.commonTomorrow;
    if (n == -1) return c.l.commonYesterday;
    if (n > 1 && n <= 30) return c.l.commonInDays(n);
    if (n < -1 && n >= -30) return c.l.recDaysAgo(-n);
    return c.f.dateShort(d);
  }

  /// `HH:mm`, or `null`.
  static (int, int)? clock(Object? v) {
    if (v is! String) return null;
    final RegExpMatch? m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(v);
    if (m == null) return null;
    final int h = int.parse(m[1]!), min = int.parse(m[2]!);
    if (h > 23 || min > 59) return null;
    return (h, min);
  }

  static String isoClock(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  /// A stored time in the reader's clock format.
  static String showClock(LumeRecordContext c, Object? v) {
    final (int, int)? t = clock(v);
    if (t == null) return '';
    return c.f.time(DateTime(2000, 1, 1, t.$1, t.$2));
  }
}
