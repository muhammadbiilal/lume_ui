/// Medication on screen: the tool pumped directly over a store the test
/// holds — a test fixture, never seeded into a reader's Medication.
///
/// Unlike most converted tools, this does not route through
/// `pumpLumeRouter`/`LumeRoutes.tool`: wiring `meds` into the shared tool
/// registry and catalogue-driven router is a separate integration pass
/// (outside this feature's own two directories), so this pumps [MedsTool]
/// directly with a hand-built [LumeToolRequest] over the real catalogue
/// entry, exactly as [pumpLume] is meant for.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/meds/application/meds_providers.dart';
import 'package:lume/features/meds/domain/meds_book.dart';
import 'package:lume/features/meds/domain/meds_failure.dart';
import 'package:lume/features/meds/domain/meds_model.dart';
import 'package:lume/features/meds/domain/meds_repository.dart';
import 'package:lume/features/meds/presentation/meds_tool.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

/// The feature exactly as the shared catalogue declares it — read, never
/// re-declared, so a test can never drift from what the real app ships.
final LumeFeature kMedsFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == 'meds',
);

class MedsWorld {
  MedsWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = MedsRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final MedsRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  MedsEntry add(
    String name, {
    String dose = '500 mg',
    MedsSchedule schedule = MedsSchedule.daily,
    String? firstDoseAt,
    int? dosesLeft,
    String? notes,
  }) {
    _tick();
    final MedsResult<MedsWrite> r = repo.add(
      MedsDraft(
        name: name,
        dose: dose,
        schedule: schedule,
        firstDoseAt: firstDoseAt,
        dosesLeft: dosesLeft,
        notes: notes,
      ),
    );
    if (r.failure != null) throw StateError('${r.failure}');
    return r.value!.medication!;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    medsRepositoryProvider.overrideWithValue(repo),
  ];

  MedsBook book() => repo.view().book();

  void dispose() => store.dispose();
}

Future<void> pumpMeds(
  WidgetTester tester,
  MedsWorld world, {
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  LumeUserContext user = const LumeUserContext(),
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    MedsTool(
      request: LumeToolRequest(
        feature: kMedsFeature,
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
