/// Fuel Prices, used: a Pakistani reader's own market, a reader in a
/// country with no entry (the honest fallback), and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/fuel/presentation/fuel_tool.dart';

import '../../helpers/load_fonts.dart';
import 'fuel_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  group('a market the reference names', () {
    testWidgets('Pakistan: petrol leads, in rupees', (
      WidgetTester tester,
    ) async {
      await pumpFuel(tester, country: 'PK');
      expect(find.byType(LumeFuelTool), findsOneWidget);

      final LumeSummaryCard summary = tester.widget<LumeSummaryCard>(
        find.byKey(LumeFuelTool.summaryKey),
      );
      expect(summary.kicker, contains('RON 92'));
      expect(summary.value, contains('264.61'));

      final LumeTable grades = tester.widget<LumeTable>(
        find.byKey(LumeFuelTool.gradesKey),
      );
      expect(grades.rows, hasLength(4));
      expect(grades.rows[0][0], contains('RON 92'));
      expect(grades.rows[0][2], contains('264.61'));
      expect(grades.rows[0][1], contains('262.47'));
    });

    testWidgets('the United States: priced by the gallon, in dollars', (
      WidgetTester tester,
    ) async {
      await pumpFuel(tester, country: 'US', city: 'New York');
      final LumeSummaryCard summary = tester.widget<LumeSummaryCard>(
        find.byKey(LumeFuelTool.summaryKey),
      );
      expect(summary.value, contains('3.12'));
      expect(summary.value, contains(r'$'));
    });
  });

  group('a country with no entry', () {
    testWidgets('reads the honest global fallback, never a blank screen', (
      WidgetTester tester,
    ) async {
      await pumpFuel(tester, country: 'FR', city: 'Paris');
      expect(find.byType(LumeFuelTool), findsOneWidget);

      final LumeSummaryCard summary = tester.widget<LumeSummaryCard>(
        find.byKey(LumeFuelTool.summaryKey),
      );
      // The fallback's own petrol price, in dollars — not a French price
      // dressed up, and not blank.
      expect(summary.value, contains('1.28'));
      expect(summary.value, contains(r'$'));

      final LumeTable grades = tester.widget<LumeTable>(
        find.byKey(LumeFuelTool.gradesKey),
      );
      expect(grades.rows, hasLength(2));
    });
  });

  group('language', () {
    testWidgets('Urdu: the screen still renders, right to left, without '
        'overflow', (WidgetTester tester) async {
      await pumpFuel(tester, locale: const Locale('ur'));
      expect(find.byType(LumeFuelTool), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('at 200% text scale, nothing overflows', (
      WidgetTester tester,
    ) async {
      await pumpFuel(tester, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
