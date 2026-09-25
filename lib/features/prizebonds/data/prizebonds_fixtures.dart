/// Prize Bonds — Pakistan's national savings bearer-bond scheme, typed.
///
/// `tools/money/prizebonds.tool.js` over `D.PRIZE_BONDS`: a country-keyed map
/// with exactly one entry, `PK`, of four denominations — Rs 100, 200, 750 and
/// 1,500 — each carrying its own draw number, draw date, three prize tiers
/// (first, second, third) and a winner count. Every other country has no
/// entry, and the reference itself falls back to an `unavailable` composition
/// when `list` is missing (§18–19 of the module) — this is a Pakistan-specific
/// government instrument, not something every market has a version of.
///
/// **Dayroz obligation:** every figure below is the reference's own hardcoded
/// fixture data, carried over unchanged. A real integration needs the State
/// Bank of Pakistan's own draw results — the schedule, the winning numbers
/// and the prize tiers for each denomination — as a live or periodically
/// refreshed source (the catalogue's freshness is `draw`); nothing here is
/// invented or extrapolated for a country the reference does not cover.
library;

import 'package:flutter/foundation.dart';

@immutable
class LumePrizeBond {
  const LumePrizeBond({
    required this.denom,
    required this.draw,
    required this.date,
    required this.first,
    required this.second,
    required this.third,
    required this.winners,
  });

  /// The bond's face value, in the scheme's own currency (`b.denom`).
  final int denom;

  /// `b.draw` — the draw's own name, e.g. `Draw 47`. Not translated by the
  /// reference in any locale.
  final String draw;

  /// `b.date` — the draw's date, as the reference writes it (`15 Sep`), not a
  /// [DateTime]: the reference never parses it, only displays it.
  final String date;

  final double first;
  final double second;
  final double third;
  final int winners;
}

@immutable
class LumePrizeBondScheme {
  const LumePrizeBondScheme(this.bonds);

  final List<LumePrizeBond> bonds;

  /// `D.PRIZE_BONDS` — one country.
  static const Map<String, List<LumePrizeBond>> _byCountry =
      <String, List<LumePrizeBond>>{
        'PK': <LumePrizeBond>[
          LumePrizeBond(
            denom: 100,
            draw: 'Draw 47',
            date: '15 Sep',
            first: 700000,
            second: 200000,
            third: 1000,
            winners: 2394,
          ),
          LumePrizeBond(
            denom: 200,
            draw: 'Draw 98',
            date: '15 Sep',
            first: 750000,
            second: 250000,
            third: 1250,
            winners: 2394,
          ),
          LumePrizeBond(
            denom: 750,
            draw: 'Draw 102',
            date: '15 Oct',
            first: 1500000,
            second: 500000,
            third: 9300,
            winners: 1696,
          ),
          LumePrizeBond(
            denom: 1500,
            draw: 'Draw 99',
            date: '15 Nov',
            first: 3000000,
            second: 1000000,
            third: 18500,
            winners: 1696,
          ),
        ],
      };

  /// `D.PRIZE_BONDS[c.profile.country]` — `null` where the scheme has no
  /// entry, which the tool reads as "not available in your country" rather
  /// than showing an empty scheme.
  static LumePrizeBondScheme? forCountry(String country) {
    final List<LumePrizeBond>? bonds = _byCountry[country];
    return bonds == null ? null : LumePrizeBondScheme(bonds);
  }

  /// `list.slice().sort(function (a, b) { return a.denom - b.denom; })[0]` —
  /// the lowest denomination. Sorted fresh, as the reference does, though the
  /// fixture list is already written in ascending order.
  LumePrizeBond get next => (List<LumePrizeBond>.of(
    bonds,
  )..sort((LumePrizeBond a, LumePrizeBond b) => a.denom - b.denom)).first;

  /// `list.reduce(function (a, b) { return a + b.first + b.second * 3 +
  /// b.third * b.winners; }, 0)` — first prize counted once, second counted
  /// three times over (the reference's own constant multiplier, not a
  /// per-denomination winner count) and third across all of its winners.
  double get prizePool => bonds.fold(
    0,
    (double a, LumePrizeBond b) =>
        a + b.first + b.second * 3 + b.third * b.winners,
  );

  /// `list.reduce(function (a, b) { return a + b.winners; }, 0)`.
  int get totalWinners =>
      bonds.fold(0, (int a, LumePrizeBond b) => a + b.winners);
}
