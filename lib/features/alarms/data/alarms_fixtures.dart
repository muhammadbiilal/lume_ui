/// Alarms — the reference's own fixture, ported as-is.
///
/// `tools/personal/alarms.tool.js` has no entry in `tool-data.js`: its three
/// alarms are a literal array inside `context.js`' own `alarms()` function,
/// rebuilt fresh on every call rather than read from a store —
///
/// ```js
/// function alarms() {
///   var list = [
///     { id: 'a1', at: L.time(6, 30),  label: t('alarms.a1'), repeat: t('alarms.weekdays'), on: true  },
///     { id: 'a2', at: L.time(7, 15),  label: t('alarms.a2'), repeat: t('alarms.weekend'),  on: false },
///     { id: 'a3', at: L.time(22, 30), label: t('alarms.a3'), repeat: t('alarms.daily'),    on: true  }
///   ];
///   var next = list.filter(function (a) { return a.on; })[0];
///   if (next) next.inLabel = t('alarms.inHours', { n: 8 });
///   return { list: list, next: next };
/// }
/// ```
///
/// "in about 8 hours" is not a real countdown from the device clock: `n: 8`
/// is a constant, called every time regardless of the actual time of day —
/// the same class of fixed figure Focus Timer's own reference constants are
/// (see `tool_capability.dart`'s `inputOnly`/`fixture` split), not something
/// this port invents a real clock for.
library;

/// Which of the three fixture alarms a row is — its `label` and the words
/// `at`/`repeat` resolve to live in [LumeAlarmText], not here, so this stays
/// a plain value the way `reminder_model.dart` keeps its own repeat kind.
enum LumeAlarmLabel { work, lieIn, windDown }

/// `alarms.weekdays` / `alarms.weekend` / `alarms.daily`.
enum LumeAlarmRepeat { weekdays, weekend, daily }

/// One row of the reference's fixture array — a wake time, a label, a repeat
/// pattern, and whether it is armed.
class LumeAlarm {
  const LumeAlarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    required this.repeat,
    required this.on,
  });

  final String id;

  /// 24-hour fields; [LumeAlarmText.time] formats them for the reader's own
  /// locale and clock preference — never `HH:MM` directly.
  final int hour;
  final int minute;

  final LumeAlarmLabel label;
  final LumeAlarmRepeat repeat;
  final bool on;
}

/// The reference's own three-alarm fixture, in the reference's own order.
abstract final class LumeAlarmBoard {
  static const List<LumeAlarm> alarms = <LumeAlarm>[
    LumeAlarm(
      id: 'a1',
      hour: 6,
      minute: 30,
      label: LumeAlarmLabel.work,
      repeat: LumeAlarmRepeat.weekdays,
      on: true,
    ),
    LumeAlarm(
      id: 'a2',
      hour: 7,
      minute: 15,
      label: LumeAlarmLabel.lieIn,
      repeat: LumeAlarmRepeat.weekend,
      on: false,
    ),
    LumeAlarm(
      id: 'a3',
      hour: 22,
      minute: 30,
      label: LumeAlarmLabel.windDown,
      repeat: LumeAlarmRepeat.daily,
      on: true,
    ),
  ];

  /// `list.filter(a => a.on)[0]` — the first armed alarm in fixture order, or
  /// `null` when none is (the reference then leaves `next` `undefined` and
  /// the tool shows `alarms.none` instead).
  static LumeAlarm? next(List<LumeAlarm> alarms) {
    for (final LumeAlarm a in alarms) {
      if (a.on) return a;
    }
    return null;
  }

  /// `t('alarms.inHours', { n: 8 })` — always 8, never computed from the
  /// alarm's own time or the device clock (see the library note above).
  static const int nextInHours = 8;
}
