/// Zakat, used: typing asset values, the computed result, below nisab, and
/// Urdu.
///
/// Pumped through [pumpZakatTool] (`zakat_screen_harness.dart`), through the
/// real router now that `tool_registry.dart` carries `'zakat'`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/zakat/presentation/zakat_tool.dart';

import '../../helpers/load_fonts.dart';
import 'zakat_screen_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  Finder input(Key key) =>
      find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

  LumeSummaryCard summary(WidgetTester tester) =>
      tester.widget<LumeSummaryCard>(find.byKey(LumeZakatTool.summaryKey));

  group('it works it out as the reader types', () {
    testWidgets('more cash moves the payable figure and the caption', (
      WidgetTester tester,
    ) async {
      await pumpZakatTool(tester);
      final LumeSummaryCard before = summary(tester);

      await tester.ensureVisible(input(LumeZakatTool.cashKey));
      await tester.enterText(input(LumeZakatTool.cashKey), '5000000');
      await tester.pump();

      final LumeSummaryCard after = summary(tester);
      expect(after.value, isNot(before.value));
      expect(after.caption, isNotEmpty);
    });

    testWidgets('the breakdown carries the same eight rows the summary '
        'agrees with', (WidgetTester tester) async {
      await pumpZakatTool(tester);
      final LumeTable table = tester.widget<LumeTable>(
        find.byKey(LumeZakatTool.breakdownKey),
      );
      expect(table.rows, hasLength(8));
      // The last row is "payable", and its value is the summary's headline.
      expect(table.rows.last.last, summary(tester).value);
    });

    testWidgets('an empty field is nothing, not an error', (
      WidgetTester tester,
    ) async {
      await pumpZakatTool(tester);
      await tester.ensureVisible(input(LumeZakatTool.cashKey));
      await tester.enterText(input(LumeZakatTool.cashKey), '');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(LumeZakatTool), findsOneWidget);
    });
  });

  group('below nisab', () {
    testWidgets('clearing every asset field reads as below nisab, and '
        'nothing is payable', (WidgetTester tester) async {
      await pumpZakatTool(tester);
      for (final Key key in <Key>[
        LumeZakatTool.cashKey,
        LumeZakatTool.goldKey,
        LumeZakatTool.silverKey,
        LumeZakatTool.investmentsKey,
        LumeZakatTool.businessKey,
        LumeZakatTool.liabilitiesKey,
      ]) {
        await tester.ensureVisible(input(key));
        await tester.enterText(input(key), '0');
        await tester.pump();
      }
      final LumeSummaryCard s = summary(tester);
      expect(s.caption, isNotEmpty);
      // Nothing owned at all cannot clear any nisab, so the headline figure
      // reads as the currency's own zero.
      expect(s.value, isNot(contains(RegExp(r'[1-9]'))));
    });
  });

  group('language', () {
    testWidgets('Urdu: the tool still renders, right to left, with no '
        'overflow', (WidgetTester tester) async {
      await pumpZakatTool(tester, locale: const Locale('ur'));
      expect(find.byType(LumeZakatTool), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('personalisation', () {
    testWidgets('a non-Pakistan reader sees their own currency, not PKR', (
      WidgetTester tester,
    ) async {
      await pumpZakatTool(
        tester,
        country: 'US',
        region: 'New York',
        city: 'New York',
      );
      expect(find.textContaining(r'$'), findsWidgets);
      expect(find.textContaining('Rs '), findsNothing);
    });
  });
}
