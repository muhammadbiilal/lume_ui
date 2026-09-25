/// Daily Streak on screen: first use, checking in today, the streak
/// updating, and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/streak/presentation/streak_tool.dart';

import '../../helpers/load_fonts.dart';
import 'streak_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumeStreakTool.summaryKey));

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('nothing checked in, the summary shows a real zero', (WidgetTester t) async {
      final StreakWorld w = StreakWorld();
      await pumpStreak(t, w);
      final LumeSummaryCard s = summary(t);
      expect(s.value, '0');
      expect(w.repo.view().checkIns, isEmpty);
      expect(find.byKey(LumeStreakTool.checkInKey), findsOneWidget);
      w.dispose();
    });
  });

  group('checking in today', () {
    testWidgets('toggling the row logs today and the summary updates', (WidgetTester t) async {
      final StreakWorld w = StreakWorld();
      await pumpStreak(t, w);
      expect(summary(t).value, '0');

      await tapShown(t, find.bySemanticsLabel('Checked in today, Today'));

      expect(w.repo.view().checkIns, hasLength(1));
      expect(w.repo.view().checkIns.single.date, kToday);
      expect(summary(t).value, '1');
      w.dispose();
    });

    testWidgets('a streak already running keeps counting once today is added', (
      WidgetTester t,
    ) async {
      final StreakWorld w = StreakWorld();
      w.checkIn(kToday.addDays(-2));
      w.checkIn(kToday.addDays(-1));
      await pumpStreak(t, w);
      expect(summary(t).value, '2');

      await tapShown(t, find.bySemanticsLabel('Checked in today, Today'));

      expect(summary(t).value, '3');
      w.dispose();
    });

    testWidgets('toggling it off again removes today, with Undo', (WidgetTester t) async {
      final StreakWorld w = StreakWorld();
      w.checkIn(kToday);
      await pumpStreak(t, w);
      expect(summary(t).value, '1');

      await tapShown(t, find.bySemanticsLabel('Checked in today, Today'));
      expect(w.repo.view().checkIns, isEmpty);
      expect(summary(t).value, '0');

      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().checkIns, hasLength(1));
      expect(summary(t).value, '1');
      w.dispose();
    });
  });

  group('milestones', () {
    testWidgets('a 7-day streak marks the first milestone done', (WidgetTester t) async {
      final StreakWorld w = StreakWorld();
      for (int i = 0; i < 7; i++) {
        w.checkIn(kToday.addDays(-i));
      }
      await pumpStreak(t, w);
      expect(summary(t).value, '7');
      expect(find.byKey(LumeStreakTool.milestoneKey(7)), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: today\'s row is translated', (WidgetTester t) async {
      final StreakWorld w = StreakWorld();
      await pumpStreak(t, w, locale: const Locale('ur'));
      expect(find.byType(LumeRecordRow), findsOneWidget);
      expect(find.text('آج'), findsWidgets);
      w.dispose();
    });
  });
}
