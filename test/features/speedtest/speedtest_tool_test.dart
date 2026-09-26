/// Speed Test, as `tools/daily/speedtest.tool.js` composes it: the gauge and
/// Start test, download / upload / ping, the connection and the history —
/// through the real router.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/speedtest/application/speedtest_providers.dart';
import 'package:lume/features/speedtest/data/speedtest_fixtures.dart';
import 'package:lume/features/speedtest/presentation/speedtest_gauge.dart';
import 'package:lume/features/speedtest/presentation/speedtest_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

Future<void> pumpSpeedtest(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  int seed = 7,
  bool animate = false,
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: LumeRoutes.tool(LumeRoutes.tools, LumeSpeedtestTool.id),
    profile: taxProfile('default_pk'),
    surface: const Size(390, 1600),
    locale: locale,
    textScale: textScale,
    animate: animate,
    settle: !animate,
    overrides: <Override>[
      speedtestRandomProvider.overrideWithValue(math.Random(seed)),
    ],
  );
  // With motion on, something on screen always animates, so nothing settles.
  if (animate) {
    await tester.pump(const Duration(seconds: 1));
  } else {
    await tester.pumpAndSettle();
  }
}

LumeSpeedGauge gauge(WidgetTester tester) =>
    tester.widget<LumeSpeedGauge>(find.byKey(LumeSpeedtestTool.gaugeKey));

void main() {
  testWidgets('the reference order: gauge, metrics, connection, history', (
    WidgetTester tester,
  ) async {
    await pumpSpeedtest(tester);
    double last = -1;
    for (final Key k in <Key>[
      LumeSpeedtestTool.gaugeKey,
      LumeSpeedtestTool.startKey,
      LumeSpeedtestTool.metricsKey,
      LumeSpeedtestTool.connectionKey,
      LumeSpeedtestTool.historyKey,
    ]) {
      final double y = tester.getTopLeft(find.byKey(k)).dy;
      expect(y, greaterThan(last), reason: '$k');
      last = y;
    }
  });

  testWidgets('opens on the reference’s 48.2 Mbps, 20.2 up and 18 ms', (
    WidgetTester tester,
  ) async {
    await pumpSpeedtest(tester);
    expect(gauge(tester).value, '48.2');
    expect(gauge(tester).fraction, closeTo(48.2 / 200, 1e-9));
    final List<String> values = tester
        .widgetList<LumeMetric>(find.byType(LumeMetric))
        .map((LumeMetric m) => m.value)
        .toList();
    expect(values, <String>['48.2', '20.2', '18 ms']);
    expect(find.text('Test server'), findsOneWidget);
    expect(find.text('Islamabad · Pakistan'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(LumeSpeedtestTool.historyKey),
        matching: find.byType(LumeRichRow),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('Start test eases to a new reading, then says it', (
    WidgetTester tester,
  ) async {
    await pumpSpeedtest(tester, animate: true);
    final double expected = LumeSpeedtestFixtures.nextReading(math.Random(7));

    await tester.tap(find.byKey(LumeSpeedtestTool.startKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    final double mid = double.parse(gauge(tester).value);
    expect(mid, greaterThan(0));
    expect(mid, lessThan(expected));

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    expect(gauge(tester).value, expected.toStringAsFixed(1));
    expect(
      find.descendant(
        of: find.byType(LumeToast),
        matching: find.text('${expected.toStringAsFixed(1)} Mbps down'),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('with reduced motion, Start test lands on the reading at once', (
    WidgetTester tester,
  ) async {
    await pumpSpeedtest(tester);
    final double expected = LumeSpeedtestFixtures.nextReading(math.Random(7));
    await tester.tap(find.byKey(LumeSpeedtestTool.startKey));
    await tester.pump();
    await tester.pump();
    expect(gauge(tester).value, expected.toStringAsFixed(1));
    await tester.pump(const Duration(seconds: 4));
  });

  for (final (String name, Locale locale, double scale)
      in <(String, Locale, double)>[
        ('Urdu', const Locale('ur'), 1),
        ('Arabic', const Locale('ar'), 1),
        ('200 %', const Locale('en'), 2),
      ]) {
    testWidgets('$name, without overflow', (WidgetTester tester) async {
      await pumpSpeedtest(tester, locale: locale, textScale: scale);
      expect(find.byKey(LumeSpeedtestTool.gaugeKey), findsOneWidget);
      expectNoOverflow(tester);
    });
  }
}
