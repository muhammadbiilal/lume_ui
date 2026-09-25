/// Vaccinations on screen: the tool built directly over a store the test
/// holds — a test fixture, never seeded into a reader's Vaccinations.
///
/// Vaccinations is not yet named in `tool_registry.dart` (that mapping is
/// added when it is wired into the app, alongside the other tools built in
/// this same rollout), so there is no `LumeRoutes.tool(..., 'vaccines')` to
/// route to yet. This pumps the tool widget directly through [pumpLume],
/// exactly as `tool_frame_test.dart` pumps `LumeToolFrame` directly — the
/// same environment a routed screen renders inside of, minus the shell
/// around it.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/vaccines/application/vaccines_providers.dart';
import 'package:lume/features/vaccines/domain/vaccines_repository.dart';
import 'package:lume/features/vaccines/presentation/vaccines_tool.dart';

import '../../helpers/lume_harness.dart';

/// The real catalogue entry — read, never duplicated, so a test exercises
/// the actual metadata (`sensitive: true`, its `related` set) rather than a
/// stand-in that could drift from it.
final LumeFeature kVaccinesFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == 'vaccines',
);

class VaccinesWorld {
  VaccinesWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(hydrateDelay: readDelay, now: () => clock);
    repo = VaccinesRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final VaccinesRepository repo;
  DateTime clock = kFixtureInstant;

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    vaccinesRepositoryProvider.overrideWithValue(repo),
  ];

  void dispose() => store.dispose();
}

Future<void> pumpVaccines(
  WidgetTester tester,
  VaccinesWorld world, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  double textScale = 1,
  List<Override> overrides = const <Override>[],
  VoidCallback? onBack,
  ValueChanged<String>? onOpenRelated,
}) async {
  await pumpLume(
    tester,
    VaccinesTool(
      request: LumeToolRequest(
        feature: kVaccinesFeature,
        user: user,
        branch: 'tools',
        onBack: onBack,
        onOpenRelated: onOpenRelated,
      ),
    ),
    surface: LumeViewport.tall,
    locale: locale,
    textScale: textScale,
    overrides: <Override>[...world.overrides, ...overrides],
  );
  await tester.pumpAndSettle();
}
