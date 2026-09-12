/// Today's day, as a deterministic fixture.
///
/// Every figure here was read off the running prototype at the pinned instant
/// with `measure_destinations.mjs --screen today`, not transcribed from its
/// markup. Where the two disagree the measurement wins, because the markup is
/// what the screen is *built* from and the measurement is what it *renders*.
///
/// This is not persistence. [LumeFakeTodayRepository.durable] is `false` and
/// ticking a task lives for as long as the process does.
library;

import 'dart:async';

import '../../../core/icons/lume_icons.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../home/domain/home_content.dart';
import '../../home/domain/home_model.dart';
import '../domain/today_model.dart';
import '../domain/today_repository.dart';

/// What the ring card and the tasks statistic say, in every state.
///
/// `today.screen.js` writes both as literals — the ring's sentence into static
/// markup and the statistic as `L.num(2) + '/' + L.num(5)` — and neither
/// follows the task list. Reproduced by decision (T1, T2): a reader outside
/// the Islamic experience has four tasks and still reads five, and ticking a
/// task moves neither figure.
///
/// **Dayroz obligation.** Both must be derived from the task store, so the
/// sentence above the list agrees with the list. Until then they are a
/// reference fixture reproducing a prototype's bug.
const int kReferenceTasksDone = 2;
const int kReferenceTaskCount = 5;
const int kReferenceMeetingsLeft = 1;

/// The five daily prayers for a city, in minutes past midnight.
typedef _Timetable = ({int fajr, int dhuhr, int asr, int maghrib, int isha});

/// Measured from the running prototype, city by city.
///
/// The reference computes these from a real solar calculation for the city,
/// the date and the method. Reproducing that algorithm belongs to the Prayer
/// tool at F6; until then the fixture carries what the calculation produced
/// for the cities the captures cover.
///
/// **A city that is not here gets no prayer rows at all**, rather than another
/// city's times. Showing a reader in Dubai the Islamabad timetable would be a
/// correctness failure in a religious feature, and an emptier agenda is the
/// honest answer to "this build cannot work it out" — the same rule
/// `LumeZoneDatabase.zoneFor` follows when it returns `null`.
const Map<String, _Timetable> _prayerByCity = <String, _Timetable>{
  // 7 September 2026, MWL. Measured: 4:20 · 12:07 · 3:41 pm · 6:27 pm · 7:47 pm
  'Islamabad': (
    fajr: 4 * 60 + 20,
    dhuhr: 12 * 60 + 7,
    asr: 15 * 60 + 41,
    maghrib: 18 * 60 + 27,
    isha: 19 * 60 + 47,
  ),
  // Measured: 4:21 · 1:00 pm · 4:36 pm · 7:35 pm · 9:28 pm
  'London': (
    fajr: 4 * 60 + 21,
    dhuhr: 13 * 60,
    asr: 16 * 60 + 36,
    maghrib: 19 * 60 + 35,
    isha: 21 * 60 + 28,
  ),
};

/// Sunset, which is Maghrib, for the markets the captures cover. Explore's
/// weather card reads it, and it comes from the same calculation as the
/// timetable above so the two cannot disagree.
const Map<String, int> _sunsetByCountry = <String, int>{
  'PK': 18 * 60 + 27,
  'GB': 19 * 60 + 35,
  'US': 19 * 60 + 20,
};

/// The sunset minute for a market, or `null` where this build cannot say.
int? lumeSunsetMinute(String countryCode) => _sunsetByCountry[countryCode];

/// The prayer timetable for a city, or `null` where this build cannot say.
LumePrayerTimetable? lumeTimetableFor(String city, DateTime day) {
  final _Timetable? t = _prayerByCity[city];
  if (t == null) return null;
  DateTime at(int minute) =>
      DateTime(day.year, day.month, day.day, minute ~/ 60, minute % 60);
  return LumePrayerTimetable(
    times: <LumePrayerTime>[
      LumePrayerTime(key: 'fajr', at: at(t.fajr)),
      LumePrayerTime(key: 'dhuhr', at: at(t.dhuhr)),
      LumePrayerTime(key: 'asr', at: at(t.asr)),
      LumePrayerTime(key: 'maghrib', at: at(t.maghrib)),
      LumePrayerTime(key: 'isha', at: at(t.isha)),
    ],
  );
}

/// The published loadshedding schedule, for a day.
///
/// The same five slots Home's fixture carries. The *area* is the reader's own
/// city, because that is what `toolCtx('loadshed').loadshed()` returns and
/// what Today and Explore both show — Home's Discover card says "Gulshan"
/// because its markup says so, which is part of C17 and not a second source.
LumeOutage lumeReferenceOutage(DateTime day, String area) {
  DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
  return LumeOutage(
    area: area,
    slots: <LumeOutageSlot>[
      LumeOutageSlot(from: at(6, 0), to: at(7, 0)),
      LumeOutageSlot(from: at(10, 0), to: at(11, 0)),
      LumeOutageSlot(from: at(14, 0), to: at(16, 0)),
      LumeOutageSlot(from: at(19, 0), to: at(20, 0)),
      LumeOutageSlot(from: at(23, 0), to: at(23, 59)),
    ],
  );
}

/// The three base agenda events, which the reference writes as literals.
///
/// Ids rather than copy: the titles and the "15 min · Video call" lines are
/// translated, where the reference leaves them English in every language.
const List<LumeAgendaEntry> _baseEvents = <LumeAgendaEntry>[
  LumeAgendaEntry(
    id: 'standup',
    minuteOfDay: 9 * 60 + 30,
    kind: LumeAgendaKind.event,
    target: null,
    done: true,
  ),
  LumeAgendaEntry(
    id: 'review',
    minuteOfDay: 14 * 60,
    kind: LumeAgendaKind.event,
    target: null,
    isNow: true,
  ),
  LumeAgendaEntry(
    id: 'groceries',
    minuteOfDay: 18 * 60 + 30,
    kind: LumeAgendaKind.errand,
    target: LumeHomeTarget.tool('shopping'),
  ),
];

/// The five tasks, in the order the reference lists them.
const List<LumeTodayTask> _tasks = <LumeTodayTask>[
  LumeTodayTask(
    id: 'electricity',
    minuteOfDay: 7 * 60,
    done: true,
    // `data-loc` in the reference: "Pay the K-Electric bill" in Pakistan,
    // "Pay the electricity bill" everywhere else.
    countryLabel: 'PK',
  ),
  LumeTodayTask(id: 'email', minuteOfDay: 10 * 60 + 15, done: true),
  LumeTodayTask(id: 'summary', minuteOfDay: 15 * 60, done: false),
  // `data-faith="islamic"`, and the only task with no clock time.
  LumeTodayTask(id: 'alKahf', minuteOfDay: null, done: false),
  LumeTodayTask(id: 'callHome', minuteOfDay: 21 * 60, done: false),
];

/// The four habits and their seven days, oldest first.
const List<LumeHabit> _habits = <LumeHabit>[
  LumeHabit(
    id: 'fajr',
    days: <bool>[true, true, true, false, true, true, true],
    streak: 6,
  ),
  LumeHabit(
    id: 'quran',
    days: <bool>[true, true, false, true, true, true, true],
    streak: 4,
  ),
  LumeHabit(
    id: 'steps',
    days: <bool>[true, true, false, true, true, false, true],
    streak: 2,
  ),
  LumeHabit(
    id: 'water',
    days: <bool>[true, false, true, true, false, true, false],
    streak: 1,
  ),
];

/// Which habits belong to the Islamic experience.
const Set<String> _faithHabits = <String>{'fajr', 'quran'};

/// Which tasks do.
const Set<String> _faithTasks = <String>{'alKahf'};

/// Composes the day. Pure, so the composition can be asserted without pumping
/// a frame.
abstract final class LumeTodayComposer {
  /// The agenda, merged and sorted.
  ///
  /// Base events, then the outage where the reader's market has one and the
  /// catalogue lets them see it, then the five prayers when the Islamic
  /// experience is on — and then one sort, because the reference sorts once
  /// over everything rather than appending in sections.
  static List<LumeAgendaEntry> agenda({
    required LumeUserContext user,
    required LumeEligibility eligibility,
    required DateTime now,
    LumeOutage? outage,
  }) {
    final List<LumeAgendaEntry> out = <LumeAgendaEntry>[..._baseEvents];

    if (outage != null && eligibility.visibleById('loadshed', user) != null) {
      final LumeOutageSlot? next = outage.nextAfter(now);
      if (next != null) {
        out.add(
          LumeAgendaEntry(
            id: 'outage',
            minuteOfDay: next.from.hour * 60 + next.from.minute,
            kind: LumeAgendaKind.outage,
            target: const LumeHomeTarget.tool('loadshed'),
            detail: outage.area,
          ),
        );
      }
    }

    if (user.islamic) {
      final LumePrayerTimetable? times = lumeTimetableFor(
        user.city,
        DateTime(now.year, now.month, now.day),
      );
      if (times != null) {
        for (final LumePrayerTime p in times.times) {
          out.add(
            LumeAgendaEntry(
              id: 'prayer.${p.key}',
              minuteOfDay: p.at.hour * 60 + p.at.minute,
              kind: LumeAgendaKind.prayer,
              target: const LumeHomeTarget.tool('prayer'),
              detail: p.key,
            ),
          );
        }
      }
    }

    out.sort(
      (LumeAgendaEntry a, LumeAgendaEntry b) =>
          a.minuteOfDay.compareTo(b.minuteOfDay),
    );
    return out;
  }

  /// The three statistics, faith-swapped in the first two.
  static List<LumeTodayStat> stats({
    required LumeUserContext user,
    required List<LumeTodayTask> tasks,
  }) => <LumeTodayStat>[
    if (user.islamic) ...<LumeTodayStat>[
      const LumeTodayStat(id: LumeTodayStatId.prayerStreak, value: 12),
      const LumeTodayStat(id: LumeTodayStatId.readToday, value: 18),
    ] else ...<LumeTodayStat>[
      const LumeTodayStat(id: LumeTodayStatId.dailyStreak, value: 12),
      const LumeTodayStat(id: LumeTodayStatId.steps, value: 4.2),
    ],
    // T2, reproduced by decision. `today.screen.js` pushes
    // `L.num(2) + '/' + L.num(5)` — two literals — and the figures do not
    // follow the list: a reader with four tasks still reads 2/5, and ticking
    // one does not move it. Carried as numbers rather than as a string so the
    // digits are still the reader's.
    const LumeTodayStat(
      id: LumeTodayStatId.tasksDone,
      value: kReferenceTasksDone,
      secondary: kReferenceTaskCount,
    ),
  ];

  /// The tasks this reader can see.
  static List<LumeTodayTask> tasksFor(LumeUserContext user) => <LumeTodayTask>[
    for (final LumeTodayTask t in _tasks)
      if (user.islamic || !_faithTasks.contains(t.id)) t,
  ];

  /// The habits this reader can see.
  static List<LumeHabit> habitsFor(LumeUserContext user) => <LumeHabit>[
    for (final LumeHabit h in _habits)
      if (user.islamic || !_faithHabits.contains(h.id)) h,
  ];

  /// The reflection card: an ayah, or a thought.
  static LumeReflection reflectionFor(LumeUserContext user) => user.islamic
      ? const LumeAyahReflection(
          arabic: 'أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ',
          translation:
              'Truly, it is in the remembrance of God that hearts find rest.',
          surah: 'Ar-Ra’d',
          chapter: 13,
          verse: 28,
        )
      : const LumeThoughtReflection(
          text:
              'Small things done consistently beat big things done '
              'occasionally.',
          attribution: 'On building habits',
        );

  /// The glyph an entry wears.
  static String iconFor(
    LumeAgendaEntry entry,
    LumeAgendaState state,
  ) => switch (entry.kind) {
    LumeAgendaKind.outage => LumeIcons.bolt,
    LumeAgendaKind.errand => LumeIcons.cart,
    LumeAgendaKind.prayer =>
      state == LumeAgendaState.done ? LumeIcons.checkCircle : LumeIcons.bell,
    LumeAgendaKind.event =>
      state == LumeAgendaState.now ? LumeIcons.clock : LumeIcons.checkCircle,
  };
}

/// The fixture repository.
class LumeFakeTodayRepository implements LumeTodayRepository {
  LumeFakeTodayRepository({
    required this.eligibility,
    this.outage,
    this.delay = Duration.zero,
    this.pending = false,
    this.fails = false,
  });

  /// A load that never returns, for the loading state.
  factory LumeFakeTodayRepository.slow({
    required LumeEligibility eligibility,
  }) => LumeFakeTodayRepository(eligibility: eligibility, pending: true);

  final LumeEligibility eligibility;

  /// The loadshedding schedule, where the market has one.
  final LumeOutage? outage;

  final Duration delay;
  final bool pending;

  /// A store that cannot answer. The reference has no such state; this exists
  /// because a real aggregate can fail and the screen must not pretend
  /// otherwise.
  final bool fails;

  /// Ticked tasks, for the life of the process and no longer.
  final Map<String, bool> _ticked = <String, bool>{};

  int loads = 0;

  /// A write lives for as long as the process does. Reported through every
  /// [LumeTodayDay] so nothing upstream can mistake it for persistence.
  bool get durable => false;

  @override
  Future<LumeTodayDay> load(
    LumeUserContext user, {
    required DateTime now,
  }) async {
    loads++;
    if (pending) return Completer<LumeTodayDay>().future;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (fails) throw StateError('today is unavailable');
    return LumeTodayDay(data: _compose(user, now), durable: durable);
  }

  @override
  Future<LumeTodayDay> setTaskDone(
    LumeUserContext user, {
    required DateTime now,
    required String taskId,
    required bool done,
  }) async {
    _ticked[taskId] = done;
    return LumeTodayDay(data: _compose(user, now), durable: durable);
  }

  LumeTodayData _compose(LumeUserContext user, DateTime now) {
    final int nowMinute = now.hour * 60 + now.minute;

    final List<LumeTodayTask> tasks = <LumeTodayTask>[
      for (final LumeTodayTask t in LumeTodayComposer.tasksFor(user))
        _ticked.containsKey(t.id)
            ? LumeTodayTask(
                id: t.id,
                minuteOfDay: t.minuteOfDay,
                done: _ticked[t.id]!,
                countryLabel: t.countryLabel,
              )
            : t,
    ];

    final List<LumeAgendaEntry> agenda = LumeTodayComposer.agenda(
      user: user,
      eligibility: eligibility,
      now: now,
      // The schedule is the market's; the area is the reader's own city.
      outage:
          outage ??
          (user.country == 'PK'
              ? lumeReferenceOutage(
                  DateTime(now.year, now.month, now.day),
                  user.city,
                )
              : null),
    );

    return LumeTodayData(
      header: LumeTodayHeader(
        date: now,
        // The reference's literal, for every day of the year (T4). A real
        // Hijri conversion is the Islamic Calendar tool's, at F6.
        hijri: user.islamic ? '15 Rabi’ al-Awwal' : null,
      ),
      progress: LumeDayProgress(
        minuteOfDay: nowMinute,
        // T1, reproduced by decision. The sentence is static markup in the
        // reference — "2 of 5 tasks done. One meeting left this afternoon." —
        // written once and never rewritten, so all three figures are the
        // reference's own rather than the day's.
        summary: const LumeDaySummary(
          tasksDone: kReferenceTasksDone,
          taskCount: kReferenceTaskCount,
          meetingsLeft: kReferenceMeetingsLeft,
        ),
      ),
      stats: LumeTodayComposer.stats(user: user, tasks: tasks),
      reflection: LumeTodayComposer.reflectionFor(user),
      agenda: agenda,
      tasks: tasks,
      habits: LumeTodayComposer.habitsFor(user),
      showPrivate: true,
    );
  }
}
