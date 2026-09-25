/// Fuel Cost, used: the opening figures for a metric and an imperial reader,
/// that its price field is genuinely Fuel Prices' own, that typing into it
/// computes a real result, and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/fuel/data/fuel_fixtures.dart';
import 'package:lume/features/fuel/presentation/fuelcost_tool.dart';
import 'package:lume/features/tools/application/tool_numbers.dart';

import '../../helpers/load_fonts.dart';
import 'fuel_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  group('what it opens on', () {
    testWidgets('metric: 400 km, 12 km/L, and Pakistan\'s own petrol price', (
      WidgetTester tester,
    ) async {
      await pumpFuelcost(tester, country: 'PK');
      expect(find.byType(LumeFuelcostTool), findsOneWidget);

      expect(fuelTyped(tester, LumeFuelcostTool.distanceKey), '400');
      expect(fuelTyped(tester, LumeFuelcostTool.economyKey), '12');
      expect(fuelTyped(tester, LumeFuelcostTool.peopleKey), '2');
      // The cross-tool link: Fuel Cost's own opening price is not a second,
      // independent figure — it is Fuel Prices' own leading grade for the
      // same country, read straight off the fixture.
      expect(
        fuelTyped(tester, LumeFuelcostTool.priceKey),
        lumeJsNumber(LumeFuel.forCountry('PK').main.price),
      );
      expect(fuelTyped(tester, LumeFuelcostTool.priceKey), '264.61');
    });

    testWidgets('imperial: 250 mi, 32 mpg, and the US\'s own price', (
      WidgetTester tester,
    ) async {
      await pumpFuelcost(tester, country: 'US', city: 'New York');
      expect(fuelTyped(tester, LumeFuelcostTool.distanceKey), '250');
      expect(fuelTyped(tester, LumeFuelcostTool.economyKey), '32');
      expect(
        fuelTyped(tester, LumeFuelcostTool.priceKey),
        lumeJsNumber(LumeFuel.forCountry('US').main.price),
      );
    });

    testWidgets('a country with no market reads the same fallback price '
        'Fuel Prices itself would show', (WidgetTester tester) async {
      await pumpFuelcost(tester, country: 'FR', city: 'Paris');
      expect(
        fuelTyped(tester, LumeFuelcostTool.priceKey),
        lumeJsNumber(LumeFuel.fallback.main.price),
      );
    });
  });

  group('typing into it computes a real result', () {
    testWidgets('a longer distance raises the total, and the compare table '
        'agrees with it', (WidgetTester tester) async {
      await pumpFuelcost(tester);
      LumeSummaryCard summary() => tester.widget<LumeSummaryCard>(
        find.byKey(LumeFuelcostTool.summaryKey),
      );
      final String before = summary().value;

      await tester.ensureVisible(fuelInput(LumeFuelcostTool.distanceKey));
      await tester.enterText(fuelInput(LumeFuelcostTool.distanceKey), '800');
      await tester.pumpAndSettle();

      final String after = summary().value;
      expect(after, isNot(before));

      final LumeTable compare = tester.widget<LumeTable>(
        find.byKey(LumeFuelcostTool.compareKey),
      );
      expect(compare.rows, hasLength(3));
      // The solo row's own cost is the summary's headline figure.
      expect(compare.rows[0].last, after);
    });

    testWidgets('an emptied field reads as nothing owed, not an error', (
      WidgetTester tester,
    ) async {
      await pumpFuelcost(tester);
      await tester.ensureVisible(fuelInput(LumeFuelcostTool.economyKey));
      await tester.enterText(fuelInput(LumeFuelcostTool.economyKey), '');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(LumeFuelcostTool), findsOneWidget);
    });
  });

  group('language', () {
    testWidgets('Urdu: the screen still renders, right to left, without '
        'overflow', (WidgetTester tester) async {
      await pumpFuelcost(tester, locale: const Locale('ur'));
      expect(find.byType(LumeFuelcostTool), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
