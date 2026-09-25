/// Habits on screen: the tool opened for a reader over a store the test
/// holds — a test fixture, never seeded into a reader's Habits.
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
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/habits/application/habits_providers.dart';
import 'package:lume/features/habits/domain/habits_book.dart';
import 'package:lume/features/habits/domain/habits_failure.dart';
import 'package:lume/features/habits/domain/habits_model.dart';
import 'package:lume/features/habits/domain/habits_repository.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

class HabitsWorld {
  HabitsWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = HabitsRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final HabitsRepository repo;
  DateTime clock = kFixtureInstant;
  final Map<String, LumeRecordId> habits = <String, LumeRecordId>{};

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  Habit add(
    String name, {
    HabitFrequency frequency = HabitFrequency.daily,
    String? notes,
  }) {
    _tick();
    final HabitsResult<HabitsWrite> r = repo.addHabit(
      HabitDraft(name: name, frequency: frequency, notes: notes),
    );
    if (r.failure != null) throw StateError('${r.failure}');
    habits[name] = r.value!.habit!.id;
    return r.value!.habit!;
  }

  void checkIn(LumeRecordId id, LumeDate date) {
    _tick();
    final HabitsResult<HabitsWrite> r = repo.toggleCheckin(id, date);
    if (r.failure != null) throw StateError('${r.failure}');
  }

  /// One habit with real state, entered as a reader would, checked off
  /// today and yesterday.
  HabitsWorld reference() {
    final Habit h = add('Read');
    checkIn(h.id, LumeDate(2026, 9, 6));
    checkIn(h.id, LumeDate(2026, 9, 7));
    clock = kFixtureInstant;
    return this;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    habitsRepositoryProvider.overrideWithValue(repo),
  ];

  HabitsBook book([LumeDate? today]) =>
      repo.view().book(today ?? LumeDate(2026, 9, 7));

  void dispose() => store.dispose();
}

Future<GoRouter> pumpHabits(
  WidgetTester tester,
  HabitsWorld world, {
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
    initialLocation: LumeRoutes.tool(LumeRoutes.tools, 'habits'),
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
