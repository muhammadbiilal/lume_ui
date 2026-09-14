/// Documents on the record layer — `record-schemas.js` `documents`.
///
/// What a document record is, and how one reads: the row with its standing,
/// the lock hero and the facts. The family deletes for good: its schema is
/// not recoverable, so a delete says so before it asks and offers no Undo.
library;

import 'package:flutter/widgets.dart';

import '../../../core/localization/lume_format.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/data/record_seeds.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_schema.dart';
import '../data/documents_fixtures.dart';
import 'documents_strings.dart';

/// `RECORD_SCHEMAS.documents.fields`.
const LumeRecordSchema kDocumentsSchema = LumeRecordSchema(
  collection: 'documents',
  recoverable: false,
  fields: <LumeRecordField>[
    LumeRecordField(
      name: 'name',
      kind: LumeRecordFieldKind.text,
      required: true,
    ),
    LumeRecordField(name: 'cat', kind: LumeRecordFieldKind.select),
    LumeRecordField(
      name: 'num',
      kind: LumeRecordFieldKind.text,
      optional: true,
    ),
    LumeRecordField(
      name: 'expires',
      kind: LumeRecordFieldKind.date,
      optional: true,
    ),
    LumeRecordField(
      name: 'holder',
      kind: LumeRecordFieldKind.text,
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

abstract final class LumeDocumentRecords {
  /// `defaultFor(f)` — the first category, and today for the expiry.
  static Map<String, Object?> defaults(DateTime now) => <String, Object?>{
    'cat': LumeDocumentCategory.values.first.name,
    'expires': lumeIsoDay(now, 0),
  };

  /// `txt(t, v)` over `resolve()`.
  static String text(AppLocalizations l, LumeRecord r, String name) {
    final Object? v = r[name];
    if (v == null) return '';
    return r.seeded ? LumeDocumentsStrings.seeded(l, v) : '$v';
  }

  /// The record with every seeded string resolved — what an edit form opens
  /// with.
  static LumeRecord resolved(AppLocalizations l, LumeRecord r) => r.seeded
      ? r.copyWith(
          fields: <String, Object?>{
            for (final MapEntry<String, Object?> e in r.fields.entries)
              e.key: e.value is String
                  ? LumeDocumentsStrings.seeded(l, e.value)
                  : e.value,
          },
        )
      : r;

  /// `r.cat || 'other'`.
  static LumeDocumentCategory category(LumeRecord r) =>
      LumeDocumentCategory.byId(r['cat'] as String?) ??
      LumeDocumentCategory.other;

  static DateTime? day(Object? v) {
    if (v is! String || v.length != 10) return null;
    return DateTime.tryParse(v);
  }

  /// `relDays(r.expires)`.
  static int? daysLeft(LumeRecord r, DateTime now) {
    final DateTime? d = day(r['expires']);
    if (d == null) return null;
    return DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  }

  /// `showDate(c, v)` — the locale's short date; the stored text when it is
  /// not a date.
  static String showDate(LumeFormatting f, Object? v) {
    final DateTime? d = day(v);
    return d == null ? '$v' : f.dateShort(d);
  }

  static String initial(String title) {
    final String t = title.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  /// `row(r).sub` — the category and the expiry, or "No expiry".
  static String rowSub(AppLocalizations l, LumeFormatting f, LumeRecord r) =>
      <String>[
        LumeDocumentsStrings.category(l, category(r)),
        r['expires'] == null || r['expires'] == ''
            ? l.docsNoExpiry
            : showDate(f, r['expires']),
      ].join(' · ');

  /// `row(r).badge` — expired, expiring within 45 days, or valid; none for a
  /// document that does not expire.
  static LumeBadge? badge(AppLocalizations l, LumeRecord r, DateTime now) {
    final int? n = daysLeft(r, now);
    if (n == null) return null;
    if (n < 0) {
      return LumeBadge(label: l.docsExpired, tone: LumeBadgeTone.late_);
    }
    if (n < LumeVaultDocument.soon) {
      return LumeBadge(
        label: l.docsExpiringSoonShort,
        tone: LumeBadgeTone.warn,
      );
    }
    return LumeBadge(label: l.docsValid, tone: LumeBadgeTone.ok);
  }

  /// `hero(r).caption`.
  static String heroCaption(
    AppLocalizations l,
    LumeFormatting f,
    LumeRecord r,
  ) => r['expires'] == null || r['expires'] == ''
      ? l.docsNoExpiry
      : l.recExpiresOn(showDate(f, r['expires']));

  /// `matches(schema, r, c, q)` — search looks through what the row shows.
  static bool matches(
    AppLocalizations l,
    LumeFormatting f,
    LumeRecord r,
    String query,
  ) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return <String>[
      text(l, r, 'name'),
      rowSub(l, f, r),
    ].join(' ').toLowerCase().contains(q);
  }

  static String sentence(String s) => s.isEmpty
      ? s
      : s.characters.first.toUpperCase() + s.characters.skip(1).string;
}
