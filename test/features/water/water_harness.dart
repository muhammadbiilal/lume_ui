/// Water's shared test harness: the tool opened for a reader, over a record
/// store the test holds.
///
/// `tool_registry.dart` names `water`, so [pumpWater] opens the route and the
/// tool is built by `app_router.dart` `_tool` itself — the same eligibility,
/// read from the same profile, refusing in the same place — inside the shell
/// that draws around it. That shell is what makes the tool bar's back control
/// and the rail-inset wide columns real, which the parity cells are measured
/// against.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';
import 'package:lume/features/water/presentation/water_tool.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// `/tools/tool/water`.
final String kWater = LumeRoutes.tool(LumeRoutes.tools, LumeWaterTool.id);

/// A store on the fixture day that reads at once.
///
/// [seeded] is the parity build: Water's seeds exist only there
/// ([kLumeParityOnlySeeds]), and a development or release build opens the
/// collection empty. Both are states this tool has to draw.
LumeMemoryRecordRepository waterStore({bool seeded = true, DateTime? now}) {
  final LumeMemoryRecordRepository store = LumeMemoryRecordRepository(
    seeds: (String collection, DateTime at) =>
        lumeRecordSeeds(collection, at, reproducesReference: seeded),
    now: () => now ?? kFixtureInstant,
    hydrateDelay: null,
  );
  addTearDown(store.dispose);
  return store;
}

/// Pump Water for a reader, through the tool route.
Future<void> pumpWater(
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
    initialLocation: kWater,
    profile: profile ?? taxProfile(state),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
    clock: now == null ? null : LumeClock.fixed(now),
    // Appended after the harness's own, so a store the test holds wins.
    overrides: <Override>[
      recordRepositoryProvider.overrideWithValue(store ?? waterStore()),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

/// A reader whose zone is what [zone] says — an identifier no database has,
/// to reach the day-unknown state.
LumeProfileRepository waterReader({String? zone, String country = 'PK'}) =>
    LumeMemoryProfileRepository(
      initial: taxReader(country: country).copyWith(timeZone: zone),
    );

/// Every string rendered under [of], in paint order.
List<String> waterTexts(WidgetTester tester, Finder of) => <String>[
  for (final Text t in tester.widgetList<Text>(
    find.descendant(of: of, matching: find.byType(Text)),
  ))
    if (t.data != null) t.data!,
];

/// Every string on the screen.
List<String> allTexts(WidgetTester tester) => <String>[
  for (final Text t in tester.widgetList<Text>(find.byType(Text)))
    if (t.data != null) t.data!,
];

Future<void> tapWater(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}
