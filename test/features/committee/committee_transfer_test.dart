/// Committee out and in (`COMMITTEE_PROPOSAL.md` §12): lossless JSON that
/// keeps names to itself by default, an import that is all or nothing and
/// names every problem, and a CSV that says plainly it cannot come back.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/committee/domain/committee_book.dart';
import 'package:lume/features/committee/domain/committee_model.dart';
import 'package:lume/features/committee/domain/committee_repository.dart';
import 'package:lume/features/committee/domain/committee_transfer.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

import 'committee_harness.dart';

/// The document for everything the harness holds.
String exportOf(CommitteeHarness h, {bool includeNames = false}) {
  final CommitteeSnapshot s = h.repo.view();
  return committeeExportJson(
    committees: s.committees,
    members: s.members,
    positions: s.positions,
    cycles: s.cycles,
    contributions: s.contributions,
    payouts: s.payouts,
    exportedAt: DateTime.utc(2026, 9, 7, 12),
    build: '1.0.0',
    durable: h.repo.durable,
    includeNames: includeNames,
  );
}

Map<String, Object?> parse(String document) =>
    jsonDecode(document) as Map<String, Object?>;

List<Map<String, Object?>> rows(Map<String, Object?> doc, String key) =>
    <Map<String, Object?>>[
      for (final Object? x in doc[key]! as List<Object?>)
        x! as Map<String, Object?>,
    ];

void main() {
  late CommitteeHarness h;

  setUp(() {
    h = CommitteeHarness();
  });
  tearDown(() => h.dispose());

  group('export', () {
    test('names are left out unless the reader asks for them', () {
      final Committee c = h.add(name: 'Office committee', note: 'Fridays');
      h.collect(c.id, 1);
      final Map<String, Object?> doc = parse(exportOf(h));
      expect(doc['namesIncluded'], isFalse);
      final Map<String, Object?> committee = rows(doc, 'committees').single;
      expect(committee['label'], 'Committee 1');
      expect(committee.containsKey('name'), isFalse);
      expect(committee.containsKey('note'), isFalse);
      final List<Map<String, Object?>> members = rows(doc, 'members');
      expect(
        members.map((Map<String, Object?> m) => m['label']),
        containsAll(<String>['You', 'Member 1']),
      );
      expect(
        members.every((Map<String, Object?> m) => !m.containsKey('name')),
        isTrue,
      );
      expect(exportOf(h), isNot(contains('Ahmed')));
      expect(exportOf(h), isNot(contains('Fridays')));

      final Map<String, Object?> full = parse(exportOf(h, includeNames: true));
      expect(full['namesIncluded'], isTrue);
      expect(rows(full, 'committees').single['name'], 'Office committee');
      expect(rows(full, 'committees').single['note'], 'Fridays');
      expect(
        rows(full, 'members').map((Map<String, Object?> m) => m['name']),
        containsAll(<String>['Ahmed', 'Sara', 'You']),
      );
    });

    test('every record, with its id, version, instant and stored date', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      expect(h.payout(c.id, 1).failure, isNull);
      final Map<String, Object?> doc = parse(exportOf(h));
      expect(doc['schema'], 'lume.committee/1');
      expect(doc['exportVersion'], 1);
      expect(
        (doc['source']! as Map<String, Object?>)['store'],
        'memory',
        reason: 'this build is not durable, and says so',
      );
      expect(rows(doc, 'committees'), hasLength(1));
      expect(rows(doc, 'members'), hasLength(5));
      expect(rows(doc, 'positions'), hasLength(5));
      expect(rows(doc, 'cycles'), hasLength(5));
      expect(rows(doc, 'contributions'), hasLength(5));
      expect(rows(doc, 'payouts'), hasLength(1));

      final Map<String, Object?> committee = rows(doc, 'committees').single;
      expect(committee['contributionMinor'], 2830000);
      expect(committee['positions'], 5);
      expect(committee['firstDue'], '2026-06-07');
      expect(committee['frequency'], 'monthly');
      expect(committee['readerRole'], 'member');
      expect(committee.containsKey('cancelledOn'), isFalse);
      // Nothing derived is written: no pool, no total, no collected.
      expect(committee.containsKey('pool'), isFalse);
      expect(committee.containsKey('collected'), isFalse);

      final Map<String, Object?> payout = rows(doc, 'payouts').single;
      expect(payout['amountMinor'], 14150000);
      expect(payout['state'], 'active');
      expect(rows(doc, 'cycles').first['due'], '2026-06-07');
    });

    test('a cancelled committee carries the day it was cancelled', () {
      final Committee c = h.add();
      expect(
        h.repo
            .setCancelled(
              c.id,
              true,
              on: d(9, 8),
              version: h.view(c.id).committee.version,
            )
            .failure,
        isNull,
      );
      expect(
        rows(parse(exportOf(h)), 'committees').single['cancelledOn'],
        '2026-09-08',
      );
    });
  });

  group('import', () {
    test('a whole committee moves to an empty store, ids and versions '
        'intact', () {
      final Committee c = h.add();
      for (int n = 1; n <= 2; n++) {
        h.collect(c.id, n);
        expect(h.payout(c.id, n).failure, isNull);
      }
      final String document = exportOf(h, includeNames: true);
      final String before = h.records();

      final CommitteeHarness to = CommitteeHarness(seed: 9);
      final CommitteeImportReport report = committeeImportCheck(
        document,
        to.store,
      );
      expect(report.issues, isEmpty);
      expect(
        report.create,
        28,
        reason:
            '1 committee, 5 members, 5 positions, 5 cycles, '
            '10 contributions and 2 payouts',
      );
      expect(report.update, 0);
      expect(report.unchanged, 0);
      final LumeTxResult<int> applied = committeeImportApply(report, to.store);
      expect(applied.ok, isTrue);
      expect(applied.value, 28);
      expect(to.records(), before, reason: 'byte for byte');

      final CommitteeView v = to.view(c.id);
      expect(v.name, 'Office committee');
      expect(v.collected.minor, 28300000);
      expect(v.paidOut.minor, 28300000);
      to.expectSound();
      to.dispose();
    });

    test('importing the same document twice changes nothing the second '
        'time', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      final String document = exportOf(h);
      final CommitteeHarness to = CommitteeHarness(seed: 9);
      committeeImportApply(committeeImportCheck(document, to.store), to.store);
      final String once = to.records();

      final CommitteeImportReport again = committeeImportCheck(
        document,
        to.store,
      );
      expect(again.issues, isEmpty);
      expect(again.create, 0);
      expect(again.update, 0);
      expect(again.unchanged, 21);
      expect(again.records, isEmpty);
      expect(to.records(), once);
      to.dispose();
      expect(c.id.value.isNotEmpty, isTrue);
    });

    test('a document that is not this schema, or a newer version, is '
        'refused whole', () {
      expect(
        committeeImportCheck('not json', h.store).issues.single.reason,
        'json',
      );
      expect(
        committeeImportCheck(
          '{"schema":"lume.ledger/1"}',
          h.store,
        ).issues.single.path,
        r'$.schema',
      );
      expect(
        committeeImportCheck(
          '{"schema":"lume.committee/1","exportVersion":2}',
          h.store,
        ).issues.single.reason,
        'unsupportedVersion',
      );
    });

    test('a payout naming a position that does not hold that cycle is '
        'refused by path, and nothing is written', () {
      final Committee c = h.add();
      h.collect(c.id, 3);
      expect(h.payout(c.id, 3).failure, isNull);
      final Map<String, Object?> doc = parse(exportOf(h));
      // Point cycle 3's payout at cycle 1's position.
      final Map<String, Object?> payout = rows(doc, 'payouts').single;
      final Map<String, Object?> wrong = rows(
        doc,
        'positions',
      ).firstWhere((Map<String, Object?> p) => p['cycle'] == 1);
      payout['positionId'] = wrong['id'];

      final CommitteeHarness to = CommitteeHarness(seed: 9);
      final CommitteeImportReport report = committeeImportCheck(
        jsonEncode(doc),
        to.store,
      );
      expect(
        report.issues,
        contains(
          CommitteeImportIssue(
            'payouts.${payout['id']}.positionId',
            'notRecipient',
          ),
        ),
      );
      expect(committeeImportApply(report, to.store).ok, isFalse);
      expect(to.recordLines(), isEmpty);
      to.dispose();
    });

    test('a contribution pointing at another committee\'s cycle is a '
        'reference problem', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      final Map<String, Object?> doc = parse(exportOf(h));
      final Map<String, Object?> x = rows(doc, 'contributions').first;
      x['cycleId'] = LumeRecordId.generate().value;

      final CommitteeHarness to = CommitteeHarness(seed: 9);
      final CommitteeImportReport report = committeeImportCheck(
        jsonEncode(doc),
        to.store,
      );
      expect(
        report.issues,
        contains(
          CommitteeImportIssue('contributions.${x['id']}.cycleId', 'reference'),
        ),
      );
      expect(to.recordLines(), isEmpty);
      to.dispose();
    });

    test('two positions claiming one cycle are damage, and the file is '
        'refused', () {
      final Committee c = h.add();
      final Map<String, Object?> doc = parse(exportOf(h));
      final List<Map<String, Object?>> positions = rows(doc, 'positions');
      positions[1]['cycle'] = positions[0]['cycle'];

      final CommitteeHarness to = CommitteeHarness(seed: 9);
      final CommitteeImportReport report = committeeImportCheck(
        jsonEncode(doc),
        to.store,
      );
      expect(
        report.issues.map((CommitteeImportIssue i) => i.reason),
        contains('damaged:positionCycles'),
      );
      expect(to.recordLines(), isEmpty);
      to.dispose();
      expect(c.id.value.isNotEmpty, isTrue);
    });

    test('a duplicate id, a bad uuid and a wrong instant are each named', () {
      final Committee c = h.add();
      final Map<String, Object?> doc = parse(exportOf(h));
      final List<Map<String, Object?>> members = rows(doc, 'members');
      members[1]['id'] = members[0]['id'];
      members[2]['id'] = 'not-a-uuid';
      members[3]['createdAt'] = '2026-09-07 10:00';
      final List<CommitteeImportIssue> issues = committeeImportCheck(
        jsonEncode(doc),
        h.store,
      ).issues;
      expect(
        issues.map((CommitteeImportIssue i) => i.reason),
        containsAll(<String>['duplicateId', 'uuid', 'instant']),
      );
      expect(c.id.value.isNotEmpty, isTrue);
    });

    test('an amount that is not the committee\'s contribution is damage', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      final Map<String, Object?> doc = parse(exportOf(h));
      rows(doc, 'contributions').first['amountMinor'] = 2000000;
      final CommitteeHarness to = CommitteeHarness(seed: 9);
      expect(
        committeeImportCheck(
          jsonEncode(doc),
          to.store,
        ).issues.map((CommitteeImportIssue i) => i.reason),
        contains('damaged:contribution'),
      );
      to.dispose();
      expect(c.id.value.isNotEmpty, isTrue);
    });

    test('a record held at another version is a conflict, not an '
        'overwrite', () {
      final Committee c = h.add();
      final String document = exportOf(h);
      expect(
        h.repo
            .editCommittee(
              c.id,
              name: 'Renamed',
              version: h.view(c.id).committee.version,
            )
            .failure,
        isNull,
      );
      final CommitteeImportReport report = committeeImportCheck(
        document,
        h.store,
      );
      expect(
        report.issues,
        contains(CommitteeImportIssue('committees.${c.id.value}', 'conflict')),
      );
      expect(committeeImportApply(report, h.store).ok, isFalse);
      expect(h.view(c.id).name, 'Renamed');
    });

    test('a failure part-way through applying writes none of it', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      final String document = exportOf(h);
      final CommitteeHarness to = CommitteeHarness(seed: 9);
      to.store.publishFault = (_, int i) {
        if (i == 7) throw StateError('disk');
      };
      final LumeTxResult<int> r = committeeImportApply(
        committeeImportCheck(document, to.store),
        to.store,
      );
      to.store.publishFault = null;
      expect(r.ok, isFalse);
      expect(to.recordLines(), isEmpty);
      to.dispose();
      expect(c.id.value.isNotEmpty, isTrue);
    });
  });

  group('CSV', () {
    test('one row per position per cycle, with a BOM and CRLF', () {
      final Committee c = h.add();
      h.collect(c.id, 1);
      expect(h.payout(c.id, 1).failure, isNull);
      final String csv = committeeExportCsv(h.book());
      expect(csv.codeUnitAt(0), 0xFEFF);
      final List<String> lines = csv.split('\r\n')
        ..removeWhere((String l) => l.isEmpty);
      expect(lines, hasLength(26), reason: 'a heading and 5 × 5 rows');
      expect(lines.first.substring(1), kCommitteeCsvColumns.join(','));

      final List<String> first = lines[1].split(',');
      expect(first[1], 'Committee 1');
      expect(first[3], 'PKR');
      expect(first[4], '1', reason: 'cycle');
      expect(first[11], '2830000', reason: 'contribution in minor units');
      expect(first[12], '28300.00');
      expect(first[13], 'yes', reason: 'paid');
      expect(first[16], '14150000', reason: 'the cycle collected its pool');
      expect(first[18], 'yes', reason: 'the payout is recorded');
      // A cycle nobody has paid into yet.
      expect(lines.last.split(',')[13], 'no');
    });

    test('names are left out unless asked for, and a comma is quoted', () {
      final Committee c = h.add(
        name: 'Office, Friday',
        members: <CommitteeMemberDraft>[
          const CommitteeMemberDraft(
            name: 'You',
            isReader: true,
            cycles: <int>[1],
          ),
          const CommitteeMemberDraft(name: 'Ahmed', cycles: <int>[2]),
        ],
      );
      expect(committeeExportCsv(h.book()), isNot(contains('Ahmed')));
      expect(committeeExportCsv(h.book()), contains('Member 2'));
      expect(committeeExportCsv(h.book()), contains('You'));
      final String named = committeeExportCsv(h.book(), includeNames: true);
      expect(named, contains('"Office, Friday"'));
      expect(named, contains('Ahmed'));
      expect(c.id.value.isNotEmpty, isTrue);
    });

    test('CSV is not a document this tool will read back', () {
      final Committee c = h.add();
      final String csv = committeeExportCsv(h.book());
      expect(committeeImportCheck(csv, h.store).issues.single.reason, 'json');
      expect(c.id.value.isNotEmpty, isTrue);
    });
  });
}
