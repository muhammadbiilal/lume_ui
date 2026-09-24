import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_book.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_failure.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_model.dart';
import 'package:lume/features/subscriptions/domain/subscriptions_repository.dart';

import 'subscriptions_harness.dart';

void main() {
  group('model and codec', () {
    test('a subscription round-trips through its fields', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add(name: 'Spotify', category: 'Music', amount: rs(5));
      expect(s.name, 'Spotify');
      expect(s.category, 'Music');
      expect(s.amount, rs(5));
      expect(s.state, SubscriptionState.active);
    });

    test('a zero amount is refused', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final SubscriptionsResult<SubscriptionsWrite> r = h.tryAdd(amount: rs(0));
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'amount');
    });

    test('an empty name is refused', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final SubscriptionsResult<SubscriptionsWrite> r = h.tryAdd(name: '  ');
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'name');
    });

    test('a custom cycle needs a day count in range', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final SubscriptionsResult<SubscriptionsWrite> r = h.tryAdd(
        cycle: SubscriptionCycle.custom,
        customDays: null,
      );
      expect(r.ok, isFalse);
      expect(r.failure!.field, 'customDays');
    });

    test('a record of the wrong schema is a defect, not a crash', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      h.raw(SubscriptionsCollections.subscriptions, 'not-a-uuid', <String, Object?>{
        'schema': 'lume.other/1',
      });
      expect(h.book().defects, hasLength(1));
      expect(h.book().defects.first.reason, 'schema');
    });
  });

  group('renewal — real arithmetic, never a hand-typed pair', () {
    test('monthly: the next occurrence on or after today', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      // Started 14 Jan; today is 7 Sep -> next occurrence is 14 Sep.
      final Subscription s = h.add(startedOn: d(1, 14));
      final SubscriptionView v = h.view(s.id, kToday);
      expect(v.nextRenewal, d(9, 14));
      expect(v.daysUntil, 7);
      expect(v.dueSoon, isTrue);
    });

    test('monthly: today falls exactly on the renewal day', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add(startedOn: d(1, 7));
      final SubscriptionView v = h.view(s.id, kToday);
      expect(v.nextRenewal, kToday);
      expect(v.daysUntil, 0);
    });

    test('monthly: month-end clamps without drifting (31 Jan -> 28 Feb -> 31 Mar)', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add(startedOn: LumeDate(2026, 1, 31));
      expect(h.view(s.id, LumeDate(2026, 2, 1)).nextRenewal, LumeDate(2026, 2, 28));
      expect(h.view(s.id, LumeDate(2026, 3, 1)).nextRenewal, LumeDate(2026, 3, 31));
    });

    test('yearly: the next anniversary on or after today', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add(
        startedOn: d(3, 3),
        cycle: SubscriptionCycle.yearly,
      );
      final SubscriptionView v = h.view(s.id, kToday);
      expect(v.nextRenewal, LumeDate(2027, 3, 3));
    });

    test('custom: every stepDays from the anchor', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add(
        startedOn: d(8, 1),
        cycle: SubscriptionCycle.custom,
        customDays: 14,
      );
      // 1 Aug, 15 Aug, 29 Aug, 12 Sep — the first on/after 7 Sep.
      final SubscriptionView v = h.view(s.id, kToday);
      expect(v.nextRenewal, d(9, 12));
    });

    test('without the reader\'s day, nothing is dated', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add();
      final SubscriptionView v = h.repo.view().book(null).subscription(s.id)!;
      expect(v.nextRenewal, isNull);
      expect(v.daysUntil, isNull);
      expect(v.dueSoon, isFalse);
    });
  });

  group('monthly-equivalent — corrects the reference\'s row mislabel', () {
    test('monthly is itself', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add(amount: rs(9));
      expect(h.view(s.id).monthlyEquivalent, rs(9));
    });

    test('yearly divides by 12 — never shown as the row\'s bare amount', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add(amount: rs(120), cycle: SubscriptionCycle.yearly);
      expect(h.view(s.id).monthlyEquivalent, rs(10));
    });

    test('custom scales by 30/customDays', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add(
        amount: rs(14),
        cycle: SubscriptionCycle.custom,
        customDays: 14,
      );
      // 14 / 14 * 30 = 30.
      expect(h.view(s.id).monthlyEquivalent, rs(30));
    });
  });

  group('aggregate summary', () {
    test('monthly is the sum of active subscriptions\' equivalents; yearly is real math on it', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      h.add(name: 'Netflix', amount: rs(9));
      h.add(name: 'Spotify', amount: rs(5));
      final Subscription yearly = h.add(
        name: 'Domain',
        amount: rs(14),
        cycle: SubscriptionCycle.yearly,
      );
      h.repo.setCancelled(yearly.id, true, version: yearly.version);

      final SubscriptionsCurrencySummary s = h.book().summary(pkr);
      // Cancelled is excluded, matching the reference's "active" concept
      // this build adds (the reference has none at all).
      expect(s.monthly, rs(14));
      expect(s.yearly, rs(168));
      expect(s.activeCount, 2);
    });

    test('next is the active subscription renewing soonest', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription soon = h.add(name: 'Soon', startedOn: d(9, 10));
      h.add(name: 'Later', startedOn: d(11, 1));
      final SubscriptionsCurrencySummary s = h.book().summary(pkr);
      expect(s.next?.subscription.id, soon.id);
    });

    test('byCategory groups active subscriptions, real sums', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      h.add(name: 'Netflix', category: 'Entertainment', amount: rs(9));
      h.add(name: 'Prime', category: 'Entertainment', amount: rs(6));
      h.add(name: 'Spotify', category: 'Music', amount: rs(5));
      final Map<String, LumeMoney> byCat = h.book().byCategory(pkr, 'Other');
      expect(byCat['Entertainment'], rs(15));
      expect(byCat['Music'], rs(5));
    });

    test('upcoming is sorted by days until renewal, real records only', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription later = h.add(name: 'Later', startedOn: d(11, 1));
      final Subscription soon = h.add(name: 'Soon', startedOn: d(9, 10));
      final List<SubscriptionView>? up = h.book().upcoming();
      expect(up, isNotNull);
      expect(up!.first.subscription.id, soon.id);
      expect(up.last.subscription.id, later.id);
    });
  });

  group('mixed currencies', () {
    test('summaries never sum across currencies', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      h.add(name: 'Netflix', amount: rs(9));
      h.add(name: 'US thing', amount: dollars(3));
      final SubscriptionsBook book = h.book();
      expect(book.currencies, <dynamic>[pkr, usd]);
      expect(book.summary(pkr).monthly, rs(9));
      expect(book.summary(usd).monthly, dollars(3));
    });
  });

  group('cancel, delete, undo', () {
    test('cancelling keeps the record and excludes it from sums', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add(amount: rs(9));
      h.repo.setCancelled(s.id, true, version: s.version);
      expect(h.book().summary(pkr).activeCount, 0);
      expect(h.repo.view().subscriptions, hasLength(1));
    });

    test('deleting, then undo, restores it', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      final Subscription s = h.add(amount: rs(9));
      final SubscriptionsResult<SubscriptionsWrite> del = h.repo.delete(
        s.id,
        version: s.version,
      );
      expect(h.repo.view().subscriptions, isEmpty);
      final SubscriptionsResult<void> u = h.repo.undo(del.value!);
      expect(u.ok, isTrue);
      expect(h.repo.view().subscriptions, hasLength(1));
    });
  });

  group('Option B — non-durability', () {
    test('the repository reports itself as not durable', () {
      final SubscriptionsHarness h = SubscriptionsHarness();
      addTearDown(h.dispose);
      expect(h.repo.durable, isFalse);
    });
  });
}
