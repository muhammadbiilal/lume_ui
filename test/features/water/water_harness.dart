/// Water's shared test harness: the tool opened for a reader, over a record
/// store the test holds.
///
/// Water is not in `kLumeToolRegistry` yet — the integrator adds it — so
/// there is no route to pump. [pumpWater] builds the [LumeToolRequest] the
/// route would build, from the same catalogue entry and the same profile, and
/// hands it to [LumeWaterTool.open] inside the app's own providers.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/auth/domain/auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/water/presentation/water_tool.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// The catalogue's own entry — the one the route would pass.
final LumeFeature kWaterFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeWaterTool.id,
);

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

/// Pump Water for a reader.
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
  final LumeProfileRepository profiles = profile ?? taxProfile(state);
  final LumeAuthRepository auth = LumeFakeAuthRepository.withAccount();
  final LumeStartupController gate = LumeStartupController(
    authRepository: auth,
    profileRepository: profiles,
  );
  addTearDown(gate.dispose);
  // The launch, as the router's host runs it. Not awaited: the profile scope
  // listens, and the pump below settles once it has published.
  unawaited(gate.boot());

  await pumpLume(
    tester,
    LumeProfileScope(
      builder: (BuildContext context, LumeUserContext user) =>
          LumeWaterTool.open(
            LumeToolRequest(
              feature: kWaterFeature,
              user: user,
              branch: LumeRoutes.tools,
            ),
          ),
    ),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
    now: now,
    overrides: <Override>[
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(profiles),
      startupControllerProvider.overrideWithValue(gate),
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
