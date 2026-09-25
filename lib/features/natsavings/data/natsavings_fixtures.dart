/// National Savings — Pakistan's government savings certificates, typed.
///
/// `tools/money/natsavings.tool.js` over `D.NAT_SAVINGS`: a country-keyed map
/// with exactly one entry, `PK`, of five certificates and accounts — Behbood,
/// Defence, Regular Income, Special Savings and the Pensioners' Benefit
/// Account — each carrying its own annual rate, term, payout schedule,
/// minimum deposit and eligibility. Every other country has no entry, and the
/// reference itself falls back to an `unavailable` composition when `list` is
/// missing (`if (!list) return UI.section({ body: UI.emptyState(...) })`) —
/// this is a Pakistan-specific government savings scheme, not something every
/// market has a version of.
///
/// **Dayroz obligation:** every figure below is the reference's own hardcoded
/// fixture data, carried over unchanged. A real integration needs the Central
/// Directorate of National Savings' own published rates — kept current and
/// dated, not a fixture that quietly goes stale; nothing here is invented or
/// extrapolated for a country the reference does not cover.
library;

import 'package:flutter/foundation.dart';

/// One certificate or account, as `NAT_SAVINGS` lists it. Names, terms,
/// payout schedules and eligibility are the reference's own English text —
/// it never runs them through `c.t()`, so this does not invent a translation
/// the reference does not have.
@immutable
class LumeSavingsInstrument {
  const LumeSavingsInstrument({
    required this.name,
    required this.rate,
    required this.term,
    required this.payout,
    required this.min,
    required this.eligible,
  });

  final String name;

  /// The annual profit rate, as a percentage (`15.36` means 15.36%).
  final double rate;

  /// `'10 years'` — free text, as the reference writes it.
  final String term;

  /// `'Monthly'`, `'On maturity'`, `'Half-yearly'`.
  final String payout;

  /// The minimum deposit, in the scheme's own currency.
  final double min;

  /// Who may open the account — `'All'` for the general public.
  final String eligible;

  /// `parseInt(p.term, 10)` — the term's leading number of years, for the
  /// sort bar's `'term'` dimension.
  int get termYears =>
      int.tryParse(RegExp(r'^\d+').stringMatch(term) ?? '') ?? 0;
}

@immutable
class LumeNatSavingsScheme {
  const LumeNatSavingsScheme(this.instruments);

  final List<LumeSavingsInstrument> instruments;

  /// `D.NAT_SAVINGS` — one country.
  static const Map<String, List<LumeSavingsInstrument>> _byCountry =
      <String, List<LumeSavingsInstrument>>{
        'PK': <LumeSavingsInstrument>[
          LumeSavingsInstrument(
            name: 'Behbood Savings Certificate',
            rate: 15.36,
            term: '10 years',
            payout: 'Monthly',
            min: 5000,
            eligible: 'Widows, seniors, disabled',
          ),
          LumeSavingsInstrument(
            name: 'Defence Savings Certificate',
            rate: 13.02,
            term: '10 years',
            payout: 'On maturity',
            min: 500,
            eligible: 'All',
          ),
          LumeSavingsInstrument(
            name: 'Regular Income Certificate',
            rate: 13.44,
            term: '5 years',
            payout: 'Monthly',
            min: 50000,
            eligible: 'All',
          ),
          LumeSavingsInstrument(
            name: 'Special Savings Certificate',
            rate: 12.60,
            term: '3 years',
            payout: 'Half-yearly',
            min: 500,
            eligible: 'All',
          ),
          LumeSavingsInstrument(
            name: 'Pensioners’ Benefit Account',
            rate: 15.36,
            term: '10 years',
            payout: 'Monthly',
            min: 5000,
            eligible: 'Pensioners',
          ),
        ],
      };

  /// `D.NAT_SAVINGS[c.profile.country]` — `null` where the scheme has no
  /// entry, which the tool reads as "not available in your country" rather
  /// than showing an empty scheme, and never as another country's figures.
  static LumeNatSavingsScheme? forCountry(String country) {
    final List<LumeSavingsInstrument>? list = _byCountry[country];
    return list == null ? null : LumeNatSavingsScheme(list);
  }

  /// `list.slice().sort((a, b) => b.rate - a.rate)[0]` — the highest rate,
  /// and the first of a tie in the reference's own order. `reduce` finds it
  /// without leaning on `List.sort`'s stability, which Dart does not
  /// guarantee the way a modern JS engine's `Array.sort` does.
  LumeSavingsInstrument get best =>
      instruments.reduce((LumeSavingsInstrument a, LumeSavingsInstrument b) {
        return b.rate > a.rate ? b : a;
      });
}

/// `(p.name + ' ' + p.eligible).toLowerCase().indexOf(query) !== -1` — kept
/// here rather than on the widget so the tool's search logic can be tested
/// without pulling in the presentation layer's own localization dependency.
List<LumeSavingsInstrument> lumeNatSavingsFilter(
  List<LumeSavingsInstrument> list,
  String query,
) {
  final String q = query.trim().toLowerCase();
  return <LumeSavingsInstrument>[
    for (final LumeSavingsInstrument p in list)
      if (q.isEmpty || '${p.name} ${p.eligible}'.toLowerCase().contains(q)) p,
  ];
}

/// `c.sortBy(list, { rate, term, min }, 'rate', 'desc')` — a single stable
/// comparator with the direction folded in, exactly as `context.js` `sortBy`
/// writes it: `(x - y) * dir`. Two instruments tied on the chosen dimension
/// keep the reference's own order regardless of direction — `dir` only ever
/// flips a real difference, never a zero — so this sorts by original position
/// on a tie rather than reversing the whole list.
List<LumeSavingsInstrument> lumeNatSavingsSort(
  List<LumeSavingsInstrument> list, {
  required String sort,
  required bool descending,
}) {
  final int dir = descending ? -1 : 1;
  double key(LumeSavingsInstrument p) => switch (sort) {
    'term' => p.termYears.toDouble(),
    'min' => p.min,
    _ => p.rate,
  };
  final List<(int, LumeSavingsInstrument)> indexed = <(
    int,
    LumeSavingsInstrument,
  )>[
    for (int i = 0; i < list.length; i++) (i, list[i]),
  ];
  indexed.sort((
    (int, LumeSavingsInstrument) a,
    (int, LumeSavingsInstrument) b,
  ) {
    final double diff = (key(a.$2) - key(b.$2)) * dir;
    if (diff != 0) return diff < 0 ? -1 : 1;
    return a.$1.compareTo(b.$1);
  });
  return <LumeSavingsInstrument>[
    for (final (int, LumeSavingsInstrument) e in indexed) e.$2,
  ];
}
