/// Installments out and in: lossless `lume.installments/1` JSON with names
/// left out by default, all-or-nothing import that lists every problem by a
/// stable path, and a CSV view that cannot come back in
/// (`INSTALLMENTS_PROPOSAL.md` §40.13).
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/installments/domain/installments_book.dart';
import 'package:lume/features/installments/domain/installments_model.dart';
import 'package:lume/features/installments/domain/installments_repository.dart';
import 'package:lume/features/installments/domain/installments_transfer.dart';
import 'package:lume/features/records/domain/record_model.dart';

import 'installments_harness.dart';

/// Each record as the file carries it: collection, id, fields, version and
/// creation instant.
List<String> content(InstallmentsHarness h) => <String>[
  for (final String c in InstallmentsCollections.all)
    for (final LumeRecord r in h.store.view(c).items)
      '$c ${r.id} v${r.version} ${r.createdAt.toIso8601String()} '
          '${jsonEncode(<String, Object?>{for (final String k in r.fields.keys.toList()..sort())
            if (r.fields[k] != null) k: r.fields[k]})}',
]..sort();

String export(InstallmentsHarness h, {bool names = false}) {
  final InstallmentsSnapshot s = h.repo.view();
  return installmentsExportJson(
    plans: s.plans,
    schedule: s.schedule,
    payments: s.payments,
    exportedAt: DateTime.utc(2026, 9, 7, 12),
    build: 'test',
    durable: false,
    includeNames: names,
  );
}

/// Two plans in two currencies, one with a deposit and a cash price, one
/// paid, one payment voided, one plan cancelled.
InstallmentsHarness world() {
  final InstallmentsHarness h = InstallmentsHarness();
  final InstallmentPlan a = h.add(
    item: 'Laptop',
    merchant: 'TechMart',
    note: 'For work',
    deposit: rs(5000),
    depositOn: d(3, 30),
    cashPrice: rs(110000),
  );
  final InstallmentPlan b = h.add(
    item: 'Phone',
    merchant: 'Mobile Hub',
    amount: dollars(48),
    count: 18,
    firstDue: d(6, 27),
  );
  h.payNext(a.id, 3);
  h.payNext(b.id, 2);
  final InstallmentPayment v = h.plan(b.id).payments.first;
  h.repo.setPaymentVoided(v.id, true, version: v.version);
  h.repo.setCancelled(b.id, true, version: b.version);
  return h;
}

void main() {
  test('names are left out unless the reader includes them', () {
    final InstallmentsHarness h = world();
    final String doc = export(h);
    expect(doc, isNot(contains('Laptop')));
    expect(doc, isNot(contains('TechMart')));
    expect(doc, isNot(contains('For work')));
    expect(doc, contains('"label": "Plan 1"'));
    final String named = export(h, names: true);
    expect(named, contains('"item": "Laptop"'));
    expect(named, contains('"merchant": "TechMart"'));
    expect(named, contains('"note": "For work"'));
    h.dispose();
  });

  test('lossless: ids, versions, minor units, the anchor, due dates, '
      'states and instants round-trip exactly', () {
    final InstallmentsHarness h = world();
    final String doc = export(h, names: true);
    final Map<String, Object?> json = jsonDecode(doc) as Map<String, Object?>;
    expect(json['schema'], kInstallmentsSchema);
    final Map<String, Object?> plan =
        (json['plans']! as List<Object?>).first! as Map<String, Object?>;
    expect(
      plan.keys,
      containsAll(<String>[
        'id',
        'currency',
        'amountMinor',
        'count',
        'frequency',
        'firstDue',
        'state',
        'createdAt',
        'version',
      ]),
    );

    final InstallmentsHarness fresh = InstallmentsHarness(seed: 9);
    final InstallmentsImportReport r = installmentsImportCheck(
      doc,
      fresh.store,
    );
    expect(r.issues, isEmpty);
    expect(r.create, 2 + 12 + 18 + 3 + 2);
    expect(installmentsImportApply(r, fresh.store).ok, isTrue);
    // Every record: its id, its fields, its version and when it was made.
    // (When it was last updated is the store's, not the file's.)
    expect(content(fresh), content(h));
    fresh.expectSound();
    h.dispose();
    fresh.dispose();
  });

  test('a file without names comes in as numbered plans', () {
    final InstallmentsHarness h = world();
    final InstallmentsHarness fresh = InstallmentsHarness(seed: 9);
    final InstallmentsImportReport r = installmentsImportCheck(
      export(h),
      fresh.store,
    );
    expect(r.ok, isTrue);
    expect(r.namesIncluded, isFalse);
    installmentsImportApply(r, fresh.store);
    expect(
      fresh.book().plans.map((InstallmentPlanView v) => v.plan.item).toSet(),
      <String>{'Plan 1', 'Plan 2'},
    );
    h.dispose();
    fresh.dispose();
  });

  group('all or nothing', () {
    Map<String, Object?> doc(InstallmentsHarness h) =>
        jsonDecode(export(h, names: true)) as Map<String, Object?>;

    void expectNothingWritten(InstallmentsHarness into, String text) {
      final String before = into.records();
      final InstallmentsImportReport r = installmentsImportCheck(
        text,
        into.store,
      );
      expect(r.ok, isFalse);
      expect(installmentsImportApply(r, into.store).ok, isFalse);
      expect(into.records(), before);
    }

    test('a payment naming an instalment that is not there', () {
      final InstallmentsHarness h = world();
      final Map<String, Object?> j = doc(h);
      final Map<String, Object?> p =
          (j['payments']! as List<Object?>).first! as Map<String, Object?>;
      p['installmentId'] = '00000000-0000-4000-8000-000000000001';
      final InstallmentsHarness fresh = InstallmentsHarness(seed: 9);
      final InstallmentsImportReport r = installmentsImportCheck(
        jsonEncode(j),
        fresh.store,
      );
      expect(
        r.issues,
        contains(
          InstallmentsImportIssue(
            'payments.${p['id']}.installmentId',
            'reference',
          ),
        ),
      );
      expectNothingWritten(fresh, jsonEncode(j));
      h.dispose();
      fresh.dispose();
    });

    test('every problem, by a stable path — nothing repaired', () {
      final InstallmentsHarness h = world();
      final Map<String, Object?> j = doc(h);
      final List<Object?> plans = j['plans']! as List<Object?>;
      (plans[0]! as Map<String, Object?>)['frequency'] = 'weekly';
      (plans[1]! as Map<String, Object?>)['amountMinor'] = 1.5;
      final List<Object?> rows = j['schedule']! as List<Object?>;
      rows.removeLast(); // a plan short of one instalment
      final InstallmentsHarness fresh = InstallmentsHarness(seed: 9);
      final InstallmentsImportReport r = installmentsImportCheck(
        jsonEncode(j),
        fresh.store,
      );
      expect(
        r.issues,
        contains(
          const InstallmentsImportIssue('plans[0].frequency', 'unsupported'),
        ),
      );
      expect(
        r.issues,
        contains(const InstallmentsImportIssue('plans[1].amountMinor', 'type')),
      );
      expectNothingWritten(fresh, jsonEncode(j));
      h.dispose();
      fresh.dispose();
    });

    test('a schedule that does not add up is refused', () {
      final InstallmentsHarness h = world();
      final Map<String, Object?> j = doc(h);
      final List<Object?> rows = j['schedule']! as List<Object?>;
      rows.removeLast();
      final InstallmentsHarness fresh = InstallmentsHarness(seed: 9);
      final InstallmentsImportReport r = installmentsImportCheck(
        jsonEncode(j),
        fresh.store,
      );
      expect(
        r.issues.map((InstallmentsImportIssue i) => i.reason),
        contains('damaged:rowCount'),
      );
      expectNothingWritten(fresh, jsonEncode(j));
      h.dispose();
      fresh.dispose();
    });

    test('the same id at another version is a conflict', () {
      final InstallmentsHarness h = world();
      final String text = export(h, names: true);
      // Import into the same store after one more write.
      final InstallmentPlanView v = h.book().plans.first;
      h.repo.editPlan(
        v.plan.id,
        InstallmentPlanDraft(
          item: 'Renamed',
          amount: v.plan.amount,
          count: v.plan.count,
          firstDue: v.plan.firstDue,
          deposit: v.plan.deposit,
          depositOn: v.plan.depositOn,
          cashPrice: v.plan.cashPrice,
        ),
        version: v.plan.version,
      );
      final InstallmentsImportReport r = installmentsImportCheck(text, h.store);
      expect(
        r.issues,
        contains(
          InstallmentsImportIssue('plans.${v.plan.id.value}', 'conflict'),
        ),
      );
      expectNothingWritten(h, text);
      h.dispose();
    });

    test('wrong schema, newer version, not JSON', () {
      final InstallmentsHarness h = InstallmentsHarness();
      expect(
        installmentsImportCheck('{"schema":"lume.ledger/1"}', h.store).issues,
        <InstallmentsImportIssue>[
          const InstallmentsImportIssue(r'$.schema', 'schema'),
        ],
      );
      expect(
        installmentsImportCheck(
          '{"schema":"$kInstallmentsSchema","exportVersion":2}',
          h.store,
        ).issues.single.reason,
        'unsupportedVersion',
      );
      expect(
        installmentsImportCheck('not json', h.store).issues.single.reason,
        'json',
      );
      h.dispose();
    });
  });

  test('CSV: one row per instalment, names left out, and it cannot be '
      'imported', () {
    final InstallmentsHarness h = world();
    final String csv = installmentsExportCsv(h.book());
    final List<String> lines = csv.split('\r\n')..removeLast();
    expect(lines.first, '\uFEFF${kInstallmentsCsvColumns.join(',')}');
    expect(lines, hasLength(1 + 12 + 18));
    expect(csv, isNot(contains('Laptop')));
    expect(csv, contains('Plan 1'));
    expect(installmentsImportCheck(csv, h.store).issues.single.reason, 'json');
    // Its rows agree with the book.
    expect(
      lines.where((String l) => l.contains(',yes,')).length,
      3 + 1, // three paid, and one of two after the void
    );
    h.dispose();
  });

  test('export and import leave the schedule\'s stored dates alone', () {
    final InstallmentsHarness h = InstallmentsHarness();
    h.add(firstDue: LumeDate(2026, 1, 31), count: 3);
    final InstallmentsHarness fresh = InstallmentsHarness(seed: 9);
    installmentsImportApply(
      installmentsImportCheck(export(h), fresh.store),
      fresh.store,
    );
    expect(
      fresh.book().plans.single.rows.map((InstallmentRow r) => r.row.due),
      <LumeDate>[
        LumeDate(2026, 1, 31),
        LumeDate(2026, 2, 28),
        LumeDate(2026, 3, 31),
      ],
    );
    h.dispose();
    fresh.dispose();
  });
}
