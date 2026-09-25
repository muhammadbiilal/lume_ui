/// Faraid's arithmetic — a line-by-line port of `context.js` `faraid()`,
/// verified heir combination by heir combination against the classical
/// fixed-shares system (Qur'an 4:11-12) rather than merely trusted.
///
/// No web capture exists for this tool (`docs/conversion_archive/measurements`
/// has none named `tool_faraid_*`), so every expected figure below is worked
/// out by hand — both from the reference's own formula *and*, separately,
/// from the classical fiqh route (fixed share + `asaba`/`radd`) — with both
/// routes shown to agree. See `lib/features/faraid/domain/faraid_maths.dart`
/// for the full reasoning; this file is the receipts.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_reference_rates.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/features/faraid/domain/faraid_maths.dart';

LumeMoney money(double major, LumeCurrency currency) =>
    LumeMoney.sum((major * currency.scale).round(), currency);

LumeFaraidResult faraidFor(
  String code, {
  double gross = 0,
  double debts = 0,
  double bequest = 0,
  int wives = 0,
  int sons = 0,
  int daughters = 0,
}) {
  final LumeCurrency currency = LumeCurrency.of(code);
  return LumeFaraidRules.compute(
    inputs: LumeFaraidInputs(
      gross: money(gross, currency),
      debts: money(debts, currency),
      bequestRequested: money(bequest, currency),
      wives: wives,
      sons: sons,
      daughters: daughters,
    ),
  );
}

LumeFaraidShare? shareOf(LumeFaraidResult r, LumeFaraidShareKind kind) {
  for (final LumeFaraidShare s in r.shares) {
    if (s.kind == kind) return s;
  }
  return null;
}

void main() {
  group('the opening fields', () {
    test('are the reference\'s own defaults, rounded to the thousand', () {
      final LumeCurrency usd = LumeCurrency.of('USD');
      final LumeCurrency pkr = LumeCurrency.of('PKR');
      // `Math.round(60000 * rate / 1000) * 1000`.
      expect(LumeFaraidRules.openingGross(1, usd).minor, 6000000); // $60,000
      expect(
        LumeFaraidRules.openingGross(lumeRatePerUsd('PKR'), pkr).minor,
        1698000000, // Rs 16,980,000 (60000 * 283, already a multiple of 1000)
      );
      // `Math.round(5000 * rate / 1000) * 1000`.
      expect(LumeFaraidRules.openingDebts(1, usd).minor, 500000); // $5,000
      expect(
        LumeFaraidRules.openingDebts(lumeRatePerUsd('PKR'), pkr).minor,
        141500000, // Rs 1,415,000 (5000 * 283)
      );
    });
  });

  group('textbook combination 1 — wife, a son and a daughter', () {
    test('wife an eighth; the residue split 2:1 between the son and the '
        'daughter (asaba bi\'l-ghayr, Qur\'an 4:11)', () {
      // net = $24,000. Wife 1/8 = 3,000. Residue 21,000 split 2:1 among
      // 1 son + 1 daughter (3 parts of 7,000): son 14,000, daughter 7,000.
      final LumeFaraidResult r = faraidFor(
        'USD',
        gross: 24000,
        wives: 1,
        sons: 1,
        daughters: 1,
      );
      expect(r.net.minor, money(24000, r.net.currency).minor);
      expect(shareOf(r, LumeFaraidShareKind.wife)!.amount.minor, 300000);
      expect(
        shareOf(r, LumeFaraidShareKind.wife)!.fraction,
        LumeFaraidFraction.eighth,
      );
      expect(shareOf(r, LumeFaraidShareKind.sons)!.amount.minor, 1400000);
      expect(shareOf(r, LumeFaraidShareKind.daughters)!.amount.minor, 700000);
      // The son takes exactly twice the daughter's share.
      expect(
        shareOf(r, LumeFaraidShareKind.sons)!.amount.minor,
        2 * shareOf(r, LumeFaraidShareKind.daughters)!.amount.minor,
      );
      // Nothing left unaccounted.
      expect(shareOf(r, LumeFaraidShareKind.unallocated), isNull);
    });
  });

  group('textbook combination 2 — wife and two sons, no daughters', () {
    test('wife an eighth; the sons (pure asaba) take the whole residue', () {
      final LumeFaraidResult r = faraidFor(
        'USD',
        gross: 16000,
        wives: 1,
        sons: 2,
      );
      expect(
        shareOf(r, LumeFaraidShareKind.wife)!.amount.minor,
        200000,
      ); // 1/8 of 16,000
      expect(
        shareOf(r, LumeFaraidShareKind.sons)!.amount.minor,
        1400000,
      ); // 7/8 of 16,000
      expect(shareOf(r, LumeFaraidShareKind.daughters), isNull);
      expect(shareOf(r, LumeFaraidShareKind.unallocated), isNull);
    });
  });

  group('textbook combination 3 — wife and a lone son', () {
    test('the son, sole descendant, takes the entire residue', () {
      final LumeFaraidResult r = faraidFor(
        'USD',
        gross: 8000,
        wives: 1,
        sons: 1,
      );
      expect(shareOf(r, LumeFaraidShareKind.wife)!.amount.minor, 100000); // 1/8
      expect(shareOf(r, LumeFaraidShareKind.sons)!.amount.minor, 700000); // 7/8
    });
  });

  group('two daughters, no sons, no wife', () {
    test('take the whole estate — 2/3 fard plus radd of the remaining '
        'third, since no other heir is entered to compete for it', () {
      final LumeFaraidResult r = faraidFor('USD', gross: 9000, daughters: 2);
      // Classical route, worked by hand: fard 2/3 of 9,000 = 6,000; the
      // remaining 3,000 (1/3) returns to the daughters, the only Qur'anic
      // heir left (no wife here to exclude from radd) = 9,000 total.
      expect(shareOf(r, LumeFaraidShareKind.daughters)!.amount.minor, 900000);
      expect(shareOf(r, LumeFaraidShareKind.wife), isNull);
      expect(shareOf(r, LumeFaraidShareKind.unallocated), isNull);
    });
  });

  group('a lone daughter, no sons, no wife', () {
    test('takes the whole estate — 1/2 fard plus radd of the other half', () {
      final LumeFaraidResult r = faraidFor('USD', gross: 5000, daughters: 1);
      expect(shareOf(r, LumeFaraidShareKind.daughters)!.amount.minor, 500000);
    });
  });

  group('a wife alone, no children — the reference\'s own real gap', () {
    test('takes her 1/4 only; the remaining 3/4 is disclosed as '
        'unallocated, never silently folded into her share nor silently '
        'dropped', () {
      final LumeFaraidResult r = faraidFor('USD', gross: 12000, wives: 1);
      final LumeFaraidShare wife = shareOf(r, LumeFaraidShareKind.wife)!;
      expect(wife.fraction, LumeFaraidFraction.quarter);
      expect(
        wife.amount.minor,
        300000,
      ); // exactly 1/4 of 12,000 — never inflated
      final LumeFaraidShare unallocated = shareOf(
        r,
        LumeFaraidShareKind.unallocated,
      )!;
      expect(
        unallocated.amount.minor,
        900000,
      ); // the undisclosed 3/4, made honest
      // The two rows account for the whole net estate between them.
      expect(wife.amount.minor + unallocated.amount.minor, r.net.minor);
    });
  });

  group('no heirs entered at all', () {
    test('the whole net estate is disclosed as unallocated — the '
        'reference\'s own zero-heir fallback, generalised', () {
      final LumeFaraidResult r = faraidFor('USD', gross: 5000);
      expect(r.shares, hasLength(1));
      expect(r.shares.single.kind, LumeFaraidShareKind.unallocated);
      expect(r.shares.single.amount.minor, r.net.minor);
    });

    test('and produces no row at all when net is already zero', () {
      final LumeFaraidResult r = faraidFor('USD', gross: 0);
      expect(r.shares, isEmpty);
    });
  });

  group('debts and the bequest cap', () {
    test('the bequest is capped at one third of the estate after debts', () {
      // afterDebts = 90,000. Cap = 30,000. Requested 40,000 is refused down
      // to the cap; net = 90,000 − 30,000 = 60,000.
      final LumeFaraidResult r = faraidFor('USD', gross: 90000, bequest: 40000);
      expect(r.afterDebts.minor, money(90000, r.afterDebts.currency).minor);
      expect(r.bequest.minor, money(30000, r.bequest.currency).minor);
      expect(r.net.minor, money(60000, r.net.currency).minor);
    });

    test('a bequest under the cap is granted in full', () {
      final LumeFaraidResult r = faraidFor('USD', gross: 90000, bequest: 10000);
      expect(r.bequest.minor, money(10000, r.bequest.currency).minor);
      expect(r.net.minor, money(80000, r.net.currency).minor);
    });

    test('debts exceeding the gross estate clamp to zero, never negative', () {
      final LumeFaraidResult r = faraidFor(
        'USD',
        gross: 1000,
        debts: 5000,
        wives: 1,
        sons: 2,
        daughters: 1,
      );
      expect(r.afterDebts.minor, 0);
      expect(r.net.minor, 0);
      // Every entered heir still gets a row — it is simply a row of zero,
      // not omitted, matching `shares.push` running unconditionally on
      // heir *count*, never on the amount it works out to.
      expect(shareOf(r, LumeFaraidShareKind.wife)!.amount.minor, 0);
      expect(shareOf(r, LumeFaraidShareKind.sons)!.amount.minor, 0);
      expect(shareOf(r, LumeFaraidShareKind.daughters)!.amount.minor, 0);
      expect(shareOf(r, LumeFaraidShareKind.unallocated), isNull);
    });
  });

  group('awl cannot happen — proved, not merely asserted in a comment', () {
    test('over every combination this tool\'s three heir categories can '
        'express, the shares never sum to more than net, and always sum '
        'to exactly net once the unallocated remainder is counted', () {
      final LumeCurrency usd = LumeCurrency.of('USD');
      final LumeMoney net = money(97531, usd); // an odd, unrounded figure
      for (int wives = 0; wives <= 2; wives++) {
        for (int sons = 0; sons <= 3; sons++) {
          for (int daughters = 0; daughters <= 3; daughters++) {
            final LumeFaraidResult r = LumeFaraidRules.compute(
              inputs: LumeFaraidInputs(
                gross: net,
                debts: LumeMoney.zero(usd),
                bequestRequested: LumeMoney.zero(usd),
                wives: wives,
                sons: sons,
                daughters: daughters,
              ),
            );
            final int total = r.shares.fold(
              0,
              (int sum, LumeFaraidShare s) => sum + s.amount.minor,
            );
            // Every combination accounts for the whole net estate —
            // nothing left over, nothing double-counted.
            expect(
              total,
              net.minor,
              reason: 'wives=$wives sons=$sons daughters=$daughters',
            );
            // And restricting to the heirs actually entered (excluding the
            // disclosed remainder), the total never exceeds net — the
            // structural reason `awl` cannot arise from this heir set.
            final int heirsOnly = r.shares
                .where(
                  (LumeFaraidShare s) =>
                      s.kind != LumeFaraidShareKind.unallocated,
                )
                .fold(0, (int sum, LumeFaraidShare s) => sum + s.amount.minor);
            expect(
              heirsOnly,
              lessThanOrEqualTo(net.minor),
              reason: 'wives=$wives sons=$sons daughters=$daughters',
            );
          }
        }
      }
    });
  });
}
