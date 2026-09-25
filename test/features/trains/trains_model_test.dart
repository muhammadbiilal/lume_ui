/// The Trains tool's own data — the real roster and station timeline
/// `LumeTrainsComposer` hands both Trains surfaces, and its pure helpers
/// over them.
///
/// Deliberately independent of `trains_tool.dart`: that file calls
/// `AppLocalizations` getters this tool's report is still waiting on
/// (`trainsFind` and the rest — see `trains_tool_test.dart`'s own doc
/// comment), so a test that imported it could not compile until they land.
/// Nothing asserted here needs a locale at all.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/trains/data/trains_fixtures.dart';
import 'package:lume/features/trains/domain/trains_model.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 25, 12);
  final List<LumeTrainService> roster = LumeTrainsComposer.departures(
    '',
    on: now,
  );

  group('the roster — `TRAINS`, ported', () {
    test('five named services, in the reference’s order', () {
      expect(roster.map((LumeTrainService t) => t.number).toList(), <String>[
        '5UP',
        '7UP',
        '41UP',
        '27DN',
        '101UP',
      ]);
    });

    test('Green Line Express — 5UP', () {
      final LumeTrainService t = roster.first;
      expect(t.name, 'Green Line Express');
      expect(t.fromCode, 'KYC');
      expect(t.from, 'Karachi Cantt');
      expect(t.toCode, 'ISL');
      expect(t.to, 'Islamabad');
      expect(t.departMinute, 22 * 60);
      expect(t.arriveMinute, 17 * 60 + 30);
      expect(t.durationMinutes, 19 * 60 + 30);
      expect(t.status, LumeTrainStatus.onTime);
      expect(t.delayMinutes, 0);
      expect(t.fare, 8900);
      expect(t.platform, '4');
      expect(t.speedKmh, 96);
      expect(t.next, 'Rohri Junction');
      expect(t.progress, 0.48);
      expect(t.classes, <String>['AC Sleeper', 'AC Business']);
      expect(t.isLate, isFalse);
      expect(t.code, '5');
    });

    test('Tezgam Express — 7UP, 35 minutes late', () {
      final LumeTrainService t = roster[1];
      expect(t.status, LumeTrainStatus.late_);
      expect(t.delayMinutes, 35);
      expect(t.isLate, isTrue);
      expect(t.code, '7');
    });

    test('Karakoram Express — 41UP', () {
      final LumeTrainService t = roster[2];
      expect(t.fromCode, 'KYC');
      expect(t.toCode, 'LHR');
      expect(t.speedKmh, 104);
      expect(t.classes, <String>['AC Business', 'Economy']);
      expect(t.code, '41');
    });

    test('Shalimar Express — 27DN, departed and not late', () {
      final LumeTrainService t = roster[3];
      expect(t.from, 'Lahore');
      expect(t.to, 'Karachi City');
      expect(t.status, LumeTrainStatus.departed);
      expect(t.delayMinutes, 0);
      expect(t.isLate, isFalse);
      expect(t.code, '27');
    });

    test('Pakistan Express — 101UP, 70 minutes late, Economy only', () {
      final LumeTrainService t = roster[4];
      expect(t.status, LumeTrainStatus.late_);
      expect(t.delayMinutes, 70);
      expect(t.fare, 4850);
      expect(t.classes, <String>['Economy']);
      expect(t.code, '101');
    });
  });

  group('the station timeline — `TRAIN_STOPS`, ported', () {
    final List<LumeTrainTimelineStop> stops =
        LumeTrainsComposer.timelineStops();

    test('eight stops, Karachi Cantt to Islamabad, in order', () {
      expect(stops.map((LumeTrainTimelineStop s) => s.name).toList(), <String>[
        'Karachi Cantt',
        'Hyderabad Junction',
        'Rohri Junction',
        'Rahim Yar Khan',
        'Multan Cantt',
        'Lahore Junction',
        'Rawalpindi',
        'Islamabad',
      ]);
    });

    test('a done stop, an actual time later than scheduled', () {
      final LumeTrainTimelineStop s = stops[1];
      expect(s.scheduledMinute, 5);
      expect(s.actualMinute, 11);
      expect(s.state, LumeTrainTimelineState.done);
      expect(s.km, 165);
    });

    test('the stop the train is at now', () {
      final LumeTrainTimelineStop s = stops[2];
      expect(s.name, 'Rohri Junction');
      expect(s.actualMinute, s.scheduledMinute);
      expect(s.state, LumeTrainTimelineState.now);
      expect(s.km, 480);
    });

    test('a stop still ahead has no actual time yet', () {
      final LumeTrainTimelineStop s = stops.last;
      expect(s.name, 'Islamabad');
      expect(s.actualMinute, isNull);
      expect(s.state, LumeTrainTimelineState.next);
      expect(s.km, 1505);
    });
  });

  group('the operator — keyed by country, not fixed', () {
    test('Pakistan has one', () {
      expect(LumeTrainsComposer.operatorFor('PK'), 'Pakistan Railways');
    });

    test('a country with no rail network in Lume yet has none', () {
      expect(LumeTrainsComposer.operatorFor('US'), isEmpty);
      expect(LumeTrainsComposer.operatorFor('GB'), isEmpty);
    });
  });

  group('LumeTrainsComposer.filterByStatus — the status filter', () {
    test('all keeps the whole roster', () {
      expect(LumeTrainsComposer.filterByStatus(roster, status: 'all'), roster);
    });

    test('ontime keeps the on-time and the departed, not the late', () {
      expect(
        LumeTrainsComposer.filterByStatus(
          roster,
          status: 'ontime',
        ).map((LumeTrainService t) => t.number),
        <String>['5UP', '41UP', '27DN'],
      );
    });

    test('late keeps only the delayed', () {
      expect(
        LumeTrainsComposer.filterByStatus(
          roster,
          status: 'late',
        ).map((LumeTrainService t) => t.number),
        <String>['7UP', '101UP'],
      );
    });
  });

  group('LumeTrainsComposer fare arithmetic — the reference’s own formula', () {
    final LumeTrainService fiveUp = roster.first;

    test('the first tier is the full fare', () {
      expect(LumeTrainsComposer.fareForTier(fiveUp, 0), 8900);
      expect(LumeTrainsComposer.seatsForTier(0), 48);
    });

    test('a later tier is 72% of the fare, 17 fewer seats', () {
      expect(
        LumeTrainsComposer.fareForTier(fiveUp, 1),
        closeTo(8900 * 0.72, 0.001),
      );
      expect(LumeTrainsComposer.seatsForTier(1), 31);
    });
  });
}
