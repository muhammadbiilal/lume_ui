/// Media Saver, as `tools/daily/mediasaver.tool.js` composes it: a link and
/// Fetch, three figures, and the library — through the real router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/mediasaver/data/mediasaver_fixtures.dart';
import 'package:lume/features/mediasaver/presentation/mediasaver_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

Future<void> pumpMediaSaver(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: LumeRoutes.tool(LumeRoutes.tools, LumeMediaSaverTool.id),
    profile: taxProfile('default_pk'),
    surface: const Size(390, 1400),
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

Finder toast(String text) =>
    find.descendant(of: find.byType(LumeToast), matching: find.text(text));

void main() {
  testWidgets('link and Fetch, then the figures, then the library', (
    WidgetTester tester,
  ) async {
    await pumpMediaSaver(tester);
    double last = -1;
    for (final Key k in <Key>[
      LumeMediaSaverTool.fieldKey,
      LumeMediaSaverTool.fetchKey,
      LumeMediaSaverTool.metricsKey,
      LumeMediaSaverTool.libraryKey,
    ]) {
      final double y = tester.getTopLeft(find.byKey(k)).dy;
      expect(y, greaterThan(last), reason: '$k');
      last = y;
    }
    expect(
      tester
          .widget<LumeToolField>(find.byKey(LumeMediaSaverTool.fieldKey))
          .label,
      'Paste a link',
    );
  });

  testWidgets('the reference’s figures: 3 saved, 182 MB, today', (
    WidgetTester tester,
  ) async {
    await pumpMediaSaver(tester);
    expect(
      tester
          .widgetList<LumeMetric>(find.byType(LumeMetric))
          .map((LumeMetric m) => m.value)
          .toList(),
      <String>['3', '182 MB', 'Today'],
    );
    expect(find.byType(LumeImageCard), findsNWidgets(3));
    expect(find.text('Recipe video'), findsOneWidget);
    expect(find.text('3.2 MB'), findsOneWidget);
  });

  testWidgets('Fetch and a tile say the reference’s lines', (
    WidgetTester tester,
  ) async {
    await pumpMediaSaver(tester);
    await tester.tap(find.byKey(LumeMediaSaverTool.fetchKey));
    await tester.pump();
    expect(toast('Fetching media'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(
      find.byKey(LumeMediaSaverTool.tile(LumeSavedMediaKind.audio)),
    );
    await tester.pump();
    expect(toast('Podcast clip'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('the link is kept for the session', (WidgetTester tester) async {
    await pumpMediaSaver(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(LumeMediaSaverTool.fieldKey),
        matching: find.byType(EditableText),
      ),
      'https://example.com/v',
    );
    await tester.pump();
    expect(find.text('https://example.com/v'), findsOneWidget);
  });

  for (final (String name, Locale locale, double scale)
      in <(String, Locale, double)>[
        ('Urdu', const Locale('ur'), 1),
        ('Arabic', const Locale('ar'), 1),
        ('200 %', const Locale('en'), 2),
      ]) {
    testWidgets('$name, without overflow', (WidgetTester tester) async {
      await pumpMediaSaver(tester, locale: locale, textScale: scale);
      expect(find.byType(LumeImageCard), findsNWidgets(3));
      expectNoOverflow(tester);
    });
  }
}
