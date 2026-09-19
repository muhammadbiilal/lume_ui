/// Ledger on screen: the tool opened for a reader over a store the test
/// holds, with the reference's three people written as the reader would
/// write them — a test fixture, never seeded into a reader's Ledger (D11).
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/platform_services.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/platform/lume_export.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/ledger/application/ledger_providers.dart';
import 'package:lume/features/ledger/domain/ledger_failure.dart';
import 'package:lume/features/ledger/domain/ledger_model.dart';
import 'package:lume/features/ledger/domain/ledger_repository.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// A store and a Ledger on the fixture instant (7 September 2026, 11:41
/// UTC), ids from a seeded source.
class LedgerWorld {
  LedgerWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = LedgerRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final LedgerRepository repo;
  DateTime clock = kFixtureInstant.subtract(const Duration(days: 60));
  final LumeRecordingTextSharer sharer = LumeRecordingTextSharer();
  final LumeRecordingExporter exporter = LumeRecordingExporter();

  final Map<String, LumeRecordId> people = <String, LumeRecordId>{};

  LumeRecordId person(String name, {String? note}) {
    clock = clock.add(const Duration(minutes: 1));
    return people[name] = repo.addParty(name, note: note).value!.id;
  }

  LedgerEntry add(
    String name,
    LedgerKind kind,
    LumeMoney amount,
    LumeDate on, {
    LumeDate? due,
    String? note,
    bool confirm = false,
  }) {
    clock = clock.add(const Duration(minutes: 1));
    final LedgerResult<LedgerWrite> r = repo.addEntry(
      LedgerEntryDraft(
        partyId: people[name]!,
        kind: kind,
        amount: amount,
        on: on,
        due: due,
        note: note,
      ),
      confirmExcess: confirm,
    );
    if (r.failure != null) throw StateError('${r.failure}');
    return r.value!.entry!;
  }

  /// The reference's composition as the reader would enter it, in their
  /// currency: Ahmed owes 34,000 (due 19 Sept), Sara is owed 12,700,
  /// Bilal owes 17,000 overdue since 31 Aug. PKR by default.
  LedgerWorld reference([LumeCurrency? currency]) {
    final LumeCurrency c = currency ?? LumeCurrency.of('PKR');
    LumeMoney m(int major) => LumeMoney.entry(major * c.scale, c);
    person('Ahmed');
    person('Sara');
    person('Bilal');
    add(
      'Ahmed',
      LedgerKind.lent,
      m(34000),
      LumeDate(2026, 8, 11),
      due: LumeDate(2026, 9, 19),
      note: 'Car repair',
    );
    add(
      'Sara',
      LedgerKind.borrowed,
      m(12700),
      LumeDate(2026, 9, 1),
      note: 'Dinner',
    );
    add(
      'Bilal',
      LedgerKind.lent,
      m(17000),
      LumeDate(2026, 7, 17),
      due: LumeDate(2026, 8, 31),
      note: 'Rent share',
    );
    clock = kFixtureInstant;
    return this;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    ledgerRepositoryProvider.overrideWithValue(repo),
    textSharerProvider.overrideWithValue(sharer),
    exporterProvider.overrideWithValue(exporter),
  ];

  void dispose() => store.dispose();
}

Future<GoRouter> pumpLedger(
  WidgetTester tester,
  LedgerWorld world, {
  String state = 'default_pk',
  LumeProfileRepository? profile,
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String query = '',
  List<Override> overrides = const <Override>[],
  bool animate = false,
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation:
        '${LumeRoutes.tool(LumeRoutes.tools, 'ledger')}${query.isEmpty ? '' : '?$query'}',
    profile: profile ?? taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    animate: animate,
    overrides: <Override>[...world.overrides, ...overrides],
  );
  await tester.pumpAndSettle();
  return router;
}
