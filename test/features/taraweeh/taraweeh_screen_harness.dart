/// Taraweeh on screen: the tool opened directly for a reader over a store
/// the test holds.
///
/// Unlike most converted tools, this pumps [TaraweehTool] directly
/// ([pumpLume]) rather than through the real router (`LumeRoutes.tool(...)`):
/// Taraweeh's wave lands in parallel with several other tools, and the
/// shared `tool_registry.dart` this repository routes through is out of
/// scope for this change — it is wired up in the integration pass that
/// follows. The screen itself is exercised exactly as the router would host
/// it, with the same provider overrides and the same clock.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/taraweeh/application/taraweeh_providers.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_failure.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_model.dart';
import 'package:lume/features/taraweeh/domain/taraweeh_repository.dart';
import 'package:lume/features/taraweeh/presentation/taraweeh_tool.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

class TaraweehWorld {
  TaraweehWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = TaraweehRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final TaraweehRepository repo;
  DateTime clock = kFixtureInstant;

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  TaraweehNight logTonight(LumeDate date, {int rakaat = 20}) {
    _tick();
    final TaraweehResult<TaraweehWrite> r = repo.logTonight(
      date,
      rakaat: rakaat,
    );
    if (r.failure != null) throw StateError('${r.failure}');
    return r.value!.night!;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    taraweehRepositoryProvider.overrideWithValue(repo),
  ];

  void dispose() => store.dispose();
}

/// The fixture night, matching [kFixtureInstant]: 7 September 2026.
final LumeDate kToday = LumeDate(2026, 9, 7);

Future<void> pumpTaraweeh(
  WidgetTester tester,
  TaraweehWorld world, {
  LumeUserContext user = const LumeUserContext(islamic: true),
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  List<Override> overrides = const <Override>[],
}) async {
  final LumeFeature feature = kLumeFeatures.firstWhere(
    (LumeFeature f) => f.id == LumeTaraweehTool.id,
  );
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    TaraweehTool(
      request: LumeToolRequest(feature: feature, user: user, branch: 'tools'),
    ),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    overrides: <Override>[
      startupControllerProvider.overrideWithValue(gate),
      ...world.overrides,
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}
