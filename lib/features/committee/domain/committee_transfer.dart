/// Committee out and in: `lume.committee/1` JSON, lossless and importable;
/// CSV, one row per position per cycle for a spreadsheet, export only
/// (`COMMITTEE_PROPOSAL.md` §12).
///
/// **Names stay private by default.** A committee is a list of people and
/// whether each of them paid. An export writes "Committee 1" and
/// "Member 1", "Member 2" (numbered by id, stable within the file), keeps
/// the reader as "You", and leaves notes out. Names go in only on the
/// reader's explicit choice.
///
/// **Import is all or nothing.** The whole document is decoded and checked
/// — schema and version, every record, every id and reference, every
/// currency and bound, the payout order, the recipient of each cycle, the
/// role and the reader, every invariant, and what the tool already holds —
/// before anything is written; then it is applied in one transaction, or
/// not at all. Every problem is listed with a stable path and a reason;
/// nothing is repaired, dropped or renumbered.
///
/// **CSV cannot come back in.** It cannot carry the ids that tie a
/// contribution to a position and a cycle, so it is a view, and import
/// reads JSON only.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import '../../records/domain/record_model.dart';
import '../../records/domain/record_repository.dart';
import '../../records/domain/record_transaction.dart';
import 'committee_book.dart';
import 'committee_model.dart';

/// The export format's own version.
const int kCommitteeExportVersion = 1;

String _instant(DateTime t) => t.toUtc().toIso8601String();

// ---- export ----------------------------------------------------------------

/// The `lume.committee/1` document for these records.
///
/// [includeNames] writes committee and member names and their notes;
/// otherwise both are labelled and the notes left out.
String committeeExportJson({
  required List<Committee> committees,
  required List<CommitteeMember> members,
  required List<CommitteePosition> positions,
  required List<CommitteeCycle> cycles,
  required List<CommitteeContribution> contributions,
  required List<CommitteePayout> payouts,
  required DateTime exportedAt,
  required String build,
  required bool durable,
  bool includeNames = false,
}) {
  final List<Committee> cs = <Committee>[...committees]
    ..sort((Committee a, Committee b) => a.id.compareTo(b.id));
  final Map<LumeRecordId, int> number = <LumeRecordId, int>{
    for (int i = 0; i < cs.length; i++) cs[i].id: i + 1,
  };
  final List<CommitteeMember> ms = <CommitteeMember>[...members]
    ..sort((CommitteeMember a, CommitteeMember b) => a.id.compareTo(b.id));
  final Map<LumeRecordId, int> memberNumber = <LumeRecordId, int>{
    for (int i = 0; i < ms.length; i++) ms[i].id: i + 1,
  };
  final Map<String, Object?> doc = <String, Object?>{
    'schema': kCommitteeSchema,
    'exportVersion': kCommitteeExportVersion,
    'exportedAt': _instant(exportedAt),
    'source': <String, Object?>{
      'app': 'Lume',
      'build': build,
      'store': durable ? 'durable' : 'memory',
    },
    'namesIncluded': includeNames,
    'committees': <Map<String, Object?>>[
      for (final Committee c in cs)
        <String, Object?>{
          'id': c.id.value,
          if (includeNames)
            'name': c.name
          else
            'label': 'Committee ${number[c.id]}',
          if (includeNames && c.note != null) 'note': c.note,
          'currency': c.currency.code,
          'contributionMinor': c.contribution.minor,
          'positions': c.positions,
          'frequency': c.frequency.name,
          'firstDue': c.firstDue.toIso(),
          'readerRole': c.readerRole.name,
          if (c.cancelledOn != null) 'cancelledOn': c.cancelledOn!.toIso(),
          'createdAt': _instant(c.createdAt),
          'version': c.version,
        },
    ],
    'members': <Map<String, Object?>>[
      for (final CommitteeMember m in ms)
        <String, Object?>{
          'id': m.id.value,
          'committeeId': m.committeeId.value,
          if (includeNames)
            'name': m.name
          else
            'label': m.isReader ? 'You' : 'Member ${memberNumber[m.id]}',
          'isReader': m.isReader,
          if (includeNames && m.note != null) 'note': m.note,
          'createdAt': _instant(m.createdAt),
          'version': m.version,
        },
    ],
    'positions': <Map<String, Object?>>[
      for (final CommitteePosition p in <CommitteePosition>[
        ...positions,
      ]..sort(_positionOrder))
        <String, Object?>{
          'id': p.id.value,
          'committeeId': p.committeeId.value,
          'memberId': p.memberId.value,
          'cycle': p.cycle,
          'createdAt': _instant(p.createdAt),
          'version': p.version,
        },
    ],
    'cycles': <Map<String, Object?>>[
      for (final CommitteeCycle c in <CommitteeCycle>[
        ...cycles,
      ]..sort(_cycleOrder))
        <String, Object?>{
          'id': c.id.value,
          'committeeId': c.committeeId.value,
          'n': c.n,
          'due': c.due.toIso(),
          'createdAt': _instant(c.createdAt),
          'version': c.version,
        },
    ],
    'contributions': <Map<String, Object?>>[
      for (final CommitteeContribution x
          in <CommitteeContribution>[...contributions]..sort(
            (CommitteeContribution a, CommitteeContribution b) =>
                a.id.compareTo(b.id),
          ))
        <String, Object?>{
          'id': x.id.value,
          'committeeId': x.committeeId.value,
          'cycleId': x.cycleId.value,
          'positionId': x.positionId.value,
          'amountMinor': x.amount.minor,
          'currency': x.currency.code,
          'paidOn': x.paidOn.toIso(),
          'state': x.state.name,
          'createdAt': _instant(x.createdAt),
          'version': x.version,
        },
    ],
    'payouts': <Map<String, Object?>>[
      for (final CommitteePayout o in <CommitteePayout>[
        ...payouts,
      ]..sort((CommitteePayout a, CommitteePayout b) => a.id.compareTo(b.id)))
        <String, Object?>{
          'id': o.id.value,
          'committeeId': o.committeeId.value,
          'cycleId': o.cycleId.value,
          'positionId': o.positionId.value,
          'amountMinor': o.amount.minor,
          'currency': o.currency.code,
          'paidOn': o.paidOn.toIso(),
          'state': o.state.name,
          'createdAt': _instant(o.createdAt),
          'version': o.version,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(doc);
}

int _positionOrder(CommitteePosition a, CommitteePosition b) {
  final int c = a.committeeId.compareTo(b.committeeId);
  return c != 0 ? c : a.cycle.compareTo(b.cycle);
}

int _cycleOrder(CommitteeCycle a, CommitteeCycle b) {
  final int c = a.committeeId.compareTo(b.committeeId);
  return c != 0 ? c : a.n.compareTo(b.n);
}

/// The CSV columns, fixed English machine names whatever the app language.
const List<String> kCommitteeCsvColumns = <String>[
  'committee_id',
  'committee',
  'committee_state',
  'currency',
  'cycle',
  'cycles',
  'due',
  'member',
  'is_reader',
  'position_id',
  'receives_cycle',
  'contribution_minor',
  'contribution',
  'paid',
  'paid_on',
  'contribution_id',
  'cycle_collected_minor',
  'cycle_pool_minor',
  'payout_recorded',
  'payout_on',
  'payout_id',
];

/// One row per position per cycle: UTF-8 with a byte-order mark, comma
/// separated, RFC 4180 quoting, CRLF. A view for a spreadsheet — it cannot
/// be imported. Committees and members are labelled unless [includeNames].
String committeeExportCsv(CommitteeBook book, {bool includeNames = false}) {
  String cell(Object? v) {
    final String s = v?.toString() ?? '';
    return s.contains(RegExp('[",\r\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  final List<CommitteeView> vs = <CommitteeView>[...book.committees]
    ..sort(
      (CommitteeView a, CommitteeView b) =>
          a.committee.id.compareTo(b.committee.id),
    );
  final StringBuffer out = StringBuffer('\uFEFF')
    ..write(kCommitteeCsvColumns.join(','))
    ..write('\r\n');
  for (int i = 0; i < vs.length; i++) {
    final CommitteeView v = vs[i];
    final Map<String, int> memberNumber = <String, int>{
      for (int m = 0; m < v.members.length; m++)
        v.members[m].member.id.value: m + 1,
    };
    for (final CommitteeCycleView c in v.cycles) {
      for (final CommitteeSlot s in c.slots) {
        final CommitteeMemberView? who = v.memberOf(s.position.memberId);
        final String name = includeNames
            ? (who?.name ?? '')
            : (who?.isReader ?? false)
            ? 'You'
            : 'Member ${memberNumber[s.position.memberId.value]}';
        out
          ..write(
            <Object?>[
              v.committee.id.value,
              includeNames ? v.name : 'Committee ${i + 1}',
              v.status.name,
              v.currency.code,
              c.n,
              v.positionCount,
              c.due.toIso(),
              name,
              (who?.isReader ?? false) ? 'yes' : 'no',
              s.position.id.value,
              s.position.cycle,
              v.contribution.minor,
              v.contribution.toDecimalString(),
              s.paid ? 'yes' : 'no',
              s.contribution?.paidOn.toIso(),
              s.contribution?.id.value,
              c.collected.minor,
              c.pool.minor,
              c.paidOut ? 'yes' : 'no',
              c.payout?.paidOn.toIso(),
              c.payout?.id.value,
            ].map(cell).join(','),
          )
          ..write('\r\n');
      }
    }
  }
  return out.toString();
}

// ---- import ----------------------------------------------------------------

/// One problem in an import: where, and why — stable machine words.
@immutable
class CommitteeImportIssue {
  const CommitteeImportIssue(this.path, this.reason);

  /// `committees[2].contributionMinor`, `payouts.<id>.positionId`, `$`.
  final String path;

  /// `json`, `schema`, `version`, `missing`, `type`, `uuid`, `duplicateId`,
  /// `reference`, `committee`, `notRecipient`, `currency`, `overflow`,
  /// `date`, `value`, `unsupported`, `conflict`, `invariant:<rule>`,
  /// `damaged:<reason>` …
  final String reason;

  @override
  String toString() => '$path: $reason';

  @override
  bool operator ==(Object other) =>
      other is CommitteeImportIssue &&
      other.path == path &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(path, reason);
}

/// What an import would do, or why it cannot.
@immutable
class CommitteeImportReport {
  const CommitteeImportReport({
    required this.issues,
    this.create = 0,
    this.update = 0,
    this.unchanged = 0,
    this.namesIncluded = false,
    this.records = const <(String, LumeRecord, bool)>[],
  });

  final List<CommitteeImportIssue> issues;
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
/// written. Apply the report with [committeeImportApply].
CommitteeImportReport committeeImportCheck(
  String document,
  LumeRecordRepository store,
) {
  CommitteeImportReport only(String path, String reason) =>
      CommitteeImportReport(
        issues: <CommitteeImportIssue>[CommitteeImportIssue(path, reason)],
      );
  final Object? root;
  try {
    root = jsonDecode(document);
  } on FormatException {
    return only(r'$', 'json');
  }
  if (root is! Map<String, Object?>) return only(r'$', 'type');
  if (root['schema'] != kCommitteeSchema) return only(r'$.schema', 'schema');
  final Object? version = root['exportVersion'];
  if (version is! int) return only(r'$.exportVersion', 'type');
  if (version != kCommitteeExportVersion) {
    return only(
      r'$.exportVersion',
      version > kCommitteeExportVersion ? 'unsupportedVersion' : 'version',
    );
  }
  final Map<String, Object?> doc = root;
  final bool names = doc['namesIncluded'] == true;
  final List<CommitteeImportIssue> issues = <CommitteeImportIssue>[];
  final List<(String, LumeRecord)> records = <(String, LumeRecord)>[];
  final Set<String> ids = <String>{};

  List<Map<String, Object?>> list(String key) {
    final Object? v = doc[key];
    if (v is! List<Object?>) {
      issues.add(CommitteeImportIssue('\$.$key', 'missing'));
      return const <Map<String, Object?>>[];
    }
    final List<Map<String, Object?>> out = <Map<String, Object?>>[];
    for (int i = 0; i < v.length; i++) {
      if (v[i] is Map<String, Object?>) {
        out.add(v[i]! as Map<String, Object?>);
      } else {
        issues.add(CommitteeImportIssue('$key[$i]', 'type'));
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
      issues.add(CommitteeImportIssue('$path.id', 'uuid'));
      return null;
    }
    if (!ids.add(id)) {
      issues.add(CommitteeImportIssue('$path.id', 'duplicateId'));
      return null;
    }
    final Object? at = m['createdAt'];
    final DateTime? created = at is String ? DateTime.tryParse(at) : null;
    if (created == null || !created.isUtc) {
      issues.add(CommitteeImportIssue('$path.createdAt', 'instant'));
      return null;
    }
    final Object? v = m['version'];
    if (v is! int || v < 1) {
      issues.add(CommitteeImportIssue('$path.version', 'version'));
      return null;
    }
    return LumeRecord(
      id: id,
      fields: <String, Object?>{'schema': kCommitteeSchema, ...fields},
      version: v,
      createdAt: created,
      updatedAt: created,
    );
  }

  final List<Committee> committees = <Committee>[];
  final List<CommitteeMember> members = <CommitteeMember>[];
  final List<CommitteePosition> positions = <CommitteePosition>[];
  final List<CommitteeCycle> cycles = <CommitteeCycle>[];
  final List<CommitteeContribution> contributions = <CommitteeContribution>[];
  final List<CommitteePayout> payouts = <CommitteePayout>[];

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
      } on CommitteeDefectException catch (e) {
        issues.add(
          CommitteeImportIssue(
            '$key[$i].${_path(key, e.defect.field)}',
            e.defect.reason,
          ),
        );
      }
    }
  }

  decode<Committee>(
    'committees',
    CommitteeCollections.committees,
    (Map<String, Object?> m) => <String, Object?>{
      'name': names ? m['name'] : (m['name'] ?? m['label']),
      'note': m['note'],
      'currency': m['currency'],
      'contributionMinor': m['contributionMinor'],
      'positions': m['positions'],
      'frequency': m['frequency'],
      'firstDue': m['firstDue'],
      'readerRole': m['readerRole'],
      'cancelledOn': m['cancelledOn'],
    },
    Committee.decode,
    committees,
  );
  decode<CommitteeMember>(
    'members',
    CommitteeCollections.members,
    (Map<String, Object?> m) => <String, Object?>{
      'committee': m['committeeId'],
      'name': names ? m['name'] : (m['name'] ?? m['label']),
      'isReader': m['isReader'],
      'note': m['note'],
    },
    CommitteeMember.decode,
    members,
  );
  decode<CommitteePosition>(
    'positions',
    CommitteeCollections.positions,
    (Map<String, Object?> m) => <String, Object?>{
      'committee': m['committeeId'],
      'member': m['memberId'],
      'cycle': m['cycle'],
    },
    CommitteePosition.decode,
    positions,
  );
  decode<CommitteeCycle>(
    'cycles',
    CommitteeCollections.cycles,
    (Map<String, Object?> m) => <String, Object?>{
      'committee': m['committeeId'],
      'n': m['n'],
      'due': m['due'],
    },
    CommitteeCycle.decode,
    cycles,
  );
  decode<CommitteeContribution>(
    'contributions',
    CommitteeCollections.contributions,
    (Map<String, Object?> m) => <String, Object?>{
      'committee': m['committeeId'],
      'cycle': m['cycleId'],
      'position': m['positionId'],
      'amountMinor': m['amountMinor'],
      'currency': m['currency'],
      'paidOn': m['paidOn'],
      'state': m['state'],
    },
    CommitteeContribution.decode,
    contributions,
  );
  decode<CommitteePayout>(
    'payouts',
    CommitteeCollections.payouts,
    (Map<String, Object?> m) => <String, Object?>{
      'committee': m['committeeId'],
      'cycle': m['cycleId'],
      'position': m['positionId'],
      'amountMinor': m['amountMinor'],
      'currency': m['currency'],
      'paidOn': m['paidOn'],
      'state': m['state'],
    },
    CommitteePayout.decode,
    payouts,
  );

  // What the tool already holds.
  final Map<String, LumeRecord> held = <String, LumeRecord>{
    for (final String c in CommitteeCollections.all)
      for (final LumeRecord r in store.view(c).items) r.id: r,
  };
  final List<Committee> heldCommittees = <Committee>[];
  final List<CommitteeMember> heldMembers = <CommitteeMember>[];
  final List<CommitteePosition> heldPositions = <CommitteePosition>[];
  final List<CommitteeCycle> heldCycles = <CommitteeCycle>[];
  final List<CommitteeContribution> heldContributions =
      <CommitteeContribution>[];
  final List<CommitteePayout> heldPayouts = <CommitteePayout>[];
  void hold<T>(String c, T Function(LumeRecord) decode, List<T> into) {
    for (final LumeRecord r in store.view(c).items) {
      try {
        into.add(decode(r));
      } on CommitteeDefectException {
        issues.add(
          CommitteeImportIssue('destination.${r.id}', 'damaged:defect'),
        );
      }
    }
  }

  hold(CommitteeCollections.committees, Committee.decode, heldCommittees);
  hold(CommitteeCollections.members, CommitteeMember.decode, heldMembers);
  hold(CommitteeCollections.positions, CommitteePosition.decode, heldPositions);
  hold(CommitteeCollections.cycles, CommitteeCycle.decode, heldCycles);
  hold(
    CommitteeCollections.contributions,
    CommitteeContribution.decode,
    heldContributions,
  );
  hold(CommitteeCollections.payouts, CommitteePayout.decode, heldPayouts);

  int create = 0, update = 0, unchanged = 0;
  final List<(String, LumeRecord, bool)> writes =
      <(String, LumeRecord, bool)>[];
  for (final (String c, LumeRecord r) in records) {
    final LumeRecord? there = held[r.id];
    if (there == null) {
      create++;
      writes.add((c, r, false));
    } else if (there.version != r.version) {
      issues.add(CommitteeImportIssue('${_key(c)}.${r.id}', 'conflict'));
    } else if (mapEquals(_plain(there.fields), _plain(r.fields))) {
      unchanged++;
    } else {
      update++;
      writes.add((c, r, true));
    }
  }

  // References and rules over what the tool would hold.
  final Map<LumeRecordId, Committee> allCommittees = <LumeRecordId, Committee>{
    for (final Committee c in heldCommittees) c.id: c,
    for (final Committee c in committees) c.id: c,
  };
  final Map<LumeRecordId, CommitteeMember> allMembers =
      <LumeRecordId, CommitteeMember>{
        for (final CommitteeMember m in heldMembers) m.id: m,
        for (final CommitteeMember m in members) m.id: m,
      };
  final Map<LumeRecordId, CommitteePosition> allPositions =
      <LumeRecordId, CommitteePosition>{
        for (final CommitteePosition p in heldPositions) p.id: p,
        for (final CommitteePosition p in positions) p.id: p,
      };
  final Map<LumeRecordId, CommitteeCycle> allCycles =
      <LumeRecordId, CommitteeCycle>{
        for (final CommitteeCycle c in heldCycles) c.id: c,
        for (final CommitteeCycle c in cycles) c.id: c,
      };

  void owner(String key, String id, LumeRecordId committee) {
    if (!allCommittees.containsKey(committee)) {
      issues.add(CommitteeImportIssue('$key.$id.committeeId', 'reference'));
    }
  }

  for (final CommitteeMember m in members) {
    owner('members', m.id.value, m.committeeId);
  }
  for (final CommitteeCycle c in cycles) {
    owner('cycles', c.id.value, c.committeeId);
  }
  for (final CommitteePosition p in positions) {
    owner('positions', p.id.value, p.committeeId);
    final CommitteeMember? m = allMembers[p.memberId];
    if (m == null) {
      issues.add(
        CommitteeImportIssue('positions.${p.id.value}.memberId', 'reference'),
      );
    } else if (m.committeeId != p.committeeId) {
      issues.add(
        CommitteeImportIssue('positions.${p.id.value}.memberId', 'committee'),
      );
    }
  }

  // A contribution or a payout belongs to one committee, and its cycle and
  // its position must belong to that same one. A payout must also name the
  // position that holds its cycle.
  void entry(
    String key,
    LumeRecordId id,
    LumeRecordId committeeId,
    LumeRecordId cycleId,
    LumeRecordId positionId, {
    required bool isPayout,
  }) {
    owner(key, id.value, committeeId);
    final CommitteeCycle? cycle = allCycles[cycleId];
    final CommitteePosition? position = allPositions[positionId];
    if (cycle == null) {
      issues.add(CommitteeImportIssue('$key.${id.value}.cycleId', 'reference'));
    } else if (cycle.committeeId != committeeId) {
      issues.add(CommitteeImportIssue('$key.${id.value}.cycleId', 'committee'));
    }
    if (position == null) {
      issues.add(
        CommitteeImportIssue('$key.${id.value}.positionId', 'reference'),
      );
    } else if (position.committeeId != committeeId) {
      issues.add(
        CommitteeImportIssue('$key.${id.value}.positionId', 'committee'),
      );
    } else if (isPayout && cycle != null && position.cycle != cycle.n) {
      issues.add(
        CommitteeImportIssue('$key.${id.value}.positionId', 'notRecipient'),
      );
    }
  }

  for (final CommitteeContribution x in contributions) {
    entry(
      'contributions',
      x.id,
      x.committeeId,
      x.cycleId,
      x.positionId,
      isPayout: false,
    );
  }
  for (final CommitteePayout o in payouts) {
    entry(
      'payouts',
      o.id,
      o.committeeId,
      o.cycleId,
      o.positionId,
      isPayout: true,
    );
  }

  if (issues.isEmpty) {
    try {
      final CommitteeBook book = CommitteeBook.from(
        committees: allCommittees.values.toList(),
        members: allMembers.values.toList(),
        positions: allPositions.values.toList(),
        cycles: allCycles.values.toList(),
        // Keyed by id, so a record held and imported again at the same
        // version counts once, not twice.
        contributions: <LumeRecordId, CommitteeContribution>{
          for (final CommitteeContribution x in heldContributions) x.id: x,
          for (final CommitteeContribution x in contributions) x.id: x,
        }.values.toList(),
        payouts: <LumeRecordId, CommitteePayout>{
          for (final CommitteePayout o in heldPayouts) o.id: o,
          for (final CommitteePayout o in payouts) o.id: o,
        }.values.toList(),
        today: null,
      );
      for (final CommitteeDamage d in book.damage) {
        issues.add(
          CommitteeImportIssue(
            d.id == null ? 'committees.${d.committee}' : 'records.${d.id}',
            'damaged:${d.reason}',
          ),
        );
      }
      for (final String broken in book.invariants()) {
        issues.add(
          CommitteeImportIssue(r'$', 'invariant:${broken.split(' ').first}'),
        );
      }
      // Every sum the screen would draw fits its bound, or this throws.
      final List<CommitteeCurrencySummary> sums = book.summaries;
      assert(sums.length == book.currencies.length);
    } on LumeMoneyException catch (e) {
      issues.add(CommitteeImportIssue(r'$', e.failure.name));
    }
  }

  return CommitteeImportReport(
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
LumeTxResult<int> committeeImportApply(
  CommitteeImportReport report,
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
  CommitteeCollections.committees => 'committees',
  CommitteeCollections.members => 'members',
  CommitteeCollections.positions => 'positions',
  CommitteeCollections.cycles => 'cycles',
  CommitteeCollections.contributions => 'contributions',
  _ => 'payouts',
};

/// The record's field name as the JSON writes it. A position's `cycle` is
/// the number of the cycle it receives, not a reference, so it keeps its
/// own name.
String _path(String key, String field) => switch (field) {
  'committee' => 'committeeId',
  'member' => 'memberId',
  'cycle' => key == 'positions' ? 'cycle' : 'cycleId',
  'position' => 'positionId',
  _ => field,
};

Map<String, Object?> _plain(Map<String, Object?> m) => <String, Object?>{
  for (final MapEntry<String, Object?> e in m.entries)
    if (e.value != null) e.key: e.value,
};
