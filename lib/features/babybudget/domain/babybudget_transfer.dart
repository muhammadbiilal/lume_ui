/// Baby Budget out and in: `lume.babybudget/1` JSON, lossless and
/// importable; CSV, one row per spend for a spreadsheet, export only
/// (`BABY_BUDGET_PROPOSAL.md` §12).
///
/// **Names stay private by default.** A baby budget holds a child's name
/// and what a family spends on them, so an export writes "Budget 1",
/// "Budget 2" and "Category 1", "Category 2" (numbered by id, stable
/// within the file) and leaves every label and note out. The reader's own
/// words go in only on their explicit choice.
///
/// **Import is all or nothing.** The whole document is decoded and
/// checked — schema and version, every record, every id and reference,
/// every currency and bound, spent-or-planned, the shape of the plans,
/// the budget's first day, every invariant, and what the tool already
/// holds — before anything is written; then it is applied in one
/// transaction, or not at all. Every problem is listed with a stable path
/// and a reason; nothing is repaired, dropped or renumbered.
///
/// **CSV cannot come back in.** It cannot carry the ids that tie a spend
/// to its category and a category to its budget, so it is a view, and
/// import reads JSON only.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'babybudget_book.dart';
import 'babybudget_model.dart';

/// The export format's own version.
const int kBabyBudgetExportVersion = 1;

String _instant(DateTime t) => t.toUtc().toIso8601String();

// ---- export ----------------------------------------------------------------

/// The `lume.babybudget/1` document for these records.
///
/// [includeNames] writes budget and category names, the budget's note and
/// each spend's label; otherwise both are labelled and the rest left out.
String babyBudgetExportJson({
  required List<BabyBudget> budgets,
  required List<BabyCategory> categories,
  required List<BabySpend> spends,
  required DateTime exportedAt,
  required String build,
  required bool durable,
  bool includeNames = false,
}) {
  final List<BabyBudget> bs = <BabyBudget>[...budgets]
    ..sort((BabyBudget a, BabyBudget b) => a.id.compareTo(b.id));
  final Map<LumeRecordId, int> number = <LumeRecordId, int>{
    for (int i = 0; i < bs.length; i++) bs[i].id: i + 1,
  };
  final List<BabyCategory> byId = <BabyCategory>[...categories]
    ..sort((BabyCategory a, BabyCategory b) => a.id.compareTo(b.id));
  final Map<LumeRecordId, int> categoryNumber = <LumeRecordId, int>{
    for (int i = 0; i < byId.length; i++) byId[i].id: i + 1,
  };
  final Map<String, Object?> doc = <String, Object?>{
    'schema': kBabyBudgetSchema,
    'exportVersion': kBabyBudgetExportVersion,
    'exportedAt': _instant(exportedAt),
    'source': <String, Object?>{
      'app': 'Lume',
      'build': build,
      'store': durable ? 'durable' : 'memory',
    },
    'namesIncluded': includeNames,
    'budgets': <Map<String, Object?>>[
      for (final BabyBudget b in bs)
        <String, Object?>{
          'id': b.id.value,
          if (includeNames)
            'name': b.name
          else
            'label': 'Budget ${number[b.id]}',
          if (includeNames && b.note != null) 'note': b.note,
          'currency': b.currency.code,
          if (b.monthlyPlan != null) 'planMinor': b.monthlyPlan!.minor,
          'startedOn': b.startedOn.toIso(),
          if (b.archivedOn != null) 'archivedOn': b.archivedOn!.toIso(),
          'createdAt': _instant(b.createdAt),
          'version': b.version,
        },
    ],
    'categories': <Map<String, Object?>>[
      for (final BabyCategory c in <BabyCategory>[
        ...categories,
      ]..sort(_categoryOrder))
        <String, Object?>{
          'id': c.id.value,
          'budgetId': c.budgetId.value,
          if (includeNames)
            'name': c.name
          else
            'label': 'Category ${categoryNumber[c.id]}',
          if (c.monthlyPlan != null) 'planMinor': c.monthlyPlan!.minor,
          'order': c.order,
          'colour': c.colour,
          'createdAt': _instant(c.createdAt),
          'version': c.version,
        },
    ],
    'spends': <Map<String, Object?>>[
      for (final BabySpend s in <BabySpend>[...spends]..sort(_spendOrder))
        <String, Object?>{
          'id': s.id.value,
          'budgetId': s.budgetId.value,
          if (s.categoryId != null) 'categoryId': s.categoryId!.value,
          if (includeNames && s.label != null) 'label': s.label,
          'amountMinor': s.amount.minor,
          'currency': s.currency.code,
          'planned': s.planned,
          if (s.spentOn != null) 'spentOn': s.spentOn!.toIso(),
          if (s.expectedOn != null) 'expectedOn': s.expectedOn!.toIso(),
          'state': s.state.name,
          'createdAt': _instant(s.createdAt),
          'version': s.version,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(doc);
}

int _categoryOrder(BabyCategory a, BabyCategory b) {
  final int c = a.budgetId.compareTo(b.budgetId);
  if (c != 0) return c;
  final int o = a.order.compareTo(b.order);
  return o != 0 ? o : a.id.compareTo(b.id);
}

int _spendOrder(BabySpend a, BabySpend b) {
  final int c = a.budgetId.compareTo(b.budgetId);
  return c != 0 ? c : babySpendOrder(a, b);
}

/// The CSV columns, fixed English machine names whatever the app language.
const List<String> kBabyBudgetCsvColumns = <String>[
  'budget_id',
  'budget',
  'budget_state',
  'currency',
  'category_id',
  'category',
  'spend_id',
  'label',
  'planned',
  'date',
  'amount_minor',
  'amount',
  'state',
];

/// One row per spend, planned and recorded alike: UTF-8 with a byte-order
/// mark, comma separated, RFC 4180 quoting, CRLF. A view for a
/// spreadsheet — it cannot be imported. Budgets and categories are
/// labelled, and labels left out, unless [includeNames].
String babyBudgetExportCsv(BabyBudgetBook book, {bool includeNames = false}) {
  String cell(Object? v) {
    final String s = v?.toString() ?? '';
    return s.contains(RegExp('[",\r\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final List<BabyBudgetView> vs = <BabyBudgetView>[...book.budgets]
    ..sort(
      (BabyBudgetView a, BabyBudgetView b) =>
          a.budget.id.compareTo(b.budget.id),
    );
  final StringBuffer out = StringBuffer('\uFEFF')
    ..write(kBabyBudgetCsvColumns.join(','))
    ..write('\r\n');
  for (int i = 0; i < vs.length; i++) {
    final BabyBudgetView v = vs[i];
    final Map<String, int> categoryNumber = <String, int>{
      for (int c = 0; c < v.categories.length; c++)
        v.categories[c].id.value: c + 1,
    };
    for (final BabySpend s in v.spends) {
      final BabyCategory? c = v.categoryOf(s.categoryId);
      out
        ..write(
          <Object?>[
            v.budget.id.value,
            includeNames ? v.name : 'Budget ${i + 1}',
            v.status.name,
            v.currency.code,
            s.categoryId?.value,
            c == null
                ? null
                : includeNames
                ? c.name
                : 'Category ${categoryNumber[c.id.value]}',
            s.id.value,
            includeNames ? s.label : null,
            s.planned ? 'yes' : 'no',
            s.day?.toIso(),
            s.amount.minor,
            s.amount.toDecimalString(),
            s.state.name,
          ].map(cell).join(','),
        )
        ..write('\r\n');
    }
  }
  return out.toString();
}

// ---- import ----------------------------------------------------------------

/// Only ever used to decode a category whose budget is absent, so the
/// orphan can be reported rather than dropped; the book refuses to count
/// it either way.
final LumeCurrency _anyCurrency = LumeCurrency.of('USD');

/// One problem in an import: where, and why — stable machine words.
@immutable
class BabyBudgetImportIssue {
  const BabyBudgetImportIssue(this.path, this.reason);

  /// `budgets[2].planMinor`, `spends.<id>.categoryId`, `$`.
  final String path;

  /// `json`, `schema`, `version`, `missing`, `type`, `uuid`, `duplicateId`,
  /// `reference`, `budget`, `currency`, `overflow`, `date`, `value`,
  /// `planned`, `spent`, `zero`, `unsupportedVersion`, `conflict`,
  /// `invariant:<rule>`, `damaged:<reason>` …
  final String reason;

  @override
  String toString() => '$path: $reason';

  @override
  bool operator ==(Object other) =>
      other is BabyBudgetImportIssue &&
      other.path == path &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(path, reason);
}

/// What an import would do, or why it cannot.
@immutable
class BabyBudgetImportReport {
  const BabyBudgetImportReport({
    required this.issues,
    this.create = 0,
    this.update = 0,
    this.unchanged = 0,
    this.namesIncluded = false,
    this.records = const <(String, LumeRecord, bool)>[],
  });

  final List<BabyBudgetImportIssue> issues;
  final int create;
  final int update;
  final int unchanged;
  final bool namesIncluded;

  /// The records to write, in order, each with whether it updates one
  /// already held at the same version.
  final List<(String, LumeRecord, bool)> records;

  bool get ok => issues.isEmpty;
}

/// Decode and check [document] against what [store] holds — nothing is
/// written. Apply the report with [babyBudgetImportApply].
BabyBudgetImportReport babyBudgetImportCheck(
  String document,
  LumeRecordRepository store,
) {
  BabyBudgetImportReport only(String path, String reason) =>
      BabyBudgetImportReport(
        issues: <BabyBudgetImportIssue>[BabyBudgetImportIssue(path, reason)],
      );
  final Object? root;
  try {
    root = jsonDecode(document);
  } on FormatException {
    return only(r'$', 'json');
  }
  if (root is! Map<String, Object?>) return only(r'$', 'type');
  if (root['schema'] != kBabyBudgetSchema) return only(r'$.schema', 'schema');
  final Object? version = root['exportVersion'];
  if (version is! int) return only(r'$.exportVersion', 'type');
  if (version != kBabyBudgetExportVersion) {
    return only(
      r'$.exportVersion',
      version > kBabyBudgetExportVersion ? 'unsupportedVersion' : 'version',
    );
  }
  final Map<String, Object?> doc = root;
  final bool names = doc['namesIncluded'] == true;
  final List<BabyBudgetImportIssue> issues = <BabyBudgetImportIssue>[];
  final List<(String, LumeRecord)> records = <(String, LumeRecord)>[];
  final Set<String> ids = <String>{};

  List<Map<String, Object?>> list(String key) {
    final Object? v = doc[key];
    if (v is! List<Object?>) {
      issues.add(BabyBudgetImportIssue('\$.$key', 'missing'));
      return const <Map<String, Object?>>[];
    }
    final List<Map<String, Object?>> out = <Map<String, Object?>>[];
    for (int i = 0; i < v.length; i++) {
      if (v[i] is Map<String, Object?>) {
        out.add(v[i]! as Map<String, Object?>);
      } else {
        issues.add(BabyBudgetImportIssue('$key[$i]', 'type'));
      }
    }
    return out;
  }

  LumeRecord? envelope(
    String path,
    Map<String, Object?> m,
    Map<String, Object?> fields,
  ) {
    final Object? id = m['id'];
    if (id is! String || LumeRecordId.tryParse(id)?.value != id) {
      issues.add(BabyBudgetImportIssue('$path.id', 'uuid'));
      return null;
    }
    if (!ids.add(id)) {
      issues.add(BabyBudgetImportIssue('$path.id', 'duplicateId'));
      return null;
    }
    final Object? at = m['createdAt'];
    final DateTime? created = at is String ? DateTime.tryParse(at) : null;
    if (created == null || !created.isUtc) {
      issues.add(BabyBudgetImportIssue('$path.createdAt', 'instant'));
      return null;
    }
    final Object? v = m['version'];
    if (v is! int || v < 1) {
      issues.add(BabyBudgetImportIssue('$path.version', 'version'));
      return null;
    }
    return LumeRecord(
      id: id,
      fields: <String, Object?>{'schema': kBabyBudgetSchema, ...fields},
      version: v,
      createdAt: created,
      updatedAt: created,
    );
  }

  final List<BabyBudget> budgets = <BabyBudget>[];
  final List<BabyCategory> categories = <BabyCategory>[];
  final List<BabySpend> spends = <BabySpend>[];

  void decode<T>(
    String key,
    String collection,
    Map<String, Object?> Function(Map<String, Object?>) fields,
    T Function(LumeRecord) as,
    List<T> into,
  ) {
    final List<Map<String, Object?>> items = list(key);
    for (int i = 0; i < items.length; i++) {
      final LumeRecord? r = envelope('$key[$i]', items[i], fields(items[i]));
      if (r == null) continue;
      try {
        into.add(as(r));
        records.add((collection, r));
      } on BabyBudgetDefectException catch (e) {
        issues.add(
          BabyBudgetImportIssue(
            '$key[$i].${_path(e.defect.field)}',
            e.defect.reason,
          ),
        );
      }
    }
  }

  decode<BabyBudget>(
    'budgets',
    BabyBudgetCollections.budgets,
    (Map<String, Object?> m) => <String, Object?>{
      'name': names ? m['name'] : (m['name'] ?? m['label']),
      'note': m['note'],
      'currency': m['currency'],
      'planMinor': m['planMinor'],
      'startedOn': m['startedOn'],
      'archivedOn': m['archivedOn'],
    },
    BabyBudget.decode,
    budgets,
  );

  // What the tool already holds. Budgets are read before anything else,
  // here and from the file, because a category's plan is only money in
  // its own budget's currency.
  final Map<String, LumeRecord> held = <String, LumeRecord>{
    for (final String c in BabyBudgetCollections.all)
      for (final LumeRecord r in store.view(c).items) r.id: r,
  };
  final List<BabyBudget> heldBudgets = <BabyBudget>[];
  final List<BabyCategory> heldCategories = <BabyCategory>[];
  final List<BabySpend> heldSpends = <BabySpend>[];
  void hold<T>(String c, T Function(LumeRecord) as, List<T> into) {
    for (final LumeRecord r in store.view(c).items) {
      try {
        into.add(as(r));
      } on BabyBudgetDefectException {
        issues.add(
          BabyBudgetImportIssue('destination.${r.id}', 'damaged:defect'),
        );
      }
    }
  }

  hold(BabyBudgetCollections.budgets, BabyBudget.decode, heldBudgets);
  final Map<String, LumeCurrency> currencies = <String, LumeCurrency>{
    for (final BabyBudget b in heldBudgets) b.id.value: b.currency,
    for (final BabyBudget b in budgets) b.id.value: b.currency,
  };
  BabyCategory asCategory(LumeRecord r) {
    final Object? owner = r['budget'];
    return BabyCategory.decode(
      r,
      currency: (owner is String ? currencies[owner] : null) ?? _anyCurrency,
    );
  }

  decode<BabyCategory>(
    'categories',
    BabyBudgetCollections.categories,
    (Map<String, Object?> m) => <String, Object?>{
      'budget': m['budgetId'],
      'name': names ? m['name'] : (m['name'] ?? m['label']),
      'planMinor': m['planMinor'],
      'order': m['order'],
      'colour': m['colour'],
    },
    asCategory,
    categories,
  );
  decode<BabySpend>(
    'spends',
    BabyBudgetCollections.spends,
    (Map<String, Object?> m) => <String, Object?>{
      'budget': m['budgetId'],
      'category': m['categoryId'],
      'label': names ? m['label'] : null,
      'amountMinor': m['amountMinor'],
      'currency': m['currency'],
      'planned': m['planned'],
      'spentOn': m['spentOn'],
      'expectedOn': m['expectedOn'],
      'state': m['state'],
    },
    BabySpend.decode,
    spends,
  );
  hold(BabyBudgetCollections.categories, asCategory, heldCategories);
  hold(BabyBudgetCollections.spends, BabySpend.decode, heldSpends);

  int create = 0, update = 0, unchanged = 0;
  final List<(String, LumeRecord, bool)> writes =
      <(String, LumeRecord, bool)>[];
  for (final (String c, LumeRecord r) in records) {
    final LumeRecord? there = held[r.id];
    if (there == null) {
      create++;
      writes.add((c, r, false));
    } else if (there.version != r.version) {
      issues.add(BabyBudgetImportIssue('${_key(c)}.${r.id}', 'conflict'));
    } else if (mapEquals(_plain(there.fields), _plain(r.fields))) {
      unchanged++;
    } else {
      update++;
      writes.add((c, r, true));
    }
  }

  // References over what the tool would hold, named before the rules are
  // run on it: a rule has nothing useful to say about a record whose
  // budget or category is not there at all.
  final Map<LumeRecordId, BabyBudget> allBudgets = <LumeRecordId, BabyBudget>{
    for (final BabyBudget b in heldBudgets) b.id: b,
    for (final BabyBudget b in budgets) b.id: b,
  };
  final Map<LumeRecordId, BabyCategory> allCategories =
      <LumeRecordId, BabyCategory>{
        for (final BabyCategory c in heldCategories) c.id: c,
        for (final BabyCategory c in categories) c.id: c,
      };

  void owner(String key, String id, LumeRecordId budget) {
    if (!allBudgets.containsKey(budget)) {
      issues.add(BabyBudgetImportIssue('$key.$id.budgetId', 'reference'));
    }
  }

  for (final BabyCategory c in categories) {
    owner('categories', c.id.value, c.budgetId);
  }
  for (final BabySpend s in spends) {
    owner('spends', s.id.value, s.budgetId);
    final LumeRecordId? id = s.categoryId;
    if (id == null) continue;
    final BabyCategory? c = allCategories[id];
    if (c == null) {
      issues.add(
        BabyBudgetImportIssue('spends.${s.id.value}.categoryId', 'reference'),
      );
    } else if (c.budgetId != s.budgetId) {
      issues.add(
        BabyBudgetImportIssue('spends.${s.id.value}.categoryId', 'budget'),
      );
    }
  }

  if (issues.isEmpty) {
    try {
      // The tool's own reading of the whole thing: §7's rules, run here
      // exactly as they are run before any ordinary write.
      final BabyBudgetBook book = BabyBudgetBook.from(
        budgets: allBudgets.values.toList(),
        categories: allCategories.values.toList(),
        // Keyed by id, so a record held and imported again at the same
        // version counts once, not twice.
        spends: <LumeRecordId, BabySpend>{
          for (final BabySpend s in heldSpends) s.id: s,
          for (final BabySpend s in spends) s.id: s,
        }.values.toList(),
        today: null,
      );
      for (final BabyBudgetDamage d in book.damage) {
        issues.add(
          BabyBudgetImportIssue(
            d.id == null ? 'budgets.${d.budget}' : 'records.${d.id}',
            'damaged:${d.reason}',
          ),
        );
      }
      for (final String broken in book.invariants()) {
        issues.add(
          BabyBudgetImportIssue(r'$', 'invariant:${broken.split(' ').first}'),
        );
      }
      // Every sum the screen would draw fits its bound, or this throws.
      final List<BabyBudgetSummary> sums = book.summaries;
      assert(sums.length == book.currencies.length);
    } on LumeMoneyException catch (e) {
      issues.add(BabyBudgetImportIssue(r'$', e.failure.name));
    }
  }

  return BabyBudgetImportReport(
    issues: issues,
    create: create,
    update: update,
    unchanged: unchanged,
    namesIncluded: names,
    records: writes,
  );
}

/// Write a checked report in one transaction. A report with issues writes
/// nothing.
LumeTxResult<int> babyBudgetImportApply(
  BabyBudgetImportReport report,
  LumeRecordRepository store, {
  String? idempotencyKey,
}) {
  if (!report.ok) {
    return const LumeTxResult<int>.failed(
      LumeTxFailure(LumeTxFailureKind.rejected, detail: 'issues'),
    );
  }
  return store.run<int>(
    (LumeRecordTx tx) {
      for (final (String c, LumeRecord r, bool existing) in report.records) {
        if (existing) {
          tx.update(c, r.id, r.fields, expectVersion: r.version);
        } else {
          tx.insert(c, r);
        }
      }
      return report.records.length;
    },
    idempotencyKey: idempotencyKey,
    fingerprint: idempotencyKey == null
        ? null
        : report.records
              .map(
                ((String, LumeRecord, bool) x) => '${x.$2.id}@${x.$2.version}',
              )
              .join(','),
  );
}

String _key(String collection) => switch (collection) {
  BabyBudgetCollections.budgets => 'budgets',
  BabyBudgetCollections.categories => 'categories',
  _ => 'spends',
};

/// The record's field name as the JSON writes it.
String _path(String field) => switch (field) {
  'budget' => 'budgetId',
  'category' => 'categoryId',
  _ => field,
};

Map<String, Object?> _plain(Map<String, Object?> m) => <String, Object?>{
  for (final MapEntry<String, Object?> e in m.entries)
    if (e.value != null) e.key: e.value,
};
