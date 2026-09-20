/// Committee on the real router, over an in-memory store with seeded ids
/// and a controllable clock.
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
import 'package:lume/features/committee/application/committee_providers.dart';
import 'package:lume/features/committee/domain/committee_book.dart';
import 'package:lume/features/committee/domain/committee_failure.dart';
import 'package:lume/features/committee/domain/committee_model.dart';
import 'package:lume/features/committee/domain/committee_repository.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

final LumeCurrency pkr = LumeCurrency.of('PKR');

LumeMoney rs(num rupees) => LumeMoney.entry((rupees * 100).round(), pkr);

LumeDate day(int month, int d) => LumeDate(2026, month, d);

/// The corrected reference committee, as a reader would enter it
/// (`COMMITTEE_PROPOSAL.md` §6, Example A).
class CommitteeWorld {
  CommitteeWorld({this.seed = 1, Duration? readDelay}) {
    store = LumeMemoryRecordRepository(
      hydrateDelay: readDelay,
      now: () => clock,
    );
    repo = CommitteeRepository(store, random: Random(seed), now: () => clock);
    if (readDelay == null) repo.open();
  }

  final int seed;
  late final LumeMemoryRecordRepository store;
  late final CommitteeRepository repo;

  /// Seeding writes land in the past, so nothing depends on a wall clock.
  DateTime clock = kFixtureInstant.subtract(const Duration(days: 200));
  final LumeRecordingExporter exporter = LumeRecordingExporter();
  final Map<String, LumeRecordId> committees = <String, LumeRecordId>{};

  void _tick() => clock = clock.add(const Duration(minutes: 1));

  Committee add({
    String name = 'Office committee',
    LumeMoney? contribution,
    LumeDate? firstDue,
    List<CommitteeMemberDraft>? members,
  }) {
    _tick();
    final CommitteeResult<CommitteeWrite> r = repo.addCommittee(
      CommitteeDraft(
        name: name,
        contribution: contribution ?? rs(28300),
        firstDue: firstDue ?? day(6, 7),
        members: members ?? reference(),
      ),
    );
    if (r.failure != null) throw StateError('add $name: ${r.failure}');
    committees[name] = r.value!.committee!.id;
    return r.value!.committee!;
  }

  static List<CommitteeMemberDraft> reference() => <CommitteeMemberDraft>[
    const CommitteeMemberDraft(name: 'Ahmed', cycles: <int>[1]),
    const CommitteeMemberDraft(name: 'Bilal', cycles: <int>[2]),
    const CommitteeMemberDraft(name: 'Sara', cycles: <int>[3]),
    const CommitteeMemberDraft(name: 'You', isReader: true, cycles: <int>[4]),
    const CommitteeMemberDraft(name: 'Hina', cycles: <int>[5]),
  ];

  CommitteeView view(LumeRecordId id, [LumeDate? today]) =>
      book(today).committee(id)!;

  CommitteeBook book([LumeDate? today]) => repo.view().book(today ?? day(9, 7));

  /// Everyone pays the cycle, except those named.
  void collect(
    LumeRecordId id,
    int n, {
    Set<String> except = const <String>{},
  }) {
    final CommitteeView v = view(id);
    final CommitteeCycleView c = v.cycles.firstWhere(
      (CommitteeCycleView x) => x.n == n,
    );
    for (final CommitteeMemberView m in v.members) {
      if (except.contains(m.name)) continue;
      _tick();
      final CommitteeResult<CommitteeWrite> r = repo.recordContribution(
        id,
        c.cycle.id,
        m.member.id,
        c.due,
      );
      if (r.failure != null) throw StateError('pay $n ${m.name}');
    }
  }

  void payout(LumeRecordId id, int n) {
    final CommitteeCycleView c = view(
      id,
    ).cycles.firstWhere((CommitteeCycleView x) => x.n == n);
    _tick();
    final CommitteeResult<CommitteeWrite> r = repo.recordPayout(
      id,
      c.cycle.id,
      c.due,
    );
    if (r.failure != null) throw StateError('payout $n: ${r.failure}');
  }

  /// The reference committee with cycles 1–3 collected and 1–2 paid out,
  /// as of 7 September 2026.
  CommitteeWorld reference_() {
    final Committee c = add();
    for (int n = 1; n <= 3; n++) {
      collect(c.id, n, except: n == 3 ? <String>{'Hina'} : <String>{});
    }
    payout(c.id, 1);
    payout(c.id, 2);
    clock = kFixtureInstant;
    return this;
  }

  List<Override> get overrides => <Override>[
    recordRepositoryProvider.overrideWithValue(store),
    committeeRepositoryProvider.overrideWithValue(repo),
    exporterProvider.overrideWithValue(exporter),
  ];

  void dispose() => store.dispose();
}

Future<GoRouter> pumpCommittee(
  WidgetTester tester,
  CommitteeWorld world, {
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
        '${LumeRoutes.tool(LumeRoutes.tools, 'committee')}'
        '${query.isEmpty ? '' : '?$query'}',
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
