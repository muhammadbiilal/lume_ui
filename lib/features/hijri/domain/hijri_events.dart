/// The Hijri calendar's own fixed dates — worked out, never listed.
///
/// `tools/islamic/hijri.tool.js` closes with `D.ISLAMIC_EVENTS`, five rows
/// with a name, a Hijri date, a Gregorian date and a day count baked into
/// `tool-data.js:690-696` as literal numbers — "Eid al-Fitr … 20 Mar … in 193
/// days" — true of no year in particular and wrong for every year but the one
/// the fixture was written against. Lume's "no fabricated data" rule forbids
/// reproducing that: this file computes the same handful of calendar
/// transitions for real, from the day the reader opens the tool, using the
/// one Hijri conversion the app already carries ([LumeHijriDate.of],
/// `core/time/lume_hijri.dart`) rather than a second copy of its arithmetic.
///
/// **Why a forward scan and not a closed-form inverse.** [LumeHijriDate.of]
/// only goes one way — a Gregorian day to the Hijri date it falls on — and
/// this file is not the place to add the tabular calendar's inverse (Hijri to
/// Gregorian): that belongs beside the forward function it would have to stay
/// in lockstep with, and this rollout wave is confined to `features/hijri`.
/// A day-by-day scan needs no inverse: every Hijri year in this calendar is
/// 354 or 355 days (`lume_hijri.dart`'s own doc), so scanning forward at most
/// [LumeHijriEvents.horizonDays] civil days from today is guaranteed to reach
/// every one of the six transitions below at least once, and the first hit is
/// the next occurrence.
///
/// **What is left out, and why.** The reference's fifth row, "Laylat al-Qadr
/// (likely)" on 27 Ramadan, is not a calendar transition at all — which night
/// of the last ten it falls on is a matter of scholarly opinion, not a date
/// this or any calendar can compute — so it is dropped rather than given a
/// false arithmetic certainty (the same reasoning `ROLLOUT_WAVE_3.md` gives
/// for holding `holidays` back over Eid dates it could not derive honestly).
/// What remains are the six transitions a calendar — any calendar, tabular or
/// observational — is actually in a position to name: a month starting on its
/// first day.
library;

import 'package:flutter/foundation.dart';

import '../../../core/time/lume_hijri.dart';

/// Which of the six computed transitions one [LumeHijriEvent] is.
enum LumeHijriEventId {
  islamicNewYear,
  ashura,
  ramadanBegins,
  eidAlFitr,
  dayOfArafah,
  eidAlAdha,
}

/// One transition, found by [LumeHijriEvents.upcoming] and never invented.
@immutable
class LumeHijriEvent {
  const LumeHijriEvent({
    required this.id,
    required this.hijri,
    required this.gregorian,
    required this.daysAway,
  });

  final LumeHijriEventId id;

  /// The Hijri date this transition falls on — always the target month's 1st,
  /// 9th or 10th, carrying the year the scan actually reached.
  final LumeHijriDate hijri;

  /// The civil (Gregorian) date the scan found it on.
  final DateTime gregorian;

  /// Whole civil days from the day the scan started. `0` is today.
  final int daysAway;

  @override
  bool operator ==(Object other) =>
      other is LumeHijriEvent &&
      other.id == id &&
      other.hijri == hijri &&
      other.gregorian == gregorian &&
      other.daysAway == daysAway;

  @override
  int get hashCode => Object.hash(id, hijri, gregorian, daysAway);
}

/// Pure scheduling over [LumeHijriDate]: no widget, no locale, no clock of its
/// own — [today] is always handed in.
abstract final class LumeHijriEvents {
  /// The Hijri (month, day) each id names the *first* day of — Muharram is
  /// month 1.
  static const Map<LumeHijriEventId, (int, int)> _targets =
      <LumeHijriEventId, (int, int)>{
        LumeHijriEventId.islamicNewYear: (1, 1),
        LumeHijriEventId.ashura: (1, 10),
        LumeHijriEventId.ramadanBegins: (9, 1),
        LumeHijriEventId.eidAlFitr: (10, 1),
        LumeHijriEventId.dayOfArafah: (12, 9),
        LumeHijriEventId.eidAlAdha: (12, 10),
      };

  /// A Hijri year is at most 355 days (`lume_hijri.dart`): every target below
  /// recurs at least once inside this many civil days from any start date.
  static const int horizonDays = 380;

  /// Every transition in [_targets], each the next one on or after [today],
  /// in chronological order.
  ///
  /// [today] is a civil date — only its year, month and day are read, exactly
  /// as [LumeHijriDate.of] reads whatever [DateTime] it is given.
  static List<LumeHijriEvent> upcoming(DateTime today) {
    final List<LumeHijriEvent> out = <LumeHijriEvent>[
      for (final MapEntry<LumeHijriEventId, (int, int)> t in _targets.entries)
        _next(today, id: t.key, month: t.value.$1, day: t.value.$2),
    ];
    out.sort(
      (LumeHijriEvent a, LumeHijriEvent b) => a.daysAway.compareTo(b.daysAway),
    );
    return out;
  }

  static LumeHijriEvent _next(
    DateTime today, {
    required LumeHijriEventId id,
    required int month,
    required int day,
  }) {
    // Walked over `LumeHijriDate.walkForward` — the same day-by-day scan
    // Ramadan's own countdown now walks too (`ramadan_tool.dart`'s
    // `_daysUntil`), extracted once both agents independently arrived at it.
    final (
      DateTime gregorian,
      LumeHijriDate hijri,
      int daysAway,
    ) = LumeHijriDate.walkForward(
      start: today,
      matches: (LumeHijriDate h) => h.month == month && h.day == day,
      horizonDays: horizonDays,
      reason:
          'No occurrence of Hijri $month/$day within $horizonDays days '
          'of ${today.toIso8601String()} — the tabular calendar\'s year '
          'is at most 355 days, so this should be unreachable.',
    );
    return LumeHijriEvent(
      id: id,
      hijri: hijri,
      gregorian: gregorian,
      daysAway: daysAway,
    );
  }
}
