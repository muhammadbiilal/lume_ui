/// Everything Subscriptions shows, derived from the stored records — never
/// stored itself (`SUBSCRIPTIONS_PROPOSAL.md` §2).
///
/// The reference hand-types `renews` (a display string) and `days` (an
/// integer) as two independent literals with no recurrence engine behind
/// either (`tool-data.js:763-769`). Here, `nextRenewal`/`daysUntil` are
/// computed from one stored anchor date every time — real date arithmetic,
/// not a pair of numbers that can disagree with each other.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_month_anchor.dart';
import '../../../core/values/lume_record_id.dart';
import 'subscriptions_model.dart';

/// One subscription with everything worked out from its record.
@immutable
class SubscriptionView {
  const SubscriptionView._({
    required this.subscription,
    required this.nextRenewal,
    required this.daysUntil,
    required this.monthlyEquivalent,
  });

  final Subscription subscription;

  /// The next occurrence of [Subscription.startedOn]'s cycle on or after
  /// the reader's day; `null` without it.
  final LumeDate? nextRenewal;

  /// `null` without the reader's day.
  final int? daysUntil;

  /// [Subscription.amount] if monthly; ÷12 if yearly; ×30÷[customDays] if
  /// custom — divided before multiplied, so a very large amount cannot
  /// overflow the intermediate product on a web build (`LumeMoney`'s own
  /// 2^53 bound).
  final LumeMoney monthlyEquivalent;

  LumeCurrency get currency => subscription.currency;
  bool get active => subscription.active;

  /// Unpaid attention: due within a week, matching the reference's own
  /// `days <= 7` warn threshold (`subs.tool.js:48`).
  bool get dueSoon => daysUntil != null && daysUntil! <= 7;
}

/// The figures of one currency.
@immutable
class SubscriptionsCurrencySummary {
  const SubscriptionsCurrencySummary({
    required this.currency,
    required this.monthly,
    required this.yearly,
    required this.activeCount,
    required this.next,
  });

  final LumeCurrency currency;

  /// Σ monthly-equivalent of every active subscription in this currency.
  final LumeMoney monthly;

  /// monthly × 12 — a real derived multiplication, not an independent
  /// figure (mirrors the reference's own `yearly = monthly * 12`).
  final LumeMoney yearly;
  final int activeCount;

  /// The active subscription renewing soonest, or `null` with none or
  /// without the reader's day.
  final SubscriptionView? next;
}

@immutable
class SubscriptionsBook {
  const SubscriptionsBook._({
    required this.subscriptions,
    required this.defects,
    required this.today,
  });

  factory SubscriptionsBook.from({
    required List<Subscription> subscriptions,
    List<SubscriptionsDefect> defects = const <SubscriptionsDefect>[],
    required LumeDate? today,
  }) {
    final List<SubscriptionView> views = <SubscriptionView>[
      for (final Subscription s in subscriptions)
        () {
          final LumeDate? next = today == null ? null : _nextRenewal(s, today);
          return SubscriptionView._(
            subscription: s,
            nextRenewal: next,
            daysUntil: next == null ? null : today!.daysUntil(next),
            monthlyEquivalent: _monthlyEquivalent(s),
          );
        }(),
    ];
    return SubscriptionsBook._(subscriptions: views, defects: defects, today: today);
  }

  final List<SubscriptionView> subscriptions;
  final List<SubscriptionsDefect> defects;
  final LumeDate? today;

  bool get isEmpty => subscriptions.isEmpty;

  SubscriptionView? subscription(LumeRecordId id) {
    for (final SubscriptionView v in subscriptions) {
      if (v.subscription.id == id) return v;
    }
    return null;
  }

  List<LumeCurrency> get currencies => <LumeCurrency>{
    for (final SubscriptionView v in subscriptions) v.currency,
  }.toList()..sort();

  List<SubscriptionsCurrencySummary> get summaries => <SubscriptionsCurrencySummary>[
    for (final LumeCurrency c in currencies) summary(c),
  ];

  SubscriptionsCurrencySummary summary(LumeCurrency c) {
    final List<SubscriptionView> mine = <SubscriptionView>[
      for (final SubscriptionView v in subscriptions)
        if (v.currency == c && v.active) v,
    ];
    LumeMoney monthly = LumeMoney.zero(c);
    for (final SubscriptionView v in mine) {
      monthly += v.monthlyEquivalent;
    }
    SubscriptionView? next;
    for (final SubscriptionView v in mine) {
      if (v.daysUntil == null) continue;
      if (next == null || v.daysUntil! < next.daysUntil!) next = v;
    }
    return SubscriptionsCurrencySummary(
      currency: c,
      monthly: monthly,
      yearly: LumeMoney.sum(monthly.minor * 12, c),
      activeCount: mine.length,
      next: next,
    );
  }

  /// Active subscriptions grouped by category (untranslated free text, as
  /// the reference keeps it), monthly-equivalent per group, for the donut.
  Map<String, LumeMoney> byCategory(LumeCurrency c, String uncategorised) {
    final Map<String, LumeMoney> out = <String, LumeMoney>{};
    for (final SubscriptionView v in subscriptions) {
      if (v.currency != c || !v.active) continue;
      final String key = v.subscription.category ?? uncategorised;
      out[key] = (out[key] ?? LumeMoney.zero(c)) + v.monthlyEquivalent;
    }
    return out;
  }

  /// Active subscriptions sorted by days until renewal, soonest first;
  /// `null` without the reader's day. Mirrors the reference's "Coming up"
  /// timeline (`subs.tool.js:57-59`), over real records.
  List<SubscriptionView>? upcoming({int count = 4}) {
    if (today == null) return null;
    final List<SubscriptionView> active = <SubscriptionView>[
      for (final SubscriptionView v in subscriptions)
        if (v.active) v,
    ]..sort((SubscriptionView a, SubscriptionView b) => a.daysUntil!.compareTo(b.daysUntil!));
    return active.take(count).toList();
  }

  static LumeDate _nextRenewal(Subscription s, LumeDate today) => switch (s.cycle) {
    SubscriptionCycle.monthly => _nextByMonthStep(s.startedOn, today, 1),
    SubscriptionCycle.yearly => _nextByMonthStep(s.startedOn, today, 12),
    SubscriptionCycle.custom => _nextByDays(s.startedOn, today, s.customDays!),
  };

  /// The smallest occurrence of a [stepMonths]-month cycle anchored on
  /// [anchor] that falls on or after [today]. Checked by ascending
  /// candidate rather than solved algebraically, since a calendar month's
  /// length varies and the anchor's day may clamp (`lumeMonthlyDue`).
  static LumeDate _nextByMonthStep(LumeDate anchor, LumeDate today, int stepMonths) {
    if (!anchor.isBefore(today)) return anchor;
    final int monthsBetween =
        (today.year - anchor.year) * 12 + (today.month - anchor.month);
    final int approx = (monthsBetween / stepMonths).ceil();
    for (int n = approx < 2 ? 0 : approx - 2; ; n++) {
      final LumeDate? d = lumeMonthlyDue(anchor, 1 + n * stepMonths);
      if (d == null) return anchor; // past the calendar's range: never
      if (!d.isBefore(today)) return d;
    }
  }

  static LumeDate _nextByDays(LumeDate anchor, LumeDate today, int stepDays) {
    if (!anchor.isBefore(today)) return anchor;
    final int daysBetween = anchor.daysUntil(today);
    final int steps = (daysBetween / stepDays).ceil();
    return anchor.addDays(steps * stepDays);
  }

  static LumeMoney _monthlyEquivalent(Subscription s) => switch (s.cycle) {
    SubscriptionCycle.monthly => s.amount,
    SubscriptionCycle.yearly => LumeMoney.sum(s.amount.minor ~/ 12, s.currency),
    SubscriptionCycle.custom => LumeMoney.sum(
      (s.amount.minor ~/ s.customDays!) * 30,
      s.currency,
    ),
  };
}
