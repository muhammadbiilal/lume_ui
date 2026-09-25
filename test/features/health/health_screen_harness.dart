/// Health Records on screen: the tool opened for a reader over a store the
/// test holds — a test fixture, never seeded into a reader's Health Records.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/health/application/health_providers.dart';
import 'package:lume/features/health/domain/health_book.dart';
import 'package:lume/features/health/domain/health_failure.dart';
import 'package:lume/features/health/domain/health_model.dart';
import 'package:lume/features/health/domain/health_repository.dart';
import 'package:lume/features/health/presentation/health_tool.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

/// The catalogue's own `health` entry — read, never redefined, so a test
/// exercises the same metadata the shipped app gates on.
LumeFeature healthFeature() =>
    kLumeFeatures.firstWhere((LumeFeature f) => f.id == 'health');

class HealthWorld {
  HealthWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = HealthRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final HealthRepository repo;
  DateTime clock = kFixtureInstant.subtract(const Duration(days: 60));
  final Map<String, LumeRecordId> records = <String, LumeRecordId>{};

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  HealthRecord add(
    String title, {
    HealthRecordKind kind = HealthRecordKind.appointment,
    LumeDate? date,
    String? source = 'City Clinic',
    String? value,
    String? notes,
  }) {
    _tick();
    final HealthResult<HealthWrite> r = repo.add(
      HealthDraft(
        title: title,
        kind: kind,
        date: date ?? LumeDate(2026, 1, 14),
        source: source,
        value: value,
        notes: notes,
      ),
    );
    if (r.failure != null) throw StateError('${r.failure}');
    records[title] = r.value!.record!.id;
    return r.value!.record!;
  }

  /// One record with real state, entered as a reader would.
  HealthWorld reference() {
    add('Annual physical', date: LumeDate(2026, 9, 14));
    clock = kFixtureInstant;
    return this;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    healthRepositoryProvider.overrideWithValue(repo),
  ];

  HealthBook book([LumeDate? today]) =>
      repo.view().book(today ?? LumeDate(2026, 9, 7));

  void dispose() => store.dispose();
}

/// Pumps [HealthTool] directly — bypassing the route table, which does not
/// yet carry an entry for this tool's id (a separate integration step, not
/// part of building the tool itself). This mirrors what every other tool's
/// test does through `pumpLumeRouter`/`LumeRoutes.tool`, just one layer
/// lower: a real [LumeToolRequest] over the same [pumpLume] harness every
/// other widget test in this codebase already uses.
Future<void> pumpHealth(
  WidgetTester tester,
  HealthWorld world, {
  LumeUserContext user = const LumeUserContext(),
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    LumeHealthTool.open(
      LumeToolRequest(feature: healthFeature(), user: user, branch: 'tools'),
    ),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    overrides: <Override>[...world.overrides, ...overrides],
  );
}
