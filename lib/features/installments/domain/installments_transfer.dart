/// Installments out and in: `lume.installments/1` JSON, lossless and
/// importable; CSV, one row per scheduled instalment for a spreadsheet,
/// export only (`INSTALLMENTS_PROPOSAL.md` §40.13).
///
/// **Names stay private by default.** What a reader bought, and from whom,
/// can say something about their health, family or debts, so an export
/// writes each plan as "Plan 1", "Plan 2" (by id, stable within the file)
/// and leaves merchants and notes out. They are written only on the
/// reader's explicit choice.
///
/// **Import is all or nothing.** The whole document is decoded and checked
/// — schema and version, every record, every id and reference, currencies
/// and bounds, every schedule and payment rule, every invariant, and what
/// the tool already holds — before anything is written; then it is applied
/// in one transaction, or not at all. Every problem is listed with a stable
/// path and reason; nothing is repaired, dropped or renumbered.
///
/// **CSV cannot come back in.** It cannot carry the ids that tie a payment
/// to its instalment and an instalment to its plan, so it is a view, and
/// import reads JSON only.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'installments_book.dart';
import 'installments_model.dart';

/// The export format's own version.
const int kInstallmentsExportVersion = 1;

String _instant(DateTime t) => t.toUtc().toIso8601String();

// ---- export ----------------------------------------------------------------

/// The `lume.installments/1` document for these records.
///
/// [includeNames] writes items, merchants and notes; otherwise plans are
/// labelled and merchants and notes left out.
String installmentsExportJson({
  required List<InstallmentPlan> plans,
  required List<ScheduledInstallment> schedule,
  required List<InstallmentPayment> payments,
  required DateTime exportedAt,
  required String build,
  required bool durable,
  bool includeNames = false,
}) {
  final List<InstallmentPlan> ps = <InstallmentPlan>[...plans]
    ..sort((InstallmentPlan a, InstallmentPlan b) => a.id.compareTo(b.id));
  final Map<LumeRecordId, int> number = <LumeRecordId, int>{
    for (int i = 0; i < ps.length; i++) ps[i].id: i + 1,
  };
  final Map<String, Object?> doc = <String, Object?>{
    'schema': kInstallmentsSchema,
    'exportVersion': kInstallmentsExportVersion,
    'exportedAt': _instant(exportedAt),
    'source': <String, Object?>{
      'app': 'Lume',
      'build': build,
      'store': durable ? 'durable' : 'memory',
    },
    'namesIncluded': includeNames,
    'plans': <Map<String, Object?>>[
      for (final InstallmentPlan p in ps)
        <String, Object?>{
          'id': p.id.value,
          if (includeNames) 'item': p.item else 'label': 'Plan ${number[p.id]}',
          if (includeNames && p.merchant != null) 'merchant': p.merchant,
          if (includeNames && p.note != null) 'note': p.note,
          'currency': p.currency.code,
          'amountMinor': p.amount.minor,
          'count': p.count,
          'frequency': p.frequency.name,
          'firstDue': p.firstDue.toIso(),
          if (p.deposit != null) 'depositMinor': p.deposit!.minor,
          if (p.depositOn != null) 'depositOn': p.depositOn!.toIso(),
          if (p.cashPrice != null) 'cashPriceMinor': p.cashPrice!.minor,
          'state': p.state.name,
          'createdAt': _instant(p.createdAt),
          'version': p.version,
        },
    ],
    'schedule': <Map<String, Object?>>[
      for (final ScheduledInstallment r in <ScheduledInstallment>[
        ...schedule,
      ]..sort(_rowOrder))
        <String, Object?>{
          'id': r.id.value,
          'planId': r.planId.value,
          'seq': r.seq,
          'due': r.due.toIso(),
          'amountMinor': r.amount.minor,
          'currency': r.amount.currency.code,
          'createdAt': _instant(r.createdAt),
          'version': r.version,
        },
    ],
    'payments': <Map<String, Object?>>[
      for (final InstallmentPayment p
          in <InstallmentPayment>[...payments]..sort(
            (InstallmentPayment a, InstallmentPayment b) =>
                a.id.compareTo(b.id),
          ))
        <String, Object?>{
          'id': p.id.value,
          'planId': p.planId.value,
          'installmentId': p.installmentId.value,
          'amountMinor': p.amount.minor,
          'currency': p.amount.currency.code,
          'paidOn': p.paidOn.toIso(),
          'state': p.state.name,
          'createdAt': _instant(p.createdAt),
          'version': p.version,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(doc);
}

int _rowOrder(ScheduledInstallment a, ScheduledInstallment b) {
  final int p = a.planId.compareTo(b.planId);
  return p != 0 ? p : a.seq.compareTo(b.seq);
}

/// The CSV columns, fixed English machine names whatever the app language.
const List<String> kInstallmentsCsvColumns = <String>[
  'plan_id',
  'plan',
  'plan_state',
  'seq',
  'count',
  'due',
  'amount_minor',
  'amount',
  'currency',
  'paid',
  'paid_on',
  'payment_id',
];

/// One row per scheduled instalment: UTF-8 with a byte-order mark, comma
/// separated, RFC 4180 quoting, CRLF. A view for a spreadsheet — it cannot
/// be imported. Plans are labelled unless [includeNames].
String installmentsExportCsv(
  InstallmentsBook book, {
  bool includeNames = false,
}) {
  String cell(Object? v) {
    final String s = v?.toString() ?? '';
    return s.contains(RegExp('[",\r\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final List<InstallmentPlanView> ps = <InstallmentPlanView>[...book.plans]
    ..sort(
      (InstallmentPlanView a, InstallmentPlanView b) =>
          a.plan.id.compareTo(b.plan.id),
    );
  final StringBuffer out = StringBuffer('\uFEFF')
    ..write(kInstallmentsCsvColumns.join(','))
    ..write('\r\n');
  for (int i = 0; i < ps.length; i++) {
    final InstallmentPlanView v = ps[i];
    for (final InstallmentRow r in v.rows) {
      out
        ..write(
          <Object?>[
            v.plan.id.value,
            includeNames ? v.plan.item : 'Plan ${i + 1}',
            v.plan.state.name,
            r.row.seq,
            v.plan.count,
            r.row.due.toIso(),
            r.row.amount.minor,
            r.row.amount.toDecimalString(),
            r.row.amount.currency.code,
            r.paid ? 'yes' : 'no',
            r.payment?.paidOn.toIso(),
            r.payment?.id.value,
          ].map(cell).join(','),
        )
        ..write('\r\n');
    }
  }
  return out.toString();
}

// ---- import ----------------------------------------------------------------

/// One problem in an import: where, and why — stable machine words.
@immutable
class InstallmentsImportIssue {
  const InstallmentsImportIssue(this.path, this.reason);

  /// `plans[2].amountMinor`, `payments.<id>.installmentId`, `$`.
  final String path;

  /// `json`, `schema`, `version`, `missing`, `type`, `uuid`, `duplicateId`,
  /// `reference`, `currency`, `overflow`, `date`, `value`, `unsupported`,
  /// `conflict`, `invariant:<rule>`, `damaged:<reason>` …
  final String reason;

  @override
  String toString() => '$path: $reason';

  @override
  bool operator ==(Object other) =>
      other is InstallmentsImportIssue &&
      other.path == path &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(path, reason);
}

/// What an import would do, or why it cannot.
@immutable
class InstallmentsImportReport {
  const InstallmentsImportReport({
    required this.issues,
    this.create = 0,
    this.update = 0,
    this.unchanged = 0,
    this.namesIncluded = false,
    this.records = const <(String, LumeRecord, bool)>[],
  });

  final List<InstallmentsImportIssue> issues;
  final int create;
  final int update;
  final int unchanged;
  final bool namesIncluded;

  /// The records to write, in order — plans, schedule, payments — each with
  /// whether it updates one already held at the same version.
  final List<(String, LumeRecord, bool)> records;

  bool get ok => issues.isEmpty;
}

/// Decode and check [document] against what [store] holds — nothing is
/// written. Apply the report with [installmentsImportApply].
InstallmentsImportReport installmentsImportCheck(
  String document,
  LumeRecordRepository store,
) {
  InstallmentsImportReport only(String path, String reason) =>
      InstallmentsImportReport(
        issues: <InstallmentsImportIssue>[
          InstallmentsImportIssue(path, reason),
        ],
      );
  final Object? root;
  try {
    root = jsonDecode(document);
  } on FormatException {
    return only(r'$', 'json');
  }
  if (root is! Map<String, Object?>) return only(r'$', 'type');
  if (root['schema'] != kInstallmentsSchema) return only(r'$.schema', 'schema');
  final Object? version = root['exportVersion'];
  if (version is! int) return only(r'$.exportVersion', 'type');
  if (version != kInstallmentsExportVersion) {
    return only(
      r'$.exportVersion',
      version > kInstallmentsExportVersion ? 'unsupportedVersion' : 'version',
    );
  }
  final Map<String, Object?> doc = root;
  final bool names = doc['namesIncluded'] == true;
  final List<InstallmentsImportIssue> issues = <InstallmentsImportIssue>[];
  final List<(String, LumeRecord)> records = <(String, LumeRecord)>[];
  final Set<String> ids = <String>{};

  List<Map<String, Object?>> list(String key) {
    final Object? v = doc[key];
    if (v is! List<Object?>) {
      issues.add(InstallmentsImportIssue('\$.$key', 'missing'));
      return const <Map<String, Object?>>[];
    }
    final List<Map<String, Object?>> out = <Map<String, Object?>>[];
    for (int i = 0; i < v.length; i++) {
      if (v[i] is Map<String, Object?>) {
        out.add(v[i]! as Map<String, Object?>);
      } else {
        issues.add(InstallmentsImportIssue('$key[$i]', 'type'));
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
      issues.add(InstallmentsImportIssue('$path.id', 'uuid'));
      return null;
    }
    if (!ids.add(id)) {
      issues.add(InstallmentsImportIssue('$path.id', 'duplicateId'));
      return null;
    }
    final Object? at = m['createdAt'];
    final DateTime? created = at is String ? DateTime.tryParse(at) : null;
    if (created == null || !created.isUtc) {
      issues.add(InstallmentsImportIssue('$path.createdAt', 'instant'));
      return null;
    }
    final Object? v = m['version'];
    if (v is! int || v < 1) {
      issues.add(InstallmentsImportIssue('$path.version', 'version'));
      return null;
    }
    return LumeRecord(
      id: id,
      fields: <String, Object?>{'schema': kInstallmentsSchema, ...fields},
      version: v,
      createdAt: created,
      updatedAt: created,
    );
  }

  final List<InstallmentPlan> plans = <InstallmentPlan>[];
  final List<ScheduledInstallment> schedule = <ScheduledInstallment>[];
  final List<InstallmentPayment> payments = <InstallmentPayment>[];

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
      } on InstallmentsDefectException catch (e) {
        issues.add(
          InstallmentsImportIssue(
            '$key[$i].${_path(e.defect.field)}',
            e.defect.reason,
          ),
        );
      }
    }
  }

  decode<InstallmentPlan>(
    'plans',
    InstallmentsCollections.plans,
    (Map<String, Object?> m) => <String, Object?>{
      'item': names ? m['item'] : (m['item'] ?? m['label']),
      'merchant': m['merchant'],
      'note': m['note'],
      'currency': m['currency'],
      'amountMinor': m['amountMinor'],
      'count': m['count'],
      'frequency': m['frequency'],
      'firstDue': m['firstDue'],
      'depositMinor': m['depositMinor'],
      'depositOn': m['depositOn'],
      'cashPriceMinor': m['cashPriceMinor'],
      'state': m['state'],
    },
    InstallmentPlan.decode,
    plans,
  );
  decode<ScheduledInstallment>(
    'schedule',
    InstallmentsCollections.schedule,
    (Map<String, Object?> m) => <String, Object?>{
      'plan': m['planId'],
      'seq': m['seq'],
      'due': m['due'],
      'amountMinor': m['amountMinor'],
      'currency': m['currency'],
    },
    ScheduledInstallment.decode,
    schedule,
  );
  decode<InstallmentPayment>(
    'payments',
    InstallmentsCollections.payments,
    (Map<String, Object?> m) => <String, Object?>{
      'plan': m['planId'],
      'installment': m['installmentId'],
      'amountMinor': m['amountMinor'],
      'currency': m['currency'],
      'paidOn': m['paidOn'],
      'state': m['state'],
    },
    InstallmentPayment.decode,
    payments,
  );

  // What the tool already holds.
  final Map<String, LumeRecord> held = <String, LumeRecord>{
    for (final String c in InstallmentsCollections.all)
      for (final LumeRecord r in store.view(c).items) r.id: r,
  };
  final List<InstallmentPlan> heldPlans = <InstallmentPlan>[];
  final List<ScheduledInstallment> heldRows = <ScheduledInstallment>[];
  final List<InstallmentPayment> heldPays = <InstallmentPayment>[];
  void hold<T>(String c, T Function(LumeRecord) decode, List<T> into) {
    for (final LumeRecord r in store.view(c).items) {
      try {
        into.add(decode(r));
      } on InstallmentsDefectException {
        issues.add(
          InstallmentsImportIssue('destination.${r.id}', 'damaged:defect'),
        );
      }
    }
  }

  hold(InstallmentsCollections.plans, InstallmentPlan.decode, heldPlans);
  hold(InstallmentsCollections.schedule, ScheduledInstallment.decode, heldRows);
  hold(InstallmentsCollections.payments, InstallmentPayment.decode, heldPays);

  int create = 0, update = 0, unchanged = 0;
  final List<(String, LumeRecord, bool)> writes =
      <(String, LumeRecord, bool)>[];
  for (final (String c, LumeRecord r) in records) {
    final LumeRecord? there = held[r.id];
    if (there == null) {
      create++;
      writes.add((c, r, false));
    } else if (there.version != r.version) {
      issues.add(InstallmentsImportIssue('${_key(c)}.${r.id}', 'conflict'));
    } else if (mapEquals(_plain(there.fields), _plain(r.fields))) {
      unchanged++;
    } else {
      update++;
      writes.add((c, r, true));
    }
  }

  // References and rules over what the tool would hold.
  final Map<LumeRecordId, InstallmentPlan> allPlans =
      <LumeRecordId, InstallmentPlan>{
        for (final InstallmentPlan p in heldPlans) p.id: p,
        for (final InstallmentPlan p in plans) p.id: p,
      };
  final Map<LumeRecordId, ScheduledInstallment> allRows =
      <LumeRecordId, ScheduledInstallment>{
        for (final ScheduledInstallment r in heldRows) r.id: r,
        for (final ScheduledInstallment r in schedule) r.id: r,
      };
  final Map<LumeRecordId, InstallmentPayment> allPays =
      <LumeRecordId, InstallmentPayment>{
        for (final InstallmentPayment p in heldPays) p.id: p,
        for (final InstallmentPayment p in payments) p.id: p,
      };
  for (final ScheduledInstallment r in schedule) {
    if (!allPlans.containsKey(r.planId)) {
      issues.add(
        InstallmentsImportIssue('schedule.${r.id}.planId', 'reference'),
      );
    }
  }
  for (final InstallmentPayment p in payments) {
    if (!allPlans.containsKey(p.planId)) {
      issues.add(
        InstallmentsImportIssue('payments.${p.id}.planId', 'reference'),
      );
    }
    final ScheduledInstallment? row = allRows[p.installmentId];
    if (row == null) {
      issues.add(
        InstallmentsImportIssue('payments.${p.id}.installmentId', 'reference'),
      );
    } else if (row.planId != p.planId) {
      issues.add(InstallmentsImportIssue('payments.${p.id}.planId', 'plan'));
    }
  }
  if (issues.isEmpty) {
    try {
      final InstallmentsBook book = InstallmentsBook.from(
        plans: allPlans.values.toList(),
        schedule: allRows.values.toList(),
        payments: allPays.values.toList(),
        today: null,
      );
      for (final InstallmentsDamage d in book.damage) {
        issues.add(
          InstallmentsImportIssue(
            d.id == null ? 'plans.${d.plan}' : 'records.${d.id}',
            'damaged:${d.reason}',
          ),
        );
      }
      for (final String broken in book.invariants()) {
        issues.add(
          InstallmentsImportIssue(r'$', 'invariant:${broken.split(' ').first}'),
        );
      }
      // Every sum the screen would draw fits its bound, or this throws.
      final List<InstallmentsCurrencySummary> sums = book.summaries;
      assert(sums.length == book.currencies.length);
    } on LumeMoneyException catch (e) {
      issues.add(InstallmentsImportIssue(r'$', e.failure.name));
    }
  }

  return InstallmentsImportReport(
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
LumeTxResult<int> installmentsImportApply(
  InstallmentsImportReport report,
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
  InstallmentsCollections.plans => 'plans',
  InstallmentsCollections.schedule => 'schedule',
  _ => 'payments',
};

String _path(String field) => switch (field) {
  'plan' => 'planId',
  'installment' => 'installmentId',
  _ => field,
};

Map<String, Object?> _plain(Map<String, Object?> m) => <String, Object?>{
  for (final MapEntry<String, Object?> e in m.entries)
    if (e.value != null) e.key: e.value,
};
