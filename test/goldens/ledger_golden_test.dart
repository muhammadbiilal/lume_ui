/// Lending Ledger, pinned and captured: the reference's composition in its
/// seven cells plus landscape, and every state the reader reaches — first
/// use, each filter, settled and archived, credit, mixed currencies, search
/// and no match, the forms and their failures, the sheets, Undo, the
/// reminder and its unavailable state, export redaction, the day-unknown
/// and damaged states, loading and a storage failure.
///
/// The populated cells also write a `.flutter.png` beside the browser's
/// `.web.png` in `docs/conversion_archive/shots/tools/tool_ledger_default_pk/`
/// for `compare.mjs`. The reference draws its three people from a fixture;
/// here the same three are entered through the repository as a reader would
/// (a test fixture — a reader's Ledger starts empty, D11).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/features/ledger/domain/ledger_model.dart';
import 'package:lume/features/ledger/presentation/ledger_sheets.dart';
import 'package:lume/features/ledger/presentation/ledger_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/records/domain/record_transaction.dart';

import '../features/ledger/ledger_screen_harness.dart';
import '../features/tax/tax_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';

const String kOut = '$kShotsDir/tools';

typedef Cell = (
  String name,
  Size size,
  ThemeMode theme,
  Locale locale,
  double scale,
);

const List<Cell> kCells = <Cell>[
  ('390x844_light_en', Size(390, 844), ThemeMode.light, Locale('en'), 1.0),
  ('390x844_dark_en', Size(390, 844), ThemeMode.dark, Locale('en'), 1.0),
  ('700x900_light_en', Size(700, 900), ThemeMode.light, Locale('en'), 1.0),
  ('1100x900_light_en', Size(1100, 900), ThemeMode.light, Locale('en'), 1.0),
  ('852x393_light_en', Size(852, 393), ThemeMode.light, Locale('en'), 1.0),
  ('390x844_light_ur', Size(390, 844), ThemeMode.light, Locale('ur'), 1.0),
  ('390x844_light_ar', Size(390, 844), ThemeMode.light, Locale('ar'), 1.0),
  ('390x844_light_en_x2', Size(390, 844), ThemeMode.light, Locale('en'), 2.0),
];

const Cell kPhone = (
  '390x844_light_en',
  Size(390, 844),
  ThemeMode.light,
  Locale('en'),
  1.0,
);

final LumeCurrency pkr = LumeCurrency.of('PKR');
LumeMoney rs(int rupees) => LumeMoney.entry(rupees * 100, pkr);

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  Future<void> shoot(
    WidgetTester tester, {
    required String golden,
    required Cell cell,
    required LedgerWorld world,
    LumeProfileRepository? profile,
    String query = '',
    List<Override> overrides = const <Override>[],
    Future<void> Function(WidgetTester tester)? after,
    bool compared = false,
  }) async {
    await captureLumeRoute(
      tester,
      location:
          '${LumeRoutes.tool(LumeRoutes.tools, 'ledger')}${query.isEmpty ? '' : '?$query'}',
      name: golden,
      outDir: compared ? kOut : 'build/ledger_shots',
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      profile: profile ?? taxProfile('default_pk'),
      overrides: <Override>[...world.overrides, ...overrides],
      after: after,
    );
    expect(find.byType(LumeToolFrame), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${golden}_${cell.$1}.png'),
    );
    world.dispose();
  }

  group('Ledger — the reference composition', () {
    for (final Cell cell in kCells) {
      testWidgets(cell.$1, (WidgetTester t) async {
        await shoot(
          t,
          golden: 'tool_ledger_default_pk',
          cell: cell,
          world: LedgerWorld().reference(),
          compared: true,
        );
      });
    }
  });

  group('Ledger — states', () {
    final Finder deleteButton = find.descendant(
      of: find.byKey(LedgerSheetKeys.confirm),
      matching: find.text('Delete'),
    );

    Future<void> state(
      WidgetTester t,
      String name,
      LedgerWorld world, {
      Future<void> Function(WidgetTester tester)? after,
      LumeProfileRepository? profile,
      String query = '',
      List<Override> overrides = const <Override>[],
      Cell cell = kPhone,
    }) => shoot(
      t,
      golden: 'tool_ledger_$name',
      cell: cell,
      world: world,
      profile: profile,
      query: query,
      overrides: overrides,
      after: after,
    );

    testWidgets('first use', (WidgetTester t) async {
      await state(t, 'empty', LedgerWorld());
    });

    testWidgets('first use, Urdu', (WidgetTester t) async {
      await state(
        t,
        'empty',
        LedgerWorld(),
        cell: (
          '390x844_light_ur',
          const Size(390, 844),
          ThemeMode.light,
          const Locale('ur'),
          1.0,
        ),
      );
    });

    for (final LedgerFilter f in <LedgerFilter>[
      LedgerFilter.owesYou,
      LedgerFilter.youOwe,
      LedgerFilter.overdue,
    ]) {
      testWidgets('filtered: ${f.name}', (WidgetTester t) async {
        await state(
          t,
          'filter-${f.name}',
          LedgerWorld().reference(),
          after: (WidgetTester t) =>
              tapShown(t, find.byKey(LumeLedgerTool.filterChip(f))),
        );
      });
    }

    testWidgets('a settled person, and an archived one under its switch', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.person('Omar');
      w.add('Omar', LedgerKind.lent, rs(500), LumeDate(2026, 8, 1));
      w.add('Omar', LedgerKind.repaidToMe, rs(500), LumeDate(2026, 8, 20));
      w.person('Hina');
      w.add('Hina', LedgerKind.lent, rs(900), LumeDate(2026, 6, 1));
      w.add('Hina', LedgerKind.repaidToMe, rs(900), LumeDate(2026, 6, 20));
      w.repo.setArchived(w.people['Hina']!, true, version: 1);
      await state(
        t,
        'settled-archived',
        w,
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeLedgerTool.archivedKey)),
      );
    });

    testWidgets('credit kept for a person', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.add(
        'Bilal',
        LedgerKind.repaidToMe,
        rs(17500),
        LumeDate(2026, 9, 5),
        confirm: true,
      );
      await state(t, 'credit', w);
    });

    testWidgets('mixed currencies: codes, one summary each, People once', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.add(
        'Ahmed',
        LedgerKind.lent,
        LumeMoney.entry(5000, LumeCurrency.of('USD')),
        LumeDate(2026, 8, 20),
      );
      await state(t, 'mixed', w);
    });

    testWidgets('search results', (WidgetTester t) async {
      await state(
        t,
        'search',
        LedgerWorld().reference(),
        after: (WidgetTester t) async {
          await t.enterText(find.byKey(LumeLedgerTool.searchKey), 'rent');
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('no results', (WidgetTester t) async {
      await state(
        t,
        'noresults',
        LedgerWorld().reference(),
        after: (WidgetTester t) async {
          await t.enterText(find.byKey(LumeLedgerTool.searchKey), 'zzz');
          await t.pumpAndSettle();
          await t.ensureVisible(find.byKey(LumeLedgerTool.noMatchKey));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('a person', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.add('Ahmed', LedgerKind.repaidToMe, rs(4000), LumeDate(2026, 8, 20));
      await state(t, 'person', w, query: 'person=${w.people['Ahmed']!.value}');
    });

    testWidgets('an entry and its allocations', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      final LedgerEntry r = w.add(
        'Ahmed',
        LedgerKind.repaidToMe,
        rs(4000),
        LumeDate(2026, 8, 20),
      );
      await state(
        t,
        'entry',
        w,
        query: 'person=${w.people['Ahmed']!.value}',
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeLedgerTool.historyRow(r.id.value))),
      );
    });

    Future<void> openForm(WidgetTester t) =>
        tapShown(t, find.byKey(LumeLedgerTool.addKey));

    testWidgets('validation failure', (WidgetTester t) async {
      await state(
        t,
        'form-invalid',
        LedgerWorld().reference(),
        after: (WidgetTester t) async {
          await openForm(t);
          await t.enterText(find.byKey(LumeLedgerTool.amountField), '12.345');
          await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
        },
      );
    });

    testWidgets('keyboard open on the form', (WidgetTester t) async {
      await state(
        t,
        'form-keyboard',
        LedgerWorld().reference(),
        after: (WidgetTester t) async {
          await openForm(t);
          await t.tap(find.byKey(LumeLedgerTool.amountField));
          t.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
          await t.pumpAndSettle();
        },
      );
      t.view.resetViewInsets();
    });

    testWidgets('allocation picker', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.add(
        'Ahmed',
        LedgerKind.lent,
        rs(6000),
        LumeDate(2026, 8, 25),
        due: LumeDate(2026, 10, 1),
      );
      await state(
        t,
        'allocation',
        w,
        query: 'person=${w.people['Ahmed']!.value}',
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeLedgerTool.personAddKey));
          await t.tap(find.text('Got back'));
          await t.pumpAndSettle();
          await tapShown(t, find.text('Choose'));
        },
      );
    });

    testWidgets('overpayment confirmation', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      await state(
        t,
        'overpayment',
        w,
        query: 'person=${w.people['Bilal']!.value}',
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeLedgerTool.personAddKey));
          await t.tap(find.text('Got back'));
          await t.pumpAndSettle();
          await t.enterText(find.byKey(LumeLedgerTool.amountField), '17500');
          await tapShown(t, find.byKey(LumeLedgerTool.saveKey));
        },
      );
    });

    testWidgets('deleting a paid loan asks what becomes of its repayment', (
      WidgetTester t,
    ) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.add('Ahmed', LedgerKind.repaidToMe, rs(4000), LumeDate(2026, 8, 20));
      final LedgerEntry loan = w.repo.view().entries.firstWhere(
        (LedgerEntry e) =>
            e.partyId == w.people['Ahmed'] && e.kind == LedgerKind.lent,
      );
      await state(
        t,
        'delete-orphans',
        w,
        query: 'person=${w.people['Ahmed']!.value}',
        after: (WidgetTester t) async {
          await tapShown(
            t,
            find.byKey(LumeLedgerTool.historyRow(loan.id.value)),
          );
          await tapShown(t, find.byKey(LumeLedgerTool.deleteKey));
          await tapShown(t, deleteButton);
        },
      );
    });

    testWidgets('Undo after a delete', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      final LedgerEntry r = w.add(
        'Ahmed',
        LedgerKind.repaidToMe,
        rs(4000),
        LumeDate(2026, 8, 20),
      );
      await state(
        t,
        'undo',
        w,
        query: 'person=${w.people['Ahmed']!.value}',
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeLedgerTool.historyRow(r.id.value)));
          await tapShown(t, find.byKey(LumeLedgerTool.deleteKey));
          await t.tap(deleteButton);
          await t.pump();
          await t.pump(const Duration(milliseconds: 400));
        },
      );
    });

    testWidgets('reminder preview', (WidgetTester t) async {
      await state(
        t,
        'reminder',
        LedgerWorld().reference(),
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeLedgerTool.remindKey));
          await tapShown(
            t,
            find.byWidgetPredicate(
              (Widget w) =>
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith(
                    'ledger.remind.',
                  ) &&
                  (w.key! as ValueKey<String>).value.endsWith('.PKR'),
            ),
          );
        },
      );
    });

    testWidgets('sharing unavailable', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.sharer.outcome = LumeShareOutcome.unavailable;
      await state(
        t,
        'reminder-unavailable',
        w,
        query: 'person=${w.people['Bilal']!.value}',
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeLedgerTool.personRemindKey));
          await tapShown(t, find.byKey(LedgerSheetKeys.reminderShare));
        },
      );
    });

    testWidgets('export with names left out', (WidgetTester t) async {
      await state(
        t,
        'export',
        LedgerWorld().reference(),
        after: (WidgetTester t) => tapShown(t, find.bySemanticsLabel('Export')),
      );
    });

    testWidgets('day unknown: a region with several zones and no city', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'dayunknown',
        LedgerWorld().reference(),
        profile: LumeMemoryProfileRepository(
          initial: taxReader(country: 'US', region: 'New York', city: ''),
        ),
        after: (WidgetTester t) => tapShown(
          t,
          find.byKey(LumeLedgerTool.filterChip(LedgerFilter.overdue)),
        ),
      );
    });

    testWidgets('a damaged scope', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld().reference();
      w.add('Ahmed', LedgerKind.repaidToMe, rs(4000), LumeDate(2026, 8, 20));
      // An allocation left from an older reconciliation, as a store could
      // hold after a failed migration: shown, never silently rebuilt.
      final LumeRecord a = w.store
          .view(LedgerCollections.allocations)
          .items
          .single;
      w.store.run<void>((LumeRecordTx tx) {
        tx.insert(
          LedgerCollections.allocations,
          LumeRecord(
            id: '00000000-0000-4000-8000-00000000d0d0',
            fields: <String, Object?>{...a.fields, 'scopeRevision': 1},
            version: 1,
            createdAt: a.createdAt,
            updatedAt: a.createdAt,
          ),
        );
        tx.update(LedgerCollections.allocations, a.id, <String, Object?>{
          ...a.fields,
          'scopeRevision': 2,
        }, expectVersion: a.version);
      });
      await state(t, 'damaged', w, query: 'person=${w.people['Ahmed']!.value}');
    });

    testWidgets('loading: the first read, still under way', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'loading',
        LedgerWorld(readDelay: const Duration(hours: 1)),
      );
    });

    testWidgets('a storage failure reading the Ledger', (WidgetTester t) async {
      final LedgerWorld w = LedgerWorld();
      w.store.retry(LedgerCollections.entries);
      w.store.unreadable.add(LedgerCollections.entries);
      w.store.retry(LedgerCollections.entries);
      await state(t, 'storage-failure', w);
    });
  });
}
