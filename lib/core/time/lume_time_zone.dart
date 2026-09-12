/// A handmade rule table that satisfies [LumeZoneDatabase].
///
/// **Reference infrastructure. Not a timezone authority, and not Dayroz's.**
///
/// Each zone here states a standard offset and, where it has one, which
/// daylight-saving family it follows. Six zones, two rules, no package — which
/// is exactly what a conversion needs: the fixtures are deterministic, the
/// tests run the same in Karachi and Auckland, and nothing depends on a
/// network or a platform channel.
///
/// It is also, deliberately, a poor database. It has no history, so a date
/// before the rule it encodes is wrong. It has no future beyond today's
/// legislation, so a jurisdiction that moves or abolishes its change makes it
/// wrong without telling anyone. It knows six zones and there are hundreds. It
/// has no concept of a zone being renamed, split, or having its offset
/// redefined, all of which happen.
///
/// So it implements the boundary in `lume_zone.dart` rather than being it.
/// Dayroz installs a maintained IANA database behind [LumeZoneDatabase] — the
/// `timezone` package or the platform's own — and this file does not travel
/// with it. **Copying this table into Dayroz would be a decision to make
/// separately, with evidence, and this phase has not made it.**
///
/// `market_session.dart` names [LumeZone] and never this file, and
/// `market_zone_boundary_test.dart` fails if that stops being true.
library;

import 'package:flutter/foundation.dart';

import 'lume_zone.dart';

/// Which daylight-saving family a zone follows.
enum LumeDstRule {
  /// No seasonal change. Karachi, Dubai, Riyadh, Kolkata.
  none,

  /// North America since 2007: forward at 02:00 local standard on the second
  /// Sunday in March, back at 02:00 local daylight on the first Sunday in
  /// November.
  northAmerica,

  /// The European Union and the United Kingdom: forward at 01:00 **UTC** on the
  /// last Sunday in March, back at 01:00 UTC on the last Sunday in October.
  /// Defined in UTC on purpose, so every European zone turns at once.
  europe,
}

/// One zone, as a rule rather than as a record.
@immutable
class LumeTimeZone implements LumeZone {
  const LumeTimeZone({
    required this.id,
    required this.standardOffset,
    this.rule = LumeDstRule.none,
    this.savingOffset = const Duration(hours: 1),
  });

  /// The IANA identifier, because that is what the fixtures carry.
  @override
  final String id;

  /// The offset from UTC outside daylight saving.
  final Duration standardOffset;

  final LumeDstRule rule;

  /// How far the clock moves when saving is in force.
  final Duration savingOffset;

  /// Whether daylight saving is in force at [instant].
  bool isSaving(DateTime instant) {
    final DateTime utc = instant.toUtc();
    return switch (rule) {
      LumeDstRule.none => false,
      LumeDstRule.northAmerica => _between(
        utc,
        // 02:00 local standard on the second Sunday in March.
        _nthWeekday(
          utc.year,
          DateTime.march,
          DateTime.sunday,
          2,
        ).add(const Duration(hours: 2)).subtract(standardOffset),
        // 02:00 local daylight on the first Sunday in November.
        _nthWeekday(
          utc.year,
          DateTime.november,
          DateTime.sunday,
          1,
        ).add(const Duration(hours: 2)).subtract(standardOffset + savingOffset),
      ),
      LumeDstRule.europe => _between(
        utc,
        _nthWeekday(
          utc.year,
          DateTime.march,
          DateTime.sunday,
          -1,
        ).add(const Duration(hours: 1)),
        _nthWeekday(
          utc.year,
          DateTime.october,
          DateTime.sunday,
          -1,
        ).add(const Duration(hours: 1)),
      ),
    };
  }

  /// The offset from UTC at [instant].
  @override
  Duration offsetAt(DateTime instant) =>
      isSaving(instant) ? standardOffset + savingOffset : standardOffset;

  /// The wall clock this zone is showing at [instant].
  ///
  /// Returned as a *naive* value — its `isUtc` is false and its fields are the
  /// zone's, not the device's. Reading `.hour` off it is the point; converting
  /// it back to an instant is not, and nothing does.
  @override
  DateTime wallClockAt(DateTime instant) {
    final DateTime shifted = instant.toUtc().add(offsetAt(instant));
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
    );
  }

  static bool _between(DateTime t, DateTime from, DateTime to) =>
      !t.isBefore(from) && t.isBefore(to);

  static DateTime _nthWeekday(int year, int month, int weekday, int n) =>
      LumeWeekday.nthUtc(year, month, weekday, n);

  @override
  bool operator ==(Object other) =>
      other is LumeTimeZone &&
      other.id == id &&
      other.standardOffset == standardOffset &&
      other.rule == rule &&
      other.savingOffset == savingOffset;

  @override
  int get hashCode => Object.hash(id, standardOffset, rule, savingOffset);
}

/// The zones the fixtures name.
///
/// Reachable as a [LumeZoneDatabase] through [LumeRuleTableZones], which is
/// the form anything outside this file should take it in.
abstract final class LumeTimeZones {
  static const LumeTimeZone karachi = LumeTimeZone(
    id: 'Asia/Karachi',
    standardOffset: Duration(hours: 5),
  );
  static const LumeTimeZone dubai = LumeTimeZone(
    id: 'Asia/Dubai',
    standardOffset: Duration(hours: 4),
  );
  static const LumeTimeZone riyadh = LumeTimeZone(
    id: 'Asia/Riyadh',
    standardOffset: Duration(hours: 3),
  );
  static const LumeTimeZone kolkata = LumeTimeZone(
    id: 'Asia/Kolkata',
    standardOffset: Duration(hours: 5, minutes: 30),
  );
  static const LumeTimeZone newYork = LumeTimeZone(
    id: 'America/New_York',
    standardOffset: Duration(hours: -5),
    rule: LumeDstRule.northAmerica,
  );
  static const LumeTimeZone london = LumeTimeZone(
    id: 'Europe/London',
    standardOffset: Duration.zero,
    rule: LumeDstRule.europe,
  );

  static const List<LumeTimeZone> all = <LumeTimeZone>[
    karachi,
    dubai,
    riyadh,
    kolkata,
    newYork,
    london,
  ];

  /// `null` when this table cannot answer for a zone — which callers must
  /// handle rather than substituting the device's.
  static LumeTimeZone? byId(String id) {
    for (final LumeTimeZone z in all) {
      if (z.id == id) return z;
    }
    return null;
  }
}

/// [LumeTimeZones] as a [LumeZoneDatabase].
///
/// The only place the conversion's rule table is handed to something that
/// asked for a database, so it is the one line Dayroz replaces. Swapping in a
/// maintained IANA database is a change to *this* binding and nothing else.
@immutable
class LumeRuleTableZones implements LumeZoneDatabase {
  const LumeRuleTableZones();

  @override
  LumeZone? zoneFor(String id) => LumeTimeZones.byId(id);

  @override
  Iterable<String> get ids => LumeTimeZones.all.map((LumeTimeZone z) => z.id);
}
