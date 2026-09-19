/// Installments on screen: the tool opened for a reader over a store the
/// test holds, with the reference's three plans written as the reader would
/// write them — a test fixture, never seeded into a reader's Installments.
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
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/installments/application/installments_providers.dart';
import 'package:lume/features/installments/domain/installments_book.dart';
import 'package:lume/features/installments/domain/installments_failure.dart';
import 'package:lume/features/installments/domain/installments_model.dart';
import 'package:lume/features/installments/domain/installments_repository.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// A store and Installments on the fixture instant (7 September 2026, 11:41
/// UTC), ids from a seeded source.
class InstallmentsWorld {
  InstallmentsWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = InstallmentsRepository(
      store,
      random: Random(seed),
      now: () => clock,
    );
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final InstallmentsRepository repo;
  DateTime clock = kFixtureInstant.subtract(const Duration(days: 200));
  final LumeRecordingExporter exporter = LumeRecordingExporter();
  final Map<String, LumeRecordId> plans = <String, LumeRecordId>{};

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  InstallmentPlan add(
    String item,
    LumeMoney amount,
    int count,
    LumeDate firstDue, {
    String? merchant,
    String? note,
    LumeMoney? deposit,
    LumeDate? depositOn,
    LumeMoney? cashPrice,
  }) {
    _tick();
    final InstallmentsResult<InstallmentsWrite> r = repo.addPlan(
      InstallmentPlanDraft(
        item: item,
        merchant: merchant,
        note: note,
        amount: amount,
        count: count,
        firstDue: firstDue,
        deposit: deposit,
        depositOn: depositOn,
        cashPrice: cashPrice,
      ),
    );
    if (r.failure != null) throw StateError('${r.failure}');
    plans[item] = r.value!.plan!.id;
    return r.value!.plan!;
  }

  /// Pay [item]'s next [n] instalments, each on its due date.
  void pay(String item, int n) {
    for (int i = 0; i < n; i++) {
      final InstallmentRow next = repo
          .view()
          .book(null)
          .plan(plans[item]!)!
          .next!;
      _tick();
      final InstallmentsResult<InstallmentsWrite> r = repo.recordPayment(
        plans[item]!,
        next.row.id,
        next.row.due,
      );
      if (r.failure != null) throw StateError('${r.failure}');
    }
  }

  /// The reference's three plans, in the reader's currency, entered as a
  /// reader would: Laptop from TechMart, 26,900 × 12, five paid, the sixth
  /// due 14 Sept; Sofa set from HomeStore, 17,500 × 9, seven paid, the
  /// eighth due 19 Sept; Phone from Mobile Hub, 13,600 × 18, three paid,
  /// the fourth due 27 Sept. PKR by default.
  InstallmentsWorld reference([LumeCurrency? currency]) {
    final LumeCurrency c = currency ?? LumeCurrency.of('PKR');
    LumeMoney m(int major) => LumeMoney.entry(major * c.scale, c);
    add('Laptop', m(26900), 12, LumeDate(2026, 4, 14), merchant: 'TechMart');
    add('Sofa set', m(17500), 9, LumeDate(2026, 2, 19), merchant: 'HomeStore');
    add('Phone', m(13600), 18, LumeDate(2026, 6, 27), merchant: 'Mobile Hub');
    pay('Laptop', 5);
    pay('Sofa set', 7);
    pay('Phone', 3);
    clock = kFixtureInstant;
    return this;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    installmentsRepositoryProvider.overrideWithValue(repo),
    exporterProvider.overrideWithValue(exporter),
  ];

  InstallmentsBook book([LumeDate? today]) =>
      repo.view().book(today ?? LumeDate(2026, 9, 7));

  void dispose() => store.dispose();
}

Future<GoRouter> pumpInstallments(
  WidgetTester tester,
  InstallmentsWorld world, {
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
        '${LumeRoutes.tool(LumeRoutes.tools, 'installments')}${query.isEmpty ? '' : '?$query'}',
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
