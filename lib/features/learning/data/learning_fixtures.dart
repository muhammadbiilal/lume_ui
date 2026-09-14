/// Learning & Growth's figures — `context.js` `learning()` and `tool-data.js`
/// `COURSES`, as the reference ships them.
///
/// **Fixture-only.** A week of minutes, a streak, three courses and a
/// consistency grid, none of it measured from anybody's learning. The frame
/// says so ("Stored on this device"), and Dayroz replaces this with the
/// reader's own courses and sessions.
library;

import '../../../core/fixtures/lume_reference_random.dart';

/// A course's tint — `course__icon--<tone>`.
enum LumeCourseTone { accent, violet, amber }

/// One course in progress.
class LumeCourse {
  const LumeCourse({
    required this.name,
    required this.provider,
    required this.progress,
    required this.minutes,
    required this.streak,
    required this.tone,
  });

  /// The course's own title — the reader's data, not interface copy, so it is
  /// shown as written rather than translated.
  final String name;
  final String provider;

  /// 0–1.
  final double progress;

  /// The length of a session.
  final int minutes;
  final int streak;
  final LumeCourseTone tone;
}

/// `learning()`.
class LumeLearningWeek {
  const LumeLearningWeek({
    required this.minutes,
    required this.streak,
    required this.goalShare,
    required this.milestoneMinutes,
    required this.week,
    required this.consistency,
    required this.courses,
  });

  final int minutes;
  final int streak;

  /// This week's minutes against the weekly goal, 0–1.
  final double goalShare;

  /// "Next milestone" — the reference writes it as the literal `200 min`.
  final int milestoneMinutes;

  /// Minutes a day, Monday first.
  final List<double> week;

  /// Thirty-five days of consistency, 0–3.
  final List<int> consistency;

  final List<LumeCourse> courses;

  /// The grid's one-sentence meaning: how many of its days had anything.
  int get activeDays => consistency.where((int l) => l > 0).length;
}

/// `COURSES`.
const List<LumeCourse> kReferenceCourses = <LumeCourse>[
  LumeCourse(
    name: 'Arabic — Level 2',
    provider: 'Self-paced',
    progress: 0.62,
    minutes: 25,
    streak: 9,
    tone: LumeCourseTone.accent,
  ),
  LumeCourse(
    name: 'Financial modelling',
    provider: 'Course library',
    progress: 0.34,
    minutes: 40,
    streak: 3,
    tone: LumeCourseTone.violet,
  ),
  LumeCourse(
    name: 'Photography basics',
    provider: 'Weekend series',
    progress: 0.88,
    minutes: 15,
    streak: 12,
    tone: LumeCourseTone.amber,
  ),
];

/// `learning()` — `heatDays(35, 6612, 0.32)` for the grid.
final LumeLearningWeek kReferenceLearningWeek = LumeLearningWeek(
  minutes: 185,
  streak: 9,
  goalShare: 0.74,
  milestoneMinutes: 200,
  week: const <double>[20, 35, 0, 40, 25, 35, 30],
  consistency: lumeHeatDays(35, 6612, 0.32),
  courses: kReferenceCourses,
);
