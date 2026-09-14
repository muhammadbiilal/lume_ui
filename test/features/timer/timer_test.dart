/// Timer, against the running reference, and run.
///
/// The countdown runs on `Timer.periodic` inside the test's fake-async zone,
/// so a second is `tester.pump(const Duration(seconds: 1))` and nothing waits
/// on a wall clock.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_clock_face.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/timer/application/timer_controller.dart';
import 'package:lume/features/timer/presentation/timer_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../tax/tax_harness.dart';
import '../tools/tool_parity.dart';

final String kTimer = LumeRoutes.tool(LumeRoutes.tools, 'timer');

Finder preset(String label) => find.descendant(
  of: find.byKey(LumeTimerTool.presetsKey),
  matching: find.text(label),
);

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('timer');
  tearDownAll(parity.write);

  String time(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(LumeTimerTool.timeKey),
          matching: find.byType(Text),
        ),
      )
      .data!;

  Finder inHistory(String text) => find.descendant(
    of: find.byKey(LumeTimerTool.historyKey),
    matching: find.text(text),
  );

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'clockface': find.byType(LumeClockFace),
    'clockface.time': find.byKey(LumeTimerTool.timeKey),
    'clockface.sub': find.text('Choose a preset or set your own'),
    'clock.btn1': find.byKey(LumeTimerTool.startKey),
    'clock.btn2': find.byKey(LumeTimerTool.resetKey),
    'sect.title': find.text('Presets'),
    'chips': find.byKey(LumeTimerTool.presetsKey),
    'chip1': find.byType(LumeChoiceChip).first,
    'chip4': find.byType(LumeChoiceChip).at(3),
    'rows': find.byKey(LumeTimerTool.historyKey),
    'crow1': find.byType(LumeCompactRow).first,
    'crow.label': inHistory('25 min'),
    'crow.value': inHistory('Today'),
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  const Set<String> textBlocks = <String>{
    'clockface.time',
    'clockface.sub',
    'sect.title',
    'crow.label',
    'crow.value',
  };

  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_timer_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_timer_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_timer_default_pk_1100x900_light_en', const Size(1050, 5000)),
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpTax(tester, location: kTimer, surface: size);
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          noWidth: textBlocks,
          drifting: <String>{'srcbar', 'related', 'rows', 'crow1'},
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }
  });

  group('what it says, in each state the reference was captured in', () {
    void expectWords(WidgetTester tester, String cell) {
      final Map<String, dynamic> k =
          webToolCell(cell)!['composition'] as Map<String, dynamic>;
      final Map<String, dynamic> header = k['header'] as Map<String, dynamic>;
      expect(find.text(header['title'] as String), findsOneWidget);
      expect(find.text(header['sub'] as String), findsOneWidget);
      expect(find.byType(LumeIconButton), findsNothing);

      final Map<String, dynamic> clock = k['clock'] as Map<String, dynamic>;
      expect(time(tester), clock['time']);
      expect(find.text(clock['sub'] as String), findsOneWidget);
      expect(<String>[
        ...textsUnder(tester, find.byKey(LumeTimerTool.startKey)),
        ...textsUnder(tester, find.byKey(LumeTimerTool.resetKey)),
      ], clock['buttons']);
      expect(
        textsUnder(tester, find.byKey(LumeTimerTool.presetsKey)),
        clock['chips'],
      );
      expect(textsUnder(tester, find.byKey(LumeTimerTool.historyKey)), <String>[
        for (final dynamic h in clock['history'] as List<dynamic>) ...<String>[
          (h as Map<String, dynamic>)['label'] as String,
          h['value'] as String,
        ],
      ]);
      final Map<String, dynamic> src = k['source'] as Map<String, dynamic>;
      expect(find.text(src['fresh'] as String), findsOneWidget);
      expect(
        textsUnder(
          tester,
          find.byType(LumeSourceLine),
        ).where((String t) => t.trim() != '·').toList(),
        src['line'],
      );
      expect(textsUnder(tester, find.byType(LumeRelatedTools)), k['related']);
    }

    testWidgets('opened', (WidgetTester tester) async {
      await pumpTax(tester, location: kTimer, surface: const Size(390, 5000));
      expectWords(tester, 'tool_timer_default_pk_390x844_light_en');
    });

    testWidgets('a preset chosen', (WidgetTester tester) async {
      await pumpTax(tester, location: kTimer, surface: const Size(390, 5000));
      await tester.tap(preset('5 min'));
      await tester.pump();
      expectWords(tester, 'tool_timer_default_pk_set300_390x844_light_en');
    });

    testWidgets('running — a minute, three seconds in', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, location: kTimer, surface: const Size(390, 5000));
      await tester.tap(preset('1 min'));
      await tester.pump();
      await tester.tap(find.byKey(LumeTimerTool.startKey));
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      // The reference was captured 2.4 s after Start, when its interval had
      // fired twice and a third tick was due: `00:57`.
      expectWords(tester, 'tool_timer_default_pk_running_390x844_light_en');
      await tester.tap(find.byKey(LumeTimerTool.startKey));
      await tester.pump();
    });
  });

  group('the countdown', () {
    late LumeToolSession session;
    late int finished;

    LumeTimerController make() {
      session = LumeToolSession();
      finished = 0;
      return LumeTimerController(
        session: session,
        onFinished: () => finished++,
      );
    }

    testWidgets('starting with nothing held counts down from five minutes', (
      WidgetTester tester,
    ) async {
      final LumeTimerController c = make();
      expect(c.display, '00:00');
      c.toggle();
      expect(c.running, isTrue);
      expect(c.display, '05:00');
      await tester.pump(const Duration(seconds: 1));
      expect(c.display, '04:59');
      c.dispose();
    });

    testWidgets('start again pauses, on the same control', (
      WidgetTester tester,
    ) async {
      final LumeTimerController c = make()..set(90);
      c.toggle();
      await tester.pump(const Duration(seconds: 2));
      c.toggle();
      expect(c.running, isFalse);
      await tester.pump(const Duration(seconds: 5));
      expect(c.display, '01:28');
      c.dispose();
    });

    testWidgets('reset holds the last preset, or five minutes', (
      WidgetTester tester,
    ) async {
      final LumeTimerController c = make()..set(600);
      c.toggle();
      await tester.pump(const Duration(seconds: 3));
      c.reset();
      expect((c.running, c.display), (false, '10:00'));
      c.dispose();

      final LumeTimerController fresh = make()..reset();
      expect(fresh.display, '05:00');
      fresh.dispose();
    });

    testWidgets('zero stops the clock, holds zero, and finishes once', (
      WidgetTester tester,
    ) async {
      final LumeTimerController c = make()..set(2);
      c.toggle();
      await tester.pump(const Duration(seconds: 5));
      expect((c.running, c.display, finished), (false, '00:00', 1));
      // Start from zero begins the last preset again.
      c.toggle();
      expect(c.display, '00:02');
      c.dispose();
    });

    test('minutes are not wrapped into hours', () {
      expect(LumeTimerController.format(1500), '25:00');
      expect(LumeTimerController.format(3725), '62:05');
      expect(LumeTimerController.format(-4), '00:00');
    });
  });

  group('on screen', () {
    testWidgets('finishing toasts and vibrates, and says so to a reader', (
      WidgetTester tester,
    ) async {
      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpTax(tester, location: kTimer, surface: const Size(390, 5000));
      await tester.tap(preset('1 min'));
      await tester.pump();
      await tester.tap(find.byKey(LumeTimerTool.startKey));
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(time(tester), '00:00');
      expect(find.text('Timer finished'), findsOneWidget);
      expect(
        calls.where((MethodCall c) => c.method == 'HapticFeedback.vibrate'),
        hasLength(1),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(LumeToast), findsNothing);
    });

    testWidgets('leaving stops the clock and keeps the seconds', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await pumpTax(tester, location: kTimer);
      await tester.tap(preset('10 min'));
      await tester.pump();
      await tester.tap(find.byKey(LumeTimerTool.startKey));
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byType(LumeBackButton), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(LumeTimerTool), findsNothing);
      await tester.pump(const Duration(seconds: 30));

      router.go(kTimer);
      await tester.pumpAndSettle();
      expect(time(tester), '09:56');
      await tester.pump(const Duration(seconds: 2));
      expect(time(tester), '09:56', reason: 'it came back stopped');
    });

    testWidgets('right to left, the time reads left to right', (
      WidgetTester tester,
    ) async {
      await pumpTax(tester, location: kTimer, locale: const Locale('ur'));
      await tester.tap(find.byType(LumeChoiceChip).at(1));
      await tester.pump();
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      expect(
        Directionality.of(
          tester.element(
            find.descendant(
              of: find.byKey(LumeTimerTool.timeKey),
              matching: find.byType(Text),
            ),
          ),
        ),
        TextDirection.ltr,
      );
      expect(time(tester), '05:00');
      // Start leads from the right.
      expect(
        tester.getCenter(find.byKey(LumeTimerTool.startKey)).dx,
        greaterThan(tester.getCenter(find.byKey(LumeTimerTool.resetKey)).dx),
      );
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpTax(tester, location: kTimer, textScale: 2);
      expectNoOverflow(tester);
    });

    testWidgets('the time is a live region', (WidgetTester tester) async {
      await pumpTax(tester, location: kTimer);
      final SemanticsHandle h = tester.ensureSemantics();
      final SemanticsNode node = tester.getSemantics(
        find.byKey(LumeTimerTool.timeKey),
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);
      h.dispose();
    });
  });
}
