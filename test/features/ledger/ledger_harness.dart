/// A Ledger over an in-memory store, a controllable clock and seeded ids —
/// deterministic, and never the wall clock.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/values/lume_record_id.dart';
import 'package:lume/features/ledger/domain/ledger_book.dart';
import 'package:lume/features/ledger/domain/ledger_failure.dart';
import 'package:lume/features/ledger/domain/ledger_model.dart';
import 'package:lume/features/ledger/domain/ledger_repository.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';

final LumeCurrency pkr = LumeCurrency.of('PKR');
final LumeCurrency usd = LumeCurrency.of('USD');

/// Rupees, in paisa.
LumeMoney rs(num rupees) => LumeMoney.entry((rupees * 100).round(), pkr);

/// Dollars, in cents.
LumeMoney usdollars(num dollars) =>
    LumeMoney.entry((dollars * 100).round(), usd);

/// 2026 dates.
LumeDate d(int month, int day) => LumeDate(2026, month, day);

/// The worked examples' today: 7 September 2026.
final LumeDate kToday = d(9, 7);

class LedgerHarness {
  LedgerHarness({int seed = 1}) {
    store = LumeMemoryRecordRepository(hydrateDelay: null, now: () => clock);
    repo = LedgerRepository(store, random: Random(seed), now: () => clock);
    repo.open();
  }

  late final LumeMemoryRecordRepository store;
  late final LedgerRepository repo;
  DateTime clock = DateTime.utc(2026, 9, 7, 10);

  /// Each write a minute after the last, so creation instants differ.
  void tick([Duration by = const Duration(minutes: 1)]) =>
      clock = clock.add(by);

  LedgerBook book([LumeDate? today]) => repo.view().book(today ?? kToday);

  LumeRecordId person(String name) {
    tick();
    final LedgerResult<LedgerParty> r = repo.addParty(name);
    expect(r.failure, isNull, reason: 'add $name');
    return r.value!.id;
  }

  LedgerResult<LedgerWrite> tryAdd(
    LumeRecordId party,
    LedgerKind kind,
    LumeMoney amount,
    LumeDate on, {
    LumeDate? due,
    bool confirm = false,
    List<LedgerManualDraft>? manual,
  }) {
    tick();
    return repo.addEntry(
      LedgerEntryDraft(
        partyId: party,
        kind: kind,
        amount: amount,
        on: on,
        due: due,
      ),
      confirmExcess: confirm,
      manual: manual,
    );
  }

  LedgerEntry add(
    LumeRecordId party,
    LedgerKind kind,
    LumeMoney amount,
    LumeDate on, {
    LumeDate? due,
    bool confirm = false,
    List<LedgerManualDraft>? manual,
  }) {
    final LedgerResult<LedgerWrite> r = tryAdd(
      party,
      kind,
      amount,
      on,
      due: due,
      confirm: confirm,
      manual: manual,
    );
    expect(r.failure, isNull, reason: '$kind $amount');
    return r.value!.entry!;
  }

  LedgerEntry entry(LumeRecordId id) => book().entry(id)!;

  LedgerBalance row(LumeRecordId party, [LumeCurrency? currency]) => book()
      .balancesOf(party)
      .firstWhere((LedgerBalance b) => b.currency == (currency ?? pkr));

  /// The counting allocations from a repayment, as (principal, minor).
  List<(LumeRecordId, int)> paid(LumeRecordId repayment) =>
      <(LumeRecordId, int)>[
        for (final LedgerAllocation a in book().allocationsOf(repayment))
          if (a.repaymentId == repayment) (a.principalId, a.amount.minor),
      ];

  int remaining(LumeRecordId principal) => book().remaining[principal]!.minor;
  int credit(LumeRecordId repayment) => book().credit[repayment]!.minor;

  void expectSound() => expect(book().invariants(), isEmpty);

  void dispose() => store.dispose();
}
