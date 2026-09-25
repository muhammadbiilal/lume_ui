/// Cricket — `tools/daily/cricket.tool.js` over `tool-data.js` `CRICKET`,
/// typed.
///
/// One frozen match (PAK v ENG, an ODI at Gaddafi Stadium, Lahore) with its
/// scorecard, three fixtures and a five-team table, exactly as the reference
/// writes them. The reference's `UI.freshness({ quality: 'live' })` over this
/// match is cosmetic: there is no feed behind it, live or otherwise — every
/// figure below is a literal from `tool-data.js`, fixed at the moment it was
/// written. Nothing here is worked out from a clock or refreshed.
///
/// **Dayroz obligation:** a real Cricket needs a licensed live-score
/// provider — ball-by-ball state, an innings that actually progresses, a
/// fixture list that rolls forward, and a table that recomputes after every
/// result — with its own delay disclosed. Until one exists, this tool's
/// capability is not registered as live or on-device-computed
/// (`LumeDataCapability`), so the shared source bar calls it what it is,
/// "Sample data", whatever freshness kind the catalogue declares for it.
library;

import 'package:flutter/foundation.dart';

/// One batter's line, mid-innings.
@immutable
class LumeCricketBatter {
  const LumeCricketBatter({
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.strikeRate,
    required this.out,
  });

  final String name;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;

  /// `!b.out` draws "not out" beside the name.
  final bool out;
}

/// One bowler's figures, mid-innings.
@immutable
class LumeCricketBowler {
  const LumeCricketBowler({
    required this.name,
    required this.overs,
    required this.maidens,
    required this.runs,
    required this.wickets,
    required this.economy,
  });

  final String name;

  /// Overs-and-balls notation (`7.2` is 7 overs, 2 balls) — written as the
  /// reference writes it, not a decimal fraction of an over.
  final double overs;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;
}

/// The one match the reference has — `k.live`.
@immutable
class LumeCricketMatch {
  const LumeCricketMatch({
    required this.team1,
    required this.team1Full,
    required this.team2,
    required this.team2Full,
    required this.score1,
    required this.overs1,
    required this.score2,
    required this.overs2,
    required this.runRate,
    required this.venue,
    required this.format,
    required this.batters,
    required this.bowlers,
  });

  final String team1;
  final String team1Full;
  final String team2;
  final String team2Full;

  /// `m.s1` — already written as the reference writes a score ("214/4").
  final String score1;

  /// `m.o1` — overs bowled, as text ("38.2").
  final String overs1;

  /// `m.s2` — "—" where the side chasing has not batted yet.
  final String score2;
  final String overs2;

  final double runRate;

  /// "Gaddafi Stadium, Lahore".
  final String venue;

  /// "ODI · 2nd of 3".
  final String format;

  final List<LumeCricketBatter> batters;
  final List<LumeCricketBowler> bowlers;

  /// `m.venue.split(',')[0]` — the metrics strip's third figure.
  String get venueCity => venue.split(',').first;

  /// `m.s2 && m.s2 !== '—'` — whether a second innings has runs on the board.
  bool get hasSecondInnings => score2.isNotEmpty && score2 != '—';
}

/// One row of `k.fixtures`.
@immutable
class LumeCricketFixture {
  const LumeCricketFixture({
    required this.team1,
    required this.team2,
    required this.when,
    required this.venue,
    required this.format,
  });

  final String team1;
  final String team2;

  /// "11 Sep · 15:00" — split on `f.when.split(' · ')` for the row's value
  /// and its sub-value.
  final String when;
  final String venue;
  final String format;

  static const String _sep = ' · ';

  /// `f.when.split(' · ')[0]`.
  String get date => when.split(_sep).first;

  /// `f.when.split(' · ')[1]`.
  String get time {
    final List<String> parts = when.split(_sep);
    return parts.length > 1 ? parts[1] : '';
  }
}

/// One row of `k.standings`.
@immutable
class LumeCricketStanding {
  const LumeCricketStanding({
    required this.team,
    required this.played,
    required this.won,
    required this.lost,
    required this.points,
    required this.netRunRate,
  });

  final String team;
  final int played;
  final int won;
  final int lost;
  final int points;

  /// `s.nrr` — already signed, as the reference writes it ("+0.84", "−0.06").
  final String netRunRate;
}

/// `D.CRICKET`, kept as the reference has it.
abstract final class LumeCricket {
  static const LumeCricketMatch match = LumeCricketMatch(
    team1: 'PAK',
    team1Full: 'Pakistan',
    team2: 'ENG',
    team2Full: 'England',
    score1: '214/4',
    overs1: '38.2',
    score2: '—',
    overs2: '—',
    runRate: 5.58,
    venue: 'Gaddafi Stadium, Lahore',
    format: 'ODI · 2nd of 3',
    batters: <LumeCricketBatter>[
      LumeCricketBatter(
        name: 'Babar Azam',
        runs: 88,
        balls: 94,
        fours: 7,
        sixes: 1,
        strikeRate: 93.6,
        out: false,
      ),
      LumeCricketBatter(
        name: 'Salman Agha',
        runs: 42,
        balls: 38,
        fours: 4,
        sixes: 0,
        strikeRate: 110.5,
        out: false,
      ),
    ],
    bowlers: <LumeCricketBowler>[
      LumeCricketBowler(
        name: 'A. Rashid',
        overs: 8,
        maidens: 0,
        runs: 41,
        wickets: 2,
        economy: 5.12,
      ),
      LumeCricketBowler(
        name: 'J. Archer',
        overs: 7.2,
        maidens: 1,
        runs: 38,
        wickets: 1,
        economy: 5.18,
      ),
    ],
  );

  static const List<LumeCricketFixture> fixtures = <LumeCricketFixture>[
    LumeCricketFixture(
      team1: 'PAK',
      team2: 'ENG',
      when: '11 Sep · 15:00',
      venue: 'Karachi',
      format: 'ODI 3',
    ),
    LumeCricketFixture(
      team1: 'IND',
      team2: 'AUS',
      when: '12 Sep · 09:30',
      venue: 'Chennai',
      format: 'T20 1',
    ),
    LumeCricketFixture(
      team1: 'SA',
      team2: 'NZ',
      when: '14 Sep · 13:00',
      venue: 'Cape Town',
      format: 'Test 1',
    ),
  ];

  static const List<LumeCricketStanding> standings = <LumeCricketStanding>[
    LumeCricketStanding(
      team: 'India',
      played: 8,
      won: 6,
      lost: 2,
      points: 12,
      netRunRate: '+0.84',
    ),
    LumeCricketStanding(
      team: 'Australia',
      played: 8,
      won: 5,
      lost: 3,
      points: 10,
      netRunRate: '+0.42',
    ),
    LumeCricketStanding(
      team: 'Pakistan',
      played: 8,
      won: 5,
      lost: 3,
      points: 10,
      netRunRate: '+0.18',
    ),
    LumeCricketStanding(
      team: 'England',
      played: 8,
      won: 4,
      lost: 4,
      points: 8,
      netRunRate: '−0.06',
    ),
    LumeCricketStanding(
      team: 'South Africa',
      played: 8,
      won: 3,
      lost: 5,
      points: 6,
      netRunRate: '−0.31',
    ),
  ];
}
