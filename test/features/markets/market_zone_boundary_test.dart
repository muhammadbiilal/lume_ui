/// The market calculator depends on the timezone *interface* (D29).
///
/// The session correction was approved — exchange-local time, a minute-exact
/// open, an exclusive close, the right weekend, derived holidays — on the
/// condition that the handmade rule table behind it stays what it is:
/// deterministic reference infrastructure, unsuitable as Dayroz's production
/// timezone authority, and replaceable at a stated seam.
///
/// This is that condition, asserted three ways:
///
/// 1. the calculator answers correctly for a zone implemented *here*, in this
///    file, that the rule table has never heard of;
/// 2. the calculator's source does not name the rule table at all;
/// 3. the table is reachable as a [LumeZoneDatabase], so replacing it is one
///    binding rather than a search.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_time_zone.dart';
import 'package:lume/core/time/lume_zone.dart';
import 'package:lume/features/markets/domain/market_calendar.dart';
import 'package:lume/features/markets/domain/market_session.dart';

/// A zone the rule table does not have, cannot derive, and never will: a
/// fixed +05:45, which is Kathmandu's, expressed as nothing but arithmetic.
///
/// If [LumeExchangeHours] were reaching for the table rather than taking what
/// it was given, this could not work.
class _FixedZone implements LumeZone {
  const _FixedZone(this.id, this.offset);

  @override
  final String id;

  final Duration offset;

  @override
  Duration offsetAt(DateTime instant) => offset;

  @override
  DateTime wallClockAt(DateTime instant) {
    final DateTime shifted = instant.toUtc().add(offset);
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
    );
  }
}

/// A zone that lies about the date as well as the hour, so a test can prove
/// the *weekend* comes from the zone too and not from the device.
class _AlwaysSunday implements LumeZone {
  const _AlwaysSunday();

  @override
  String get id => 'Test/AlwaysSunday';

  @override
  Duration offsetAt(DateTime instant) => Duration.zero;

  @override
  DateTime wallClockAt(DateTime instant) => DateTime(2026, 9, 6, 11);
}

void main() {
  const LumeTradingHours hours = LumeTradingHours(
    openMinute: 11 * 60,
    closeMinute: 15 * 60,
  );
  const LumeMarketCalendar calendar = LumeMarketCalendar(
    weekend: LumeMarketCalendar.weekendSatSun,
    holidays: <LumeHoliday>[LumeFixedHoliday('test-day', 12, 25)],
  );

  group('the calculator takes whatever zone it is handed', () {
    test('including one this build has no rule for', () {
      // 05:20 UTC on a Monday. In +05:45 that is 11:05, five minutes after
      // the open. In UTC it is 05:20, hours before it.
      const LumeExchangeHours exchange = LumeExchangeHours(
        zone: _FixedZone('Asia/Kathmandu', Duration(hours: 5, minutes: 45)),
        hours: hours,
        calendar: calendar,
      );
      final LumeMarketState state = exchange.stateAt(
        DateTime.utc(2026, 9, 7, 5, 20),
      );

      expect(state.isOpen, isTrue);
      expect(state.localTime.hour, 11);
      expect(state.localTime.minute, 5);
      expect(
        LumeTimeZones.byId('Asia/Kathmandu'),
        isNull,
        reason: 'the point of this test is that the table cannot answer for it',
      );
    });

    test('and the same instant is shut in a zone four hours behind it', () {
      const LumeExchangeHours exchange = LumeExchangeHours(
        zone: _FixedZone('Test/Minus', Duration(hours: 1, minutes: 45)),
        hours: hours,
        calendar: calendar,
      );
      expect(
        exchange.stateAt(DateTime.utc(2026, 9, 7, 5, 20)).closure,
        LumeMarketClosure.outsideHours,
      );
    });

    test('and reads the weekend off the zone, not the device', () {
      const LumeExchangeHours exchange = LumeExchangeHours(
        zone: _AlwaysSunday(),
        hours: hours,
        calendar: calendar,
      );
      // Inside trading hours, on a weekday everywhere else.
      final LumeMarketState state = exchange.stateAt(
        DateTime.utc(2026, 9, 9, 11),
      );
      expect(state.isOpen, isFalse);
      expect(state.closure, LumeMarketClosure.weekend);
    });
  });

  group('the seam is where it says it is', () {
    test('the calculator never names the rule table', () {
      // The strongest form of "depends on the abstraction": the words are not
      // in the file. A future edit that reaches for `LumeTimeZones` to fix
      // something fails here rather than in a market screen two phases later.
      for (final String path in <String>[
        'lib/features/markets/domain/market_session.dart',
        'lib/features/markets/domain/market_calendar.dart',
      ]) {
        final String source = File(path).readAsStringSync();
        expect(
          source.contains('lume_time_zone.dart'),
          isFalse,
          reason: '$path imports the rule table',
        );
        expect(
          source.contains('LumeTimeZones'),
          isFalse,
          reason: '$path names the rule table',
        );
        expect(
          source.contains('LumeDstRule'),
          isFalse,
          reason: '$path knows about daylight saving',
        );
      }
    });

    test('and only the fixtures bind it', () {
      // One file under `lib/` may name the table: the one that says which
      // zone each exchange is in. Everything else goes through the interface.
      final List<String> binders = <String>[];
      for (final FileSystemEntity e in Directory(
        'lib',
      ).listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final String path = e.path.replaceAll(r'\', '/');
        if (path.endsWith('core/time/lume_time_zone.dart')) continue;
        if (File(e.path).readAsStringSync().contains('LumeTimeZones')) {
          binders.add(path);
        }
      }
      expect(binders, <String>[
        'lib/features/markets/data/exchange_fixtures.dart',
      ]);
    });

    test('and the table is reachable as a database, so it can be replaced', () {
      const LumeZoneDatabase db = LumeRuleTableZones();
      expect(db.zoneFor('Asia/Karachi'), isNotNull);
      expect(db.zoneFor('Asia/Karachi')!.id, 'Asia/Karachi');
      expect(db.ids, contains('America/New_York'));

      // A build that cannot answer says so. Substituting the device's zone
      // would be a wrong answer wearing a right answer's clothes.
      expect(db.zoneFor('Antarctica/Troll'), isNull);
    });

    test('and any database at all satisfies the interface', () {
      // Proof that the boundary is implementable without the table: three
      // lines, no rules, no package.
      const LumeZoneDatabase fake = _OneZone();
      expect(fake.zoneFor('Asia/Kathmandu'), isNotNull);
      expect(fake.ids, <String>['Asia/Kathmandu']);
    });
  });
}

class _OneZone implements LumeZoneDatabase {
  const _OneZone();

  static const LumeZone _zone = _FixedZone(
    'Asia/Kathmandu',
    Duration(hours: 5, minutes: 45),
  );

  @override
  LumeZone? zoneFor(String id) => id == _zone.id ? _zone : null;

  @override
  Iterable<String> get ids => const <String>['Asia/Kathmandu'];
}
