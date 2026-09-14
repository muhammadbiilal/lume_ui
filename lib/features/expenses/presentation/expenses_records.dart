/// Expenses on the record layer — `record-schemas.js` `expenses`.
///
/// What an expense is (its fields), and how one reads: the list row, the
/// detail's hero and facts, the filter chips and what search looks through.
/// The record layer owns what create, edit and delete *do*; this says what
/// they are done to.
library;

import 'package:flutter/widgets.dart';

import '../../../core/localization/lume_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../records/data/record_seeds.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_schema.dart';
import '../data/expenses_fixtures.dart';
import 'expenses_strings.dart';

/// `RECORD_SCHEMAS.expenses.fields`.
const LumeRecordSchema kExpensesSchema = LumeRecordSchema(
  collection: 'expenses',
  fields: <LumeRecordField>[
    LumeRecordField(
      name: 'title',
      kind: LumeRecordFieldKind.text,
      required: true,
    ),
    LumeRecordField(
      name: 'amount',
      kind: LumeRecordFieldKind.money,
      required: true,
      rule: LumeFieldRule.positive,
    ),
    LumeRecordField(name: 'cat', kind: LumeRecordFieldKind.select),
    LumeRecordField(
      name: 'date',
      kind: LumeRecordFieldKind.date,
      required: true,
    ),
    LumeRecordField(name: 'method', kind: LumeRecordFieldKind.select),
    LumeRecordField(
      name: 'notes',
      kind: LumeRecordFieldKind.textarea,
      optional: true,
      wide: true,
    ),
    LumeRecordField(
      name: 'receipt',
      kind: LumeRecordFieldKind.attach,
      optional: true,
      wide: true,
    ),
  ],
);

/// One filter chip — `schema.filters(c)`.
@immutable
class LumeRecordFilter {
  const LumeRecordFilter(this.value, this.label, this.test);

  final String value;
  final String label;
  final bool Function(LumeRecord r) test;
}

abstract final class LumeExpenseRecords {
  /// `options.methods`.
  static const List<String> methods = <String>[
    'cash',
    'card',
    'transfer',
    'wallet',
  ];

  /// `defaultFor(f)` — today, the first category, the first method.
  static Map<String, Object?> defaults(DateTime now) => <String, Object?>{
    'cat': LumeExpenseCategory.values.first.name,
    'date': lumeIsoDay(now, 0),
    'method': methods.first,
  };

  /// `txt(t, v)` over `resolve()` — a seeded record's `@key` in the reader's
  /// language; a record the reader wrote, as written.
  static String text(AppLocalizations l, LumeRecord r, String name) {
    final Object? v = r[name];
    if (v == null) return '';
    return r.seeded ? LumeExpensesStrings.seeded(l, v) : '$v';
  }

  /// The record with every seeded string resolved — what an edit form opens
  /// with, so a saved sample holds words rather than keys.
  static LumeRecord resolved(AppLocalizations l, LumeRecord r) => r.seeded
      ? r.copyWith(
          fields: <String, Object?>{
            for (final MapEntry<String, Object?> e in r.fields.entries)
              e.key: e.value is String
                  ? LumeExpensesStrings.seeded(l, e.value)
                  : e.value,
          },
        )
      : r;

  /// `catOf(r)` — an unknown category is the last one, Other.
  static LumeExpenseCategory category(LumeRecord r) =>
      LumeExpenseCategory.byId(r['cat'] as String?) ??
      LumeExpenseCategory.values.last;

  static DateTime? day(Object? v) {
    if (v is! String || v.length != 10) return null;
    return DateTime.tryParse(v);
  }

  /// `relDays(v)` — calendar days from today, `null` for no date.
  static int? relativeDays(Object? v, DateTime now) {
    final DateTime? d = day(v);
    if (d == null) return null;
    return DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  }

  /// `showDate(c, v)` — the locale's short date; the stored text when it is
  /// not a date; a dash for none.
  static String showDate(LumeFormatting f, Object? v) {
    if (v == null || v == '') return '—';
    final DateTime? d = day(v);
    return d == null ? '$v' : f.dateShort(d);
  }

  /// `whenLabel(c, v)` — Today, Tomorrow, Yesterday, in a few days, a few days
  /// ago, and a date beyond a month either way.
  static String when(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    Object? v,
  ) {
    final int? n = relativeDays(v, now);
    if (n == null) return showDate(f, v);
    if (n == 0) return l.commonToday;
    if (n == 1) return l.commonTomorrow;
    if (n == -1) return l.commonYesterday;
    if (n > 1 && n <= 30) return l.commonInDays(n);
    if (n < -1 && n >= -30) return l.recDaysAgo(-n);
    return showDate(f, v);
  }

  /// `moneyRaw(|amount|, null, 0)` — the amount as stored, in the reader's
  /// currency, not converted.
  static String amount(LumeFormatting f, String currency, LumeRecord r) {
    final Object? v = r['amount'];
    final num n = v is num ? v : (num.tryParse('$v') ?? 0);
    return f.money(n.abs(), code: currency);
  }

  /// `initial(title)` — the first character, in capitals where the script
  /// has them.
  static String initial(String title) {
    final String t = title.trim();
    return t.isEmpty ? '?' : t.characters.first.toUpperCase();
  }

  /// `row(r).sub` — when, and the category.
  static String rowSub(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumeRecord r,
  ) => <String>[
    when(l, f, now, r['date']),
    LumeExpensesStrings.category(l, category(r)),
  ].where((String s) => s.isNotEmpty).join(' · ');

  /// `filters(c)` — this month, then the first three categories.
  static List<LumeRecordFilter> filters(AppLocalizations l, DateTime now) =>
      <LumeRecordFilter>[
        LumeRecordFilter(
          'month',
          l.commonThisMonth,
          (LumeRecord r) => day(r['date'])?.month == now.month,
        ),
        for (final LumeExpenseCategory c in LumeExpenseCategory.values.take(3))
          LumeRecordFilter(
            c.name,
            LumeExpensesStrings.category(l, c),
            (LumeRecord r) => r['cat'] == c.name,
          ),
      ];

  /// `matches(schema, r, c, q)` — search looks through what the row shows.
  static bool matches(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    String currency,
    LumeRecord r,
    String query,
  ) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return <String>[
      text(l, r, 'title'),
      rowSub(l, f, now, r),
      amount(f, currency, r),
    ].join(' ').toLowerCase().contains(q);
  }

  /// `head(c, key)` — a line that begins with a noun begins with a capital;
  /// identity in scripts without case.
  static String sentence(String s) => s.isEmpty
      ? s
      : s.characters.first.toUpperCase() + s.characters.skip(1).string;

  /// `createdLabel(c, r)`.
  static String created(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumeRecord r,
  ) {
    final int days = DateTime.utc(
      r.createdAt.year,
      r.createdAt.month,
      r.createdAt.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    if (days == 0) return l.recCreatedToday;
    if (days == -1) return l.recCreatedYesterday;
    return l.recCreated(f.dateShort(r.createdAt));
  }
}
