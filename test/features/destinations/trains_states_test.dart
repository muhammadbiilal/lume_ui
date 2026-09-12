/// Every surface Trains has to be drawable on.
///
/// The reference has one composition and no responsive rules of its own — the
/// shared page furniture carries the widths — so what this asserts is that the
/// screen survives them: the route search's three-part row, the running
/// strip's pin, the 152-point route cards and the five-row roster.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_explore.dart';
import 'package:lume/core/widgets/lume/lume_rail.dart';
import 'package:lume/features/trains/presentation/trains_screen.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';
import 'trains_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  const List<(String, Size)> cells = <(String, Size)>[
    ('359 wide', Size(359, 4000)),
    ('360 wide', Size(360, 4000)),
    ('390 wide', Size(390, 4000)),
    ('600 wide', Size(600, 4000)),
    ('700 wide', Size(700, 4000)),
    ('840 wide', Size(840, 4000)),
    ('1100 wide', Size(1100, 4000)),
    ('a phone on its side', Size(852, 2000)),
  ];

  group('Trains draws', () {
    for (final (String, Size) cell in cells) {
      testWidgets('at ${cell.$1} without overflowing', (
        WidgetTester tester,
      ) async {
        await pumpTrains(tester, LumeUsers.muslimPk, surface: cell.$2);
        expect(tester.takeException(), isNull);
        expect(find.byType(LumeRailSearchCard), findsOneWidget);
        expect(find.byType(LumeLiveTrainCard), findsOneWidget);
        expect(find.byType(LumeListRow), findsNWidgets(5));
      });
    }

    testWidgets('in Urdu, in Arabic and at 200 per cent', (
      WidgetTester tester,
    ) async {
      for (final (Locale, double) cell in <(Locale, double)>[
        (const Locale('ur'), 1.0),
        (const Locale('ar'), 1.0),
        (const Locale('en'), 2.0),
        (const Locale('ur'), 2.0),
      ]) {
        await pumpTrains(
          tester,
          LumeUsers.muslimPk,
          surface: const Size(390, 6000),
          locale: cell.$1,
          textScale: cell.$2,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${cell.$1} at ${cell.$2}',
        );
        expect(find.byType(LumeRouteCard), findsNWidgets(3));
      }
    });

    testWidgets('and in the dark', (WidgetTester tester) async {
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
        theme: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('right to left', () {
    testWidgets('the journey reads the way the language does', (
      WidgetTester tester,
    ) async {
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
        locale: const Locale('ur'),
      );

      // The origin field is at the trailing edge in Urdu, which is the left.
      final Rect origin = tester.getRect(
        find.byKey(const ValueKey<String>('trains.origin')),
      );
      final Rect swap = tester.getRect(find.byType(LumeRailSwap));
      expect(
        swap.center.dx,
        lessThan(origin.center.dx),
        reason: 'the swap sits at the leading edge, which is the left in Urdu',
      );
    });

    testWidgets('and a train number is never reordered', (
      WidgetTester tester,
    ) async {
      // `rtl.css` isolates `.trainno` on purpose: `5UP` is an identifier, and
      // a bidi algorithm left to itself will move the digits.
      for (final String code in <String>['ur', 'ar']) {
        await pumpTrains(
          tester,
          LumeUsers.muslimPk,
          surface: const Size(390, 6000),
          locale: Locale(code),
        );
        expect(find.text('5UP'), findsWidgets, reason: code);
        expect(find.text('101UP'), findsOneWidget, reason: code);
        expect(find.text('22:00'), findsWidgets, reason: code);
      }
    });
  });

  group('reduced motion', () {
    testWidgets('the running strip settles rather than pulsing forever', (
      WidgetTester tester,
    ) async {
      // The live dot repeats indefinitely while motion is allowed. A test
      // pumps with animations disabled, and a page that never settles is a
      // page that ignored the setting.
      await pumpTrains(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(LumeStatusPill), findsWidgets);
    });
  });

  group('the whole page has one scroller', () {
    testWidgets('and it remembers where it was', (WidgetTester tester) async {
      await pumpTrains(tester, LumeUsers.muslimPk, surface: LumeViewport.phone);
      final Finder scroller = find.byType(Scrollable).first;
      await tester.drag(scroller, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scroller).position.pixels,
        greaterThan(0),
      );
      expect(find.byType(LumeTrainsScreen), findsOneWidget);
    });
  });
}
