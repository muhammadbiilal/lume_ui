/// Ledger's export (lossless JSON with names private by default; CSV for a
/// spreadsheet) and its all-or-nothing import.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/ledger/domain/ledger_book.dart';
import 'package:lume/features/ledger/domain/ledger_model.dart';
import 'package:lume/features/ledger/domain/ledger_repository.dart';
import 'package:lume/features/ledger/domain/ledger_transfer.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

import 'ledger_harness.dart';

/// Ahmed owes Rs 6,000 (E1) and Sara is owed Rs 1,500 (E4), with a note
/// that names someone, a voided entry and a confirmed credit.
LedgerHarness populated({int seed = 1}) {
  final LedgerHarness h = LedgerHarness(seed: seed);
  final LumeRecordId ahmed = h.person('Ahmed');
  final LumeRecordId sara = h.person('Sara, "S"');
  h.tick();
  h.repo.addEntry(
    LedgerEntryDraft(
      partyId: ahmed,
      kind: LedgerKind.lent,
      amount: rs(10000),
      on: d(8, 1),
      due: d(9, 1),
      note: 'Car repair — for Ahmed\'s brother',
    ),
  );
  h.add(ahmed, LedgerKind.repaidToMe, rs(4000), d(8, 20));
  h.add(sara, LedgerKind.borrowed, rs(2000), d(9, 1), due: d(9, 10));
  h.add(sara, LedgerKind.repaidByMe, rs(500), d(9, 5));
  final LedgerEntry v = h.add(ahmed, LedgerKind.lent, rs(1), d(8, 2));
  h.repo.setVoided(v.id, true, version: 1);
  final LumeRecordId bilal = h.person('Bilal');
  h.add(bilal, LedgerKind.lent, rs(1000), d(8, 1));
  h.add(bilal, LedgerKind.repaidToMe, rs(1500), d(8, 10), confirm: true);
  return h;
}

String exportOf(LedgerHarness h, {bool private = true}) {
  final LedgerBook b = h.book();
  return ledgerExportJson(
    parties: b.parties,
    entries: b.entries,
    allocations: b.allocations,
    exportedAt: DateTime.utc(2026, 9, 7, 11, 41),
    build: 'test',
    durable: false,
    includePrivate: private,
  );
}

Map<String, Object?> jsonOf(String s) => jsonDecode(s) as Map<String, Object?>;

void main() {
  group('JSON export', () {
    test('the documented envelope, UTC instants, integer minor units', () {
      final LedgerHarness h = populated();
      final Map<String, Object?> doc = jsonOf(exportOf(h, private: false));
      expect(doc['schema'], 'lume.ledger/1');
      expect(doc['exportVersion'], 1);
      expect(doc['exportedAt'], '2026-09-07T11:41:00.000Z');
      expect(doc['source'], <String, Object?>{
        'app': 'Lume',
        'build': 'test',
        'store': 'memory',
      });
      final List<Object?> entries = doc['entries']! as List<Object?>;
      expect(entries, hasLength(7));
      final Map<String, Object?> first = entries
          .cast<Map<String, Object?>>()
          .firstWhere((Map<String, Object?> e) => e['amountMinor'] == 1000000);
      expect(first['currency'], 'PKR');
      expect(first['on'], '2026-08-01');
      expect(first['due'], '2026-09-01');
      expect(
        entries.cast<Map<String, Object?>>().where(
          (Map<String, Object?> e) => e['state'] == 'voided',
        ),
        hasLength(1),
      );
      expect((doc['allocations']! as List<Object?>).isNotEmpty, isTrue);
      h.dispose();
    });

    test('names and notes are private by default: labels, no notes', () {
      final LedgerHarness h = populated();
      final String text = exportOf(h, private: false);
      final Map<String, Object?> doc = jsonOf(text);
      expect(doc['namesIncluded'], isFalse);
      final List<Map<String, Object?>> parties =
          (doc['parties']! as List<Object?>).cast<Map<String, Object?>>();
      expect(parties.map((Map<String, Object?> p) => p['label']), <String>[
        'Person 1',
        'Person 2',
        'Person 3',
      ]);
      expect(text.contains('Ahmed'), isFalse);
      expect(text.contains('Sara'), isFalse);
      expect(text.contains('Car repair'), isFalse);
      expect(
        parties.every((Map<String, Object?> p) => !p.containsKey('name')),
        isTrue,
      );
      h.dispose();
    });

    test('labels follow id order and are stable across exports', () {
      final LedgerHarness h = populated();
      expect(exportOf(h, private: false), exportOf(h, private: false));
      h.dispose();
    });

    test('with names chosen, names and notes are written', () {
      final LedgerHarness h = populated();
      final String text = exportOf(h);
      expect(jsonOf(text)['namesIncluded'], isTrue);
      expect(text.contains('Ahmed'), isTrue);
      expect(text.contains('Car repair'), isTrue);
      h.dispose();
    });
  });

  group('CSV export', () {
    test(
      'BOM, fixed English header, CRLF, RFC 4180 quoting, machine values',
      () {
        final LedgerHarness h = populated();
        final String csv = ledgerExportCsv(h.book(), includePrivate: true);
        expect(
          csv.startsWith('\ufeffentry_id,party_id,party,kind,amount_minor,'),
          isTrue,
        );
        final List<String> lines = csv.substring(1).split('\r\n');
        expect(lines.first, kLedgerCsvColumns.join(','));
        expect(lines.last, '');
        expect(lines, hasLength(1 + 7 + 1));
        expect(csv.contains('"Sara, ""S"""'), isTrue);
        final String ahmedLoan = lines.firstWhere(
          (String l) => l.contains(',1000000,'),
        );
        expect(
          ahmedLoan,
          contains(
            ',lent,1000000,10000.00,PKR,2026-08-01,2026-09-01,active,600000,,',
          ),
        );
        expect(
          csv.contains('\n') && !csv.replaceAll('\r\n', '').contains('\n'),
          isTrue,
        );
        h.dispose();
      },
    );

    test('private by default: labels, never names', () {
      final LedgerHarness h = populated();
      final String csv = ledgerExportCsv(h.book());
      expect(csv.contains('Ahmed'), isFalse);
      expect(csv.contains('Person 1'), isTrue);
      h.dispose();
    });

    test('remaining and credit summarise the allocations', () {
      final LedgerHarness h = populated();
      final String csv = ledgerExportCsv(h.book());
      // Bilal's Rs 1,500 repayment: Rs 500 credit.
      expect(
        csv,
        contains(',repaidToMe,150000,1500.00,PKR,2026-08-10,,active,,50000,'),
      );
      h.dispose();
    });
  });

  group('JSON import', () {
    LedgerImportReport check(LedgerHarness into, String doc) =>
        ledgerImportCheck(doc, into.store);

    test('a valid export imports into an empty Ledger, losslessly', () {
      final LedgerHarness from = populated();
      final String doc = exportOf(from);
      final LedgerHarness to = LedgerHarness(seed: 5);
      final LedgerImportReport r = check(to, doc);
      expect(r.issues, isEmpty);
      expect(r.create, 3 + 7 + from.book().allocations.length);
      expect(ledgerImportApply(r, to.store).ok, isTrue);
      expect(
        exportOf(to),
        doc.replaceFirst(
          RegExp('"exportedAt": "[^"]*"'),
          '"exportedAt": "2026-09-07T11:41:00.000Z"',
        ),
      );
      final LedgerBook a = from.book();
      final LedgerBook b = to.book();
      expect(b.people, a.people);
      expect(
        b.summaries.map(
          (LedgerCurrencySummary s) => '${s.currency} ${s.net.minor}',
        ),
        a.summaries.map(
          (LedgerCurrencySummary s) => '${s.currency} ${s.net.minor}',
        ),
      );
      expect(b.invariants(), isEmpty);
      from.dispose();
      to.dispose();
    });

    test('importing the same file again changes nothing', () {
      final LedgerHarness from = populated();
      final String doc = exportOf(from);
      final LedgerImportReport again = check(from, doc);
      expect(again.issues, isEmpty);
      expect(again.create, 0);
      expect(again.unchanged, 3 + 7 + from.book().allocations.length);
      final String before = from.store.debugDump();
      expect(ledgerImportApply(again, from.store).ok, isTrue);
      expect(from.store.debugDump(), before);
      from.dispose();
    });

    test('a retried apply with the same key writes once', () {
      final LedgerHarness from = populated();
      final LedgerHarness to = LedgerHarness(seed: 5);
      final LedgerImportReport r = check(to, exportOf(from));
      expect(ledgerImportApply(r, to.store, idempotencyKey: 'i1').ok, isTrue);
      final LumeTxResult<int> again = ledgerImportApply(
        r,
        to.store,
        idempotencyKey: 'i1',
      );
      expect(again.receipt!.replayed, isTrue);
      from.dispose();
      to.dispose();
    });

    List<LedgerImportIssue> issuesOf(String doc) {
      final LedgerHarness to = LedgerHarness(seed: 5);
      final String before = to.store.debugDump();
      final LedgerImportReport r = check(to, doc);
      expect(ledgerImportApply(r, to.store).ok, r.ok);
      if (!r.ok) expect(to.store.debugDump(), before);
      to.dispose();
      return r.issues;
    }

    Map<String, Object?> base() {
      final LedgerHarness from = populated();
      final Map<String, Object?> doc = jsonOf(exportOf(from));
      from.dispose();
      return doc;
    }

    List<Map<String, Object?>> of(Map<String, Object?> doc, String key) =>
        (doc[key]! as List<Object?>).cast<Map<String, Object?>>();

    test('malformed JSON', () {
      expect(issuesOf('{not json'), const <LedgerImportIssue>[
        LedgerImportIssue(r'$', 'json'),
      ]);
    });

    test('the wrong schema', () {
      final Map<String, Object?> doc = base()..['schema'] = 'lume.notes/1';
      expect(issuesOf(jsonEncode(doc)).single.reason, 'schema');
    });

    test('an unsupported future version', () {
      final Map<String, Object?> doc = base()..['exportVersion'] = 2;
      expect(issuesOf(jsonEncode(doc)).single.reason, 'unsupportedVersion');
    });

    test('duplicate ids', () {
      final Map<String, Object?> doc = base();
      final List<Map<String, Object?>> e = of(doc, 'entries');
      e[1]['id'] = e[0]['id'];
      expect(
        issuesOf(jsonEncode(doc)).map((LedgerImportIssue i) => i.reason),
        contains('duplicateId'),
      );
    });

    test('a dangling person', () {
      final Map<String, Object?> doc = base();
      of(doc, 'entries')[0]['partyId'] = '00000000-0000-4000-8000-000000000001';
      expect(
        issuesOf(jsonEncode(doc)).map((LedgerImportIssue i) => i.reason),
        contains('reference'),
      );
    });

    test('a dangling repayment or principal', () {
      final Map<String, Object?> doc = base();
      of(doc, 'allocations')[0]['principalId'] =
          '00000000-0000-4000-8000-000000000002';
      final List<LedgerImportIssue> issues = issuesOf(jsonEncode(doc));
      expect(
        issues.any(
          (LedgerImportIssue i) =>
              i.path.endsWith('.principalId') && i.reason == 'reference',
        ),
        isTrue,
      );
    });

    test('a currency mismatch', () {
      final Map<String, Object?> doc = base();
      of(doc, 'allocations')[0]['currency'] = 'USD';
      expect(
        issuesOf(jsonEncode(doc)).map((LedgerImportIssue i) => i.reason),
        contains('currency'),
      );
    });

    test('an allocation larger than its entries allow', () {
      final Map<String, Object?> doc = base();
      final Map<String, Object?> a = of(doc, 'allocations')[0];
      a['amountMinor'] = (a['amountMinor']! as int) + 100000000;
      expect(
        issuesOf(jsonEncode(doc)).map((LedgerImportIssue i) => i.reason),
        contains('damaged:overAllocated'),
      );
    });

    test('an amount past the bound', () {
      final Map<String, Object?> doc = base();
      of(doc, 'entries')[0]['amountMinor'] = LumeMoney.maxEntryMinor + 1;
      expect(
        issuesOf(jsonEncode(doc)).map((LedgerImportIssue i) => i.reason),
        contains('overflow'),
      );
    });

    test('invalid precision: a fractional minor unit', () {
      final Map<String, Object?> doc = base();
      of(doc, 'entries')[0]['amountMinor'] = 1000.5;
      final List<LedgerImportIssue> issues = issuesOf(jsonEncode(doc));
      // Listed where it is; what referred to that entry is listed too.
      expect(
        issues,
        contains(const LedgerImportIssue('entries[0].amountMinor', 'type')),
      );
    });

    test('a stale version against the destination', () {
      final LedgerHarness from = populated();
      final String doc = exportOf(from);
      final LedgerEntry e = from.book().entries.firstWhere(
        (LedgerEntry x) => x.active && x.kind == LedgerKind.lent,
      );
      from.repo.editEntry(
        e.id,
        LedgerEntryDraft(
          partyId: e.partyId,
          kind: e.kind,
          amount: e.amount,
          on: e.on,
          due: e.due,
          note: 'changed',
        ),
        version: e.version,
      );
      final LedgerImportReport r = check(from, doc);
      expect(
        r.issues.any(
          (LedgerImportIssue i) =>
              i.reason == 'conflict' && i.path.contains(e.id.value),
        ),
        isTrue,
      );
      from.dispose();
    });

    test(
      'a destination conflict: an id the Ledger holds with other content',
      () {
        final LedgerHarness from = populated();
        final Map<String, Object?> doc = jsonOf(exportOf(from));
        final Map<String, Object?> p = of(doc, 'parties')[0];
        p['name'] = 'Someone else';
        p['version'] = 7;
        final LedgerImportReport r = check(from, jsonEncode(doc));
        expect(
          r.issues.map((LedgerImportIssue i) => i.reason),
          contains('conflict'),
        );
        from.dispose();
      },
    );

    test('an invariant mismatch: unconfirmed credit', () {
      final Map<String, Object?> doc = base();
      for (final Map<String, Object?> e in of(doc, 'entries')) {
        e['excessConfirmed'] = false;
      }
      expect(
        issuesOf(jsonEncode(doc)).map((LedgerImportIssue i) => i.reason),
        contains('damaged:unconfirmedCredit'),
      );
    });

    test('every problem is listed, not only the first', () {
      final Map<String, Object?> doc = base();
      of(doc, 'entries')[0]['currency'] = 'XYZ';
      of(doc, 'entries')[1]['on'] = '2026-02-30';
      of(doc, 'parties')[0]['id'] = 'not-a-uuid';
      final List<LedgerImportIssue> issues = issuesOf(jsonEncode(doc));
      expect(
        issues.map((LedgerImportIssue i) => i.reason),
        containsAll(<String>['currency', 'date', 'uuid']),
      );
    });

    test('a failure during commit rolls everything back', () {
      final LedgerHarness from = populated();
      final LedgerHarness to = LedgerHarness(seed: 5);
      final LedgerImportReport r = check(to, exportOf(from));
      final String before = to.store.debugDump();
      to.store.publishFault = (LumeTxChange c, int i) {
        if (i == 5) throw StateError('disk full');
      };
      final LumeTxResult<int> applied = ledgerImportApply(r, to.store);
      expect(applied.failure!.kind, LumeTxFailureKind.storage);
      expect(to.store.debugDump(), before);
      expect(to.book().isEmpty, isTrue);
      from.dispose();
      to.dispose();
    });

    test('a redacted export imports with its labels as names', () {
      final LedgerHarness from = populated();
      final LedgerHarness to = LedgerHarness(seed: 5);
      final LedgerImportReport r = check(to, exportOf(from, private: false));
      expect(r.issues, isEmpty);
      expect(r.namesIncluded, isFalse);
      ledgerImportApply(r, to.store);
      expect(to.book().parties.map((LedgerParty p) => p.name).toSet(), <String>{
        'Person 1',
        'Person 2',
        'Person 3',
      });
      from.dispose();
      to.dispose();
    });
  });
}
