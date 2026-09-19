/// Installments, pinned and captured: the reference's composition in its
/// eight cells, and every state the reader reaches — first use, each
/// filter, late, completed and cancelled plans, mixed currencies, no match,
/// the form with its validation and the keyboard open, a plan's detail, the
/// payment sheet, locked terms, the cancel and delete confirmations, Undo,
/// export and the import check, the day-unavailable and damaged states,
/// loading and a storage failure.
///
/// The composition cells also write a `.flutter.png` beside the browser's
/// `.web.png` in
/// `docs/conversion_archive/shots/tools/tool_installments_default_pk/` for
/// `compare.mjs`, sorted as the reference sorts by default (payments left,
/// ascending). The reference draws its three plans from a fixture; here the
/// same three are entered through the repository as a reader would — a
/// test fixture; a reader's Installments starts empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/features/installments/domain/installments_model.dart';
import 'package:lume/features/installments/presentation/installments_sheets.dart';
import 'package:lume/features/installments/presentation/installments_tool.dart';
import 'package:lume/features/installments/presentation/installments_transfer_sheets.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/domain/record_transaction.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../features/installments/installments_screen_harness.dart';
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
    required InstallmentsWorld world,
    LumeProfileRepository? profile,
    String query = '',
    List<Override> overrides = const <Override>[],
    Future<void> Function(WidgetTester tester)? after,
    bool compared = false,
  }) async {
    await captureLumeRoute(
      tester,
      location:
          '${LumeRoutes.tool(LumeRoutes.tools, 'installments')}${query.isEmpty ? '' : '?$query'}',
      name: golden,
      outDir: compared ? kOut : 'build/installments_shots',
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

  /// The reference's default order: payments left, ascending. A newly
  /// chosen sort starts descending, so it takes two presses.
  Future<void> Function(WidgetTester) referenceSort(Locale locale) =>
      (WidgetTester t) async {
        final String label = lookupAppLocalizations(locale).instSortLeft;
        for (int i = 0; i < 2; i++) {
          await tapShown(
            t,
            find.descendant(
              of: find.byKey(LumeInstallmentsTool.sortKey),
              matching: find.text(label),
            ),
          );
        }
        // Back to the top, where the browser's capture was taken.
        for (final ScrollableState x in t.stateList<ScrollableState>(
          find.byType(Scrollable),
        )) {
          if (x.position.axis == Axis.vertical && x.position.pixels > 0) {
            x.position.jumpTo(0);
          }
        }
        await t.pumpAndSettle();
      };

  group('Installments — the reference composition', () {
    for (final Cell cell in kCells) {
      testWidgets(cell.$1, (WidgetTester t) async {
        await shoot(
          t,
          golden: 'tool_installments_default_pk',
          cell: cell,
          world: InstallmentsWorld().reference(),
          after: referenceSort(cell.$4),
          compared: true,
        );
      });
    }
  });

  group('Installments — states', () {
    Future<void> state(
      WidgetTester t,
      String name,
      InstallmentsWorld world, {
      Future<void> Function(WidgetTester tester)? after,
      LumeProfileRepository? profile,
      String query = '',
      Cell cell = kPhone,
    }) => shoot(
      t,
      golden: 'tool_installments_$name',
      cell: cell,
      world: world,
      profile: profile,
      query: query,
      after: after,
    );

    InstallmentsWorld busy() {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      // Late: two unpaid instalments before 7 September.
      w.add('Bike', rs(5000), 6, LumeDate(2026, 8, 1), merchant: 'Wheels');
      // Completed.
      w.add('Blender', rs(2500), 3, LumeDate(2026, 5, 10), merchant: 'Kitchen');
      w.pay('Blender', 3);
      // Cancelled, with its history kept.
      final InstallmentPlan tv = w.add(
        'TV',
        rs(12000),
        10,
        LumeDate(2026, 3, 5),
        merchant: 'Screens',
      );
      w.pay('TV', 4);
      w.repo.setCancelled(tv.id, true, version: tv.version);
      return w;
    }

    testWidgets('first use', (WidgetTester t) async {
      await state(t, 'empty', InstallmentsWorld());
    });

    testWidgets('first use, Urdu', (WidgetTester t) async {
      await state(
        t,
        'empty',
        InstallmentsWorld(),
        cell: (
          '390x844_light_ur',
          const Size(390, 844),
          ThemeMode.light,
          const Locale('ur'),
          1.0,
        ),
      );
    });

    for (final InstallmentsFilter f in <InstallmentsFilter>[
      InstallmentsFilter.late,
      InstallmentsFilter.completed,
      InstallmentsFilter.cancelled,
      InstallmentsFilter.all,
    ]) {
      testWidgets('filtered: ${f.name}', (WidgetTester t) async {
        await state(
          t,
          'filter-${f.name}',
          busy(),
          after: (WidgetTester t) =>
              tapShown(t, find.byKey(LumeInstallmentsTool.filterChip(f))),
        );
      });
    }

    testWidgets('two currencies', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      w.add(
        'Camera',
        LumeMoney.entry(4800, LumeCurrency.of('USD')),
        10,
        LumeDate(2026, 9, 20),
        merchant: 'Lens Co',
      );
      await state(t, 'mixed-currency', w);
    });

    testWidgets('no match', (WidgetTester t) async {
      await state(
        t,
        'noresults',
        InstallmentsWorld().reference(),
        after: (WidgetTester t) async {
          await t.enterText(find.byKey(LumeInstallmentsTool.searchKey), 'zzz');
          await t.pumpAndSettle();
        },
      );
    });

    Future<void> openAdd(WidgetTester t) =>
        tapShown(t, find.byKey(LumeInstallmentsTool.addKey));

    testWidgets('the add form', (WidgetTester t) async {
      await state(t, 'form-add', InstallmentsWorld(), after: openAdd);
    });

    testWidgets('validation failure', (WidgetTester t) async {
      await state(
        t,
        'form-invalid',
        InstallmentsWorld(),
        after: (WidgetTester t) async {
          await openAdd(t);
          await t.enterText(
            find.byKey(LumeInstallmentsTool.amountField),
            '12.345',
          );
          await t.enterText(find.byKey(LumeInstallmentsTool.countField), '0');
          await tapShown(t, find.byKey(LumeInstallmentsTool.saveKey));
        },
      );
    });

    testWidgets('keyboard open on the form', (WidgetTester t) async {
      await state(
        t,
        'form-keyboard',
        InstallmentsWorld(),
        after: (WidgetTester t) async {
          await openAdd(t);
          await t.tap(find.byKey(LumeInstallmentsTool.amountField));
          t.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
          await t.pumpAndSettle();
        },
      );
      t.view.resetViewInsets();
    });

    String planQuery(InstallmentsWorld w, String item) =>
        'plan=${w.plans[item]!.value}';

    testWidgets('a plan', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await state(t, 'detail', w, query: planQuery(w, 'Laptop'));
    });

    testWidgets('a plan, dark', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await state(
        t,
        'detail',
        w,
        query: planQuery(w, 'Laptop'),
        cell: (
          '390x844_dark_en',
          const Size(390, 844),
          ThemeMode.dark,
          const Locale('en'),
          1.0,
        ),
      );
    });

    testWidgets('a plan with a deposit, a cash price and a late instalment', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld();
      w.add(
        'Bike',
        rs(5000),
        6,
        LumeDate(2026, 8, 1),
        merchant: 'Wheels',
        deposit: rs(8000),
        depositOn: LumeDate(2026, 7, 20),
        cashPrice: rs(36000),
      );
      await state(t, 'detail-late', w, query: planQuery(w, 'Bike'));
    });

    testWidgets('recording a payment', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await state(
        t,
        'pay',
        w,
        query: planQuery(w, 'Laptop'),
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeInstallmentsTool.payKey)),
      );
    });

    testWidgets('the terms locked once paid', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await state(
        t,
        'form-locked',
        w,
        query: planQuery(w, 'Laptop'),
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeInstallmentsTool.editKey)),
      );
    });

    testWidgets('cancel asks first', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await state(
        t,
        'cancel-confirm',
        w,
        query: planQuery(w, 'Phone'),
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeInstallmentsTool.cancelKey)),
      );
    });

    testWidgets('delete says what goes', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await state(
        t,
        'delete-confirm',
        w,
        query: planQuery(w, 'Laptop'),
        after: (WidgetTester t) =>
            tapShown(t, find.byKey(LumeInstallmentsTool.deleteKey)),
      );
    });

    testWidgets('deleted, with Undo', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      await state(
        t,
        'undo',
        w,
        query: planQuery(w, 'Laptop'),
        after: (WidgetTester t) async {
          await tapShown(t, find.byKey(LumeInstallmentsTool.deleteKey));
          await tapShown(
            t,
            find.descendant(
              of: find.byKey(InstallmentsSheetKeys.confirm),
              matching: find.text('Delete'),
            ),
          );
        },
      );
    });

    testWidgets('export, names left out', (WidgetTester t) async {
      await state(
        t,
        'export',
        InstallmentsWorld().reference(),
        after: (WidgetTester t) =>
            tapShown(t, find.bySemanticsLabel('Export').first),
      );
    });

    testWidgets('the import check, with its problems', (WidgetTester t) async {
      await state(
        t,
        'import-errors',
        InstallmentsWorld().reference(),
        after: (WidgetTester t) async {
          await tapShown(t, find.bySemanticsLabel('Export').first);
          await tapShown(t, find.byKey(InstallmentsTransferKeys.importOpen));
          await t.enterText(
            find.byKey(InstallmentsTransferKeys.importText),
            '{"schema":"$kInstallmentsSchema","exportVersion":1,'
            '"plans":[{"id":"x"}],"schedule":[],"payments":[]}',
          );
          await t.pumpAndSettle();
          await tapShown(t, find.byKey(InstallmentsTransferKeys.importCheck));
        },
      );
    });

    testWidgets('the reader\'s day cannot be worked out', (
      WidgetTester t,
    ) async {
      final InstallmentsWorld w = InstallmentsWorld();
      w.add('Bike', rs(5000), 6, LumeDate(2026, 8, 1), merchant: 'Wheels');
      await state(
        t,
        'day-unknown',
        w,
        profile: LumeMemoryProfileRepository(
          initial: taxReader(country: 'US', region: 'New York', city: ''),
        ),
        after: (WidgetTester t) => tapShown(
          t,
          find.byKey(LumeInstallmentsTool.filterChip(InstallmentsFilter.late)),
        ),
      );
    });

    testWidgets('a record that cannot be read', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld().reference();
      final LumeTxResult<void> r = w.store.run<void>(
        (LumeRecordTx tx) => tx.create(
          InstallmentsCollections.plans,
          'not-a-uuid',
          <String, Object?>{'schema': kInstallmentsSchema},
        ),
      );
      expect(r.ok, isTrue);
      await state(t, 'damaged', w);
    });

    testWidgets('loading: the first read, still under way', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'loading',
        InstallmentsWorld(readDelay: const Duration(hours: 1)),
      );
    });

    testWidgets('a storage failure', (WidgetTester t) async {
      final InstallmentsWorld w = InstallmentsWorld();
      w.store.retry(InstallmentsCollections.payments);
      w.store.unreadable.add(InstallmentsCollections.payments);
      w.store.retry(InstallmentsCollections.payments);
      await state(t, 'storage-failure', w);
    });
  });
}
