/// Subscriptions on screen: the tool opened for a reader over a store the
/// test holds — a test fixture, never seeded into a reader's Subscriptions.
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
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/subscriptions/application/subscriptions_providers.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_book.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_failure.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_model.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_repository.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

class SubscriptionsWorld {
  SubscriptionsWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = SubscriptionsRepository(
      store,
      random: Random(seed),
      now: () => clock,
    );
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final SubscriptionsRepository repo;
  DateTime clock = kFixtureInstant.subtract(const Duration(days: 60));
  final Map<String, LumeRecordId> subs = <String, LumeRecordId>{};

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  Subscription add(
    String name,
    LumeMoney amount, {
    String? category = 'Entertainment',
    SubscriptionCycle cycle = SubscriptionCycle.monthly,
    int? customDays,
    LumeDate? startedOn,
  }) {
    _tick();
    final SubscriptionsResult<SubscriptionsWrite> r = repo.add(
      SubscriptionDraft(
        name: name,
        category: category,
        amount: amount,
        cycle: cycle,
        customDays: customDays,
        startedOn: startedOn ?? LumeDate(2026, 1, 14),
      ),
    );
    if (r.failure != null) throw StateError('${r.failure}');
    subs[name] = r.value!.subscription!.id;
    return r.value!.subscription!;
  }

  /// One subscription with real state, entered as a reader would.
  SubscriptionsWorld reference([LumeCurrency? currency]) {
    final LumeCurrency c = currency ?? LumeCurrency.of('PKR');
    LumeMoney m(int major) => LumeMoney.entry(major * c.scale, c);
    add('Netflix', m(9), startedOn: LumeDate(2026, 8, 14));
    clock = kFixtureInstant;
    return this;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    subscriptionsRepositoryProvider.overrideWithValue(repo),
  ];

  SubscriptionsBook book([LumeDate? today]) =>
      repo.view().book(today ?? LumeDate(2026, 9, 7));

  void dispose() => store.dispose();
}

Future<GoRouter> pumpSubscriptions(
  WidgetTester tester,
  SubscriptionsWorld world, {
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
        '${LumeRoutes.tool(LumeRoutes.tools, 'subs')}${query.isEmpty ? '' : '?$query'}',
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
