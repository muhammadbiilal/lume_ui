/// Birthdays' shared test harness: the tool opened for a reader, over a
/// record store the test holds.
///
/// `tool_registry.dart` names `birthdays`, so [pumpBirthdays] opens the route
/// and the tool is built by `app_router.dart` `_tool` itself — the same
/// eligibility, read from the same profile, refusing in the same place —
/// inside the shell that draws around it. That shell is what makes the tool
/// bar's back control and the rail-inset wide columns real, which the parity
/// cells are measured against.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/birthdays/presentation/birthdays_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// `/tools/tool/birthdays`.
final String kBirthdays = LumeRoutes.tool(
  LumeRoutes.tools,
  LumeBirthdaysTool.id,
);

/// A store on the fixture day that reads at once.
///
/// [parity] is the parity build: Birthdays' seeds exist only there
/// ([kLumeParityOnlySeeds]), and a development or release build opens the
/// collection empty. Both are states this tool has to draw.
LumeMemoryRecordRepository birthdaysStore({bool parity = true}) {
  final LumeMemoryRecordRepository store = LumeMemoryRecordRepository(
    seeds: (String collection, DateTime at) =>
        lumeRecordSeeds(collection, at, reproducesReference: parity),
    now: () => kFixtureInstant,
    hydrateDelay: null,
  );
  addTearDown(store.dispose);
  return store;
}

/// Pump Birthdays for a reader, through the tool route.
Future<void> pumpBirthdays(
  WidgetTester tester, {
  String state = 'default_pk',
  LumeProfileRepository? profile,
  LumeMemoryRecordRepository? store,
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  DateTime? now,
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLumeRouter(
    tester,
    initialLocation: kBirthdays,
    profile: profile ?? taxProfile(state),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
    clock: now == null ? null : LumeClock.fixed(now),
    // Appended after the harness's own, so a store the test holds wins.
    overrides: <Override>[
      recordRepositoryProvider.overrideWithValue(store ?? birthdaysStore()),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

/// Every piece of text under [of], in paint order.
List<String> textsIn(WidgetTester tester, Finder of) => <String>[
  for (final Text t in tester.widgetList<Text>(
    find.descendant(of: of, matching: find.byType(Text)),
  ))
    t.data ?? t.textSpan?.toPlainText() ?? '',
];

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

/// Let a save's deliberate delay run, and the toast that follows go.
Future<void> settleSave(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}
