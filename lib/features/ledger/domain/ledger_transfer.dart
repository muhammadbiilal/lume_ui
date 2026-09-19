/// Ledger out and in: `lume.ledger/1` JSON, lossless and importable; CSV, a
/// one-row-per-entry view for a spreadsheet, export only
/// (`LEDGER_PROPOSAL.md` §12).
///
/// **Names stay private by default.** An export writes each person as
/// "Person 1", "Person 2" (by id, stable within the file) and leaves notes
/// out, because notes name people too. Names and notes are written only on
/// the reader's explicit choice.
///
/// **Import is all or nothing.** The whole document is decoded and checked
/// — schema and version, every record, every id and reference, currencies
/// and bounds, versions, every allocation rule, every invariant, and what
/// the Ledger already holds — before anything is written; then it is
/// applied in one transaction, or not at all. Every problem is listed with
/// a stable path and reason; nothing is repaired, dropped or renumbered.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'ledger_book.dart';
import 'ledger_model.dart';

/// The export format's own version.
const int kLedgerExportVersion = 1;

// ---- export ----------------------------------------------------------------

/// The `lume.ledger/1` document for [snapshot]'s records.
///
/// [includePrivate] writes names and notes; otherwise people are labelled
/// and notes are left out.
String ledgerExportJson({
  required List<LedgerParty> parties,
  required List<LedgerEntry> entries,
  required List<LedgerAllocation> allocations,
  required DateTime exportedAt,
  required String build,
  required bool durable,
  bool includePrivate = false,
}) {
  final List<LedgerParty> ps = <LedgerParty>[...parties]
    ..sort((LedgerParty a, LedgerParty b) => a.id.compareTo(b.id));
  final Map<LumeRecordId, int> number = <LumeRecordId, int>{
    for (int i = 0; i < ps.length; i++) ps[i].id: i + 1,
  };
  String instant(DateTime t) => t.toUtc().toIso8601String();
  final Map<String, Object?> doc = <String, Object?>{
    'schema': kLedgerSchema,
    'exportVersion': kLedgerExportVersion,
    'exportedAt': instant(exportedAt),
    'source': <String, Object?>{
      'app': 'Lume',
      'build': build,
      'store': durable ? 'durable' : 'memory',
    },
    'namesIncluded': includePrivate,
    'parties': <Map<String, Object?>>[
      for (final LedgerParty p in ps)
        <String, Object?>{
          'id': p.id.value,
          if (includePrivate)
            'name': p.name
          else
            'label': 'Person ${number[p.id]}',
          if (includePrivate && p.note != null) 'note': p.note,
          'state': p.state.name,
          'createdAt': instant(p.createdAt),
          'version': p.version,
        },
    ],
    'entries': <Map<String, Object?>>[
      for (final LedgerEntry e in <LedgerEntry>[
        ...entries,
      ]..sort((LedgerEntry a, LedgerEntry b) => a.id.compareTo(b.id)))
        <String, Object?>{
          'id': e.id.value,
          'partyId': e.partyId.value,
          'kind': e.kind.name,
          'amountMinor': e.amount.minor,
          'currency': e.currency.code,
          'on': e.on.toIso(),
          if (e.due != null) 'due': e.due!.toIso(),
          if (includePrivate && e.note != null) 'note': e.note,
          'state': e.state.name,
          'excessConfirmed': e.excessConfirmed,
          'createdAt': instant(e.createdAt),
          'version': e.version,
        },
    ],
    'allocations': <Map<String, Object?>>[
      for (final LedgerAllocation a in <LedgerAllocation>[
        ...allocations,
      ]..sort((LedgerAllocation a, LedgerAllocation b) => a.id.compareTo(b.id)))
        <String, Object?>{
          'id': a.id.value,
          'partyId': a.partyId.value,
          'repaymentId': a.repaymentId.value,
          'principalId': a.principalId.value,
          'amountMinor': a.amount.minor,
          'currency': a.amount.currency.code,
          'origin': a.origin.name,
          'scopeRevision': a.scopeRevision,
          'createdAt': instant(a.createdAt),
          'version': a.version,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(doc);
}

/// The CSV columns, fixed English machine names whatever the app language.
const List<String> kLedgerCsvColumns = <String>[
  'entry_id',
  'party_id',
  'party',
  'kind',
  'amount_minor',
  'amount',
  'currency',
  'date',
  'due',
  'state',
  'remaining_minor',
  'credit_minor',
  'created_utc',
  'version',
];

/// One row per entry: UTF-8 with a byte-order mark, comma separated,
/// RFC 4180 quoting, CRLF. Allocations cannot be written pairwise, so
/// `remaining_minor` (principals) and `credit_minor` (repayments) summarise
/// them; the JSON export is the one that imports.
String ledgerExportCsv(LedgerBook book, {bool includePrivate = false}) {
  final List<LedgerParty> ps = <LedgerParty>[...book.parties]
    ..sort((LedgerParty a, LedgerParty b) => a.id.compareTo(b.id));
  final Map<LumeRecordId, String> who = <LumeRecordId, String>{
    for (int i = 0; i < ps.length; i++)
      ps[i].id: includePrivate ? ps[i].name : 'Person ${i + 1}',
  };
  String cell(Object? v) {
    final String s = v == null ? '' : '$v';
    return s.contains(RegExp('[",\r\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final StringBuffer out = StringBuffer('\ufeff')
    ..write(kLedgerCsvColumns.join(','))
    ..write('\r\n');
  final List<LedgerEntry> entries = <LedgerEntry>[...book.entries]
    ..sort((LedgerEntry a, LedgerEntry b) {
      final int on = a.on.compareTo(b.on);
      return on != 0 ? on : a.compareCreation(b);
    });
  for (final LedgerEntry e in entries) {
    final LumeMoney? remaining = e.kind.isPrincipal
        ? book.remaining[e.id]
        : null;
    final LumeMoney? credit = e.kind.isRepayment ? book.credit[e.id] : null;
    out
      ..write(
        <Object?>[
          e.id.value,
          e.partyId.value,
          who[e.partyId] ?? '',
          e.kind.name,
          e.amount.minor,
          e.amount.toDecimalString(),
          e.currency.code,
          e.on.toIso(),
          e.due?.toIso(),
          e.state.name,
          remaining?.minor,
          credit?.minor,
          e.createdAt.toUtc().toIso8601String(),
          e.version,
        ].map(cell).join(','),
      )
      ..write('\r\n');
  }
  return out.toString();
}

// ---- import ----------------------------------------------------------------

/// One problem in an import: where, and why — stable machine words.
@immutable
class LedgerImportIssue {
  const LedgerImportIssue(this.path, this.reason);

  /// `parties[2].name`, `entries[0].amountMinor`, `$` for the document.
  final String path;

  /// `json`, `schema`, `version`, `missing`, `type`, `uuid`, `duplicateId`,
  /// `reference`, `currency`, `overflow`, `precision`, `date`, `value`,
  /// `zero`, `conflict`, `invariant`, `damaged:<reason>` …
  final String reason;

  @override
  String toString() => '$path: $reason';

  @override
  bool operator ==(Object other) =>
      other is LedgerImportIssue &&
      other.path == path &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(path, reason);
}

/// What an import would do, or why it cannot.
@immutable
class LedgerImportReport {
  const LedgerImportReport({
    required this.issues,
    this.create = 0,
    this.update = 0,
    this.unchanged = 0,
    this.namesIncluded = false,
    this.records = const <(String, LumeRecord, bool)>[],
  });

  /// Empty when the document can be applied.
  final List<LedgerImportIssue> issues;
  final int create;
  final int update;
  final int unchanged;

  /// Whether the file carries names (else "Person 1" labels come in).
  final bool namesIncluded;

  /// The records to write, in order — people, entries, allocations — each
  /// with whether it updates one the Ledger holds at the same version.
  final List<(String, LumeRecord, bool)> records;

  bool get ok => issues.isEmpty;
}

/// Decode and check [document] against what [store] holds — nothing is
/// written. Apply the report with [ledgerImportApply].
LedgerImportReport ledgerImportCheck(
  String document,
  LumeRecordRepository store,
) {
  final List<LedgerImportIssue> issues = <LedgerImportIssue>[];
  final Object? root;
  try {
    root = jsonDecode(document);
  } on FormatException {
    return const LedgerImportReport(
      issues: <LedgerImportIssue>[LedgerImportIssue(r'$', 'json')],
    );
  }
  if (root is! Map<String, Object?>) {
    return const LedgerImportReport(
      issues: <LedgerImportIssue>[LedgerImportIssue(r'$', 'type')],
    );
  }
  if (root['schema'] != kLedgerSchema) {
    return const LedgerImportReport(
      issues: <LedgerImportIssue>[LedgerImportIssue(r'$.schema', 'schema')],
    );
  }
  final Object? version = root['exportVersion'];
  if (version is! int) {
    return const LedgerImportReport(
      issues: <LedgerImportIssue>[
        LedgerImportIssue(r'$.exportVersion', 'type'),
      ],
    );
  }
  if (version != kLedgerExportVersion) {
    return LedgerImportReport(
      issues: <LedgerImportIssue>[
        LedgerImportIssue(
          r'$.exportVersion',
          version > kLedgerExportVersion ? 'unsupportedVersion' : 'version',
        ),
      ],
    );
  }
  final Map<String, Object?> doc = root;
  final bool names = doc['namesIncluded'] == true;

  // Every record, as the store would hold it.
  final List<(String, LumeRecord)> records = <(String, LumeRecord)>[];
  final Set<String> ids = <String>{};
  List<Map<String, Object?>> list(String key) {
    final Object? v = doc[key];
    if (v is! List<Object?>) {
      issues.add(LedgerImportIssue('\$.$key', 'missing'));
      return const <Map<String, Object?>>[];
    }
    return <Map<String, Object?>>[
      for (int i = 0; i < v.length; i++)
        if (v[i] is Map<String, Object?>)
          v[i]! as Map<String, Object?>
        else
          ...() {
            issues.add(LedgerImportIssue('$key[$i]', 'type'));
            return <Map<String, Object?>>[];
          }(),
    ];
  }

  LumeRecord? envelope(
    String key,
    int i,
    Map<String, Object?> m,
    Map<String, Object?> fields,
  ) {
    final String path = '$key[$i]';
    final Object? id = m['id'];
    if (id is! String || LumeRecordId.tryParse(id)?.value != id) {
      issues.add(LedgerImportIssue('$path.id', 'uuid'));
      return null;
    }
    if (!ids.add(id)) {
      issues.add(LedgerImportIssue('$path.id', 'duplicateId'));
      return null;
    }
    final DateTime? created = m['createdAt'] is String
        ? DateTime.tryParse(m['createdAt']! as String)
        : null;
    if (created == null || !created.isUtc) {
      issues.add(LedgerImportIssue('$path.createdAt', 'instant'));
      return null;
    }
    final Object? v = m['version'];
    if (v is! int || v < 1) {
      issues.add(LedgerImportIssue('$path.version', 'version'));
      return null;
    }
    return LumeRecord(
      id: id,
      fields: <String, Object?>{'schema': kLedgerSchema, ...fields},
      version: v,
      createdAt: created,
      updatedAt: created,
    );
  }

  final List<LedgerParty> parties = <LedgerParty>[];
  final List<LedgerEntry> entries = <LedgerEntry>[];
  final List<LedgerAllocation> allocations = <LedgerAllocation>[];

  void decode<T>(
    String key,
    String collection,
    Map<String, Object?> Function(Map<String, Object?>) fields,
    T Function(LumeRecord) as,
    List<T> into,
  ) {
    final List<Map<String, Object?>> items = list(key);
    for (int i = 0; i < items.length; i++) {
      final LumeRecord? r = envelope(key, i, items[i], fields(items[i]));
      if (r == null) continue;
      try {
        into.add(as(r));
        records.add((collection, r));
      } on LedgerDefectException catch (e) {
        issues.add(
          LedgerImportIssue(
            '$key[$i].${_path(e.defect.field)}',
            e.defect.reason,
          ),
        );
      }
    }
  }

  decode<LedgerParty>(
    'parties',
    LedgerCollections.parties,
    (Map<String, Object?> m) => <String, Object?>{
      'name': names ? m['name'] : (m['name'] ?? m['label']),
      'note': m['note'],
      'state': m['state'],
    },
    LedgerParty.decode,
    parties,
  );
  decode<LedgerEntry>(
    'entries',
    LedgerCollections.entries,
    (Map<String, Object?> m) => <String, Object?>{
      'party': m['partyId'],
      'kind': m['kind'],
      'amountMinor': m['amountMinor'],
      'currency': m['currency'],
      'on': m['on'],
      'due': m['due'],
      'note': m['note'],
      'state': m['state'],
      'excessConfirmed': m['excessConfirmed'],
    },
    LedgerEntry.decode,
    entries,
  );
  decode<LedgerAllocation>(
    'allocations',
    LedgerCollections.allocations,
    (Map<String, Object?> m) => <String, Object?>{
      'party': m['partyId'],
      'repayment': m['repaymentId'],
      'principal': m['principalId'],
      'amountMinor': m['amountMinor'],
      'currency': m['currency'],
      'origin': m['origin'],
      'scopeRevision': m['scopeRevision'],
    },
    LedgerAllocation.decode,
    allocations,
  );

  // What the Ledger already holds.
  final Map<String, LumeRecord> held = <String, LumeRecord>{
    for (final String c in LedgerCollections.all)
      for (final LumeRecord r in store.view(c).items) r.id: r,
  };
  final List<LedgerParty> heldParties = <LedgerParty>[];
  final List<LedgerEntry> heldEntries = <LedgerEntry>[];
  final List<LedgerAllocation> heldAllocations = <LedgerAllocation>[];
  for (final LumeRecord r in store.view(LedgerCollections.parties).items) {
    try {
      heldParties.add(LedgerParty.decode(r));
    } on LedgerDefectException {
      issues.add(LedgerImportIssue('destination.${r.id}', 'damaged:defect'));
    }
  }
  for (final LumeRecord r in store.view(LedgerCollections.entries).items) {
    try {
      heldEntries.add(LedgerEntry.decode(r));
    } on LedgerDefectException {
      issues.add(LedgerImportIssue('destination.${r.id}', 'damaged:defect'));
    }
  }
  for (final LumeRecord r in store.view(LedgerCollections.allocations).items) {
    try {
      heldAllocations.add(LedgerAllocation.decode(r));
    } on LedgerDefectException {
      issues.add(LedgerImportIssue('destination.${r.id}', 'damaged:defect'));
    }
  }

  // Conflicts with the destination: the same id at another version, or at
  // the same version with other content.
  int create = 0, update = 0, unchanged = 0;
  final List<(String, LumeRecord, bool)> writes =
      <(String, LumeRecord, bool)>[];
  for (int i = 0; i < records.length; i++) {
    final (String c, LumeRecord r) = records[i];
    final LumeRecord? there = held[r.id];
    if (there == null) {
      create++;
      writes.add((c, r, false));
    } else if (there.version != r.version) {
      // The file was made from another version of this record.
      issues.add(LedgerImportIssue('${_key(c)}.${r.id}', 'conflict'));
    } else if (mapEquals(_plain(there.fields), _plain(r.fields))) {
      unchanged++;
    } else {
      update++;
      writes.add((c, r, true));
    }
  }

  // References, rules and invariants over what the Ledger would hold.
  final Map<LumeRecordId, LedgerParty> allParties = <LumeRecordId, LedgerParty>{
    for (final LedgerParty p in heldParties) p.id: p,
    for (final LedgerParty p in parties) p.id: p,
  };
  final Map<LumeRecordId, LedgerEntry> allEntries = <LumeRecordId, LedgerEntry>{
    for (final LedgerEntry e in heldEntries) e.id: e,
    for (final LedgerEntry e in entries) e.id: e,
  };
  final Map<LumeRecordId, LedgerAllocation> allAllocations =
      <LumeRecordId, LedgerAllocation>{
        for (final LedgerAllocation a in heldAllocations) a.id: a,
        for (final LedgerAllocation a in allocations) a.id: a,
      };
  for (int i = 0; i < entries.length; i++) {
    if (!allParties.containsKey(entries[i].partyId)) {
      issues.add(
        LedgerImportIssue('entries.${entries[i].id}.partyId', 'reference'),
      );
    }
  }
  for (final LedgerAllocation a in allocations) {
    if (!allParties.containsKey(a.partyId)) {
      issues.add(LedgerImportIssue('allocations.${a.id}.partyId', 'reference'));
    }
    final LedgerEntry? rep = allEntries[a.repaymentId];
    final LedgerEntry? prin = allEntries[a.principalId];
    if (rep == null) {
      issues.add(
        LedgerImportIssue('allocations.${a.id}.repaymentId', 'reference'),
      );
    }
    if (prin == null) {
      issues.add(
        LedgerImportIssue('allocations.${a.id}.principalId', 'reference'),
      );
    }
    if (rep != null && prin != null) {
      if (rep.currency != a.amount.currency ||
          prin.currency != a.amount.currency) {
        issues.add(
          LedgerImportIssue('allocations.${a.id}.currency', 'currency'),
        );
      } else if (rep.kind.counterpart != prin.kind || !rep.kind.isRepayment) {
        issues.add(LedgerImportIssue('allocations.${a.id}', 'direction'));
      } else if (rep.partyId != a.partyId || prin.partyId != a.partyId) {
        issues.add(LedgerImportIssue('allocations.${a.id}.partyId', 'party'));
      }
    }
  }
  if (issues.isEmpty) {
    try {
      final LedgerBook book = LedgerBook.from(
        parties: allParties.values.toList(),
        entries: allEntries.values.toList(),
        allocations: allAllocations.values.toList(),
        today: null,
      );
      for (final LedgerDamage d in book.damage) {
        issues.add(
          LedgerImportIssue(
            d.id == null ? 'parties.${d.party}' : 'records.${d.id}',
            'damaged:${d.reason}',
          ),
        );
      }
      for (final String broken in book.invariants()) {
        issues.add(
          LedgerImportIssue(r'$', 'invariant:${broken.split(' ').first}'),
        );
      }
    } on LumeMoneyException catch (e) {
      issues.add(LedgerImportIssue(r'$', e.failure.name));
    }
  }

  return LedgerImportReport(
    issues: issues,
    create: create,
    update: update,
    unchanged: unchanged,
    namesIncluded: names,
    records: writes,
  );
}

/// Write a checked report in one transaction. A report with issues writes
/// nothing. Returns the transaction's result.
LumeTxResult<int> ledgerImportApply(
  LedgerImportReport report,
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
  LedgerCollections.parties => 'parties',
  LedgerCollections.entries => 'entries',
  _ => 'allocations',
};

String _path(String field) => switch (field) {
  'party' => 'partyId',
  'repayment' => 'repaymentId',
  'principal' => 'principalId',
  'name' => 'name',
  _ => field,
};

/// Fields with no value dropped, so an absent key and a null one compare
/// equal.
Map<String, Object?> _plain(Map<String, Object?> m) => <String, Object?>{
  for (final MapEntry<String, Object?> e in m.entries)
    if (e.value != null) e.key: e.value,
};

/// A currency code a reader may pick for a new entry.
bool ledgerOffers(String code) => LumeCurrency.tryOf(code)?.active ?? false;

/// A date field's text as a calendar date, or null.
LumeDate? ledgerDate(String? text) =>
    text == null ? null : LumeDate.tryParse(text);
