/// The edge of Stage 1: what the fixtures are allowed to be, and what they
/// must never be mistaken for.
///
/// Three of Today and Explore's values are the reference's own literals,
/// reproduced by decision — Nearby's Karachi venues (C22), the weather's
/// "updated 4 min ago" (C24) and Today's task totals (C23). Reproducing a
/// defect is a decision that was taken; letting it look like working software
/// is not. So each one is held to the same three rules:
///
/// * it arrives through the repository contract, not from a widget literal;
/// * it never claims to be live, or cached, or saved;
/// * the shape that replaces it at Dayroz is already in place, so the
///   substitution is a change of source rather than a change of screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/explore/data/explore_fixtures.dart';
import 'package:lume/features/explore/domain/explore_repository.dart';
import 'package:lume/features/today/data/today_fixtures.dart';
import 'package:lume/features/today/domain/today_model.dart';
import 'package:lume/features/today/domain/today_repository.dart';

import '../../helpers/load_fonts.dart';
import 'destination_harness.dart';
import 'today_explore_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  group('nothing Explore shows is labelled live', () {
    test('every source reports itself a fixture, in every market', () async {
      for (final LumeUserContext user in LumeUsers.all.values) {
        final LumeExploreSnapshot s = await composeExplore(user);
        for (final LumeExploreSource source in LumeExploreSource.values) {
          expect(
            s.of(source),
            LumeSourceFreshness.fixture,
            reason: '${user.country} · ${source.name}',
          );
        }
      }
    });

    test('and no snapshot can reach live or cached from here', () async {
      // The two values a fixture must never produce. A repository that begins
      // returning them is a repository that has started fetching, and this is
      // the test that has to be deleted deliberately when it does.
      final LumeExploreSnapshot s = await composeExplore(LumeUsers.muslimPk);
      expect(s.freshness.values, everyElement(isNot(LumeSourceFreshness.live)));
      expect(
        s.freshness.values,
        everyElement(isNot(LumeSourceFreshness.cached)),
      );
    });
  });

  group('Nearby is a source, not a decoration', () {
    test('it has a source of its own that can fail', () async {
      final LumeExploreSnapshot s = await composeExplore(
        LumeUsers.muslimPk,
        repository: LumeFakeExploreRepository(
          eligibility: kEligibility,
          failing: const <LumeExploreSource>{LumeExploreSource.nearby},
        ),
      );
      expect(s.of(LumeExploreSource.nearby), LumeSourceFreshness.unavailable);
      expect(s.data.nearby, isEmpty);
    });

    testWidgets('and when it cannot answer the section says so rather than '
        'naming a city the reader is not in', (WidgetTester tester) async {
      // The reference has no such state — its three rows are static markup
      // (C22). This is the shape Dayroz needs: a places source that cannot
      // locate the reader must be able to say nothing rather than fall back
      // to Karachi.
      await pumpExplore(
        tester,
        LumeUsers.muslimGb,
        surface: const Size(390, 6000),
        repository: LumeFakeExploreRepository(
          eligibility: kEligibility,
          failing: const <LumeExploreSource>{LumeExploreSource.nearby},
        ),
      );
      expect(find.text('Nearby'), findsOneWidget);
      expect(find.byType(LumeNotice), findsOneWidget);
      expect(find.text('Masjid-e-Tooba'), findsNothing);
    });

    testWidgets('and while it can, it reproduces Lume exactly — everywhere', (
      WidgetTester tester,
    ) async {
      // The decision, asserted so it cannot drift into a quiet repair. A
      // reader in London is told a Karachi mosque is 650 m away.
      await pumpExplore(
        tester,
        LumeUsers.muslimGb,
        surface: const Size(390, 6000),
      );
      expect(find.text('Masjid-e-Tooba'), findsOneWidget);
      expect(find.text('650 m'), findsOneWidget);
    });
  });

  group('the weather’s age is computed, not written down', () {
    test('the reading is pinned four minutes before the clock', () async {
      final LumeExploreSnapshot s = await composeExplore(LumeUsers.muslimPk);
      expect(
        s.data.weather!.observedAt,
        kPinned.subtract(const Duration(minutes: kReferenceWeatherAgeMinutes)),
      );
    });

    testWidgets('and a later clock reads a larger age, with no change to the '
        'screen', (WidgetTester tester) async {
      // The proof that the sentence is not a literal: the same snapshot, read
      // at a later moment, says something else. Dayroz supplies a real
      // observation time and this keeps working.
      final LumeExploreSnapshot s = await composeExplore(LumeUsers.muslimPk);
      expect(s.data.weather!.minutesAgoAt(kPinned), 4);
      expect(
        s.data.weather!.minutesAgoAt(kPinned.add(const Duration(minutes: 20))),
        24,
      );
      // Never negative: a reading from the future is a bug upstream, not a
      // sentence about the future.
      expect(
        s.data.weather!.minutesAgoAt(
          kPinned.subtract(const Duration(hours: 1)),
        ),
        0,
      );

      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      expect(find.text('Islamabad · updated 4 min ago'), findsOneWidget);
    });
  });

  group('Today’s writes are not storage', () {
    test('the day says so, and so does the day after a write', () async {
      final LumeFakeTodayRepository repo = LumeFakeTodayRepository(
        eligibility: kEligibility,
      );
      final LumeTodayDay loaded = await repo.load(
        LumeUsers.muslimPk,
        now: kPinned,
      );
      expect(loaded.durable, isFalse);

      final LumeTodayDay written = await repo.setTaskDone(
        LumeUsers.muslimPk,
        now: kPinned,
        taskId: 'summary',
        done: true,
      );
      expect(written.durable, isFalse);
      expect(
        written.data.tasks
            .firstWhere((LumeTodayTask t) => t.id == 'summary')
            .done,
        isTrue,
      );
    });

    test('and a second repository has never heard of the write', () async {
      // What "not durable" means, stated as a fact rather than as a flag: the
      // tick lives in one object for as long as that object does.
      final LumeFakeTodayRepository first = LumeFakeTodayRepository(
        eligibility: kEligibility,
      );
      await first.setTaskDone(
        LumeUsers.muslimPk,
        now: kPinned,
        taskId: 'summary',
        done: true,
      );
      final LumeTodayDay fresh = await LumeFakeTodayRepository(
        eligibility: kEligibility,
      ).load(LumeUsers.muslimPk, now: kPinned);
      expect(
        fresh.data.tasks
            .firstWhere((LumeTodayTask t) => t.id == 'summary')
            .done,
        isFalse,
        reason: 'the tick lived in the first repository and died with it',
      );
    });
  });

  group('Today’s totals are the reference’s, and are kept where they show', () {
    test('they live in the fixture, not in a widget', () async {
      // Named constants in `today_fixtures.dart`, so the one place to change
      // at Dayroz is the one place they are written.
      expect(kReferenceTasksDone, 2);
      expect(kReferenceTaskCount, 5);
      expect(kReferenceMeetingsLeft, 1);

      final LumeTodayData d = await composeToday(LumeUsers.muslimPk);
      expect(d.progress.summary.tasksDone, kReferenceTasksDone);
      expect(d.progress.summary.taskCount, kReferenceTaskCount);
      expect(d.progress.summary.meetingsLeft, kReferenceMeetingsLeft);
    });

    test('and they do not follow the list, in any market', () async {
      // The defect, reproduced: four tasks and still "of 5". Dayroz must
      // derive all three from one eligible task query so this cannot happen.
      for (final LumeUserContext user in LumeUsers.all.values) {
        final LumeTodayData d = await composeToday(user);
        expect(
          d.progress.summary.taskCount,
          kReferenceTaskCount,
          reason: user.country,
        );
        expect(
          d.stats
              .firstWhere(
                (LumeTodayStat s) => s.id == LumeTodayStatId.tasksDone,
              )
              .secondary,
          kReferenceTaskCount,
          reason: user.country,
        );
      }
    });
  });
}
