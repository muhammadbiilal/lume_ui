/// Goals on screen: the tool opened for a reader over a store the test
/// holds — a test fixture, never seeded into a reader's Goals.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/goals/application/goals_providers.dart';
import 'package:lume/features/goals/domain/goals_book.dart';
import 'package:lume/features/goals/domain/goals_failure.dart';
import 'package:lume/features/goals/domain/goals_model.dart';
import 'package:lume/features/goals/domain/goals_repository.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// A store and Goals on the fixture instant, ids from a seeded source.
class GoalsWorld {
  GoalsWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = GoalsRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final GoalsRepository repo;
  DateTime clock = kFixtureInstant.subtract(const Duration(days: 60));
  final Map<String, LumeRecordId> goals = <String, LumeRecordId>{};

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  Goal add(
    String name,
    LumeMoney target, {
    LumeDate? targetDate,
    GoalIcon icon = GoalIcon.target,
  }) {
    _tick();
    final GoalsResult<GoalsWrite> r = repo.addGoal(
      GoalDraft(name: name, target: target, targetDate: targetDate, icon: icon),
    );
    if (r.failure != null) throw StateError('${r.failure}');
    goals[name] = r.value!.goal!.id;
    return r.value!.goal!;
  }

  void contribute(String name, LumeMoney amount, LumeDate on) {
    _tick();
    final GoalsResult<GoalsWrite> r = repo.addContribution(
      goals[name]!,
      amount,
      on,
    );
    if (r.failure != null) throw StateError('${r.failure}');
  }

  /// One goal with real progress, entered as a reader would.
  GoalsWorld reference([LumeCurrency? currency]) {
    final LumeCurrency c = currency ?? LumeCurrency.of('PKR');
    LumeMoney m(int major) => LumeMoney.entry(major * c.scale, c);
    add('Emergency fund', m(60000), targetDate: LumeDate(2026, 12, 1));
    contribute('Emergency fund', m(38400), LumeDate(2026, 8, 1));
    clock = kFixtureInstant;
    return this;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    goalsRepositoryProvider.overrideWithValue(repo),
  ];

  GoalsBook book([LumeDate? today]) =>
      repo.view().book(today ?? LumeDate(2026, 9, 7));

  void dispose() => store.dispose();
}

Future<GoRouter> pumpGoals(
  WidgetTester tester,
  GoalsWorld world, {
  String state = 'default_pk',
  LumeProfileRepository? profile,
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String query = '',
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation:
        '${LumeRoutes.tool(LumeRoutes.tools, 'goals')}${query.isEmpty ? '' : '?$query'}',
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
