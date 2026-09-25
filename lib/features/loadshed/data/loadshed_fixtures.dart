/// Loadshedding — `context.js` `loadshed()` over `D.LOADSHED`, typed.
///
/// PK-only (`countries: ['PK']`, the catalogue's `loadshed` entry):
/// loadshedding — a scheduled, rolling power outage — is not a concept every
/// market shares, so this is fixture data for one country rather than a
/// pattern every reader gets a guessed version of. Three figures are the
/// reference's own, carried over exactly:
///
/// * [kLoadshedSlots] — the five fixed daily outage windows (`D.LOADSHED`).
/// * [kLoadshedReliability] — `reliability: 78`, how often the schedule held.
/// * [kLoadshedWeek] — `week: [6, 5, 7, 6, 4, 5, 6]`, hours without power each
///   day, Monday first (`todayIndex: (now.getDay() + 6) % 7` turns Sunday's
///   `0` into `6`, so the array itself already reads Monday → Sunday).
///
/// Everything else — which slot is running, how long until it starts or
/// ends, the day's total — is worked out from the clock over that fixed
/// schedule, the same arithmetic `loadshed()` does.
///
/// **Dayroz obligation:** a real integration needs the reader's own
/// distribution company's live outage-schedule feed for their feeder/area,
/// timestamped — not a fixed daily schedule assumed to repeat forever, and
/// not a reliability figure with no source behind it.
library;

import 'package:flutter/foundation.dart';

/// One scheduled outage window, in 24-hour `HH:mm`.
@immutable
class LumeLoadshedSlot {
  const LumeLoadshedSlot({required this.from, required this.to});

  final String from;
  final String to;
}

/// `D.LOADSHED` — five fixed outage windows, every day, the last one
/// crossing midnight.
const List<LumeLoadshedSlot> kLoadshedSlots = <LumeLoadshedSlot>[
  LumeLoadshedSlot(from: '06:00', to: '07:00'),
  LumeLoadshedSlot(from: '10:00', to: '11:00'),
  LumeLoadshedSlot(from: '14:00', to: '16:00'),
  LumeLoadshedSlot(from: '19:00', to: '20:00'),
  LumeLoadshedSlot(from: '23:00', to: '00:00'),
];

/// `reliability: 78` — kept to schedule this often, a fixed figure.
const int kLoadshedReliability = 78;

/// `week: [6, 5, 7, 6, 4, 5, 6]` — hours without power each day, Monday
/// first.
const List<int> kLoadshedWeek = <int>[6, 5, 7, 6, 4, 5, 6];

/// Where a slot sits relative to now.
enum LumeLoadshedState { done, now, next }

/// One [LumeLoadshedSlot], resolved against the clock.
@immutable
class LumeLoadshedResolvedSlot {
  const LumeLoadshedResolvedSlot({
    required this.slot,
    required this.state,
    required this.fromMinute,
    required this.toMinute,
  });

  final LumeLoadshedSlot slot;
  final LumeLoadshedState state;

  /// Minutes from midnight the outage starts.
  final int fromMinute;

  /// Minutes from midnight the outage ends — past `1440` when the slot
  /// crosses midnight (`to <= from` rolls `to` into tomorrow, exactly as the
  /// reference does), never past a single resolved day otherwise.
  final int toMinute;

  /// Whole hours the slot lasts — `Math.round((to - from) / 60)`.
  int get hours => ((toMinute - fromMinute) / 60).round();
}

/// Today's schedule, resolved against [nowMinute] — minutes since midnight
/// in the reader's own clock, exactly as `loadshed()` reads `new Date()`.
@immutable
class LumeLoadshedToday {
  const LumeLoadshedToday({
    required this.slots,
    required this.current,
    required this.next,
    required this.reliability,
    required this.week,
    required this.todayIndex,
  });

  /// `loadshed()` — [nowMinute] is minutes since midnight, [weekday] is
  /// Dart's `DateTime.weekday` (Monday `1` … Sunday `7`).
  factory LumeLoadshedToday.at({required int nowMinute, required int weekday}) {
    final List<LumeLoadshedResolvedSlot> resolved = <LumeLoadshedResolvedSlot>[
      for (final LumeLoadshedSlot s in kLoadshedSlots) _resolve(s, nowMinute),
    ];
    final LumeLoadshedResolvedSlot? current = resolved
        .where((LumeLoadshedResolvedSlot s) => s.state == LumeLoadshedState.now)
        .firstOrNull;
    final LumeLoadshedResolvedSlot next =
        resolved
            .where(
              (LumeLoadshedResolvedSlot s) => s.state == LumeLoadshedState.next,
            )
            .firstOrNull ??
        resolved.first;
    return LumeLoadshedToday(
      slots: resolved,
      current: current,
      next: next,
      reliability: kLoadshedReliability,
      week: kLoadshedWeek,
      // `(now.getDay() + 6) % 7` — Dart's weekday is already Monday-first
      // (`1`…`7`), so this is the same index without the JS re-basing.
      todayIndex: (weekday - 1) % 7,
    );
  }

  final List<LumeLoadshedResolvedSlot> slots;

  /// The slot running right now, or `null` when the reader is between two.
  final LumeLoadshedResolvedSlot? current;

  /// The next slot to start — the first one still ahead, or the schedule's
  /// own first slot when none is (`slots.filter(...)[0] || slots[0]`).
  final LumeLoadshedResolvedSlot next;

  final int reliability;
  final List<int> week;

  /// Which cell of [week] is today — Monday `0` … Sunday `6`.
  final int todayIndex;

  /// `!!current`.
  bool get isNow => current != null;

  /// `current || next` — the slot the summary card leads with.
  LumeLoadshedResolvedSlot get slot => current ?? next;

  /// Minutes until the current outage ends, or the next one begins —
  /// `current ? current.toM - nowM : Math.max(0, next.fromM - nowM)`.
  int minutesUntil(int nowMinute) {
    final LumeLoadshedResolvedSlot? c = current;
    if (c != null) return c.toMinute - nowMinute;
    final int diff = next.fromMinute - nowMinute;
    return diff < 0 ? 0 : diff;
  }

  /// `L.num(slots.reduce((a, s) => a + (s.toM - s.fromM) / 60, 0))` — the
  /// day's total hours off, always whole across the reference's own slots.
  double get hoursToday => slots.fold(
    0,
    (double a, LumeLoadshedResolvedSlot s) =>
        a + (s.toMinute - s.fromMinute) / 60,
  );

  static LumeLoadshedResolvedSlot _resolve(LumeLoadshedSlot s, int nowMinute) {
    final int from = _minutesOf(s.from);
    int to = _minutesOf(s.to);
    if (to <= from) to += 1440;
    final LumeLoadshedState state = nowMinute >= to
        ? LumeLoadshedState.done
        : nowMinute >= from
        ? LumeLoadshedState.now
        : LumeLoadshedState.next;
    return LumeLoadshedResolvedSlot(
      slot: s,
      state: state,
      fromMinute: from,
      toMinute: to,
    );
  }

  static int _minutesOf(String hhmm) {
    final List<String> parts = hhmm.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
