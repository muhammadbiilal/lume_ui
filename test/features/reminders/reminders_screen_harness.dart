/// Reminders on screen: the tool opened for a reader over the store the
/// test holds — never seeded, matching Option B's own starting point.
///
/// **Deliberately the in-memory store, not the real SQLite one.** The
/// repository is typed to [LumeRecordRepository] precisely so a widget test
/// can substitute the deterministic, synchronous, Timer-based memory store —
/// exactly like every other family's screen test — rather than a real
/// FFI-backed database, whose genuine cross-isolate I/O
/// `TestWidgetsFlutterBinding`'s controlled zone does not reliably service.
/// Real SQLite durability is proven where it belongs, against the real
/// thing: `reminders_domain_test.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/core/platform/lume_notification_gate.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/reminders/application/reminder_providers.dart';
import 'package:lume/features/reminders/data/reminder_scheduler.dart';
import 'package:lume/features/reminders/domain/reminder_repository.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';
import 'reminders_harness.dart';

class ReminderWorld {
  ReminderWorld({Duration? readDelay}) {
    store = LumeMemoryRecordRepository(hydrateDelay: readDelay, now: () => kFixtureNow);
    scheduler = LumeFakeReminderScheduler();
    repo = ReminderRepository(store, scheduler, now: () => kFixtureNow);
    gate = LumeFakeNotificationGate(
      now: const LumeNotificationState(LumeNotificationAccess.granted),
    );
    if (readDelay == null) repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final LumeFakeReminderScheduler scheduler;
  late final ReminderRepository repo;
  late final LumeFakeNotificationGate gate;

  List<Override> get overrides => <Override>[
    reminderStoreProvider.overrideWithValue(store),
    reminderSchedulerProvider.overrideWithValue(scheduler),
    reminderRepositoryProvider.overrideWithValue(repo),
    notificationGateProvider.overrideWithValue(gate),
  ];

  void dispose() => store.dispose();
}

Future<GoRouter> pumpReminders(
  WidgetTester tester,
  ReminderWorld world, {
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
    initialLocation: LumeRoutes.tool(LumeRoutes.tools, 'reminders'),
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
