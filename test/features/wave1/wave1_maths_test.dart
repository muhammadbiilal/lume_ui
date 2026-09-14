/// Rollout wave 1's arithmetic, against the figures the running reference
/// drew (`measurements/tool_*_default_pk_390x844_light_en.json`) and the
/// edges its module leaves open.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/age/domain/age_maths.dart';
import 'package:lume/features/compound/domain/compound_maths.dart';
import 'package:lume/features/datecalc/domain/date_maths.dart';
import 'package:lume/features/loan/domain/loan_maths.dart';
import 'package:lume/features/stopwatch/application/stopwatch_controller.dart';
import 'package:lume/features/tipsplit/domain/tip_maths.dart';
import 'package:lume/features/tools/application/tool_session.dart';
import 'package:lume/core/localization/lume_iso_day.dart';

class _Ticker implements Timer {
  _Ticker(this.onTick);
  final void Function(Timer) onTick;
  bool active = true;
  @override
  void cancel() => active = false;
  @override
  bool get isActive => active;
  @override
  int get tick => 0;
}

void main() {
  final DateTime fixture = DateTime(2026, 9, 7, 16, 41);

  group('Age', () {
    test('the reference cell: 33 years, 4 months and 20 days', () {
      final LumeAge a = LumeAge.of(DateTime(1993, 4, 18), fixture);
      expect(<int>[a.years, a.months, a.days], <int>[33, 4, 20]);
      expect(a.totalDays, 12195);
      expect(a.totalWeeks, 1742);
      expect(a.totalHours, 292680);
      expect(a.next, DateTime(2027, 4, 18));
      expect(a.untilNext, 223);
      expect(a.milestones.first, (10000, DateTime(2020, 9, 3)));
    });

    test('a birthday today is today, not a year away', () {
      final LumeAge a = LumeAge.of(DateTime(2000, 9, 7), fixture);
      expect(a.untilNext, 0);
      expect(a.next, DateTime(2026, 9, 7));
      expect(a.yearDone, 1);
      expect(<int>[a.years, a.months, a.days], <int>[26, 0, 0]);
    });

    test('29 February rolls to 1 March in a common year, as the reference '
        'does', () {
      final LumeAge a = LumeAge.of(DateTime(2000, 2, 29), DateTime(2027, 3, 1));
      expect(a.next, DateTime(2027, 3, 1));
      expect(a.untilNext, 0);
    });

    test('days are calendar days across a clock change', () {
      // New York moved its clocks on 8 March 2026; a millisecond count from
      // midnight would come up an hour short.
      expect(
        LumeAge.daysBetween(DateTime(2026, 3, 7), DateTime(2026, 3, 9)),
        2,
      );
    });

    test('an ISO day, and what is not one', () {
      expect(lumeParseIsoDay('1993-04-18'), DateTime(1993, 4, 18));
      expect(lumeParseIsoDay('2026-02-30'), isNull);
      expect(lumeParseIsoDay('18/04/1993'), isNull);
      expect(lumeIsoDate(DateTime(987, 1, 2)), '0987-01-02');
    });
  });

  group('Date Calculator', () {
    test('the reference cell: today to today is nothing', () {
      final LumeDateSpan s = LumeDateSpan.of(fixture, fixture);
      expect(<int>[s.days, s.weekdays, s.weekends], <int>[0, 0, 0]);
    });

    test('a week from a Monday is five weekdays and two weekend days, '
        'either way round', () {
      for (final LumeDateSpan s in <LumeDateSpan>[
        LumeDateSpan.of(DateTime(2026, 9, 7), DateTime(2026, 9, 14)),
        LumeDateSpan.of(DateTime(2026, 9, 14), DateTime(2026, 9, 7)),
      ]) {
        expect(<int>[s.days, s.weekdays, s.weekends], <int>[7, 5, 2]);
        expect(s.weeks, 1);
      }
    });

    test('the walk stops at 4 000 days, as the reference does', () {
      final LumeDateSpan s = LumeDateSpan.of(
        DateTime(2026, 1, 1),
        DateTime(2040, 1, 1),
      );
      expect(s.days, greaterThan(LumeDateSpan.walkCap));
      expect(s.weekdays + s.weekends, LumeDateSpan.walkCap);
    });

    test('adding days, forward and back, over a month end', () {
      expect(
        LumeDateSpan.plus(DateTime(2026, 9, 7), 30),
        DateTime(2026, 10, 7),
      );
      expect(
        LumeDateSpan.plus(DateTime(2026, 3, 1), -1),
        DateTime(2026, 2, 28),
      );
    });

    test('months and years are the reference’s divisors', () {
      final LumeDateSpan s = LumeDateSpan.of(
        DateTime(2026, 1, 1),
        DateTime(2027, 1, 1),
      );
      expect(s.months, closeTo(365 / 30.44, 1e-9));
      expect(s.years, closeTo(365 / 365.25, 1e-9));
    });
  });

  group('Tip & Split', () {
    test('the reference cell: Rs 11,320 at 10 % for two', () {
      final LumeTipSplit s = LumeTipSplit.of(bill: 11320, tip: 10, people: 2);
      expect(s.tipAmount, 1132);
      expect(s.total, 12452);
      expect(s.each, 6226);
      expect(LumeTipSplit.openingBill(283), 11320);
    });

    test('no fewer than one person, and no negative bill', () {
      final LumeTipSplit s = LumeTipSplit.of(bill: -5, tip: 15, people: 0);
      expect(s.people, 1);
      expect(s.bill, 0);
      expect(s.each, 0);
    });
  });

  group('Loan / EMI', () {
    final LumeLoan cell = LumeLoan.of(principal: 5660000, rate: 12, years: 5);

    test('the reference cell: Rs 125,904 a month over 60 payments', () {
      expect(LumeLoan.openingPrincipal(283), 5660000);
      expect(cell.payments, 60);
      expect(cell.emi.round(), 125904);
      expect(cell.totalInterest.round(), 1894214);
      expect(cell.totalPaid.round(), 7554214);
      expect((cell.interestShare * 100).round(), 25);
    });

    test('the schedule, as the reference tabled it', () {
      expect(cell.schedule, hasLength(5));
      expect(
        <int>[
          cell.schedule.first.principal.round(),
          cell.schedule.first.interest.round(),
          cell.schedule.first.balance.round(),
        ],
        <int>[878943, 631900, 4781057],
      );
      expect(cell.schedule.last.balance.round(), 0);
    });

    test('the rate comparison is worked on the loan amount (C83)', () {
      // The reference works it on the last month's principal, so its
      // "At 10.0%" payment is a small fraction of the real one.
      final double lower = cell.at(-2);
      final double higher = cell.at(2);
      expect(lower, lessThan(cell.emi));
      expect(lower, greaterThan(cell.emi * 0.9));
      expect(higher, greaterThan(cell.emi));
      expect(cell.at(0), cell.emi);
    });

    test('no tenure has no payment; no rate divides evenly', () {
      final LumeLoan none = LumeLoan.of(principal: 1000, rate: 12, years: 0);
      expect(none.emi, 0);
      expect(none.schedule, isEmpty);
      expect(none.totalInterest, 0);
      final LumeLoan free = LumeLoan.of(principal: 1200, rate: 0, years: 1);
      expect(free.emi, 100);
      expect(free.totalInterest, 0);
    });

    test('the schedule stops at eight years', () {
      expect(
        LumeLoan.of(principal: 100000, rate: 9, years: 20).schedule,
        hasLength(LumeLoan.scheduleYears),
      );
    });
  });

  group('Compound Interest', () {
    test('the reference cell: Rs 5,805,531 after ten years', () {
      final LumeCompound c = LumeCompound.of(
        initial: 283000,
        monthly: 28300,
        rate: 8,
        years: 10,
      );
      expect(LumeCompound.openingInitial(283), 283000);
      expect(LumeCompound.openingMonthly(283), 28300);
      expect(c.total.round(), 5805531);
      expect(c.contributed, 3679000);
      expect(c.growth.round(), 2126531);
      expect(c.returnPercent.round(), 58);
      expect(c.table.first.contributed, 622600);
      expect(c.table.first.value.round(), 658822);
      expect(c.series, hasLength(10));
    });

    test('a single year is drawn from where it started', () {
      final LumeCompound c = LumeCompound.of(
        initial: 1000,
        monthly: 0,
        rate: 12,
        years: 1,
      );
      expect(c.series, hasLength(2));
      expect(c.series.first, 1000);
    });
  });

  group('Stopwatch', () {
    late Duration now;
    late List<_Ticker> tickers;
    late LumeToolSession session;

    LumeStopwatchController watch() => LumeStopwatchController(
      session: session,
      elapsed: () => now,
      periodic: (Duration d, void Function(Timer) tick) {
        final _Ticker t = _Ticker(tick);
        tickers.add(t);
        return t;
      },
    );

    setUp(() {
      now = Duration.zero;
      tickers = <_Ticker>[];
      session = LumeToolSession();
    });

    test('counts hundredths, and a second press pauses', () {
      final LumeStopwatchController w = watch();
      expect(w.display, '00:00.00');
      w.toggle();
      now = const Duration(milliseconds: 1234);
      expect(w.display, '00:01.23');
      w.toggle();
      expect(w.running, isFalse);
      expect(tickers.single.active, isFalse);
      now = const Duration(seconds: 9);
      expect(w.display, '00:01.23', reason: 'paused time does not count');
      w.dispose();
    });

    test('laps mark each split while running; reset clears only when '
        'paused', () {
      final LumeStopwatchController w = watch()..toggle();
      now = const Duration(milliseconds: 1234);
      w.lap();
      now = const Duration(milliseconds: 3234);
      w.lap();
      expect(w.laps, <int>[1234, 2000]);
      w.reset();
      expect(w.laps, hasLength(2), reason: 'reset waits for a pause');
      w
        ..toggle()
        ..reset();
      expect(w.milliseconds, 0);
      expect(w.laps, isEmpty);
      w.lap();
      expect(w.laps, isEmpty, reason: 'no lap while stopped');
      w.dispose();
    });

    test('leaving the tool stops the clock and keeps the time', () {
      final LumeStopwatchController w = watch()..toggle();
      now = const Duration(milliseconds: 2500);
      w.dispose();
      now = const Duration(seconds: 60);
      final LumeStopwatchController back = watch();
      expect(back.running, isFalse);
      expect(back.display, '00:02.50');
      back.dispose();
    });

    test('minutes run past an hour', () {
      expect(LumeStopwatchController.format(3662330), '61:02.33');
      expect(LumeStopwatchController.format(-5), '00:00.00');
    });
  });
}
