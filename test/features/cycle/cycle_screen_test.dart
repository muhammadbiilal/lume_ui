/// Cycle Tracker on screen: the empty state, logging a period, closing an
/// ongoing one, a prediction once there is history to average, and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/cycle/domain/cycle_model.dart';
import 'package:lume/features/cycle/presentation/cycle_sheets.dart';
import 'package:lume/features/cycle/presentation/cycle_tool.dart';

import '../../helpers/load_fonts.dart';
import 'cycle_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumeCycleTool.summaryKey));

/// The fixture day: 7 September 2026.
final LumeDate kToday = LumeDate(2026, 9, 7);

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('nothing is invented — a clear next step instead', (WidgetTester t) async {
      final CycleWorld w = CycleWorld();
      await pumpCycle(t, w);
      expect(find.byKey(LumeCycleTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeCycleTool.summaryKey), findsNothing);
      expect(w.repo.view().periods, isEmpty);
      w.dispose();
    });
  });

  group('logging a period', () {
    testWidgets('the empty state\'s call to action logs today as the start', (
      WidgetTester t,
    ) async {
      final CycleWorld w = CycleWorld();
      await pumpCycle(t, w);
      await tapShown(t, find.byKey(LumeCycleTool.emptyAddKey));
      expect(find.byKey(CycleSheetKeys.startPicker), findsOneWidget);
      await tapShown(t, find.byKey(CycleSheetKeys.save));

      expect(w.repo.view().periods, hasLength(1));
      expect(w.repo.view().periods.single.startDate, kToday);
      expect(w.repo.view().periods.single.ongoing, isTrue);
      expect(find.byKey(LumeCycleTool.summaryKey), findsOneWidget);
      expect(summary(t).value, '1');
      w.dispose();
    });

    testWidgets('the primary action logs a second period the same way', (
      WidgetTester t,
    ) async {
      final CycleWorld w = CycleWorld();
      w.log(kToday.addDays(-28));
      await pumpCycle(t, w);
      await tapShown(t, find.byKey(LumeCycleTool.addKey));
      await tapShown(t, find.byKey(CycleSheetKeys.save));

      expect(w.repo.view().periods, hasLength(2));
      w.dispose();
    });
  });

  group('closing an ongoing period', () {
    testWidgets('unchecking "still ongoing" defaults the end to today and saves it', (
      WidgetTester t,
    ) async {
      final CycleWorld w = CycleWorld();
      w.log(kToday);
      await pumpCycle(t, w);
      expect(find.byKey(LumeCycleTool.currentRowKey), findsOneWidget);

      await tapShown(t, find.byKey(LumeCycleTool.currentRowKey));
      expect(find.byKey(CycleSheetKeys.ongoingToggle), findsOneWidget);
      expect(find.byKey(CycleSheetKeys.endPicker), findsNothing);
      await tapShown(t, find.byKey(CycleSheetKeys.ongoingToggle));
      expect(find.byKey(CycleSheetKeys.endPicker), findsOneWidget);
      await tapShown(t, find.byKey(CycleSheetKeys.save));

      final CyclePeriod saved = w.repo.view().periods.single;
      expect(saved.endDate, kToday);
      expect(saved.ongoing, isFalse);
      w.dispose();
    });

    testWidgets('deleting a period removes it and Undo brings it back', (
      WidgetTester t,
    ) async {
      final CycleWorld w = CycleWorld();
      w.log(kToday);
      await pumpCycle(t, w);
      await tapShown(t, find.byKey(LumeCycleTool.currentRowKey));
      await tapShown(t, find.byKey(CycleSheetKeys.delete));
      expect(find.byKey(CycleSheetKeys.confirmDelete), findsOneWidget);
      // Scoped to the confirmation sheet: its own sheet, still mounted
      // underneath, has a same-labelled Delete action of its own.
      await tapShown(
        t,
        find.descendant(
          of: find.byKey(CycleSheetKeys.confirmDelete),
          matching: find.text('Delete entry'),
        ),
      );

      expect(w.repo.view().periods, isEmpty);
      expect(find.text('Entry deleted'), findsOneWidget);

      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().periods, hasLength(1));
      w.dispose();
    });
  });

  group('a prediction once there is history to average', () {
    testWidgets('two periods 28 days apart estimate the next one and show it', (
      WidgetTester t,
    ) async {
      final CycleWorld w = CycleWorld();
      w.log(kToday.addDays(-56));
      w.log(kToday.addDays(-28));
      await pumpCycle(t, w);

      expect(find.byKey(LumeCycleTool.nextKey), findsOneWidget);
      expect(find.byKey(LumeCycleTool.historyKey), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(LumeCycleTool.nextKey), matching: find.text('today')),
        findsOneWidget,
      ); // subsRenewsIn(0)
      expect(find.text('28 days'), findsWidgets); // ageDaysCount(28)

      final LumeSummaryCard s = summary(t);
      expect(s.value, '29'); // day 29 of a 28-day average cycle
      expect(s.valueSmall, '/ 28');
      w.dispose();
    });

    testWidgets('a single logged period shows no estimate and no history', (
      WidgetTester t,
    ) async {
      final CycleWorld w = CycleWorld();
      w.log(kToday.addDays(-3));
      await pumpCycle(t, w);

      expect(find.byKey(LumeCycleTool.nextKey), findsNothing);
      expect(find.byKey(LumeCycleTool.historyKey), findsNothing);
      final LumeSummaryCard s = summary(t);
      expect(s.value, '4');
      expect(s.valueSmall, isNull);
      w.dispose();
    });
  });

  group('history', () {
    testWidgets('a completed cycle is tappable and edits that period', (
      WidgetTester t,
    ) async {
      final CycleWorld w = CycleWorld();
      final CyclePeriod first = w.log(kToday.addDays(-56));
      w.log(kToday.addDays(-28));
      await pumpCycle(t, w);

      await tapShown(t, find.byKey(LumeCycleTool.historyRowKey(first.id)));
      expect(find.byKey(CycleSheetKeys.startPicker), findsOneWidget);
      expect(find.byKey(CycleSheetKeys.delete), findsOneWidget);
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: the sheet\'s own Save and Cancel are translated', (
      WidgetTester t,
    ) async {
      final CycleWorld w = CycleWorld();
      await pumpCycle(t, w, locale: const Locale('ur'));
      await tapShown(t, find.byKey(LumeCycleTool.emptyAddKey));
      expect(find.text('محفوظ کریں'), findsOneWidget);
      expect(find.text('منسوخ'), findsOneWidget);
      w.dispose();
    });
  });
}
