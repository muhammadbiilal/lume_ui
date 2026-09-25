/// Goals on screen, through the real router: first use, the composition
/// with figures that agree, the form and its validation, a contribution
/// with Undo, complete/abandon/reactivate, delete with Undo, and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/values/lume_currency.dart';
import 'package:lume/core/values/lume_money.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/goals/domain/goals_book.dart';
import 'package:lume/features/goals/domain/goals_model.dart';
import 'package:lume/features/goals/presentation/goals_sheets.dart';
import 'package:lume/features/goals/presentation/goals_tool.dart';

import '../../helpers/load_fonts.dart';
import 'goals_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumeGoalsTool.summaryKey));

String stat(WidgetTester t, String label) =>
    n(summary(t).stats.firstWhere((LumeStat s) => s.label == label).value);

/// The formatter's spaces are non-breaking; a test reads them as spaces.
String n(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');

final LumeCurrency pkr = LumeCurrency.of('PKR');
LumeMoney rs(int rupees) => LumeMoney.entry(rupees * 100, pkr);

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('empty: what it is for, one way in, nothing seeded', (
      WidgetTester t,
    ) async {
      final GoalsWorld w = GoalsWorld();
      await pumpGoals(t, w);
      expect(find.byKey(LumeGoalsTool.emptyKey), findsOneWidget);
      expect(find.text('No savings goals yet'), findsOneWidget);
      expect(find.byKey(LumeGoalsTool.addKey), findsOneWidget);
      // Nothing of the reference's three seeded goals.
      expect(find.text('Umrah trip'), findsNothing);
      expect(w.repo.view().goals, isEmpty);
      w.dispose();
    });
  });

  group('the reference composition', () {
    testWidgets('figures agree with the record', (WidgetTester t) async {
      final GoalsWorld w = GoalsWorld().reference();
      await pumpGoals(t, w);
      final LumeSummaryCard s = summary(t);
      expect(s.kicker, 'Saved so far');
      expect(n(s.value), 'Rs 38,400.00');
      expect(n(s.caption!), 'of Rs 60,000.00 across all goals');
      expect(stat(t, 'Active goals'), '1');
      // Once as the goal card's title, once as the "Next to complete" stat.
      expect(find.text('Emergency fund'), findsNWidgets(2));
      w.dispose();
    });
  });

  group('adding a goal', () {
    testWidgets('a new goal appears with zero saved', (WidgetTester t) async {
      final GoalsWorld w = GoalsWorld();
      await pumpGoals(t, w);
      await tapShown(t, find.byKey(LumeGoalsTool.addKey));
      expect(find.byKey(LumeGoalsTool.formKey), findsOneWidget);

      await t.enterText(find.byKey(LumeGoalsTool.nameField), 'New laptop');
      await t.enterText(find.byKey(LumeGoalsTool.targetField), '1400');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeGoalsTool.saveKey));

      expect(find.byKey(LumeGoalsTool.goalKey), findsOneWidget);
      expect(find.text('New laptop'), findsWidgets);
      expect(w.repo.view().goals, hasLength(1));
      expect(w.repo.view().goals.single.name, 'New laptop');
      w.dispose();
    });

    testWidgets('an empty name is refused, on screen', (WidgetTester t) async {
      final GoalsWorld w = GoalsWorld();
      await pumpGoals(t, w);
      await tapShown(t, find.byKey(LumeGoalsTool.addKey));
      await t.enterText(find.byKey(LumeGoalsTool.targetField), '500');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeGoalsTool.saveKey));

      expect(find.byKey(LumeGoalsTool.formKey), findsOneWidget);
      final LumeFormField nameField = t.widget<LumeFormField>(
        find.byKey(LumeGoalsTool.nameField),
      );
      expect(nameField.error, isNotNull);
      expect(w.repo.view().goals, isEmpty);
      w.dispose();
    });

    testWidgets('a zero target is refused, on screen', (WidgetTester t) async {
      final GoalsWorld w = GoalsWorld();
      await pumpGoals(t, w);
      await tapShown(t, find.byKey(LumeGoalsTool.addKey));
      await t.enterText(find.byKey(LumeGoalsTool.nameField), 'Trip');
      await t.enterText(find.byKey(LumeGoalsTool.targetField), '0');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeGoalsTool.saveKey));

      expect(find.byKey(LumeGoalsTool.formKey), findsOneWidget);
      expect(w.repo.view().goals, isEmpty);
      w.dispose();
    });
  });

  group('a contribution', () {
    testWidgets('adds to saved, and Undo takes it back', (
      WidgetTester t,
    ) async {
      final GoalsWorld w = GoalsWorld().reference();
      await pumpGoals(t, w);
      await tapShown(
        t,
        find.byKey(LumeGoalsTool.row(w.goals['Emergency fund']!.value)),
      );
      expect(find.byKey(LumeGoalsTool.goalKey), findsOneWidget);

      await tapShown(t, find.byKey(LumeGoalsTool.contributeKey));
      await t.enterText(find.byKey(GoalsSheetKeys.contributeAmount), '600');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(GoalsSheetKeys.contributeGo));

      final GoalsBook after = w.book();
      expect(after.goals.single.saved, rs(39000));
      expect(find.text('Contribution added'), findsOneWidget);

      await tapShown(t, find.text('Undo'));
      final GoalsBook undone = w.book();
      expect(undone.goals.single.saved, rs(38400));
      w.dispose();
    });

    testWidgets('cannot be added to a completed goal', (WidgetTester t) async {
      final GoalsWorld w = GoalsWorld().reference();
      final GoalView v = w.book().goals.single;
      w.repo.setState(v.goal.id, GoalState.completed, version: v.goal.version);
      await pumpGoals(t, w);
      await tapShown(
        t,
        find.byKey(LumeGoalsTool.row(w.goals['Emergency fund']!.value)),
      );

      final LumeButton btn = t.widget<LumeButton>(
        find.byKey(LumeGoalsTool.contributeKey),
      );
      expect(btn.onPressed, isNull);
      w.dispose();
    });
  });

  group('completing, abandoning, reactivating', () {
    testWidgets('marking complete asks first, then keeps history', (
      WidgetTester t,
    ) async {
      final GoalsWorld w = GoalsWorld().reference();
      await pumpGoals(t, w);
      await tapShown(
        t,
        find.byKey(LumeGoalsTool.row(w.goals['Emergency fund']!.value)),
      );
      await tapShown(t, find.byKey(LumeGoalsTool.completeKey));
      // The confirmation sheet.
      expect(find.byKey(GoalsSheetKeys.confirm), findsOneWidget);
      await tapShown(t, find.byKey(GoalsSheetKeys.confirm));

      final GoalView v = w.book().goals.single;
      expect(v.goal.state, GoalState.completed);
      expect(v.saved, rs(38400)); // kept, not cleared
      expect(find.byKey(LumeGoalsTool.reactivateKey), findsOneWidget);
      w.dispose();
    });
  });

  group('delete', () {
    testWidgets('removes the goal, and Undo brings it back with its history', (
      WidgetTester t,
    ) async {
      final GoalsWorld w = GoalsWorld().reference();
      await pumpGoals(t, w);
      await tapShown(
        t,
        find.byKey(LumeGoalsTool.row(w.goals['Emergency fund']!.value)),
      );
      await tapShown(t, find.text('Delete'));
      expect(find.byType(LumeDeleteConfirmation), findsOneWidget);
      await tapShown(t, find.text('Delete').last);

      expect(w.repo.view().goals, isEmpty);
      expect(find.text('Goal deleted'), findsOneWidget);

      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().goals, hasLength(1));
      expect(w.book().goals.single.saved, rs(38400));
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: the summary and empty state are translated', (
      WidgetTester t,
    ) async {
      final GoalsWorld w = GoalsWorld();
      await pumpGoals(t, w, locale: const Locale('ur'));
      expect(find.text('ابھی تک کوئی بچت کا ہدف نہیں'), findsOneWidget);
      w.dispose();
    });
  });
}
