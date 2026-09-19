/// Everything Installments shows, derived from the stored records — never
/// stored itself (`INSTALLMENTS_PROPOSAL.md` §40.2, §40.7, §40.10).
///
/// ```text
/// scheduledTotal = instalment amount × count
/// totalPayable   = deposit + scheduledTotal
/// paidToDate     = deposit + Σ active payments
/// remaining      = totalPayable − paidToDate
/// ```
///
/// Every sum is of stored minor units in one currency, so a total always
/// equals the rows it is the total of. A plan whose records break the rules
/// is **damaged**: listed with the reason, its figures not trusted, nothing
/// written over it.
///
/// The reader's day is an input. Without it (the zone cannot be worked out)
/// nothing is late, due today or upcoming — the states are unknown, not
/// guessed.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/values/lume_money.dart';
import '../../../core/values/lume_record_id.dart';
import 'installments_model.dart';
import 'installments_schedule.dart';

/// Where one scheduled instalment stands on the reader's day.
enum InstallmentStatus {
  /// One active payment pays it.
  paid,

  /// Unpaid, due on the reader's day.
  dueToday,

  /// Unpaid, due before the reader's day.
  late,

  /// Unpaid, due after the reader's day.
  upcoming,

  /// Unpaid, and the reader's day cannot be worked out.
  unknown,
}

/// A plan's state: cancelled by the reader, completed when every instalment
/// is paid, active otherwise.
enum InstallmentPlanStatus { active, completed, cancelled }

/// One scheduled instalment with what pays it.
@immutable
class InstallmentRow {
  const InstallmentRow(this.row, this.payment, this.status, this.payments);

  final ScheduledInstallment row;

  /// The active payment, when there is one.
  final InstallmentPayment? payment;
  final InstallmentStatus status;

  /// Every payment that names this instalment, voided ones included.
  final List<InstallmentPayment> payments;

  bool get paid => payment != null;
}

/// Why a plan's records cannot be trusted.
@immutable
class InstallmentsDamage {
  const InstallmentsDamage(this.plan, this.reason, [this.id]);

  /// The plan's id as the records name it.
  final String plan;
  final String reason;

  /// The record at fault, when one is.
  final String? id;

  @override
  String toString() => '$plan: $reason${id == null ? '' : ' ($id)'}';
}

/// One plan, and everything worked out from its records.
@immutable
class InstallmentPlanView {
  const InstallmentPlanView._({
    required this.plan,
    required this.rows,
    required this.payments,
    required this.damage,
    required this.paidToDate,
    required this.lastActivity,
  });

  final InstallmentPlan plan;

  /// By sequence number.
  final List<InstallmentRow> rows;

  /// Every payment on the plan, voided ones included, newest first.
  final List<InstallmentPayment> payments;

  /// Why its records cannot be trusted, or `null`.
  final String? damage;

  /// deposit + active payments.
  final LumeMoney paidToDate;

  /// The latest creation instant among the plan and its payments — the
  /// recent-activity order, from real timestamps only.
  final DateTime lastActivity;

  bool get damaged => damage != null;
  LumeCurrency get currency => plan.currency;
  LumeMoney get scheduledTotal => plan.scheduledTotal;
  LumeMoney get totalPayable => plan.totalPayable;
  LumeMoney get remaining => totalPayable - paidToDate;

  int get paidCount => rows.where((InstallmentRow r) => r.paid).length;
  int get paymentsLeft => plan.count - paidCount;

  /// Any payment record, voided or not: the terms are then fixed (§40.8).
  bool get hasPayments => payments.isNotEmpty;

  InstallmentPlanStatus get status => plan.cancelled
      ? InstallmentPlanStatus.cancelled
      : paidCount == plan.count
      ? InstallmentPlanStatus.completed
      : InstallmentPlanStatus.active;

  /// The earliest unpaid instalment — the next to pay — or `null`.
  InstallmentRow? get next {
    for (final InstallmentRow r in rows) {
      if (!r.paid) return r;
    }
    return null;
  }

  /// Unpaid and due before the reader's day, or `null` without a day.
  int? get lateCount {
    if (rows.any((InstallmentRow r) => r.status == InstallmentStatus.unknown)) {
      return null;
    }
    return rows
        .where((InstallmentRow r) => r.status == InstallmentStatus.late)
        .length;
  }

  bool? get late => lateCount == null ? null : lateCount! > 0;

  /// Total payable less the cash price the reader noted; signed, and only a
  /// subtraction of their own numbers — never called interest.
  LumeMoney? get cashDifference =>
      plan.cashPrice == null ? null : totalPayable - plan.cashPrice!;
}

/// The figures of one currency.
@immutable
class InstallmentsCurrencySummary {
  const InstallmentsCurrencySummary({
    required this.currency,
    required this.dueThisMonth,
    required this.paidToDate,
    required this.remaining,
    required this.activePlans,
    required this.lateInstallments,
  });

  final LumeCurrency currency;

  /// Scheduled instalments of plans not cancelled, due in the reader's
  /// calendar month, paid or not; `null` without the reader's day.
  final LumeMoney? dueThisMonth;

  /// Every plan's deposit and active payments, cancelled plans included.
  final LumeMoney paidToDate;

  /// What is left on plans that are not cancelled.
  final LumeMoney remaining;
  final int activePlans;

  /// `null` without the reader's day.
  final int? lateInstallments;
}

/// One month of the "Due by month" chart.
@immutable
class InstallmentsMonth {
  const InstallmentsMonth(this.month, this.due);

  /// Its first day.
  final LumeDate month;
  final LumeMoney due;
}

@immutable
class InstallmentsBook {
  const InstallmentsBook._({
    required this.plans,
    required this.defects,
    required this.damage,
    required this.today,
  });

  /// Derive the book. Throws [LumeMoneyException] only when a sum passes
  /// its bound — the caller shows that as an error, never a wrong figure.
  factory InstallmentsBook.from({
    required List<InstallmentPlan> plans,
    required List<ScheduledInstallment> schedule,
    required List<InstallmentPayment> payments,
    List<InstallmentsDefect> defects = const <InstallmentsDefect>[],
    required LumeDate? today,
  }) {
    final Map<LumeRecordId, InstallmentPlan> byId =
        <LumeRecordId, InstallmentPlan>{
          for (final InstallmentPlan p in plans) p.id: p,
        };
    final List<InstallmentsDamage> damage = <InstallmentsDamage>[];
    final Map<LumeRecordId, List<ScheduledInstallment>> rowsOf =
        <LumeRecordId, List<ScheduledInstallment>>{};
    final Map<LumeRecordId, ScheduledInstallment> rowById =
        <LumeRecordId, ScheduledInstallment>{};
    for (final ScheduledInstallment r in schedule) {
      rowById[r.id] = r;
      if (!byId.containsKey(r.planId)) {
        damage.add(InstallmentsDamage(r.planId.value, 'orphanRow', r.id.value));
        continue;
      }
      (rowsOf[r.planId] ??= <ScheduledInstallment>[]).add(r);
    }
    final Map<LumeRecordId, List<InstallmentPayment>> paysOf =
        <LumeRecordId, List<InstallmentPayment>>{};
    for (final InstallmentPayment p in payments) {
      final ScheduledInstallment? row = rowById[p.installmentId];
      if (!byId.containsKey(p.planId)) {
        damage.add(
          InstallmentsDamage(p.planId.value, 'orphanPayment', p.id.value),
        );
        continue;
      }
      if (row == null || row.planId != p.planId) {
        damage.add(
          InstallmentsDamage(p.planId.value, 'paymentRow', p.id.value),
        );
        continue;
      }
      (paysOf[p.planId] ??= <InstallmentPayment>[]).add(p);
    }
    // A defect names its plan where it can: that plan cannot be trusted.
    final Set<String> defective = <String>{
      for (final InstallmentsDefect d in defects) ?d.planId,
    };

    final List<InstallmentPlanView> views = <InstallmentPlanView>[];
    for (final InstallmentPlan plan in plans) {
      final List<ScheduledInstallment> rows =
          <ScheduledInstallment>[...?rowsOf[plan.id]]..sort(
            (ScheduledInstallment a, ScheduledInstallment b) =>
                a.seq.compareTo(b.seq),
          );
      final List<InstallmentPayment> pays = <InstallmentPayment>[
        ...?paysOf[plan.id],
      ]..sort(installmentsPaymentOrder);
      String? why = _check(plan, rows, pays);
      if (why == null && defective.contains(plan.id.value)) why = 'defect';
      if (why != null) damage.add(InstallmentsDamage(plan.id.value, why));

      final List<InstallmentRow> states = <InstallmentRow>[
        for (final ScheduledInstallment r in rows)
          () {
            final List<InstallmentPayment> mine = <InstallmentPayment>[
              for (final InstallmentPayment p in pays)
                if (p.installmentId == r.id) p,
            ];
            final InstallmentPayment? active = mine
                .where((InstallmentPayment p) => p.active)
                .firstOrNull;
            return InstallmentRow(r, active, _status(r, active, today), mine);
          }(),
      ];
      LumeMoney paid = plan.deposit ?? LumeMoney.zero(plan.currency);
      if (why == null) {
        for (final InstallmentRow r in states) {
          if (r.payment != null) paid += r.payment!.amount;
        }
      }
      DateTime last = plan.createdAt;
      for (final InstallmentPayment p in pays) {
        if (p.createdAt.isAfter(last)) last = p.createdAt;
      }
      views.add(
        InstallmentPlanView._(
          plan: plan,
          rows: states,
          payments: pays,
          damage: why,
          paidToDate: paid,
          lastActivity: last,
        ),
      );
    }
    return InstallmentsBook._(
      plans: views,
      defects: defects,
      damage: damage,
      today: today,
    );
  }

  final List<InstallmentPlanView> plans;
  final List<InstallmentsDefect> defects;
  final List<InstallmentsDamage> damage;
  final LumeDate? today;

  bool get dayKnown => today != null;
  bool get isEmpty => plans.isEmpty;

  InstallmentPlanView? plan(LumeRecordId id) {
    for (final InstallmentPlanView p in plans) {
      if (p.plan.id == id) return p;
    }
    return null;
  }

  /// The currencies in use, by code.
  List<LumeCurrency> get currencies => <LumeCurrency>{
    for (final InstallmentPlanView p in plans) p.currency,
  }.toList()..sort();

  /// One summary per currency, the whole tool whatever is filtered; damaged
  /// plans are left out of every figure.
  List<InstallmentsCurrencySummary> get summaries =>
      <InstallmentsCurrencySummary>[
        for (final LumeCurrency c in currencies) summary(c),
      ];

  InstallmentsCurrencySummary summary(LumeCurrency c) {
    final List<InstallmentPlanView> mine = <InstallmentPlanView>[
      for (final InstallmentPlanView p in plans)
        if (p.currency == c && !p.damaged) p,
    ];
    LumeMoney paid = LumeMoney.zero(c);
    LumeMoney remaining = LumeMoney.zero(c);
    LumeMoney? due = today == null ? null : LumeMoney.zero(c);
    int active = 0;
    int? late = today == null ? null : 0;
    for (final InstallmentPlanView p in mine) {
      paid += p.paidToDate;
      if (p.status == InstallmentPlanStatus.cancelled) continue;
      remaining += p.remaining;
      if (p.status == InstallmentPlanStatus.active) active++;
      if (late != null) late += p.lateCount ?? 0;
      if (due != null) {
        for (final InstallmentRow r in p.rows) {
          if (sameMonth(r.row.due, today!)) due = due! + r.row.amount;
        }
      }
    }
    return InstallmentsCurrencySummary(
      currency: c,
      dueThisMonth: due,
      paidToDate: paid,
      remaining: remaining,
      activePlans: active,
      lateInstallments: late,
    );
  }

  /// For each of the [count] calendar months from the reader's, what falls
  /// due in [c] on plans not cancelled; `null` without the reader's day.
  List<InstallmentsMonth>? months(LumeCurrency c, {int count = 6}) {
    final LumeDate? day = today;
    if (day == null) return null;
    return <InstallmentsMonth>[
      for (int m = 0; m < count; m++)
        () {
          final LumeDate start = monthStart(day, m);
          LumeMoney sum = LumeMoney.zero(c);
          for (final InstallmentPlanView p in plans) {
            if (p.currency != c ||
                p.damaged ||
                p.status == InstallmentPlanStatus.cancelled) {
              continue;
            }
            for (final InstallmentRow r in p.rows) {
              if (sameMonth(r.row.due, start)) sum += r.row.amount;
            }
          }
          return InstallmentsMonth(start, sum);
        }(),
    ];
  }

  /// Every payment, newest first — the History.
  List<(InstallmentPlanView, InstallmentPayment)> get history =>
      <(InstallmentPlanView, InstallmentPayment)>[
        for (final InstallmentPlanView p in plans)
          for (final InstallmentPayment x in p.payments) (p, x),
      ]..sort(
        (
          (InstallmentPlanView, InstallmentPayment) a,
          (InstallmentPlanView, InstallmentPayment) b,
        ) => installmentsPaymentOrder(a.$2, b.$2),
      );

  /// The rules every stored state keeps (§40.14), as broken ones — empty
  /// when every one holds. Damaged plans are reported by [damage] instead.
  List<String> invariants() {
    final List<String> broken = <String>[];
    for (final InstallmentPlanView p in plans) {
      if (p.damaged) continue;
      final InstallmentPlan plan = p.plan;
      final String id = plan.id.value;
      if (p.rows.length != plan.count) broken.add('rows $id');
      LumeMoney rows = LumeMoney.zero(plan.currency);
      for (final InstallmentRow r in p.rows) {
        rows += r.row.amount;
      }
      if (rows != plan.scheduledTotal) broken.add('scheduledTotal $id');
      if (plan.totalPayable !=
          plan.scheduledTotal +
              (plan.deposit ?? LumeMoney.zero(plan.currency))) {
        broken.add('totalPayable $id');
      }
      LumeMoney paid = plan.deposit ?? LumeMoney.zero(plan.currency);
      for (final InstallmentRow r in p.rows) {
        final int live = r.payments
            .where((InstallmentPayment x) => x.active)
            .length;
        if (live > 1) broken.add('onePayment ${r.row.id.value}');
        if (r.payment case final InstallmentPayment pay) {
          if (pay.amount != r.row.amount) broken.add('amount ${pay.id.value}');
          paid += pay.amount;
        }
      }
      if (paid != p.paidToDate) broken.add('paidToDate $id');
      if (p.remaining != p.totalPayable - p.paidToDate) {
        broken.add('remaining $id');
      }
      if (p.remaining.isNegative) broken.add('negative $id');
      if ((p.status == InstallmentPlanStatus.completed) !=
          (!plan.cancelled && p.rows.every((InstallmentRow r) => r.paid))) {
        broken.add('completed $id');
      }
    }
    return broken;
  }

  /// A plan's own records against its rules; the reason, or `null`.
  static String? _check(
    InstallmentPlan plan,
    List<ScheduledInstallment> rows,
    List<InstallmentPayment> pays,
  ) {
    if (rows.length != plan.count) return 'rowCount';
    for (int i = 0; i < rows.length; i++) {
      final ScheduledInstallment r = rows[i];
      if (r.seq != i + 1) return 'sequence';
      if (r.amount.currency != plan.currency) return 'currency';
      if (r.amount != plan.amount) return 'rowAmount';
      if (i > 0 && r.due.isBefore(rows[i - 1].due)) return 'dueOrder';
    }
    final Map<LumeRecordId, ScheduledInstallment> byId =
        <LumeRecordId, ScheduledInstallment>{
          for (final ScheduledInstallment r in rows) r.id: r,
        };
    final Set<LumeRecordId> paid = <LumeRecordId>{};
    for (final InstallmentPayment p in pays) {
      final ScheduledInstallment? r = byId[p.installmentId];
      if (r == null) return 'paymentRow';
      if (p.amount.currency != plan.currency) return 'currency';
      if (p.amount != r.amount) return 'paymentAmount';
      if (p.active && !paid.add(r.id)) return 'twoPayments';
    }
    try {
      if (plan.deposit != null &&
          plan.deposit!.compareTo(plan.totalPayable) > 0) {
        return 'deposit';
      }
    } on LumeMoneyException {
      return 'overflow';
    }
    return null;
  }

  static InstallmentStatus _status(
    ScheduledInstallment r,
    InstallmentPayment? paid,
    LumeDate? today,
  ) {
    if (paid != null) return InstallmentStatus.paid;
    if (today == null) return InstallmentStatus.unknown;
    final int c = r.due.compareTo(today);
    return c < 0
        ? InstallmentStatus.late
        : c == 0
        ? InstallmentStatus.dueToday
        : InstallmentStatus.upcoming;
  }
}

/// Newest first: the date paid, then the moment recorded, then the id.
int installmentsPaymentOrder(InstallmentPayment a, InstallmentPayment b) {
  final int d = b.paidOn.compareTo(a.paidOn);
  if (d != 0) return d;
  final int t = b.createdAt.compareTo(a.createdAt);
  return t != 0 ? t : a.id.compareTo(b.id);
}
