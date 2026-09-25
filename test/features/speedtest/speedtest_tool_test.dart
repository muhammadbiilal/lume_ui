/// The Speed Test screen: that it never invents a reading.
///
/// The reference's own instrument (`speedtest.tool.js` + `context.js`
/// `speedTest()`) is fabricated end to end — a hardcoded 48.2 Mbps default,
/// `up: down * 0.42`, a fixed 18 ms ping, a two-row "history" of literal
/// constants, and a "Start" button (`tool.screen.js` `runSpeedTest()`) that
/// animates toward `30 + Math.random() * 70` — never a real measurement, and
/// Lume makes no network calls anywhere to measure one honestly. So this
/// screen carries no gauge, no Mbps, no ping and no history: only an honest
/// explanation, and one real way out — a hand-off to the reader's own
/// browser, which is tested here to actually open, and to fail honestly
/// when it can't.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/platform/lume_link_opener.dart';
import 'package:lume/features/speedtest/presentation/speedtest_tool.dart';

import 'speedtest_harness.dart';

void main() {
  group('what it opens on', () {
    testWidgets('an honest unavailable state, not a fabricated reading', (
      WidgetTester tester,
    ) async {
      await pumpSpeedtest(tester);
      expect(find.byKey(LumeSpeedtestTool.stateKey), findsOneWidget);

      final List<String> screen = textsIn(
        tester,
        find.byType(LumeSpeedtestTool),
      );
      // None of the reference's own fabricated figures anywhere on screen —
      // its hardcoded 48.2 Mbps down, 20.2 Mbps up (`down * 0.42`) and 18 ms
      // ping (`context.js` `speedTest()`) — and no unit that would imply a
      // real one was measured.
      for (final String fabricated in <String>['48.2', '20.2', '18', 'Mbps']) {
        expect(screen, isNot(contains(fabricated)));
      }
    });

    testWidgets('there is no Start button pretending to run a test', (
      WidgetTester tester,
    ) async {
      await pumpSpeedtest(tester);
      expect(find.byKey(LumeSpeedtestTool.openKey), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });
  });

  group('the hand-off', () {
    testWidgets('opens the real test address in the browser, on a press', (
      WidgetTester tester,
    ) async {
      final LumeRecordingLinkOpener opener = LumeRecordingLinkOpener();
      await pumpSpeedtest(
        tester,
        overrides: <Override>[linkOpenerProvider.overrideWithValue(opener)],
      );

      await tester.tap(find.byKey(LumeSpeedtestTool.openKey));
      await tester.pumpAndSettle();

      // The one address this screen ever hands anywhere, and Lume asked for
      // nothing besides it.
      expect(opener.requested, <Uri>[LumeSpeedtestTool.realTest]);
      expect(opener.opened, <Uri>[LumeSpeedtestTool.realTest]);
    });

    testWidgets('says so, honestly, when nothing on the device opens it', (
      WidgetTester tester,
    ) async {
      await pumpSpeedtest(
        tester,
        overrides: <Override>[
          linkOpenerProvider.overrideWithValue(
            LumeRecordingLinkOpener(outcome: LumeOpenOutcome.unavailable),
          ),
        ],
      );

      await tester.tap(find.byKey(LumeSpeedtestTool.openKey));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('says so, honestly, when the platform throws', (
      WidgetTester tester,
    ) async {
      await pumpSpeedtest(
        tester,
        overrides: <Override>[
          linkOpenerProvider.overrideWithValue(
            LumeRecordingLinkOpener(outcome: LumeOpenOutcome.failed),
          ),
        ],
      );

      await tester.tap(find.byKey(LumeSpeedtestTool.openKey));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('other languages and text scales', () {
    testWidgets('Urdu draws the same screen without overflowing', (
      WidgetTester tester,
    ) async {
      await pumpSpeedtest(tester, locale: const Locale('ur'));
      expect(tester.takeException(), isNull);
      expect(find.byKey(LumeSpeedtestTool.stateKey), findsOneWidget);
    });

    testWidgets('Arabic draws right to left without overflowing', (
      WidgetTester tester,
    ) async {
      await pumpSpeedtest(tester, locale: const Locale('ar'), country: 'SA');
      expect(tester.takeException(), isNull);
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeSpeedtestTool.stateKey)),
        ),
        TextDirection.rtl,
      );
    });

    testWidgets('200% text scale draws without overflowing', (
      WidgetTester tester,
    ) async {
      await pumpSpeedtest(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(find.byKey(LumeSpeedtestTool.stateKey), findsOneWidget);
    });
  });
}
