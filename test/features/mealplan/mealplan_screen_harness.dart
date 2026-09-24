/// Meal Plan on screen: the tool opened for a reader over a store the
/// test holds — a test fixture, never seeded into a reader's Meal Plan.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/features/mealplan/application/mealplan_providers.dart';
import 'package:lume/features/mealplan/domain/mealplan_book.dart';
import 'package:lume/features/mealplan/domain/mealplan_failure.dart';
import 'package:lume/features/mealplan/domain/mealplan_model.dart';
import 'package:lume/features/mealplan/domain/mealplan_repository.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

class MealPlanWorld {
  MealPlanWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(hydrateDelay: readDelay, now: () => clock);
    repo = MealPlanRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final MealPlanRepository repo;
  DateTime clock = kFixtureInstant;

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  MealPlanEntry set(LumeDate date, MealSlot slot, String text) {
    _tick();
    final MealPlanResult<MealPlanWrite> r = repo.setSlot(date, slot, text);
    if (r.failure != null) throw StateError('${r.failure}');
    return r.value!.entry!;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    mealPlanRepositoryProvider.overrideWithValue(repo),
  ];

  MealPlanWeek week(LumeDate today) => repo.view().week(today);

  void dispose() => store.dispose();
}

Future<GoRouter> pumpMealPlan(
  WidgetTester tester,
  MealPlanWorld world, {
  String state = 'default_pk',
  LumeProfileRepository? profile,
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: LumeRoutes.tool(LumeRoutes.tools, 'mealplan'),
    profile: profile ?? taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    overrides: <Override>[...world.overrides, ...overrides],
  );
  await tester.pumpAndSettle();
  return router;
}
