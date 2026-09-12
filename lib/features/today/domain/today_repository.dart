/// Where Today's day comes from.
///
/// **Today is a composition surface, not a second database.** Nothing here
/// owns a task, a habit or a prayer time; it asks for the day's *view* of
/// records that live in their own tools, and arranges them.
///
/// That shape is the whole point of the contract. A real implementation
/// aggregates what the user already has:
///
/// | Today shows | Dayroz source |
/// |---|---|
/// | agenda events | Calendar events, reminders and alarms due today |
/// | agenda prayers | the prayer schedule for the user's city and method |
/// | agenda outage | the loadshedding schedule for their area |
/// | tasks | the to-do list, filtered to today |
/// | habits | the habit tracker's last seven days |
/// | the ring's summary | counted from the same tasks and events |
/// | statistics | the streak, the reading log, the step count |
/// | the private card | nothing — it is a door, and it must stay one |
///
/// Water goals, medication schedules, fasting context, and bills or
/// subscriptions falling due are all *candidates* for the agenda on the same
/// terms: eligible, time-stamped, and belonging to today. None of them is
/// invented here.
///
/// The implementation in this repository is a deterministic fixture that
/// reproduces the prototype. It is not persistence, it is not a cache, and
/// ticking a task in it survives nothing.
library;

import '../../catalogue/domain/eligibility.dart';
import 'today_model.dart';

/// The contract. Dayroz implements it; this repository ships only doubles.
abstract interface class LumeTodayRepository {
  /// The day, for this reader, at this instant.
  ///
  /// Asynchronous because a real one reads several stores. [now] is injected
  /// rather than read, so a fixture, a golden and a test all see the same day.
  Future<LumeTodayDay> load(LumeUserContext user, {required DateTime now});

  /// Record a task's new state.
  ///
  /// Returns the day as it stands afterwards, so the caller never has to
  /// guess what the store did with the write. A fixture that does not persist
  /// says so through [LumeTodayDay.durable].
  Future<LumeTodayDay> setTaskDone(
    LumeUserContext user, {
    required DateTime now,
    required String taskId,
    required bool done,
  });
}

/// What the repository hands back.
class LumeTodayDay {
  const LumeTodayDay({required this.data, required this.durable});

  final LumeTodayData data;

  /// Whether a write survives a restart.
  ///
  /// `false` for every implementation here. Nothing may report task
  /// completion as working while this is `false` — the same honesty rule
  /// `LumeProfileRepository.isDurable` carries.
  final bool durable;
}
