/// Cycle Tracker on screen: the tool opened directly (not registered in
/// `tool_registry.dart` yet — that happens when every parallel conversion
/// lands together) over a store the test holds.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/cycle/application/cycle_providers.dart';
import 'package:lume/features/cycle/domain/cycle_failure.dart';
import 'package:lume/features/cycle/domain/cycle_model.dart';
import 'package:lume/features/cycle/domain/cycle_repository.dart';
import 'package:lume/features/cycle/presentation/cycle_tool.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature kCycleFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == 'cycle',
);

class CycleWorld {
  CycleWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = CycleRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final CycleRepository repo;
  DateTime clock = kFixtureInstant;

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  CyclePeriod log(LumeDate start, {LumeDate? end}) {
    _tick();
    final CycleResult<CycleWrite> r = repo.logPeriod(start, end: end);
    if (r.failure != null) throw StateError('${r.failure}');
    return r.value!.period!;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    cycleRepositoryProvider.overrideWithValue(repo),
  ];

  void dispose() => store.dispose();
}

Future<void> pumpCycle(
  WidgetTester tester,
  CycleWorld world, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 5000),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    CycleTool(
      request: LumeToolRequest(
        feature: kCycleFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    overrides: <Override>[...world.overrides, ...overrides],
  );
}
