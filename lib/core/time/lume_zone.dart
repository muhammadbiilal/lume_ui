/// The timezone boundary: what the product asks of a zone, and nothing about
/// where the answer comes from.
///
/// §16 says *"time-sensitive functionality must respect the user's timezone"*
/// and *"do NOT hard-code timezone offsets"*. Dart's `DateTime` knows two
/// zones — UTC, and whatever the device is set to — so a phone in London
/// cannot answer "is the Karachi exchange open" without something else. This
/// is that something else, stated as an interface so the *something* is
/// replaceable.
///
/// ## The adapter boundary
///
/// Everything that needs a foreign wall clock depends on [LumeZone], and
/// everything that needs to find one depends on [LumeZoneDatabase]. Two
/// methods and one lookup, because that is genuinely all the product asks:
/// given an instant, what does that clock read, and how far is it from UTC.
///
/// ```text
/// market session ─▶ LumeZone ◀── implemented by ── LumeTimeZone (reference)
///                     ▲                            a tz-database adapter
///                     └── found through ── LumeZoneDatabase
/// ```
///
/// **`LumeTimeZone` is the conversion's implementation, and it is not fit to
/// be Dayroz's.** It is a handful of declared rules — a standard offset plus a
/// daylight-saving family — chosen so the fixtures are deterministic and the
/// tests need no package. It is wrong for any zone whose rules changed
/// historically, for any jurisdiction that changes them next, for the zones it
/// does not list at all, and for every leap second and political redefinition
/// in between. It is reference infrastructure. Moving it into Dayroz as the
/// production authority would be a decision, not a port, and it is not one
/// this phase has taken.
///
/// **What Dayroz installs instead.** A maintained IANA database — `timezone`,
/// or the platform's own — behind a class that `implements LumeZoneDatabase`
/// and hands back `LumeZone`s. Nothing above this file changes: the market
/// calculator has never seen a rule table, and a test proves it.
library;

/// One zone's clock, however the implementation knows it.
abstract interface class LumeZone {
  /// The IANA identifier — `Asia/Karachi`. The one thing a caller may compare.
  String get id;

  /// The offset from UTC at [instant], daylight saving included.
  Duration offsetAt(DateTime instant);

  /// The wall clock this zone shows at [instant].
  ///
  /// Returned as a *naive* value: `isUtc` is false and the fields are the
  /// zone's, not the device's. Reading `.hour` off it is the point; converting
  /// it back to an instant is not, and nothing does.
  DateTime wallClockAt(DateTime instant);
}

/// Where a [LumeZone] comes from.
///
/// One lookup, and it is allowed to fail. A build that cannot answer for a
/// zone returns `null` and the caller says so — substituting the device's zone
/// would be a wrong answer wearing a right answer's clothes.
abstract interface class LumeZoneDatabase {
  LumeZone? zoneFor(String id);

  /// Every zone this database can answer for. A registry-completeness test
  /// reads it; nothing in the interface does.
  Iterable<String> get ids;
}

/// The nth weekday of a month.
///
/// Daylight-saving rules and public-holiday rules both need it — "the second
/// Sunday in March", "the last Monday in May" — and there must not be two of
/// it, because two would drift.
abstract final class LumeWeekday {
  /// The [n]th [weekday] of a month at midnight UTC. `n == -1` is the last.
  static DateTime nthUtc(int year, int month, int weekday, int n) {
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

  /// The same date as a plain calendar day, for a holiday rule.
  static DateTime nth(int year, int month, int weekday, int n) {
    final DateTime utc = nthUtc(year, month, weekday, n);
    return DateTime(utc.year, utc.month, utc.day);
  }
}
