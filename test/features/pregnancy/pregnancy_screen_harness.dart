/// Pregnancy on screen: the tool opened for a reader over a store the test
/// holds — a test fixture, never seeded into a reader's Pregnancy
/// (`mealplan_screen_harness.dart`).
///
/// This tool is not yet wired into the shared tool registry (nine other
/// tools are being converted in this same working directory right now, and
/// that registry is a shared file no single tool's work should touch), so
/// this harness pumps [PregnancyTool] directly with a hand-built request
/// rather than going through the real router — [pumpLume], not
/// [pumpLumeRouter]. Eligibility itself still comes from the real
/// catalogue: `pregnancy` already carries its feature entry there.
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
import 'package:lume/features/pregnancy/application/pregnancy_providers.dart';
import 'package:lume/features/pregnancy/domain/pregnancy_failure.dart';
import 'package:lume/features/pregnancy/domain/pregnancy_repository.dart';
import 'package:lume/features/pregnancy/presentation/pregnancy_tool.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature kPregnancyFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == 'pregnancy',
);

class PregnancyWorld {
  PregnancyWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = PregnancyRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final PregnancyRepository repo;
  DateTime clock = kFixtureInstant;

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  PregnancyResult<PregnancyWrite> set(LumeDate lmp, LumeDate today) {
    _tick();
    final PregnancyResult<PregnancyWrite> r = repo.setLmp(lmp, today);
    if (r.failure != null) throw StateError('${r.failure}');
    return r;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    pregnancyRepositoryProvider.overrideWithValue(repo),
  ];

  void dispose() => store.dispose();
}

/// Pumps [PregnancyTool] alone, inside the full Lume environment
/// ([pumpLume]) rather than the router — see the library note.
Future<void> pumpPregnancy(
  WidgetTester tester,
  PregnancyWorld world, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  Size surface = LumeViewport.tall,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    PregnancyTool(
      request: LumeToolRequest(
        feature: kPregnancyFeature,
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
