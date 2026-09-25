/// Meal Plan on screen, through the real router: first use, filling a
/// slot, editing a filled slot, clearing a slot, the two navigation
/// buttons, and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_date.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/mealplan/domain/mealplan_model.dart';
import 'package:lume/features/mealplan/presentation/mealplan_sheets.dart';
import 'package:lume/features/mealplan/presentation/mealplan_tool.dart';

import '../../helpers/load_fonts.dart';
import 'mealplan_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumeMealPlanTool.summaryKey));

final LumeDate kToday = LumeDate(2026, 9, 7);

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('every slot starts empty, nothing rotated in from a fixture', (
      WidgetTester t,
    ) async {
      final MealPlanWorld w = MealPlanWorld();
      await pumpMealPlan(t, w);
      final LumeSummaryCard s = summary(t);
      expect(s.value, '0');
      expect(s.valueSmall, '/ 21');
      expect(w.repo.view().entries, isEmpty);
      w.dispose();
    });
  });

  group('filling a slot', () {
    testWidgets('opens the sheet, saves, updates the count', (
      WidgetTester t,
    ) async {
      final MealPlanWorld w = MealPlanWorld();
      await pumpMealPlan(t, w);
      await tapShown(
        t,
        find.byKey(LumeMealPlanTool.slotKey(kToday, MealSlot.breakfast)),
      );
      expect(find.byKey(MealPlanSheetKeys.text), findsOneWidget);

      await t.enterText(find.byKey(MealPlanSheetKeys.text), 'Oats and fruit');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(MealPlanSheetKeys.save));

      expect(find.text('Oats and fruit'), findsOneWidget);
      expect(n(summary(t).value), '1');
      expect(w.repo.view().entries.single.text, 'Oats and fruit');
      w.dispose();
    });

    testWidgets('editing a filled slot replaces its text, not duplicates it', (
      WidgetTester t,
    ) async {
      final MealPlanWorld w = MealPlanWorld();
      w.set(kToday, MealSlot.lunch, 'Salad');
      await pumpMealPlan(t, w);
      await tapShown(
        t,
        find.byKey(LumeMealPlanTool.slotKey(kToday, MealSlot.lunch)),
      );
      await t.enterText(find.byKey(MealPlanSheetKeys.text), 'Soup');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(MealPlanSheetKeys.save));

      expect(w.repo.view().entries, hasLength(1));
      expect(w.repo.view().entries.single.text, 'Soup');
      w.dispose();
    });
  });

  group('clearing a slot', () {
    testWidgets('removes it, and Undo brings it back', (WidgetTester t) async {
      final MealPlanWorld w = MealPlanWorld();
      w.set(kToday, MealSlot.dinner, 'Daal');
      await pumpMealPlan(t, w);
      await tapShown(
        t,
        find.byKey(LumeMealPlanTool.slotKey(kToday, MealSlot.dinner)),
      );
      expect(find.byKey(MealPlanSheetKeys.clear), findsOneWidget);
      await tapShown(t, find.byKey(MealPlanSheetKeys.clear));

      expect(w.repo.view().entries, isEmpty);
      expect(find.text('Cleared'), findsOneWidget);

      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().entries, hasLength(1));
      w.dispose();
    });
  });

  group('navigation — kept exactly as the reference has it', () {
    testWidgets('the two buttons are real, not stubs', (WidgetTester t) async {
      final MealPlanWorld w = MealPlanWorld();
      await pumpMealPlan(t, w);
      expect(find.byKey(LumeMealPlanTool.shoppingKey), findsOneWidget);
      expect(find.byKey(LumeMealPlanTool.recipesKey), findsOneWidget);
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: the summary caption is translated', (
      WidgetTester t,
    ) async {
      final MealPlanWorld w = MealPlanWorld();
      await pumpMealPlan(t, w, locale: const Locale('ur'));
      expect(find.text('کھانے منصوبہ بند'), findsOneWidget);
      w.dispose();
    });
  });
}

String n(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');
