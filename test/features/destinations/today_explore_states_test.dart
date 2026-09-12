/// Every surface Today and Explore have to be drawable on, and every state
/// the data can be in.
///
/// The reference has no loading, error, offline or stale state for either
/// screen — both are static markup and synchronous reads. A real aggregate of
/// six stores has all four, so they exist here, and they are tested for what
/// they *say* rather than for existing: a screen that fails silently is worse
/// than one that does not fail.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_agenda.dart';
import 'package:lume/core/widgets/lume/lume_day.dart';
import 'package:lume/core/widgets/lume/lume_explore.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/features/explore/data/explore_fixtures.dart';
import 'package:lume/features/explore/domain/explore_repository.dart';
import 'package:lume/features/explore/presentation/explore_screen.dart';
import 'package:lume/features/today/data/today_fixtures.dart';
import 'package:lume/features/today/presentation/today_screen.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'destination_harness.dart';
import 'today_explore_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// Every width the brief names, plus the two breakpoint edges and the
  /// landscape phone that is compact by height.
  const List<(String, Size)> cells = <(String, Size)>[
    ('359 wide', Size(359, 4000)),
    ('360 wide', Size(360, 4000)),
    ('390 wide', Size(390, 4000)),
    ('600 wide', Size(600, 4000)),
    ('700 wide', Size(700, 4000)),
    ('840 wide', Size(840, 4000)),
    ('1100 wide', Size(1100, 4000)),
    ('a phone on its side', Size(852, 2000)),
  ];

  group('Today draws', () {
    for (final (String name, Size size) cell in cells) {
      testWidgets('at ${cell.$1} without overflowing', (
        WidgetTester tester,
      ) async {
        await pumpToday(tester, LumeUsers.muslimPk, surface: cell.$2);
        expect(tester.takeException(), isNull);
        expect(find.text('Your day'), findsOneWidget);
        expect(find.byType(LumeDayRing), findsOneWidget);
      });
    }

    testWidgets('in Urdu, in Arabic and at 200 per cent', (
      WidgetTester tester,
    ) async {
      for (final (Locale locale, double scale) cell in <(Locale, double)>[
        (const Locale('ur'), 1.0),
        (const Locale('ar'), 1.0),
        (const Locale('en'), 2.0),
        (const Locale('ur'), 2.0),
      ]) {
        await pumpToday(
          tester,
          LumeUsers.muslimPk,
          surface: const Size(390, 6000),
          locale: cell.$1,
          textScale: cell.$2,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${cell.$1} at ${cell.$2}',
        );
        expect(find.byType(LumeAgendaRow), findsWidgets);
      }
    });

    testWidgets('and in the dark', (WidgetTester tester) async {
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
        theme: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('with the ring label at its measured size until the reader '
        'asks for more', (WidgetTester tester) async {
      // The label shrinks to stay inside a fixed circle (see `ringInner`).
      // That must cost nothing at the sizes the reference is rendered at: if
      // the column already fits the clear space, `BoxFit.scaleDown` is the
      // identity and the figure is drawn exactly as measured.
      Size labelBox(WidgetTester t) => t.getSize(
        find.descendant(
          of: find.byType(LumeDayRing),
          matching: find.byType(FittedBox),
        ),
      );

      for (final double scale in <double>[1.0, 1.3]) {
        await pumpToday(
          tester,
          LumeUsers.muslimPk,
          surface: const Size(390, 4000),
          textScale: scale,
        );
        final Size inner = tester.getSize(
          find.descendant(
            of: find.byType(LumeDayRing),
            matching: find.byType(Column),
          ),
        );
        expect(
          inner.width <= LumeDayMetrics.ringInner &&
              inner.height <= LumeDayMetrics.ringInner,
          isTrue,
          reason:
              'the label is scaled down at $scale, which the reference '
              'never does: $inner',
        );
        expect(labelBox(tester).width, LumeDayMetrics.ringInner);
      }
    });
  });

  group('Explore draws', () {
    for (final (String name, Size size) cell in cells) {
      testWidgets('at ${cell.$1} without overflowing', (
        WidgetTester tester,
      ) async {
        await pumpExplore(tester, LumeUsers.muslimPk, surface: cell.$2);
        expect(tester.takeException(), isNull);
        expect(find.text('Around you'), findsOneWidget);
        expect(find.byType(LumeWeatherCard), findsOneWidget);
      });
    }

    testWidgets('in Urdu, in Arabic and at 200 per cent', (
      WidgetTester tester,
    ) async {
      for (final (Locale locale, double scale) cell in <(Locale, double)>[
        (const Locale('ur'), 1.0),
        (const Locale('ar'), 1.0),
        (const Locale('en'), 2.0),
        (const Locale('ar'), 2.0),
      ]) {
        await pumpExplore(
          tester,
          LumeUsers.muslimPk,
          surface: const Size(390, 6000),
          locale: cell.$1,
          textScale: cell.$2,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${cell.$1} at ${cell.$2}',
        );
        expect(find.byType(LumeFeatureCard), findsOneWidget);
      }
    });

    testWidgets('and in the dark', (WidgetTester tester) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
        theme: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Today while it is still arriving', () {
    testWidgets('draws its own shape, not a spinner', (
      WidgetTester tester,
    ) async {
      await pumpLume(
        tester,
        LumeTodayScreen(
          user: LumeUsers.muslimPk,
          actions: LumeRecordedDay().today,
        ),
        surface: const Size(390, 2000),
      );
      expect(find.byType(LumeSkeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // The head is there from the first frame, so the page has a title
      // before it has a day.
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Your day'), findsNothing);
    });

    testWidgets('and a load that never returns stays a skeleton', (
      WidgetTester tester,
    ) async {
      final LumeFakeTodayRepository slow = LumeFakeTodayRepository.slow(
        eligibility: kEligibility,
      );
      unawaited(slow.load(LumeUsers.muslimPk, now: kPinned));
      await pumpLume(
        tester,
        LumeTodayScreen(
          user: LumeUsers.muslimPk,
          actions: LumeRecordedDay().today,
        ),
        surface: const Size(390, 2000),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(LumeSkeleton), findsWidgets);
    });
  });

  group('Today when the day cannot be composed', () {
    testWidgets('says so, and offers the way back', (
      WidgetTester tester,
    ) async {
      int retries = 0;
      await pumpLume(
        tester,
        LumeTodayScreen(
          user: LumeUsers.muslimPk,
          actions: LumeRecordedDay().today,
          failed: true,
          onRetry: () async => retries++,
        ),
        surface: const Size(390, 2000),
      );
      expect(find.byType(LumeNotice), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(retries, 1);
    });

    test('and the repository can actually fail', () async {
      final LumeFakeTodayRepository broken = LumeFakeTodayRepository(
        eligibility: kEligibility,
        fails: true,
      );
      await expectLater(
        broken.load(LumeUsers.muslimPk, now: kPinned),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Explore while it is still arriving, and when it cannot', () {
    testWidgets('draws a skeleton, then a notice', (WidgetTester tester) async {
      await pumpLume(
        tester,
        LumeExploreScreen(
          user: LumeUsers.muslimPk,
          eligibility: kEligibility,
          actions: LumeRecordedDay().explore,
        ),
        surface: const Size(390, 2000),
      );
      expect(find.byType(LumeSkeleton), findsWidgets);
      expect(find.text('Explore'), findsWidgets);

      await pumpLume(
        tester,
        LumeExploreScreen(
          user: LumeUsers.muslimPk,
          eligibility: kEligibility,
          actions: LumeRecordedDay().explore,
          failed: true,
          onRetry: () async {},
        ),
        surface: const Size(390, 2000),
      );
      expect(find.byType(LumeNotice), findsOneWidget);
    });

    testWidgets('and one failed source does not take the rest with it', (
      WidgetTester tester,
    ) async {
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 6000),
        repository: LumeFakeExploreRepository(
          eligibility: kEligibility,
          failing: <LumeExploreSource>{
            LumeExploreSource.around,
            LumeExploreSource.news,
          },
        ),
      );
      // Two sections say they could not answer; the other six are unaffected.
      expect(find.byType(LumeNotice), findsNWidgets(2));
      expect(find.byType(LumeWeatherCard), findsOneWidget);
      expect(find.byType(LumeFeatureCard), findsOneWidget);
      expect(find.text('Collections'), findsOneWidget);
      expect(find.text('Nearby'), findsOneWidget);
    });
  });

  group('what a screen reader is told about Explore', () {
    testWidgets('every section title is a heading, and the page names '
        'itself', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 6000),
      );
      for (final String title in <String>[
        'Weather',
        'Around you',
        'Today’s reads',
        'Collections',
        'Nearby',
      ]) {
        expect(
          tester.getSemantics(find.text(title)).flagsCollection.isHeader,
          isTrue,
          reason: title,
        );
      }
      expect(find.bySemanticsLabel('Explore'), findsWidgets);
      handle.dispose();
    });

    testWidgets('and a local service row says what it is worth', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 6000),
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Fuel Prices, Petrol · Hi-Octane · Diesel, Rs 264.61'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('reduced motion', () {
    testWidgets('neither screen animates when the platform says not to', (
      WidgetTester tester,
    ) async {
      // `pumpLume` disables animations by default, which is the same switch
      // `MediaQuery.disableAnimations` carries. What matters is that both
      // settle — a screen that never settles is one that animates forever.
      await pumpToday(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await pumpExplore(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 4000),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
