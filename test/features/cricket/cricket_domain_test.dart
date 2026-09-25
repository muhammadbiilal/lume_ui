/// Cricket's data — round-tripped, not rendered.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/cricket/data/cricket_fixtures.dart';

void main() {
  group('the one match', () {
    test('is PAK v ENG, exactly as the reference writes it', () {
      const LumeCricketMatch m = LumeCricket.match;
      expect(m.team1, 'PAK');
      expect(m.team1Full, 'Pakistan');
      expect(m.team2, 'ENG');
      expect(m.team2Full, 'England');
      expect(m.score1, '214/4');
      expect(m.overs1, '38.2');
      expect(m.score2, '—');
      expect(m.overs2, '—');
      expect(m.runRate, 5.58);
      expect(m.venue, 'Gaddafi Stadium, Lahore');
      expect(m.format, 'ODI · 2nd of 3');
    });

    test('has not batted a second innings yet', () {
      expect(LumeCricket.match.hasSecondInnings, isFalse);
    });

    test('names its city from the venue', () {
      expect(LumeCricket.match.venueCity, 'Gaddafi Stadium');
    });

    test('carries two batters, not out', () {
      final List<LumeCricketBatter> b = LumeCricket.match.batters;
      expect(b, hasLength(2));
      expect(b[0].name, 'Babar Azam');
      expect(b[0].runs, 88);
      expect(b[0].balls, 94);
      expect(b[0].fours, 7);
      expect(b[0].sixes, 1);
      expect(b[0].strikeRate, 93.6);
      expect(b[0].out, isFalse);
      expect(b[1].name, 'Salman Agha');
      expect(b[1].out, isFalse);
    });

    test('carries two bowlers', () {
      final List<LumeCricketBowler> bw = LumeCricket.match.bowlers;
      expect(bw, hasLength(2));
      expect(bw[0].name, 'A. Rashid');
      expect(bw[0].overs, 8);
      expect(bw[0].maidens, 0);
      expect(bw[0].runs, 41);
      expect(bw[0].wickets, 2);
      expect(bw[0].economy, 5.12);
      expect(bw[1].name, 'J. Archer');
      expect(bw[1].overs, 7.2);
      expect(bw[1].wickets, 1);
    });
  });

  group('fixtures', () {
    test('lists three, in the reference order', () {
      expect(LumeCricket.fixtures, hasLength(3));
      expect(
        LumeCricket.fixtures.map((LumeCricketFixture f) => '${f.team1} v ${f.team2}'),
        <String>['PAK v ENG', 'IND v AUS', 'SA v NZ'],
      );
    });

    test('splits "when" into a date and a time', () {
      final LumeCricketFixture f = LumeCricket.fixtures.first;
      expect(f.when, '11 Sep · 15:00');
      expect(f.date, '11 Sep');
      expect(f.time, '15:00');
    });
  });

  group('standings', () {
    test('has five teams, ranked as the reference ranks them', () {
      expect(
        LumeCricket.standings.map((LumeCricketStanding s) => s.team),
        <String>['India', 'Australia', 'Pakistan', 'England', 'South Africa'],
      );
    });

    test('carries each team\'s signed net run rate as text', () {
      final LumeCricketStanding india = LumeCricket.standings.first;
      expect(india.played, 8);
      expect(india.won, 6);
      expect(india.lost, 2);
      expect(india.points, 12);
      expect(india.netRunRate, '+0.84');
      final LumeCricketStanding england = LumeCricket.standings[3];
      expect(england.netRunRate, '−0.06');
    });
  });
}
