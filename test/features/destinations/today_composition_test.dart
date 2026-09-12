/// What Today puts on the screen, and in what order.
///
/// The composition is a pure function, so most of this needs no frame: the
/// agenda's merge and sort, the faith swap, the statistics and the ring's
/// arithmetic are all assertable from `LumeTodayComposer` directly. What does
/// need a frame is the order the sections render in and what a screen reader
/// is told, and those are at the end.
///
/// Every figure is the one measured off the running prototype at the pinned
/// instant — see `TODAY_EXPLORE_CONTRACT.md` §1.2.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_agenda.dart';
import 'package:lume/core/widgets/lume/lume_day.dart';
import 'package:lume/core/widgets/lume/lume_destination.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/today/data/today_fixtures.dart';
import 'package:lume/features/today/domain/today_model.dart';
import 'package:lume/features/today/domain/today_repository.dart';
import 'package:lume/features/today/presentation/today_art.dart';
import 'package:lume/features/today/presentation/today_screen.dart';

import '../../helpers/load_fonts.dart';
import 'destination_harness.dart';
import 'today_explore_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  group('the sections, in the order the source emits them', () {
    testWidgets('page head, ring, statistics, reflection, day, tasks, habits, '
        'private', (WidgetTester tester) async {
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );

      // The inventory summary claimed a separate prayer timeline between the
      // ring and the Ayah. There is none: the prayers are agenda rows, and a
      // statistics row sits where the summary put the timeline.
      const List<String> order = <String>[
        LumeTodayScreen.headKey,
        LumeTodayScreen.ringKey,
        LumeTodayScreen.statsKey,
        LumeTodayScreen.reflectionKey,
        LumeTodayScreen.agendaKey,
        LumeTodayScreen.tasksKey,
        LumeTodayScreen.habitsKey,
        LumeTodayScreen.privateKey,
      ];
      final List<double> tops = <double>[
        for (final String key in order)
          tester.getTopLeft(find.byKey(ValueKey<String>(key))).dy,
      ];
      for (int i = 1; i < tops.length; i++) {
        expect(
          tops[i],
          greaterThan(tops[i - 1]),
          reason: '${order[i]} is above ${order[i - 1]}',
        );
      }
    });
  });

  group('the ring', () {
    test('is the share of the day, rounded as a percentage', () {
      // 16:41 is 1,001 minutes of 1,440 — 69.5 %, which the reference rounds
      // to 70 and not to 69.
      const LumeDayProgress p = LumeDayProgress(
        minuteOfDay: 16 * 60 + 41,
        summary: LumeDaySummary(tasksDone: 2, taskCount: 5, meetingsLeft: 1),
      );
      expect(p.percent, 70);
      expect(p.fraction, closeTo(0.6951, 0.0001));
    });

    test('and is honest at both ends of the day', () {
      LumeDayProgress at(int m) => LumeDayProgress(
        minuteOfDay: m,
        summary: const LumeDaySummary(
          tasksDone: 0,
          taskCount: 0,
          meetingsLeft: 0,
        ),
      );
      expect(at(0).percent, 0);
      expect(at(720).percent, 50);
      expect(at(1439).percent, 100);
    });

    test('and its summary is the reference\'s literal, not the list', () async {
      // T1, reproduced by decision. `today.screen.js` writes "2 of 5 tasks
      // done. One meeting left this afternoon." into static markup and never
      // rewrites it — so the figures do not follow the list, and ticking a
      // task does not move them. Carried as three numbers so the sentence is
      // still translated and the digits are still the reader's.
      final LumeTodayData d = await composeToday(LumeUsers.muslimPk);
      expect(d.progress.summary.tasksDone, 2);
      expect(d.progress.summary.taskCount, 5);
      expect(d.progress.summary.meetingsLeft, 1);

      final LumeFakeTodayRepository repo = LumeFakeTodayRepository(
        eligibility: kEligibility,
      );
      await repo.load(LumeUsers.muslimPk, now: kPinned);
      final LumeTodayData after = (await repo.setTaskDone(
        LumeUsers.muslimPk,
        now: kPinned,
        taskId: 'summary',
        done: true,
      )).data;
      expect(after.progress.summary.tasksDone, 2);
      expect(
        after.tasks.firstWhere((LumeTodayTask t) => t.id == 'summary').done,
        isTrue,
        reason: 'the list moved even though the sentence above it did not',
      );
    });

    test('and the same figures reach a reader with a shorter list', () async {
      // Four tasks outside the Islamic experience, and still "2 of 5". This
      // is the defect, reproduced: the sentence contradicts the list under it.
      final LumeTodayData d = await composeToday(LumeUsers.defaultPk);
      expect(d.tasks.length, 4);
      expect(d.progress.summary.taskCount, 5);
      expect(
        d.stats
            .firstWhere((LumeTodayStat s) => s.id == LumeTodayStatId.tasksDone)
            .secondary,
        5,
      );
    });
  });

  group('the agenda', () {
    test(
      'merges prayers, the outage and the events, then sorts once',
      () async {
        final LumeTodayData d = await composeToday(LumeUsers.muslimPk);
        // Measured: 4:20 Fajr · 9:30 standup · 12:07 Dhuhr · 14:00 review ·
        // 15:41 Asr · 18:27 Maghrib · 18:30 groceries · 19:00 outage ·
        // 19:47 Isha.
        expect(d.agenda.map((LumeAgendaEntry e) => e.id).toList(), <String>[
          'prayer.fajr',
          'standup',
          'prayer.dhuhr',
          'review',
          'prayer.asr',
          'prayer.maghrib',
          'groceries',
          'outage',
          'prayer.isha',
        ]);
      },
    );

    test(
      'and is sorted by the minute, not by the section it came from',
      () async {
        final LumeTodayData d = await composeToday(LumeUsers.muslimPk);
        final List<int> minutes = d.agenda
            .map((LumeAgendaEntry e) => e.minuteOfDay)
            .toList();
        final List<int> sorted = <int>[...minutes]..sort();
        expect(minutes, sorted);
      },
    );

    test('drops the prayers outside the Islamic experience', () async {
      final LumeTodayData d = await composeToday(LumeUsers.defaultPk);
      expect(d.agenda.map((LumeAgendaEntry e) => e.id).toList(), <String>[
        'standup',
        'review',
        'groceries',
        'outage',
      ]);
    });

    test('and the outage outside its market', () async {
      final LumeTodayData d = await composeToday(LumeUsers.muslimGb);
      expect(
        d.agenda.where((LumeAgendaEntry e) => e.id == 'outage'),
        isEmpty,
        reason: 'Loadshedding is countries: [PK]',
      );
      // London's own timetable, measured: 4:21 · 13:00 · 16:36 · 19:35 · 21:28
      expect(
        d.agenda
            .where((LumeAgendaEntry e) => e.kind == LumeAgendaKind.prayer)
            .map((LumeAgendaEntry e) => e.minuteOfDay)
            .toList(),
        <int>[4 * 60 + 21, 13 * 60, 16 * 60 + 36, 19 * 60 + 35, 21 * 60 + 28],
      );
    });

    test(
      'and shows no prayers at all where this build cannot work them out',
      () async {
        // Rather than another city's times, which would be worse than none in a
        // religious feature.
        final LumeUserContext dubai = LumeUsers.muslimPk.copyWith(
          country: 'AE',
          city: 'Dubai',
        );
        final LumeTodayData d = await composeToday(dubai);
        expect(
          d.agenda.where(
            (LumeAgendaEntry e) => e.kind == LumeAgendaKind.prayer,
          ),
          isEmpty,
        );
        expect(lumeTimetableFor('Dubai', kPinned), isNull);
      },
    );

    group('and its states', () {
      test('the one marked now is now, whatever the clock says', () async {
        final LumeTodayData d = await composeToday(LumeUsers.muslimPk);
        final LumeAgendaEntry review = d.agenda.firstWhere(
          (LumeAgendaEntry e) => e.id == 'review',
        );
        expect(review.stateAt(16 * 60 + 41), LumeAgendaState.now);
        // Even hours later: the reference's `now` is data, not a comparison.
        expect(review.stateAt(23 * 60), LumeAgendaState.now);
      });

      test('a past entry is done, a future one is not', () async {
        final LumeTodayData d = await composeToday(LumeUsers.muslimPk);
        LumeAgendaState stateOf(String id) => d.agenda
            .firstWhere((LumeAgendaEntry e) => e.id == id)
            .stateAt(16 * 60 + 41);

        expect(stateOf('prayer.fajr'), LumeAgendaState.done);
        expect(stateOf('prayer.asr'), LumeAgendaState.done);
        expect(stateOf('prayer.maghrib'), LumeAgendaState.upcoming);
        expect(stateOf('outage'), LumeAgendaState.upcoming);
      });

      test('and one flagged done stays done before its time', () async {
        final LumeTodayData d = await composeToday(LumeUsers.muslimPk);
        final LumeAgendaEntry standup = d.agenda.firstWhere(
          (LumeAgendaEntry e) => e.id == 'standup',
        );
        expect(standup.stateAt(0), LumeAgendaState.done);
      });
    });

    testWidgets('a past prayer reads "Prayed" and a future one names the '
        'adhan', (WidgetTester tester) async {
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('Prayed'), findsWidgets);
      expect(find.text('Adhan · reminder on'), findsWidgets);
    });
  });

  group('the day rolls over', () {
    test('at one minute to midnight the day is nearly done', () async {
      final LumeTodayData d = await composeToday(
        LumeUsers.muslimPk,
        now: DateTime(2026, 9, 7, 23, 59),
      );
      expect(d.progress.percent, 100);
      // Every prayer has passed, so nothing is upcoming.
      expect(
        d.agenda.where(
          (LumeAgendaEntry e) =>
              e.kind == LumeAgendaKind.prayer &&
              e.stateAt(23 * 60 + 59) == LumeAgendaState.upcoming,
        ),
        isEmpty,
      );
    });

    test('and one minute later it is a new one', () async {
      final LumeTodayData d = await composeToday(
        LumeUsers.muslimPk,
        now: DateTime(2026, 9, 8, 0, 1),
      );
      expect(d.progress.percent, 0);
      expect(d.header.date.day, 8);
      // Every prayer is ahead again, and the outage is the first of the day.
      expect(
        d.agenda
            .where(
              (LumeAgendaEntry e) =>
                  e.kind == LumeAgendaKind.prayer &&
                  e.stateAt(1) == LumeAgendaState.upcoming,
            )
            .length,
        5,
      );
      expect(
        d.agenda
            .firstWhere((LumeAgendaEntry e) => e.id == 'outage')
            .minuteOfDay,
        6 * 60,
      );
    });
  });

  group('the faith swap', () {
    test('changes the first two statistics and nothing else', () async {
      final LumeTodayData muslim = await composeToday(LumeUsers.muslimPk);
      final LumeTodayData other = await composeToday(LumeUsers.defaultPk);

      expect(
        muslim.stats.map((LumeTodayStat s) => s.id).toList(),
        <LumeTodayStatId>[
          LumeTodayStatId.prayerStreak,
          LumeTodayStatId.readToday,
          LumeTodayStatId.tasksDone,
        ],
      );
      expect(
        other.stats.map((LumeTodayStat s) => s.id).toList(),
        <LumeTodayStatId>[
          LumeTodayStatId.dailyStreak,
          LumeTodayStatId.steps,
          LumeTodayStatId.tasksDone,
        ],
      );
    });

    test('swaps the reflection rather than hiding it', () async {
      expect(
        (await composeToday(LumeUsers.muslimPk)).reflection,
        isA<LumeAyahReflection>(),
      );
      expect(
        (await composeToday(LumeUsers.defaultPk)).reflection,
        isA<LumeThoughtReflection>(),
      );
    });

    test('and drops the two faith habits and the one faith task', () async {
      final LumeTodayData muslim = await composeToday(LumeUsers.muslimPk);
      final LumeTodayData other = await composeToday(LumeUsers.defaultPk);
      expect(muslim.habits.map((LumeHabit h) => h.id).toList(), <String>[
        'fajr',
        'quran',
        'steps',
        'water',
      ]);
      expect(other.habits.map((LumeHabit h) => h.id).toList(), <String>[
        'steps',
        'water',
      ]);
      expect(muslim.tasks.length, 5);
      expect(other.tasks.length, 4);
    });

    testWidgets('and the Arabic is carried, never translated', (
      WidgetTester tester,
    ) async {
      for (final Locale locale in <Locale>[
        const Locale('en'),
        const Locale('ur'),
        const Locale('ar'),
      ]) {
        await pumpToday(
          tester,
          LumeUsers.muslimPk,
          surface: const Size(390, 4000),
          locale: locale,
        );
        expect(
          find.text('أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ'),
          findsOneWidget,
          reason: '$locale',
        );
      }
    });
  });

  group('the tasks', () {
    testWidgets('name the market\'s own utility where it has one', (
      WidgetTester tester,
    ) async {
      await pumpToday(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('Pay the K-Electric bill'), findsOneWidget);

      await pumpToday(
        tester,
        LumeUsers.muslimGb,
        surface: const Size(390, 4000),
      );
      expect(find.text('Pay the electricity bill'), findsOneWidget);
      expect(find.text('Pay the K-Electric bill'), findsNothing);
    });

    testWidgets('and a tap reports the change rather than assuming it', (
      WidgetTester tester,
    ) async {
      final LumeRecordedDay actions = await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('today.task.summary')),
      );
      await tester.pump();
      expect(actions.toggled, <(String, bool)>[('summary', true)]);
    });

    test('and the write comes back through the repository', () async {
      final LumeFakeTodayRepository repo = LumeFakeTodayRepository(
        eligibility: kEligibility,
      );
      final LumeTodayDay before = await repo.load(
        LumeUsers.muslimPk,
        now: kPinned,
      );
      expect(
        before.data.tasks
            .firstWhere((LumeTodayTask t) => t.id == 'summary')
            .done,
        isFalse,
      );
      final LumeTodayDay after = await repo.setTaskDone(
        LumeUsers.muslimPk,
        now: kPinned,
        taskId: 'summary',
        done: true,
      );
      expect(
        after.data.tasks
            .firstWhere((LumeTodayTask t) => t.id == 'summary')
            .done,
        isTrue,
      );
      expect(
        after.durable,
        isFalse,
        reason: 'nothing here persists, and it says so',
      );
    });
  });

  group('the habits', () {
    test('carry seven days each, oldest first, today last', () async {
      final LumeTodayData d = await composeToday(LumeUsers.muslimPk);
      for (final LumeHabit h in d.habits) {
        expect(h.days, hasLength(LumeHabit.window), reason: h.id);
      }
      // Measured: Fajr on time is on for six of seven with a gap at index 3.
      final LumeHabit fajr = d.habits.firstWhere(
        (LumeHabit h) => h.id == 'fajr',
      );
      expect(fajr.days, <bool>[true, true, true, false, true, true, true]);
      expect(fajr.streak, 6);
    });

    testWidgets('and say what they mean out loud', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      // A row of coloured squares is readable by an eye and nothing else.
      expect(
        find.bySemanticsLabel(RegExp('Fajr on time, 6 of 7 days')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('the private card', () {
    testWidgets('names the areas and not one record', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );

      expect(find.byType(LumePrivateCard), findsOneWidget);
      expect(find.text('Health, documents & money'), findsOneWidget);

      // Section 62: nothing *behind* the lock may reach the summary. The card
      // names three areas and carries no record, no count, no value and no
      // date — and it takes no data at all, so there is nothing it could leak.
      //
      // Asserted as a shape rather than as a word list: the card renders
      // exactly two strings, its title and its sentence, so anything added to
      // it fails here.
      final Iterable<Text> inCard = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(LumePrivateCard),
          matching: find.byType(Text),
        ),
      );
      expect(inCard.map((Text t) => t.data).toList(), <String>[
        'Health, documents & money',
        'Records, medication and expenses stay locked until you open them.',
      ]);

      // And no sensitive tool's own data reaches the page under any name.
      final String tree = tester.binding.rootElement!
          .toStringDeep()
          .toLowerCase();
      for (final String leak in <String>[
        'vaccination',
        'health record',
        'passport',
        'cnic',
        'cycle',
        'pregnancy',
      ]) {
        expect(tree.contains(leak), isFalse, reason: leak);
      }
      handle.dispose();
    });
  });

  group('what a screen reader is told', () {
    testWidgets('every section title is a heading', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      for (final String title in <String>[
        'Ayah of the day',
        'Your day',
        'Tasks',
        'Habits',
        'Private',
      ]) {
        expect(
          tester.getSemantics(find.text(title)).flagsCollection.isHeader,
          isTrue,
          reason: title,
        );
      }
      handle.dispose();
    });

    testWidgets('the ring reads as a share of the day', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.bySemanticsLabel('70% of day'), findsOneWidget);
      expect(find.byType(LumeDayRing), findsOneWidget);
      handle.dispose();
    });

    testWidgets('and an agenda row carries its time, title and detail', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.byType(LumeAgendaRow), findsWidgets);
      // A row that goes somewhere carries the whole line. The reference's
      // review has nowhere to go, and a row with no destination is not a
      // control to land on.
      expect(
        find.bySemanticsLabel(RegExp(r'6:27\u202fpm|6:27 pm, Maghrib, Adhan')),
        findsWidgets,
      );
      handle.dispose();
    });
  });

  group('the sections carry their reference copy', () {
    testWidgets('the page head, the ring and the agenda subtitle', (
      WidgetTester tester,
    ) async {
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      // Measured: "Monday, 7 September · 15 Rabi’ al-Awwal".
      expect(
        find.text('Monday, 7 September · 15 Rabi’ al-Awwal'),
        findsOneWidget,
      );
      expect(find.text('You’re on track'), findsOneWidget);
      expect(
        find.text('2 of 5 tasks done. One meeting left this afternoon.'),
        findsOneWidget,
      );
      expect(find.text('Prayers and events, in order'), findsOneWidget);
      expect(find.byType(LumePageHead), findsOneWidget);
    });

    testWidgets('and the ring card carries the sparkle the reference draws', (
      WidgetTester tester,
    ) async {
      // `<span class="sticker sticker--slow" style="top:-12px;right:-6px">` —
      // decoration, so it hangs past two of the card's edges, takes no space,
      // takes no touch and says nothing out loud.
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      final Finder sticker = find.byType(LumeTodaySticker);
      expect(sticker, findsOneWidget);

      final Rect card = tester.getRect(find.byType(LumeRingCard));
      final Rect spark = tester.getRect(sticker);
      expect(spark.top - card.top, LumeRingCard.stickerTop);
      expect(spark.right - card.right, -LumeRingCard.stickerEnd);
      expect(spark.size, const Size(46, 46));
      expect(
        find.descendant(of: sticker, matching: find.byType(ExcludeSemantics)),
        findsNothing,
        reason: 'the exclusion wraps the sticker rather than sitting in it',
      );
    });

    testWidgets('and the ayah is cited twice, in the two forms the reference '
        'writes', (WidgetTester tester) async {
      // `today.screen.js` writes the citation once as the section subtitle —
      // `Ar-Ra’d · 13:28` — and once at the foot of the card, without the
      // dot. A single finished string can only be right in one of the two
      // places, which is why the reflection carries the surah, the chapter
      // and the verse rather than a sentence.
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('Ayah of the day'), findsOneWidget);
      expect(find.text('Ar-Ra’d · 13:28'), findsOneWidget);
      expect(find.text('Ar-Ra’d 13:28'), findsOneWidget);
    });

    testWidgets('and both forms survive a change of language', (
      WidgetTester tester,
    ) async {
      // The surah's name and the verse are carried, so they read the same in
      // every language; the *join* is a translated string, so a language that
      // separates a citation differently can. Both forms still exist, which
      // is the part a literal would have got wrong.
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 6000),
        locale: const Locale('ur'),
      );
      expect(find.text('Ar-Ra’d · 13:28'), findsOneWidget);
      expect(find.text('Ar-Ra’d 13:28'), findsOneWidget);
    });

    testWidgets('and the agenda subtitle swaps outside the Islamic '
        'experience', (WidgetTester tester) async {
      await pumpToday(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('Events and reminders, in order'), findsOneWidget);
      expect(find.text('Monday, 7 September'), findsOneWidget);
    });
  });
}
