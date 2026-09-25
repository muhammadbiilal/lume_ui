/// Prize Bonds' data, against the reference's own `D.PRIZE_BONDS` table.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/prizebonds/data/prizebonds_fixtures.dart';

void main() {
  group('D.PRIZE_BONDS', () {
    test('has exactly one country — Pakistan — and no invented equivalent '
        'for anywhere else', () {
      expect(LumePrizeBondScheme.forCountry('PK'), isNotNull);
      for (final String other in <String>['US', 'GB', 'AE', 'SA', 'IN', 'JP']) {
        expect(
          LumePrizeBondScheme.forCountry(other),
          isNull,
          reason: '$other has no prize bond scheme in the reference',
        );
      }
    });

    test('carries the reference\'s four denominations, draws and prize '
        'tiers exactly', () {
      final LumePrizeBondScheme pk = LumePrizeBondScheme.forCountry('PK')!;
      expect(pk.bonds, hasLength(4));

      final Map<int, LumePrizeBond> byDenom = <int, LumePrizeBond>{
        for (final LumePrizeBond b in pk.bonds) b.denom: b,
      };
      expect(byDenom.keys.toSet(), <int>{100, 200, 750, 1500});

      final LumePrizeBond b100 = byDenom[100]!;
      expect(b100.draw, 'Draw 47');
      expect(b100.date, '15 Sep');
      expect(b100.first, 700000);
      expect(b100.second, 200000);
      expect(b100.third, 1000);
      expect(b100.winners, 2394);

      final LumePrizeBond b200 = byDenom[200]!;
      expect(b200.draw, 'Draw 98');
      expect(b200.date, '15 Sep');
      expect(b200.first, 750000);
      expect(b200.second, 250000);
      expect(b200.third, 1250);
      expect(b200.winners, 2394);

      final LumePrizeBond b750 = byDenom[750]!;
      expect(b750.draw, 'Draw 102');
      expect(b750.date, '15 Oct');
      expect(b750.first, 1500000);
      expect(b750.second, 500000);
      expect(b750.third, 9300);
      expect(b750.winners, 1696);

      final LumePrizeBond b1500 = byDenom[1500]!;
      expect(b1500.draw, 'Draw 99');
      expect(b1500.date, '15 Nov');
      expect(b1500.first, 3000000);
      expect(b1500.second, 1000000);
      expect(b1500.third, 18500);
      expect(b1500.winners, 1696);
    });

    test('the next draw is the lowest denomination, sorted rather than '
        'assumed to already be first', () {
      final LumePrizeBondScheme pk = LumePrizeBondScheme.forCountry('PK')!;
      // A scrambled order still resolves to the Rs 100 bond.
      final LumePrizeBondScheme shuffled = LumePrizeBondScheme(
        List<LumePrizeBond>.from(pk.bonds.reversed),
      );
      expect(shuffled.next.denom, 100);
      expect(shuffled.next.draw, 'Draw 47');
    });

    test('the prize pool is first once, second three times over, third across '
        'its winners — the reference\'s own formula, not each tier\'s real '
        'winner count', () {
      final LumePrizeBondScheme pk = LumePrizeBondScheme.forCountry('PK')!;
      // 100:  700,000 +  200,000×3 +  1,000×2,394 =  3,694,000
      // 200:  750,000 +  250,000×3 +  1,250×2,394 =  4,492,500
      // 750: 1,500,000 +  500,000×3 +  9,300×1,696 = 18,772,800
      // 1500: 3,000,000 + 1,000,000×3 + 18,500×1,696 = 37,376,000
      expect(pk.prizePool, 64335300);
    });

    test('total winners sums every denomination\'s own winner count', () {
      final LumePrizeBondScheme pk = LumePrizeBondScheme.forCountry('PK')!;
      expect(pk.totalWinners, 2394 + 2394 + 1696 + 1696);
    });
  });
}
