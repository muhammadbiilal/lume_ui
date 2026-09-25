/// Fasting Tracker on screen: the tool opened directly (not registered in
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
import 'package:lume/features/fasting/application/fasting_providers.dart';
import 'package:lume/features/fasting/domain/fasting_failure.dart';
import 'package:lume/features/fasting/domain/fasting_model.dart';
import 'package:lume/features/fasting/domain/fasting_repository.dart';
import 'package:lume/features/fasting/presentation/fasting_tool.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature kFastingFeature = kLumeFeatures.firstWhere((LumeFeature f) => f.id == 'fasting');

class FastingWorld {
  FastingWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(hydrateDelay: readDelay, now: () => clock);
    repo = FastingRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final FastingRepository repo;
  DateTime clock = kFixtureInstant;

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  FastEntry log(
    LumeDate date, {
    FastingKind kind = FastingKind.voluntary,
    bool kept = true,
  }) {
    _tick();
    final FastingResult<FastingWrite> r = repo.logFast(date, kind: kind, kept: kept);
    if (r.failure != null) throw StateError('${r.failure}');
    return r.value!.entry!;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    fastingRepositoryProvider.overrideWithValue(repo),
  ];

  void dispose() => store.dispose();
}

/// A Muslim user context — Fasting Tracker is faith-gated (catalogue `faith:
/// true`), same as Qibla and every other Prayer & Islam feature.
const LumeUserContext kMuslimUser = LumeUserContext(islamic: true);

Future<void> pumpFasting(
  WidgetTester tester,
  FastingWorld world, {
  LumeUserContext user = kMuslimUser,
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 5000),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    FastingTool(
      request: LumeToolRequest(feature: kFastingFeature, user: user, branch: 'tools'),
    ),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    overrides: <Override>[...world.overrides, ...overrides],
  );
}
