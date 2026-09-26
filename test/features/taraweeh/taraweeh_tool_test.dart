/// Taraweeh, as `tools/islamic/taraweeh.tool.js` composes it — the mosque
/// finder for the Ramadan nights — through the real router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_map.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/mosques/data/mosques_fixtures.dart';
import 'package:lume/features/taraweeh/presentation/taraweeh_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

Future<void> pumpTaraweeh(
  WidgetTester tester, {
  String state = 'muslim_pk',
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: LumeRoutes.tool(LumeRoutes.tools, LumeTaraweehTool.id),
    profile: taxProfile(state),
    surface: const Size(390, 2600),
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

Finder rows() => find.descendant(
  of: find.byKey(LumeTaraweehTool.listKey),
  matching: find.byType(LumeRichRow),
);

void main() {
  testWidgets('the reference’s order, down to the reminder note', (
    WidgetTester tester,
  ) async {
    await pumpTaraweeh(tester);
    double last = -1;
    for (final Key k in <Key>[
      LumeTaraweehTool.contextKey,
      LumeTaraweehTool.searchKey,
      LumeTaraweehTool.rakaatKey,
      LumeTaraweehTool.mapKey,
      LumeTaraweehTool.listKey,
      LumeTaraweehTool.closestKey,
      LumeTaraweehTool.remindKey,
    ]) {
      final double y = tester.getTopLeft(find.byKey(k)).dy;
      expect(y, greaterThan(last), reason: '$k');
      last = y;
    }
    expect(find.text('Ramadan schedule'), findsOneWidget);
    expect(find.text('Get a reminder'), findsOneWidget);
  });

  testWidgets('four mosques, each with its rakaat, reciter and start', (
    WidgetTester tester,
  ) async {
    await pumpTaraweeh(tester);
    expect(rows(), findsNWidgets(4));
    final LumeRichRow first = tester.widget<LumeRichRow>(
      find.byKey(LumeTaraweehTool.row(LumeMosqueName.central)),
    );
    expect(first.meta, contains('20 rakaat'));
    expect(first.meta, contains('Qari Ahmed'));
    expect(first.valueSub, 'Starts');
  });

  testWidgets('8 rakaat keeps the two that pray eight, and the map follows', (
    WidgetTester tester,
  ) async {
    await pumpTaraweeh(tester);
    await tester.tap(find.byKey(LumeTaraweehTool.rakaatChip('8')));
    await tester.pumpAndSettle();
    expect(rows(), findsNWidgets(2));
    expect(
      tester.widget<LumeMap>(find.byKey(LumeTaraweehTool.mapKey)).pins,
      hasLength(2),
    );
    // The closest of those two is Jamia Masjid, at 1.1 km, praying eight.
    final List<String> figures = tester
        .widgetList<LumeMetric>(
          find.descendant(
            of: find.byKey(LumeTaraweehTool.closestKey),
            matching: find.byType(LumeMetric),
          ),
        )
        .map((LumeMetric m) => m.value)
        .toList();
    expect(figures, contains('1.1 km'));
    expect(figures, contains('8'));
  });

  testWidgets('nothing found offers All, which brings them back', (
    WidgetTester tester,
  ) async {
    await pumpTaraweeh(tester);
    await tester.tap(find.byKey(LumeTaraweehTool.rakaatChip('20')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(LumeTaraweehTool.searchKey), 'bilal');
    await tester.pumpAndSettle();
    expect(find.byKey(LumeTaraweehTool.emptyKey), findsOneWidget);
    expect(find.text('No mosques match'), findsOneWidget);
  });

  testWidgets('a row says its mosque, as the reference’s toast does', (
    WidgetTester tester,
  ) async {
    await pumpTaraweeh(tester);
    await tester.tap(find.byKey(LumeTaraweehTool.row(LumeMosqueName.bilal)));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(LumeToast),
        matching: find.text('Masjid Bilal Islamabad'),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('a reader without the Islamic experience never sees it', (
    WidgetTester tester,
  ) async {
    await pumpTaraweeh(tester, state: 'default_pk');
    expect(find.byKey(LumeTaraweehTool.listKey), findsNothing);
  });

  for (final (String name, Locale locale, double scale)
      in <(String, Locale, double)>[
        ('Urdu', const Locale('ur'), 1),
        ('Arabic', const Locale('ar'), 1),
        ('200 %', const Locale('en'), 2),
      ]) {
    testWidgets('$name, without overflow', (WidgetTester tester) async {
      await pumpTaraweeh(tester, locale: locale, textScale: scale);
      expect(rows(), findsNWidgets(4));
      expectNoOverflow(tester);
    });
  }
}
