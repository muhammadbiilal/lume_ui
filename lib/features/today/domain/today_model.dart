/// Everything Today draws, as data rather than as sentences.
///
/// The screen is a composition surface: it owns no records. A task, a habit, a
/// prayer and an outage all live somewhere else and Today arranges them into
/// one day. So every model here is a *view* of something — narrow enough that
/// a real source can fill it, wide enough that the screen never has to ask a
/// second question.
///
/// **Times are carried as minutes past midnight, never as formatted strings.**
/// The reference is explicit about why: *"a locale-formatted string cannot be
/// sorted or compared, and the agenda has to do both."* Formatting happens at
/// the last moment, in the reader's locale and clock.
library;

import 'package:flutter/foundation.dart';

import '../../home/domain/home_model.dart';

/// The page head: a title, the date beneath it, and the Hijri date when the
/// Islamic experience is on.
@immutable
class LumeTodayHeader {
  const LumeTodayHeader({required this.date, this.hijri});

  final DateTime date;

  /// Already-composed Hijri text, because converting the calendar is a
  /// feature and not a formatting rule. `null` outside the Islamic
  /// experience.
  final String? hijri;

  @override
  bool operator ==(Object other) =>
      other is LumeTodayHeader && other.date == date && other.hijri == hijri;

  @override
  int get hashCode => Object.hash(date, hijri);
}

/// The progress ring: how far through the day it is, and a line about it.
@immutable
class LumeDayProgress {
  const LumeDayProgress({required this.minuteOfDay, required this.summary});

  /// Minutes past local midnight, from the injected clock.
  final int minuteOfDay;

  /// What the card says under its title.
  final LumeDaySummary summary;

  /// 0–1. The reference divides by 1440 and rounds the *percentage*, so 16:41
  /// reads 70 % rather than 69 %.
  double get fraction => minuteOfDay / Duration.minutesPerDay;

  int get percent => (fraction * 100).round();

  @override
  bool operator ==(Object other) =>
      other is LumeDayProgress &&
      other.minuteOfDay == minuteOfDay &&
      other.summary == summary;

  @override
  int get hashCode => Object.hash(minuteOfDay, summary);
}

/// The numbers behind the ring card's sentence.
///
/// The reference writes that sentence into static markup — "2 of 5 tasks done.
/// One meeting left this afternoon." — in English, for every language, and
/// never rewrites it even when a task is ticked (T1). Carried as numbers here
/// so the sentence is a translated template and the two halves of the screen
/// cannot disagree.
@immutable
class LumeDaySummary {
  const LumeDaySummary({
    required this.tasksDone,
    required this.taskCount,
    required this.meetingsLeft,
  });

  final int tasksDone;
  final int taskCount;
  final int meetingsLeft;

  @override
  bool operator ==(Object other) =>
      other is LumeDaySummary &&
      other.tasksDone == tasksDone &&
      other.taskCount == taskCount &&
      other.meetingsLeft == meetingsLeft;

  @override
  int get hashCode => Object.hash(tasksDone, taskCount, meetingsLeft);
}

/// Which statistic a `.stat` card is showing.
///
/// A key rather than a label, because the row is faith-swapped: a Muslim
/// reader gets the prayer streak and minutes read, everyone else the daily
/// streak and steps, and both get the task count.
enum LumeTodayStatId { prayerStreak, readToday, dailyStreak, steps, tasksDone }

/// One `.stat` card: a glyph, a number with a unit, a label.
@immutable
class LumeTodayStat {
  const LumeTodayStat({required this.id, required this.value, this.secondary});

  final LumeTodayStatId id;

  /// The figure. `4.2` for the steps card, which the reference renders as
  /// "4.2 k" — the number and its unit are separate so the unit can be
  /// translated and the number localised.
  final num value;

  /// The denominator, where the statistic is a ratio: `5` of "2/5".
  final num? secondary;

  @override
  bool operator ==(Object other) =>
      other is LumeTodayStat &&
      other.id == id &&
      other.value == value &&
      other.secondary == secondary;

  @override
  int get hashCode => Object.hash(id, value, secondary);
}

/// The reflection card — an ayah for a Muslim reader, a thought for everyone
/// else. One section in two forms, which is the only faith-*swapped* pair on
/// any destination.
sealed class LumeReflection {
  const LumeReflection();
}

/// Ayah of the day: Arabic, a translation, and the reference it came from.
final class LumeAyahReflection extends LumeReflection {
  const LumeAyahReflection({
    required this.arabic,
    required this.translation,
    required this.surah,
    required this.chapter,
    required this.verse,
  });

  /// Scripture, not interface copy: it is carried, never translated.
  final String arabic;

  final String translation;

  /// The surah's name as the edition writes it — "Ar-Ra’d".
  final String surah;

  /// Chapter and verse, as numbers.
  ///
  /// **Not a preassembled "Ar-Ra’d 13:28".** The screen writes the reference
  /// twice — the section subtitle joins the two with a dot and the card's
  /// attribution does not — so a single finished string could only be right
  /// in one of the two places. Carrying the parts also lets the digits follow
  /// the reader's numerals, which a literal never could.
  final int chapter;
  final int verse;
}

/// Today's thought: a line and who it is about.
final class LumeThoughtReflection extends LumeReflection {
  const LumeThoughtReflection({required this.text, required this.attribution});

  final String text;
  final String attribution;
}

/// Where an agenda entry sits relative to now.
enum LumeAgendaState {
  /// Already happened, or explicitly marked done.
  done,

  /// The one thing happening at the moment. The reference marks exactly one
  /// entry, from the data rather than from the clock.
  now,

  /// Still to come.
  upcoming,
}

/// What kind of thing an agenda entry is, which decides its glyph and its copy.
enum LumeAgendaKind { event, prayer, outage, errand }

/// One row of the day, before it is sorted.
@immutable
class LumeAgendaEntry {
  const LumeAgendaEntry({
    required this.id,
    required this.minuteOfDay,
    required this.kind,
    required this.target,
    this.done = false,
    this.isNow = false,
    this.detail,
  });

  final String id;

  /// Minutes past local midnight. The sort key, and the only time this
  /// carries.
  final int minuteOfDay;

  final LumeAgendaKind kind;

  /// Where tapping it goes. `null` for an entry with nowhere to go — the
  /// reference toasts its own title there.
  final LumeHomeTarget? target;

  /// Explicitly finished, whatever the clock says.
  final bool done;

  /// The reference's `now: true`. Exactly one entry carries it.
  final bool isNow;

  /// A value the copy needs: the prayer's key, the outage's area and length.
  final String? detail;

  /// Where this sits at [nowMinute].
  ///
  /// `is-done` where the entry says so *or* the time has passed and it is not
  /// the `now` entry — the reference's rule, kept whole.
  LumeAgendaState stateAt(int nowMinute) {
    if (isNow) return LumeAgendaState.now;
    if (done || minuteOfDay < nowMinute) return LumeAgendaState.done;
    return LumeAgendaState.upcoming;
  }

  @override
  bool operator ==(Object other) =>
      other is LumeAgendaEntry &&
      other.id == id &&
      other.minuteOfDay == minuteOfDay &&
      other.kind == kind &&
      other.target == target &&
      other.done == done &&
      other.isNow == isNow &&
      other.detail == detail;

  @override
  int get hashCode =>
      Object.hash(id, minuteOfDay, kind, target, done, isNow, detail);
}

/// One row of the task list.
@immutable
class LumeTodayTask {
  const LumeTodayTask({
    required this.id,
    required this.minuteOfDay,
    required this.done,
    this.countryLabel,
  });

  final String id;

  /// `null` where the task has no clock time — the reference's "Evening".
  final int? minuteOfDay;

  final bool done;

  /// A market whose label differs: the electricity bill is "K-Electric" in
  /// Pakistan and plain everywhere else (`data-loc` in the reference).
  final String? countryLabel;

  LumeTodayTask toggled() => LumeTodayTask(
    id: id,
    minuteOfDay: minuteOfDay,
    done: !done,
    countryLabel: countryLabel,
  );

  @override
  bool operator ==(Object other) =>
      other is LumeTodayTask &&
      other.id == id &&
      other.minuteOfDay == minuteOfDay &&
      other.done == done &&
      other.countryLabel == countryLabel;

  @override
  int get hashCode => Object.hash(id, minuteOfDay, done, countryLabel);
}

/// One habit and its last seven days.
@immutable
class LumeHabit {
  const LumeHabit({required this.id, required this.days, required this.streak});

  final String id;

  /// Seven booleans, oldest first. The last is today.
  final List<bool> days;

  final int streak;

  static const int window = 7;

  @override
  bool operator ==(Object other) =>
      other is LumeHabit &&
      other.id == id &&
      other.streak == streak &&
      listEquals(other.days, days);

  @override
  int get hashCode => Object.hash(id, streak, Object.hashAll(days));
}

/// Everything Today draws.
///
/// No per-section feed, unlike Home: the reference's Today has no repository,
/// no fetch and no failure path, so inventing partial states would be
/// inventing behaviour. What it does have is a composition that varies by
/// faith, by country and by eligibility, and that is what this carries.
@immutable
class LumeTodayData {
  const LumeTodayData({
    required this.header,
    required this.progress,
    required this.stats,
    required this.reflection,
    required this.agenda,
    required this.tasks,
    required this.habits,
    required this.showPrivate,
  });

  final LumeTodayHeader header;
  final LumeDayProgress progress;
  final List<LumeTodayStat> stats;
  final LumeReflection reflection;

  /// Already sorted by [LumeAgendaEntry.minuteOfDay].
  final List<LumeAgendaEntry> agenda;

  final List<LumeTodayTask> tasks;
  final List<LumeHabit> habits;

  /// §61: sensitive features stay one deliberate tap away. The reference
  /// always draws the card; this carries the decision so a market that
  /// genuinely has nothing private can drop it.
  final bool showPrivate;

  LumeTodayData withTasks(List<LumeTodayTask> next) => LumeTodayData(
    header: header,
    progress: progress,
    stats: stats,
    reflection: reflection,
    agenda: agenda,
    tasks: next,
    habits: habits,
    showPrivate: showPrivate,
  );

  @override
  bool operator ==(Object other) =>
      other is LumeTodayData &&
      other.header == header &&
      other.progress == progress &&
      other.reflection == reflection &&
      other.showPrivate == showPrivate &&
      listEquals(other.stats, stats) &&
      listEquals(other.agenda, agenda) &&
      listEquals(other.tasks, tasks) &&
      listEquals(other.habits, habits);

  @override
  int get hashCode => Object.hash(
    header,
    progress,
    reflection,
    showPrivate,
    Object.hashAll(stats),
    Object.hashAll(agenda),
    Object.hashAll(tasks),
    Object.hashAll(habits),
  );
}
