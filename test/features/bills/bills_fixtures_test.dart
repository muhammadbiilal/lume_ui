/// `LumeBillsFixtures` and `LumeBillsBoard`, against `D.BILLS` and
/// `context.js` `bills()` — no widgets, just the numbers.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_reference_money.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/features/bills/data/bills_fixtures.dart';

void main() {
  group('the fixture list — ported verbatim from D.BILLS', () {
    test('is the reference\'s five bills, in its own order', () {
      expect(
        LumeBillsFixtures.list.map((LumeBill b) => b.name).toList(),
        <String>['Electricity', 'Gas', 'Internet', 'Water', 'Mobile'],
      );
    });

    test('carries the reference\'s provider, amount, days, state and ref', () {
      const List<(String, String, double, int, LumeBillState, String)> want =
          <(String, String, double, int, LumeBillState, String)>[
            ('Electricity', 'K-Electric', 74, 4, LumeBillState.due, '••••4821'),
            ('Gas', 'SSGC', 21, 10, LumeBillState.upcoming, '••••7734'),
            ('Internet', 'Nayatel', 28, -5, LumeBillState.overdue, '••••1180'),
            ('Water', 'CDA', 9, 17, LumeBillState.upcoming, '••••0042'),
            ('Mobile', 'Jazz', 12, -7, LumeBillState.paid, '••••3390'),
          ];
      for (final (int i, LumeBill b) in LumeBillsFixtures.list.indexed) {
        final (
          String name,
          String provider,
          double amount,
          int days,
          LumeBillState state,
          String ref,
        ) = want[i];
        expect(b.name, name, reason: 'row $i name');
        expect(b.provider, provider, reason: 'row $i provider');
        expect(b.amountUsd, amount, reason: 'row $i amount');
        expect(b.days, days, reason: 'row $i days');
        expect(b.state, state, reason: 'row $i state');
        expect(b.ref, ref, reason: 'row $i ref');
      }
    });

    test(
      'maps each category to its own icon, and an unknown one to receipt',
      () {
        const Map<String, String> want = <String, String>{
          'Electricity': LumeIcons.bolt,
          'Gas': LumeIcons.flame,
          'Internet': LumeIcons.wifi,
          'Water': LumeIcons.droplet,
          'Mobile': LumeIcons.signal,
        };
        for (final LumeBill b in LumeBillsFixtures.list) {
          expect(b.icon, want[b.name]);
        }
        const LumeBill other = LumeBill(
          name: 'Council tax',
          provider: 'Anytown',
          amountUsd: 10,
          days: 1,
          state: LumeBillState.due,
          ref: '••••0000',
        );
        expect(other.icon, LumeIcons.receipt);
      },
    );

    test('the trend is six months, the last exactly this month\'s total', () {
      expect(LumeBillsFixtures.trend, <double>[128, 142, 118, 156, 134, 144]);
      final double total = LumeBillsFixtures.list.fold(
        0.0,
        (double s, LumeBill b) => s + b.amountUsd,
      );
      expect(LumeBillsFixtures.trend.last, total);
    });
  });

  group('the board — aggregated for one reader\'s currency', () {
    const LumeBillsBoard board = LumeBillsBoard(currency: 'USD');

    test('sorts each bill into exactly one state bucket', () {
      expect(board.overdueBills.map((LumeBill b) => b.name), <String>[
        'Internet',
      ]);
      expect(board.dueBills.map((LumeBill b) => b.name), <String>[
        'Electricity',
      ]);
      expect(board.upcomingBills.map((LumeBill b) => b.name), <String>[
        'Gas',
        'Water',
      ]);
      expect(board.paidBills.map((LumeBill b) => b.name), <String>['Mobile']);
    });

    test('totalDue is every bill not yet paid — overdue + due + upcoming', () {
      expect(board.overdueUsd, 28);
      expect(board.upcomingUsd, 21 + 9);
      expect(board.totalDueUsd, 74 + 21 + 28 + 9);
      expect(board.paidUsd, 12);
    });

    test('counts: overdueCount and paidCount plain, dueCount strict — the '
        'reference\'s own quirk', () {
      expect(board.overdueCount, 1);
      expect(board.paidCount, 1);
      // Strictly `due` — Gas and Water are `upcoming`, not counted here even
      // though the "Due" filter chip shows them (below).
      expect(board.dueCount, 1);
    });

    test('paidRatio is paidCount over every bill', () {
      expect(board.paidRatio, 1 / 5);
    });

    test(
      'money(usd) is the reference\'s dollar-to-local conversion, tidied',
      () {
        expect(board.money(74), lumeFromUsd(74, 'USD'));
        const LumeBillsBoard pk = LumeBillsBoard(currency: 'PKR');
        expect(pk.money(74), lumeFromUsd(74, 'PKR'));
        expect(pk.money(74), isNot(board.money(74)));
      },
    );

    group('shown(filter) — the reference\'s quirk, kept', () {
      test('all shows every bill', () {
        expect(board.shown(LumeBillsFilter.all), hasLength(5));
      });

      test('overdue shows only the overdue bill', () {
        expect(
          board.shown(LumeBillsFilter.overdue).map((LumeBill b) => b.name),
          <String>['Internet'],
        );
      });

      test('paid shows only the paid bill', () {
        expect(
          board.shown(LumeBillsFilter.paid).map((LumeBill b) => b.name),
          <String>['Mobile'],
        );
      });

      test(
        'due also shows upcoming — three bills, though dueCount says one',
        () {
          expect(
            board.shown(LumeBillsFilter.due).map((LumeBill b) => b.name),
            <String>['Electricity', 'Gas', 'Water'],
          );
          expect(
            board.dueCount,
            isNot(board.shown(LumeBillsFilter.due).length),
          );
        },
      );
    });

    test('history is every paid bill, then up to two more still open, in '
        'list order', () {
      expect(board.history.map((LumeBill b) => b.name), <String>[
        'Mobile',
        'Electricity',
        'Gas',
      ]);
    });

    test('trendAverageUsd is the trend\'s own mean', () {
      expect(board.trendAverageUsd, (128 + 142 + 118 + 156 + 134 + 144) / 6);
    });
  });
}
