/// Cricket — the frozen match rendered, tabs switching what is under it, and
/// a locale check.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/localization/lume_numerals.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/cricket/presentation/cricket_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

final String kCricket = LumeRoutes.tool(LumeRoutes.tools, 'cricket');

Future<GoRouter> pumpCricket(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: kCricket,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
  return router;
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

void main() {
  setUpAll(loadLumeFonts);

  const Key score = LumeCricketTool.scoreKey;
  const Key tabs = LumeCricketTool.tabsKey;
  const Key batting = LumeCricketTool.battingKey;
  const Key bowling = LumeCricketTool.bowlingKey;

  group('the frozen match', () {
    testWidgets('shows the score, the overs and both teams', (
      WidgetTester tester,
    ) async {
      await pumpCricket(tester);
      expect(
        inKey(score, find.byWidgetPredicate((Widget w) => w is LumeNumerals && w.text == '214/4')),
        findsOneWidget,
      );
      expect(inKey(score, find.text('PAK')), findsOneWidget);
      expect(inKey(score, find.text('Pakistan')), findsOneWidget);
      expect(inKey(score, find.text('ENG')), findsOneWidget);
      expect(inKey(score, find.text('England')), findsOneWidget);
      expect(inKey(score, find.textContaining('38.2')), findsOneWidget);
    });

    testWidgets('shows the batting and bowling cards by default', (
      WidgetTester tester,
    ) async {
      await pumpCricket(tester);
      final LumeTable battingTable = tester.widget<LumeTable>(
        find.byKey(batting),
      );
      expect(battingTable.rows, <List<String>>[
        <String>['Babar Azam', '88', '94', '7', '1', '93.6'],
        <String>['Salman Agha', '42', '38', '4', '0', '110.5'],
      ]);
      final LumeTable bowlingTable = tester.widget<LumeTable>(
        find.byKey(bowling),
      );
      expect(bowlingTable.rows, <List<String>>[
        <String>['A. Rashid', '8', '0', '41', '2', '5.12'],
        <String>['J. Archer', '7.2', '1', '38', '1', '5.18'],
      ]);
    });

    testWidgets('Fixtures lists the three upcoming matches', (
      WidgetTester tester,
    ) async {
      await pumpCricket(tester);
      await tester.tap(inKey(tabs, find.text('Fixtures')));
      await tester.pumpAndSettle();
      final List<String> titles = tester
          .widgetList<LumeRichRow>(find.byType(LumeRichRow))
          .map((LumeRichRow r) => r.title)
          .toList();
      expect(titles, <String>['PAK v ENG', 'IND v AUS', 'SA v NZ']);
      expect(find.byKey(batting), findsNothing);
    });

    testWidgets('Table lists the five-team standings, points bold', (
      WidgetTester tester,
    ) async {
      await pumpCricket(tester);
      await tester.tap(inKey(tabs, find.text('Table')));
      await tester.pumpAndSettle();
      final LumeTable standings = tester.widget<LumeTable>(
        find.byKey(LumeCricketTool.standingsKey),
      );
      expect(standings.rows.first, <String>[
        'India',
        '8',
        '6',
        '2',
        '12',
        '+0.84',
      ]);
      expect(find.text('Standings'), findsOneWidget);
    });
  });

  group('used', () {
    testWidgets('leaving keeps the chosen tab', (WidgetTester tester) async {
      final GoRouter router = await pumpCricket(tester);
      await tester.tap(inKey(tabs, find.text('Table')));
      await tester.pumpAndSettle();
      router.go(LumeRoutes.tools);
      await tester.pumpAndSettle();
      router.go(kCricket);
      await tester.pumpAndSettle();
      expect(find.byKey(LumeCricketTool.standingsKey), findsOneWidget);
    });

    testWidgets('in Urdu the score card runs right to left', (
      WidgetTester tester,
    ) async {
      await pumpCricket(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(tester.element(find.byType(LumeToolFrame))),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });

    testWidgets('at 200 %', (WidgetTester tester) async {
      await pumpCricket(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}
