/// Turns a stored [ReminderEntry] into a real, OS-scheduled notification —
/// `flutter_local_notifications`, behind the real/fake split every platform
/// adapter in this repo already uses (`REMINDERS_PROPOSAL.md` §3).
///
/// **The zone is the caller's to resolve, not this file's.** Scheduling a
/// time of day correctly needs the reader's real IANA zone
/// (`lume_zone.dart`'s own words: "substituting the device's zone would be
/// a wrong answer wearing a right answer's clothes"), and that resolution
/// already exists — [LumeReaderZone.readerZone] — and depends on the
/// reader's profile, which this data-layer file has no business reaching
/// into. [schedule] takes the resolved IANA identifier as a plain string;
/// `null` means resolution failed, and this scheduler does not guess UTC or
/// the device's own zone in its place — it reports
/// [ReminderScheduleOutcome.zoneUnresolved] and schedules nothing, so a
/// reminder is never silently an hour wrong.
library;

import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/values/lume_record_id.dart';
import '../domain/reminder_model.dart';

enum ReminderScheduleOutcome {
  scheduled,
  cancelled,
  zoneUnresolved,
  denied,
  failed,
}

/// A stable 31-bit id for the plugin's own int-keyed notification store —
/// derived from the record id's bytes, not `Object.hashCode` (Dart never
/// promises that is the same between runs, and this one has to be, or a
/// later [LumeReminderScheduler.cancel] would miss what an earlier
/// [LumeReminderScheduler.schedule] actually registered).
int lumeReminderNotificationId(LumeRecordId id) {
  final List<int> bytes = utf8.encode(id.value);
  // FNV-1a, 32-bit, masked into the plugin's signed 31-bit id space.
  int hash = 0x811c9dc5;
  for (final int b in bytes) {
    hash ^= b;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

const String kReminderChannelId = 'lume.reminders';

abstract interface class LumeReminderScheduler {
  /// Schedules (or replaces) [entry]'s notification. `zoneId` is the
  /// reader's resolved IANA identifier; `null` schedules nothing and
  /// reports [ReminderScheduleOutcome.zoneUnresolved].
  Future<ReminderScheduleOutcome> schedule(
    ReminderEntry entry, {
    String? zoneId,
  });

  Future<void> cancel(LumeRecordId id);

  Future<void> cancelAll();
}

class LumeLocalReminderScheduler implements LumeReminderScheduler {
  LumeLocalReminderScheduler([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    _initialized = true;
  }

  tz.TZDateTime? _next(
    tz.Location zone,
    int hour,
    int minute,
    ReminderRepeat repeat,
  ) {
    final tz.TZDateTime now = tz.TZDateTime.now(zone);
    tz.TZDateTime at = tz.TZDateTime(
      zone,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    return at;
  }

  @override
  Future<ReminderScheduleOutcome> schedule(
    ReminderEntry entry, {
    String? zoneId,
  }) async {
    final int id = lumeReminderNotificationId(entry.id);
    if (!entry.enabled) {
      await _plugin.cancel(id: id);
      return ReminderScheduleOutcome.cancelled;
    }
    if (zoneId == null) return ReminderScheduleOutcome.zoneUnresolved;
    await _ensureInit();
    final tz.Location zone;
    try {
      zone = tz.getLocation(zoneId);
    } on tz.LocationNotFoundException {
      return ReminderScheduleOutcome.zoneUnresolved;
    }
    final tz.TZDateTime? at = _next(
      zone,
      entry.atHour,
      entry.atMinute,
      entry.repeat,
    );
    if (at == null) return ReminderScheduleOutcome.failed;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: entry.label,
        body: entry.notes,
        scheduledDate: at,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            kReminderChannelId,
            'Reminders',
            channelDescription:
                'A reminder set in Lume, at the time chosen for it.',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: switch (entry.repeat) {
          ReminderRepeat.once => null,
          ReminderRepeat.daily => DateTimeComponents.time,
          ReminderRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
        },
      );
      return ReminderScheduleOutcome.scheduled;
    } on Object {
      return ReminderScheduleOutcome.failed;
    }
  }

  @override
  Future<void> cancel(LumeRecordId id) =>
      _plugin.cancel(id: lumeReminderNotificationId(id));

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}

/// Records every call instead of touching a platform, for tests.
class LumeFakeReminderScheduler implements LumeReminderScheduler {
  final Map<
    String,
    ({int atHour, int atMinute, ReminderRepeat repeat, String? zoneId})
  >
  scheduled =
      <
        String,
        ({int atHour, int atMinute, ReminderRepeat repeat, String? zoneId})
      >{};
  final List<String> cancelled = <String>[];
  bool cancelledAll = false;
  ReminderScheduleOutcome answer = ReminderScheduleOutcome.scheduled;

  @override
  Future<ReminderScheduleOutcome> schedule(
    ReminderEntry entry, {
    String? zoneId,
  }) async {
    if (!entry.enabled) {
      scheduled.remove(entry.id.value);
      cancelled.add(entry.id.value);
      return ReminderScheduleOutcome.cancelled;
    }
    if (zoneId == null) return ReminderScheduleOutcome.zoneUnresolved;
    if (answer == ReminderScheduleOutcome.scheduled) {
      scheduled[entry.id.value] = (
        atHour: entry.atHour,
        atMinute: entry.atMinute,
        repeat: entry.repeat,
        zoneId: zoneId,
      );
    }
    return answer;
  }

  @override
  Future<void> cancel(LumeRecordId id) async {
    scheduled.remove(id.value);
    cancelled.add(id.value);
  }

  @override
  Future<void> cancelAll() async {
    scheduled.clear();
    cancelledAll = true;
  }
}
