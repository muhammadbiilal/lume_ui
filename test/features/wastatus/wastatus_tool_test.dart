/// WhatsApp Status, as `tools/daily/wastatus.tool.js` composes it: the
/// "Android only" note, then "Detected statuses" with its Grant button —
/// through the real router (the test binding reports Android).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/wastatus/presentation/wastatus_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

Future<void> pumpWastatus(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: LumeRoutes.tool(LumeRoutes.tools, LumeWastatusTool.id),
    profile: taxProfile('default_pk'),
    surface: const Size(390, 1400),
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the note, then Detected statuses with its empty state', (
    WidgetTester tester,
  ) async {
    await pumpWastatus(tester);
    expect(
      tester.getTopLeft(find.byKey(LumeWastatusTool.noteKey)).dy,
      lessThan(tester.getTopLeft(find.byKey(LumeWastatusTool.detectedKey)).dy),
    );
    expect(find.text('Android only'), findsOneWidget);
    expect(find.text('Detected statuses'), findsOneWidget);
    expect(find.text('No statuses found'), findsOneWidget);
  });

  testWidgets('Grant folder access says the reference’s line', (
    WidgetTester tester,
  ) async {
    await pumpWastatus(tester);
    await tester.tap(find.byKey(LumeWastatusTool.grantKey));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(LumeToast),
        matching: find.text('Requesting access'),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
  });

  for (final (String name, Locale locale, double scale)
      in <(String, Locale, double)>[
        ('Urdu', const Locale('ur'), 1),
        ('Arabic', const Locale('ar'), 1),
        ('200 %', const Locale('en'), 2),
      ]) {
    testWidgets('$name, without overflow', (WidgetTester tester) async {
      await pumpWastatus(tester, locale: locale, textScale: scale);
      expect(find.byKey(LumeWastatusTool.grantKey), findsOneWidget);
      expectNoOverflow(tester);
    });
  }
}
