/// Wall-clock time somewhere that is not here.
///
/// Dart's `DateTime` knows two zones: UTC and whatever the device is set to.
/// That is not enough for a product whose §16 invariant is *"time-sensitive
/// functionality must respect the user's timezone"* and whose market screens
/// have to answer "is the Karachi exchange open" on a phone in London.
///
/// **This is a declared rule set, not the IANA database.** Each zone states its
/// standard offset and, where it has one, which daylight-saving rule family it
/// follows. That covers every zone the fixtures name, it is deterministic, it
/// needs no package, and it is honest about its limits: a zone whose rules
/// changed historically, or a jurisdiction that abolishes the change next year,
/// is wrong here and right in a platform database.
///
/// So the *contract* is [LumeTimeZones.byId], and the rule table is one
/// implementation of it. At Dayroz integration the table is replaced by the
/// platform's zone database behind the same lookup; nothing above this file
/// knows which one answered. That swap is the only thing pending — see
/// `docs/LUME_MARKETS.md`.
library;

import 'package:flutter/foundation.dart';

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

/// One zone.
@immutable
class LumeTimeZone {
  const LumeTimeZone({
    required this.id,
    required this.standardOffset,
    this.rule = LumeDstRule.none,
    this.savingOffset = const Duration(hours: 1),
  });

  /// The IANA identifier, because that is what the fixtures carry.
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
  Duration offsetAt(DateTime instant) =>
      isSaving(instant) ? standardOffset + savingOffset : standardOffset;

  /// The wall clock this zone is showing at [instant].
  ///
  /// Returned as a *naive* value — its `isUtc` is false and its fields are the
  /// zone's, not the device's. Reading `.hour` off it is the point; converting
  /// it back to an instant is not, and nothing does.
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

  /// The [n]th [weekday] of a month, at midnight UTC. `n == -1` is the last.
  static DateTime _nthWeekday(int year, int month, int weekday, int n) {
    if (n < 0) {
      final DateTime lastDay = DateTime.utc(
        year,
        month + 1,
        1,
      ).subtract(const Duration(days: 1));
      final int back = (lastDay.weekday - weekday + 7) % 7;
      return lastDay.subtract(Duration(days: back));
    }
    final DateTime first = DateTime.utc(year, month, 1);
    final int forward = (weekday - first.weekday + 7) % 7;
    return first.add(Duration(days: forward + (n - 1) * 7));
  }

  /// The [n]th [weekday] of a month as a plain calendar date. `n == -1` is the
  /// last. Exposed because the holiday rules need the same arithmetic and
  /// there must not be two of it.
  static DateTime nthWeekdayOf(int year, int month, int weekday, int n) {
    final DateTime utc = _nthWeekday(year, month, weekday, n);
    return DateTime(utc.year, utc.month, utc.day);
  }

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

  /// The lookup that is the contract. `null` when this build cannot answer for
  /// a zone — which callers must handle rather than substituting the device's.
  static LumeTimeZone? byId(String id) {
    for (final LumeTimeZone z in all) {
      if (z.id == id) return z;
    }
    return null;
  }
}
