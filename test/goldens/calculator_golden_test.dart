/// Calculator, pinned and captured: the pad as it opens in its eight cells,
/// and every state a reader reaches by pressing keys — digits on the
/// readout, a pending operator, a finished sum and the History it lands in,
/// the History before anything has been worked out, and the four refusals
/// the engine makes instead of guessing: a division by zero, a division that
/// does not end, a product past what the model holds, and a thirteenth
/// digit.
///
/// Every state is reached through the keypad, by the same presses a reader
/// makes; nothing is seeded and no widget is built by hand. The tool keeps no
/// clock, so every cell is a function of the presses alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/notification_feed.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/features/calculator/domain/calculator_engine.dart';
import 'package:lume/features/calculator/presentation/calculator_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';

import '../features/calculator/calculator_harness.dart';
import '../features/tax/tax_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';

/// The sidecars land beside the images, out of the way of the archive.
const String kOut = 'build/calculator_shots';

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

/// Press a sequence: an `int` is a digit, a [LumeCalcOp] is an operator, and
/// `'='`, `'.'`, `'%'`, `'C'`, `'<'` are the five named keys.
Future<void> tapKeys(WidgetTester t, List<Object> presses) async {
  for (final Object p in presses) {
    await calcTap(t, switch (p) {
      final int n => LumeCalculatorTool.digitKey(n),
      final LumeCalcOp op => LumeCalculatorTool.opKey(op),
      '=' => LumeCalculatorTool.equalsKey,
      '.' => LumeCalculatorTool.pointKey,
      '%' => LumeCalculatorTool.perCentKey,
      'C' => LumeCalculatorTool.clearKey,
      '<' => LumeCalculatorTool.backspaceKey,
      _ => throw ArgumentError('unknown press $p'),
    });
  }
}

/// Bring the readout back under the eye after a scroll down the keypad.
Future<void> showReadout(WidgetTester t) async {
  await t.ensureVisible(find.byKey(LumeCalculatorTool.expressionKey));
  await t.pumpAndSettle();
}

void main() {
  setUpAll(loadLumeFonts);

  Future<void> shoot(
    WidgetTester tester, {
    required String golden,
    required Cell cell,
    LumeProfileRepository? profile,
    List<Override> overrides = const <Override>[],
    Future<void> Function(WidgetTester tester)? after,
  }) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));

    await captureLumeRoute(
      tester,
      location: kCalculatorLocation,
      name: golden,
      outDir: kOut,
      surface: cell.$2,
      theme: cell.$3,
      locale: cell.$4,
      textScale: cell.$5,
      suffix: cell.$5 == 1.0 ? '' : '_x${cell.$5.toStringAsFixed(0)}',
      profile: profile ?? taxProfile('default_pk'),
      overrides: <Override>[
        // A capture of a tool, not of the shell's notification banner: the
        // tick is the documented knob for a walk that wants screens, and a
        // state that takes two dozen keypresses to reach would otherwise be
        // captured under a banner it has nothing to do with.
        notificationScheduleProvider.overrideWithValue(
          const LumeNotificationSchedule.off(),
        ),
        ...overrides,
      ],
      after: after,
    );
    expect(find.byType(LumeToolFrame), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('images/${golden}_${cell.$1}.png'),
    );
  }

  group('Calculator — the reference composition', () {
    for (final Cell cell in kCells) {
      testWidgets('the pad on first open, ${cell.$1}', (WidgetTester t) async {
        await shoot(t, golden: 'tool_calculator_first_open', cell: cell);
      });
    }
  });

  group('Calculator — the states a reader reaches', () {
    Future<void> state(
      WidgetTester t,
      String name, {
      Future<void> Function(WidgetTester tester)? after,
      Cell cell = kPhone,
    }) => shoot(t, golden: 'tool_calculator_$name', cell: cell, after: after);

    testWidgets('digits on the readout', (WidgetTester t) async {
      await state(
        t,
        'digits',
        after: (WidgetTester t) async {
          await tapKeys(t, <Object>[1, 2, 3, 4, 5, 6, 7]);
          await showReadout(t);
        },
      );
    });

    testWidgets('an operator pressed, and the number kept', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'pending_operator',
        after: (WidgetTester t) async {
          await tapKeys(t, <Object>[1, 2, LumeCalcOp.add]);
          await showReadout(t);
        },
      );
    });

    testWidgets('a finished sum, and the row it leaves in History', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'sum_in_history',
        after: (WidgetTester t) async {
          await tapKeys(t, <Object>[
            2,
            LumeCalcOp.add,
            3,
            LumeCalcOp.multiply,
            4,
            '=',
          ]);
          await t.ensureVisible(find.byKey(LumeCalculatorTool.historyKey));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('History, before anything has been worked out', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'history_empty',
        after: (WidgetTester t) async {
          await t.ensureVisible(find.byKey(LumeCalculatorTool.emptyKey));
          await t.pumpAndSettle();
        },
      );
    });

    testWidgets('a division by zero, named rather than answered', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'divide_by_zero',
        after: (WidgetTester t) async {
          await tapKeys(t, <Object>[8, LumeCalcOp.divide, 0, '=']);
          await showReadout(t);
        },
      );
    });

    testWidgets('a division that does not end', (WidgetTester t) async {
      await state(
        t,
        'non_terminating',
        after: (WidgetTester t) async {
          await tapKeys(t, <Object>[
            1, 0, 0, 0, 0, 0, 0, 0, //
            LumeCalcOp.divide,
            3,
            '=',
          ]);
          await showReadout(t);
        },
      );
    });

    testWidgets('a product past what the model holds', (WidgetTester t) async {
      await state(
        t,
        'overflow',
        after: (WidgetTester t) async {
          await tapKeys(t, <Object>[
            9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, //
            LumeCalcOp.multiply,
            9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, //
            '=',
          ]);
          await showReadout(t);
        },
      );
    });

    testWidgets('a thirteenth digit, refused with the number kept', (
      WidgetTester t,
    ) async {
      await state(
        t,
        'too_long',
        after: (WidgetTester t) async {
          await tapKeys(t, <Object>[1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2, 3, 4]);
          await showReadout(t);
        },
      );
    });
  });
}
