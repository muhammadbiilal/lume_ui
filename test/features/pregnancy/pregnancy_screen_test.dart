/// Pregnancy on screen: the empty state, picking a date, the dashboard it
/// produces, clearing with Undo, and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/pregnancy/presentation/pregnancy_tool.dart';

import '../../helpers/load_fonts.dart';
import 'pregnancy_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumePregnancyTool.summaryKey));

/// The fixture day, matching `kFixtureInstant` (7 September 2026).
final LumeDate kToday = LumeDate(2026, 9, 7);

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('no date set: the empty state shows, not a dashboard', (
      WidgetTester t,
    ) async {
      final PregnancyWorld w = PregnancyWorld();
      await pumpPregnancy(t, w);
      expect(find.byKey(LumePregnancyTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumePregnancyTool.summaryKey), findsNothing);
      expect(find.byKey(LumePregnancyTool.milestonesKey), findsNothing);
      expect(find.text('Not set'), findsOneWidget);
      expect(w.repo.view().profile, isNull);
      w.dispose();
    });
  });

  group('setting a date', () {
    testWidgets('picking a date closes the empty state and fills the dashboard', (
      WidgetTester t,
    ) async {
      final PregnancyWorld w = PregnancyWorld();
      await pumpPregnancy(t, w);
      await tapShown(t, find.byKey(LumePregnancyTool.lmpKey));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      // The picker opens on the fixture day, September 2026; 5 September is
      // two days before it and within the picker's allowed range.
      await tapShown(
        t,
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('5'),
        ),
      );
      await tapShown(t, find.text('OK'));

      expect(find.byKey(LumePregnancyTool.emptyKey), findsNothing);
      expect(find.byKey(LumePregnancyTool.summaryKey), findsOneWidget);
      final LumeSummaryCard s = summary(t);
      expect(s.value, '0'); // 2 days pregnant is still week 0
      expect(
        s.stats.map((LumeStat st) => '${st.label}=${st.value}'),
        contains('Days pregnant=2'),
      );
      expect(w.repo.view().profile!.lmp, LumeDate(2026, 9, 5));
      w.dispose();
    });

    testWidgets('cancelling the picker saves nothing', (WidgetTester t) async {
      final PregnancyWorld w = PregnancyWorld();
      await pumpPregnancy(t, w);
      await tapShown(t, find.byKey(LumePregnancyTool.lmpKey));
      await tapShown(t, find.text('Cancel'));
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.byKey(LumePregnancyTool.emptyKey), findsOneWidget);
      expect(w.repo.view().profile, isNull);
      w.dispose();
    });
  });

  group('the populated dashboard', () {
    testWidgets('week, trimester and progress agree with the stored date', (
      WidgetTester t,
    ) async {
      final PregnancyWorld w = PregnancyWorld();
      w.set(LumeDate(2026, 1, 5), kToday); // 245 days pregnant -> week 35
      await pumpPregnancy(t, w);
      final LumeSummaryCard s = summary(t);
      expect(s.value, '35');
      expect(s.caption, contains('Trimester 3'));
      expect(
        s.stats.map((LumeStat st) => '${st.label}=${st.value}'),
        contains('Days pregnant=245'),
      );
      expect(find.byKey(LumePregnancyTool.milestonesKey), findsOneWidget);
      expect(find.text('First trimester complete'), findsOneWidget);
      expect(find.text('Full term'), findsOneWidget);
      w.dispose();
    });
  });

  group('clearing', () {
    testWidgets('removes the date, and Undo brings it back', (
      WidgetTester t,
    ) async {
      final PregnancyWorld w = PregnancyWorld();
      w.set(LumeDate(2026, 6, 1), kToday);
      await pumpPregnancy(t, w);
      expect(find.byKey(LumePregnancyTool.summaryKey), findsOneWidget);

      await tapShown(t, find.byKey(LumePregnancyTool.clearKey));
      expect(w.repo.view().profile, isNull);
      expect(find.byKey(LumePregnancyTool.emptyKey), findsOneWidget);
      expect(find.text('Date cleared'), findsOneWidget);

      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().profile!.lmp, LumeDate(2026, 6, 1));
      expect(find.byKey(LumePregnancyTool.summaryKey), findsOneWidget);
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: the week kicker is translated', (WidgetTester t) async {
      final PregnancyWorld w = PregnancyWorld();
      w.set(LumeDate(2026, 6, 1), kToday);
      await pumpPregnancy(t, w, locale: const Locale('ur'));
      expect(find.text('ہفتہ'), findsOneWidget);
      w.dispose();
    });
  });
}
