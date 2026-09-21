/// Baby Budget out and in (`BABY_BUDGET_PROPOSAL.md` §12): lossless JSON
/// that keeps a child's name to itself by default, an import that is all
/// or nothing and names every problem, and a CSV that says plainly it
/// cannot come back.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/babybudget/domain/babybudget_book.dart';
import 'package:lume/features/babybudget/domain/babybudget_model.dart';
import 'package:lume/features/babybudget/domain/babybudget_repository.dart';
import 'package:lume/features/babybudget/domain/babybudget_transfer.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

import 'babybudget_harness.dart';

/// The document for everything the harness holds.
String exportOf(BabyBudgetHarness h, {bool includeNames = false}) {
  final BabyBudgetSnapshot s = h.repo.view();
  return babyBudgetExportJson(
    budgets: s.budgets,
    categories: s.categories,
    spends: s.spends,
    exportedAt: DateTime.utc(2026, 9, 21, 12),
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
  late BabyBudgetHarness h;

  setUp(() {
    h = BabyBudgetHarness();
  });
  tearDown(() => h.dispose());

  group('export', () {
    test('names, notes and labels are left out unless the reader asks for '
        'them', () {
      final BabyBudget b = h
          .tryAdd(name: 'Ayaan', note: 'Second baby')
          .value!
          .budget!;
      expect(
        h.spend(b.id, 1200, category: 'Clothing', label: 'Winter suit').failure,
        isNull,
      );

      final Map<String, Object?> doc = parse(exportOf(h));
      expect(doc['namesIncluded'], isFalse);
      final Map<String, Object?> budget = rows(doc, 'budgets').single;
      expect(budget['label'], 'Budget 1');
      expect(budget.containsKey('name'), isFalse);
      expect(budget.containsKey('note'), isFalse);
      expect(
        rows(doc, 'categories').map((Map<String, Object?> m) => m['label']),
        containsAll(<String>['Category 1', 'Category 2']),
      );
      expect(
        rows(
          doc,
          'categories',
        ).every((Map<String, Object?> m) => !m.containsKey('name')),
        isTrue,
      );
      expect(rows(doc, 'spends').single.containsKey('label'), isFalse);
      expect(exportOf(h), isNot(contains('Ayaan')));
      expect(exportOf(h), isNot(contains('Second baby')));
      expect(exportOf(h), isNot(contains('Winter suit')));
      expect(exportOf(h), isNot(contains('Nappies')));

      final Map<String, Object?> full = parse(exportOf(h, includeNames: true));
      expect(full['namesIncluded'], isTrue);
      expect(rows(full, 'budgets').single['name'], 'Ayaan');
      expect(rows(full, 'budgets').single['note'], 'Second baby');
      expect(
        rows(full, 'categories').map((Map<String, Object?> m) => m['name']),
        containsAll(kCategoryNames),
      );
      expect(rows(full, 'spends').single['label'], 'Winter suit');
    });

    test('every record, with its id, version, instant and stored day', () {
      final BabyBudget b = h.referenceMonth();
      final Map<String, Object?> doc = parse(exportOf(h));
      expect(doc['schema'], 'lume.babybudget/1');
      expect(doc['exportVersion'], 1);
      expect(
        (doc['source']! as Map<String, Object?>)['store'],
        'memory',
        reason: 'this build is not durable, and says so',
      );
      expect(rows(doc, 'budgets'), hasLength(1));
      expect(rows(doc, 'categories'), hasLength(4));
      expect(rows(doc, 'spends'), hasLength(4));

      final Map<String, Object?> budget = rows(doc, 'budgets').single;
      expect(budget['id'], b.id.value);
      expect(budget['currency'], 'PKR');
      expect(budget['planMinor'], 3900000);
      expect(budget['startedOn'], '2026-01-01');
      expect(budget['version'], 1);
      expect(budget.containsKey('archivedOn'), isFalse);
      // Nothing derived is written: no month, no ratio, no share.
      expect(budget.containsKey('spentToDate'), isFalse);
      expect(budget.containsKey('ratio'), isFalse);

      final List<Map<String, Object?>> categories = rows(doc, 'categories');
      expect(
        categories.map((Map<String, Object?> m) => m['order']),
        <int>[0, 1, 2, 3],
        reason: 'the reader\'s own order',
      );
      expect(categories.first['colour'], 0);
      expect(categories.first.containsKey('planMinor'), isFalse);

      final Map<String, Object?> spend = rows(doc, 'spends').last;
      expect(spend['amountMinor'], 1200000);
      expect(spend['currency'], 'PKR');
      expect(spend['planned'], isFalse);
      expect(spend['spentOn'], '2026-09-03');
      expect(spend.containsKey('expectedOn'), isFalse);
      expect(spend['state'], 'active');
    });

    test('a planned purchase carries the day it is expected and no day it '
        'went; an archived budget carries the day it was put away', () {
      final BabyBudget b = h.add();
      expect(h.plan(b.id, 4000, expectedOn: d(10, 2)).failure, isNull);
      expect(
        h.repo
            .setArchived(
              b.id,
              true,
              on: d(9, 20),
              today: kToday,
              version: h.view(b.id).budget.version,
            )
            .failure,
        isNull,
      );
      final Map<String, Object?> doc = parse(exportOf(h));
      expect(rows(doc, 'budgets').single['archivedOn'], '2026-09-20');
      final Map<String, Object?> spend = rows(doc, 'spends').single;
      expect(spend['planned'], isTrue);
      expect(spend['expectedOn'], '2026-10-02');
      expect(spend.containsKey('spentOn'), isFalse);
      expect(spend.containsKey('categoryId'), isFalse);
    });
  });

  group('import', () {
    test('a whole budget moves to an empty store, ids and versions '
        'intact', () {
      final BabyBudget b = h.referenceMonth();
      expect(
        h.plan(b.id, 6000, category: 'Health', expectedOn: d(10, 5)).failure,
        isNull,
      );
      final String document = exportOf(h, includeNames: true);
      final String before = h.records();

      final BabyBudgetHarness to = BabyBudgetHarness(seed: 9);
      final BabyBudgetImportReport report = babyBudgetImportCheck(
        document,
        to.store,
      );
      expect(report.issues, isEmpty);
      expect(
        report.create,
        10,
        reason: '1 budget, 4 categories, 4 spends and 1 planned purchase',
      );
      expect(report.update, 0);
      expect(report.unchanged, 0);
      final LumeTxResult<int> applied = babyBudgetImportApply(report, to.store);
      expect(applied.ok, isTrue);
      expect(applied.value, 10);
      expect(to.records(), before, reason: 'byte for byte');

      final BabyBudgetView v = to.view(b.id);
      expect(v.name, 'The baby');
      expect(v.spentToDate.minor, 3200000);
      expect(v.plannedTotal.minor, 600000);
      expect(v.categories.map((BabyCategory c) => c.name), kCategoryNames);
      to.expectSound();
      to.dispose();
    });

    test('importing the same document twice changes nothing the second '
        'time', () {
      h.referenceMonth();
      final String document = exportOf(h);
      final BabyBudgetHarness to = BabyBudgetHarness(seed: 9);
      babyBudgetImportApply(
        babyBudgetImportCheck(document, to.store),
        to.store,
      );
      final String once = to.records();

      final BabyBudgetImportReport again = babyBudgetImportCheck(
        document,
        to.store,
      );
      expect(again.issues, isEmpty);
      expect(again.create, 0);
      expect(again.update, 0);
      expect(again.unchanged, 9);
      expect(again.records, isEmpty);
      expect(to.records(), once);
      to.dispose();
    });

    test('a document that is not this schema, or a newer version, is '
        'refused whole', () {
      expect(
        babyBudgetImportCheck('not json', h.store).issues.single.reason,
        'json',
      );
      expect(
        babyBudgetImportCheck(
          '{"schema":"lume.ledger/1"}',
          h.store,
        ).issues.single.path,
        r'$.schema',
      );
      expect(
        babyBudgetImportCheck(
          '{"schema":"lume.babybudget/1","exportVersion":2}',
          h.store,
        ).issues.single.reason,
        'unsupportedVersion',
      );
    });

    test('a spend naming another budget\'s category is refused by path, and '
        'nothing is written', () {
      final BabyBudget mine = h.add(name: 'Ayaan');
      final BabyBudget other = h.add(name: 'Hana');
      expect(h.spend(mine.id, 2500, category: 'Health').failure, isNull);
      final Map<String, Object?> doc = parse(exportOf(h));
      final Map<String, Object?> spend = rows(doc, 'spends').single;
      spend['categoryId'] = h.category(other.id, 'Health').id.value;

      final BabyBudgetHarness to = BabyBudgetHarness(seed: 9);
      final String before = to.records();
      final BabyBudgetImportReport report = babyBudgetImportCheck(
        jsonEncode(doc),
        to.store,
      );
      expect(
        report.issues,
        contains(
          BabyBudgetImportIssue('spends.${spend['id']}.categoryId', 'budget'),
        ),
      );
      expect(babyBudgetImportApply(report, to.store).ok, isFalse);
      expect(to.records(), before, reason: 'the store is exactly as it was');
      expect(to.recordLines(), isEmpty);
      to.dispose();
    });

    test('a category whose budget is absent is a reference problem', () {
      h.add();
      final Map<String, Object?> doc = parse(exportOf(h));
      final Map<String, Object?> category = rows(doc, 'categories').first;
      category['budgetId'] = LumeRecordId.generate().value;

      final BabyBudgetHarness to = BabyBudgetHarness(seed: 9);
      final BabyBudgetImportReport report = babyBudgetImportCheck(
        jsonEncode(doc),
        to.store,
      );
      expect(
        report.issues,
        contains(
          BabyBudgetImportIssue(
            'categories.${category['id']}.budgetId',
            'reference',
          ),
        ),
      );
      expect(to.recordLines(), isEmpty);
      to.dispose();
    });

    test('a spend that is both planned and spent is refused, and nothing '
        'is written', () {
      final BabyBudget b = h.add();
      expect(
        h.plan(b.id, 4000, category: 'Clothing', expectedOn: d(10, 2)).failure,
        isNull,
      );
      final Map<String, Object?> doc = parse(exportOf(h));
      rows(doc, 'spends').single['spentOn'] = '2026-10-02';

      final BabyBudgetHarness to = BabyBudgetHarness(seed: 9);
      final String before = to.records();
      final BabyBudgetImportReport report = babyBudgetImportCheck(
        jsonEncode(doc),
        to.store,
      );
      expect(
        report.issues,
        contains(const BabyBudgetImportIssue('spends[0].spentOn', 'planned')),
      );
      expect(babyBudgetImportApply(report, to.store).ok, isFalse);
      expect(to.records(), before);
      to.dispose();
    });

    test('a category plan with no budget plan, and category plans over the '
        'budget plan, are each damage', () {
      final BabyBudget b = h.add(
        categories: <BabyCategoryDraft>[
          BabyCategoryDraft(name: 'Nappies', monthlyPlan: rs(10000)),
          BabyCategoryDraft(name: 'Formula', monthlyPlan: rs(8000), colour: 1),
        ],
      );
      final String document = exportOf(h);

      final Map<String, Object?> unplanned = parse(document);
      rows(unplanned, 'budgets').single.remove('planMinor');
      final BabyBudgetHarness to = BabyBudgetHarness(seed: 9);
      expect(
        babyBudgetImportCheck(jsonEncode(unplanned), to.store).issues,
        contains(
          BabyBudgetImportIssue(
            'budgets.${b.id.value}',
            'damaged:categoryPlanWithoutBudgetPlan',
          ),
        ),
      );

      final Map<String, Object?> over = parse(document);
      for (final Map<String, Object?> c in rows(over, 'categories')) {
        c['planMinor'] = 3000000;
      }
      expect(
        babyBudgetImportCheck(jsonEncode(over), to.store).issues,
        contains(
          BabyBudgetImportIssue(
            'budgets.${b.id.value}',
            'damaged:categoryPlanSum',
          ),
        ),
      );
      expect(to.recordLines(), isEmpty);
      to.dispose();
    });

    test('a record dated before the budget\'s first day is damage', () {
      final BabyBudget b = h.referenceMonth();
      final Map<String, Object?> doc = parse(exportOf(h));
      rows(doc, 'budgets').single['startedOn'] = '2026-09-10';

      final BabyBudgetHarness to = BabyBudgetHarness(seed: 9);
      final BabyBudgetImportReport report = babyBudgetImportCheck(
        jsonEncode(doc),
        to.store,
      );
      expect(
        report.issues,
        contains(
          BabyBudgetImportIssue('budgets.${b.id.value}', 'damaged:beforeStart'),
        ),
      );
      expect(babyBudgetImportApply(report, to.store).ok, isFalse);
      expect(to.recordLines(), isEmpty);
      to.dispose();
    });

    test('a duplicate id, a bad uuid and a wrong instant are each named', () {
      h.add();
      final Map<String, Object?> doc = parse(exportOf(h));
      final List<Map<String, Object?>> categories = rows(doc, 'categories');
      categories[1]['id'] = categories[0]['id'];
      categories[2]['id'] = 'not-a-uuid';
      categories[3]['createdAt'] = '2026-09-21 10:00';
      final List<BabyBudgetImportIssue> issues = babyBudgetImportCheck(
        jsonEncode(doc),
        h.store,
      ).issues;
      expect(
        issues.map((BabyBudgetImportIssue i) => i.reason),
        containsAll(<String>['duplicateId', 'uuid', 'instant']),
      );
    });

    test('a record held at another version is a conflict, not an '
        'overwrite', () {
      final BabyBudget b = h.add(name: 'Ayaan');
      final String document = exportOf(h, includeNames: true);
      expect(
        h.repo
            .editBudget(
              b.id,
              name: 'Renamed',
              version: h.view(b.id).budget.version,
            )
            .failure,
        isNull,
      );
      final BabyBudgetImportReport report = babyBudgetImportCheck(
        document,
        h.store,
      );
      expect(
        report.issues,
        contains(BabyBudgetImportIssue('budgets.${b.id.value}', 'conflict')),
      );
      expect(babyBudgetImportApply(report, h.store).ok, isFalse);
      expect(h.view(b.id).name, 'Renamed');
    });

    test('a failure part-way through applying writes none of it', () {
      h.referenceMonth();
      final String document = exportOf(h);
      final BabyBudgetHarness to = BabyBudgetHarness(seed: 9);
      final String before = to.records();
      to.store.publishFault = (_, int i) {
        if (i == 5) throw StateError('disk');
      };
      final LumeTxResult<int> r = babyBudgetImportApply(
        babyBudgetImportCheck(document, to.store),
        to.store,
      );
      to.store.publishFault = null;
      expect(r.ok, isFalse);
      expect(to.records(), before);
      expect(to.recordLines(), isEmpty);
      to.dispose();
    });
  });

  group('CSV', () {
    test('one row per spend, planned and recorded alike, with a BOM and '
        'CRLF', () {
      final BabyBudget b = h.referenceMonth();
      expect(
        h.plan(b.id, 6000, category: 'Health', expectedOn: d(10, 5)).failure,
        isNull,
      );
      final String csv = babyBudgetExportCsv(h.book());
      expect(csv.codeUnitAt(0), 0xFEFF);
      final List<String> lines = csv.split('\r\n')
        ..removeWhere((String l) => l.isEmpty);
      expect(lines, hasLength(6), reason: 'a heading and 5 rows');
      expect(lines.first.substring(1), kBabyBudgetCsvColumns.join(','));

      // The planned purchase is expected on 5 October, so it heads the
      // list; the recorded spends follow, newest first.
      final List<String> planned = lines[1].split(',');
      expect(planned[1], 'Budget 1');
      expect(planned[2], 'inUse');
      expect(planned[3], 'PKR');
      expect(planned[5], 'Category 4');
      expect(planned[8], 'yes', reason: 'planned');
      expect(planned[9], '2026-10-05');
      expect(planned[10], '600000', reason: 'the amount in minor units');
      expect(planned[11], '6000.00');
      expect(planned[12], 'active');

      final List<String> last = lines.last.split(',');
      expect(
        last[5],
        'Category 1',
        reason: 'the first category the reader made',
      );
      expect(last[8], 'no');
      expect(last[9], '2026-09-03');
      expect(last[10], '1200000');
    });

    test('names and labels are left out unless asked for, and a comma is '
        'quoted', () {
      final BabyBudget b = h.add(name: 'Ayaan, the second');
      expect(
        h.spend(b.id, 1200, category: 'Clothing', label: 'Winter suit').failure,
        isNull,
      );
      final String csv = babyBudgetExportCsv(h.book());
      expect(csv, isNot(contains('Ayaan')));
      expect(csv, isNot(contains('Winter suit')));
      expect(csv, isNot(contains('Clothing')));
      expect(csv, contains('Budget 1'));
      expect(csv, contains('Category 3'));

      final String named = babyBudgetExportCsv(h.book(), includeNames: true);
      expect(named, contains('"Ayaan, the second"'));
      expect(named, contains('Winter suit'));
      expect(named, contains('Clothing'));
    });

    test('CSV is not a document this tool will read back', () {
      h.referenceMonth();
      final String csv = babyBudgetExportCsv(h.book());
      expect(babyBudgetImportCheck(csv, h.store).issues.single.reason, 'json');
    });
  });
}
