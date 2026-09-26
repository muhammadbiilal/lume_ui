/// Nearby Mosques, as `tools/islamic/mosques.tool.js` composes it: the city,
/// the map, search, the radius filter, the mosques within it, and
/// Directions / Suggest a mosque — opened through the real router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_map.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/features/mosques/data/mosques_fixtures.dart';
import 'package:lume/features/mosques/presentation/mosques_tool.dart';

import '../../../helpers/capture.dart';
import '../../../helpers/lume_harness.dart';
import '../../tax/tax_harness.dart';

final String kMosques = LumeRoutes.tool(LumeRoutes.tools, LumeMosquesTool.id);

Future<void> pumpMosques(
  WidgetTester tester, {
  String state = 'muslim_pk',
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: kMosques,
    profile: taxProfile(state),
    surface: const Size(390, 2400),
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}

Finder rows() => find.descendant(
  of: find.byKey(LumeMosquesTool.listKey),
  matching: find.byType(LumeRichRow),
);

Finder toast(String text) =>
    find.descendant(of: find.byType(LumeToast), matching: find.text(text));

void main() {
  group('as the reference composes it', () {
    testWidgets('city, map, search, radius, the list, then the buttons', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester);
      final List<Key> order = <Key>[
        LumeMosquesTool.contextKey,
        LumeMosquesTool.mapKey,
        LumeMosquesTool.searchKey,
        LumeMosquesTool.radiusKey,
        LumeMosquesTool.listKey,
        LumeMosquesTool.directionsKey,
      ];
      double last = -1;
      for (final Key k in order) {
        final double y = tester.getTopLeft(find.byKey(k)).dy;
        expect(y, greaterThan(last), reason: '$k');
        last = y;
      }
      expect(
        tester.widget<LumeMap>(find.byKey(LumeMosquesTool.mapKey)).pins,
        hasLength(4),
      );
    });

    testWidgets('within 3 km, all four sample mosques, named for the city', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester);
      expect(rows(), findsNWidgets(4));
      expect(find.text('Central Mosque Islamabad'), findsOneWidget);
      expect(find.text('Masjid Bilal Islamabad'), findsOneWidget);
      expect(find.text('Near the main road, Islamabad'), findsNWidgets(4));
      expect(find.textContaining('400 m'), findsWidgets);
      expect(find.textContaining('5 min walk'), findsOneWidget);
      expect(find.textContaining('Parking · Women’s area'), findsOneWidget);
    });

    testWidgets('each row shows the city’s next prayer and its time', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester);
      final LumeRichRow first = tester.widget<LumeRichRow>(
        find.byKey(LumeMosquesTool.row(LumeMosqueName.central)),
      );
      expect(first.value, isNotNull);
      expect(<String>[
        'Fajr',
        'Dhuhr',
        'Asr',
        'Maghrib',
        'Isha',
      ], contains(first.valueSub));
    });
  });

  group('the controls', () {
    testWidgets('1 km keeps only the nearest; 5 km brings them back', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester);
      await tester.tap(find.byKey(LumeMosquesTool.radiusChip(1)));
      await tester.pumpAndSettle();
      expect(rows(), findsOneWidget);
      await tester.tap(find.byKey(LumeMosquesTool.radiusChip(5)));
      await tester.pumpAndSettle();
      expect(rows(), findsNWidgets(4));
    });

    testWidgets('search narrows by name; nothing found offers 5 km', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester);
      await tester.enterText(find.byKey(LumeMosquesTool.searchKey), 'bilal');
      await tester.pumpAndSettle();
      expect(rows(), findsOneWidget);

      await tester.enterText(find.byKey(LumeMosquesTool.searchKey), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byKey(LumeMosquesTool.emptyKey), findsOneWidget);
      expect(find.text('Nothing within this distance'), findsOneWidget);
    });

    testWidgets('a row, Directions and Suggest say the reference’s lines', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester);
      await tester.tap(find.byKey(LumeMosquesTool.row(LumeMosqueName.jamia)));
      await tester.pump();
      expect(toast('Jamia Masjid Islamabad · 1.1 km'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      await tester.tap(find.byKey(LumeMosquesTool.directionsKey));
      await tester.pump();
      expect(toast('Opening directions'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));

      await tester.tap(find.byKey(LumeMosquesTool.suggestKey));
      await tester.pump();
      expect(toast('Thanks — we’ll review it'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('the city chip opens the location picker', (
      WidgetTester tester,
    ) async {
      await pumpMosques(tester);
      await tester.tap(
        find.descendant(
          of: find.byKey(LumeMosquesTool.contextKey),
          matching: find.text('Islamabad'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LumeSheet), findsOneWidget);
    });
  });

  testWidgets('a reader without the Islamic experience never sees a mosque', (
    WidgetTester tester,
  ) async {
    await pumpMosques(tester, state: 'default_pk');
    // The refusal draws in the same frame; what must be absent is the tool.
    expect(find.byKey(LumeMosquesTool.listKey), findsNothing);
    expect(find.byKey(LumeMosquesTool.mapKey), findsNothing);
    expect(find.text('Central Mosque Islamabad'), findsNothing);
  });

  for (final (String name, Locale locale, double scale)
      in <(String, Locale, double)>[
        ('Urdu', const Locale('ur'), 1),
        ('Arabic', const Locale('ar'), 1),
        ('200 %', const Locale('en'), 2),
      ]) {
    testWidgets('$name, without overflow', (WidgetTester tester) async {
      await pumpMosques(tester, locale: locale, textScale: scale);
      expect(rows(), findsNWidgets(4));
      expectNoOverflow(tester);
    });
  }
}
