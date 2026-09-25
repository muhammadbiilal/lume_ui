/// Habits on screen, through the real router: first use, figures that
/// agree, adding a habit, toggling today's check-in, editing, deleting with
/// Undo, and Urdu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_crud.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/habits/domain/habits_book.dart';
import 'package:lume/features/habits/presentation/habits_tool.dart';

import '../../helpers/load_fonts.dart';
import 'habits_screen_harness.dart';

Future<void> tapShown(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumeHabitsTool.summaryKey));

String n(String s) => s.replaceAll(' ', ' ').replaceAll(' ', ' ');

void main() {
  setUpAll(loadLumeFonts);

  group('first use', () {
    testWidgets('empty: what it is for, one way in, nothing seeded', (
      WidgetTester t,
    ) async {
      final HabitsWorld w = HabitsWorld();
      await pumpHabits(t, w);
      expect(find.byKey(LumeHabitsTool.emptyKey), findsOneWidget);
      expect(find.byKey(LumeHabitsTool.addKey), findsOneWidget);
      expect(find.text('Read'), findsNothing);
      expect(w.repo.view().habits, isEmpty);
      w.dispose();
    });
  });

  group('the reference composition', () {
    testWidgets('figures are real, computed from the check-ins on record', (
      WidgetTester t,
    ) async {
      final HabitsWorld w = HabitsWorld().reference();
      await pumpHabits(t, w);
      final LumeSummaryCard s = summary(t);
      // One habit, checked in today: doneToday=1/1.
      expect(n(s.value), '1');
      expect(s.valueSmall, '/ 1');
      expect(find.text('Read'), findsWidgets);
      w.dispose();
    });
  });

  group('adding a habit', () {
    testWidgets('a new habit appears, with no streak yet', (
      WidgetTester t,
    ) async {
      final HabitsWorld w = HabitsWorld();
      await pumpHabits(t, w);
      await tapShown(t, find.byKey(LumeHabitsTool.addKey));
      expect(find.byKey(LumeHabitsTool.formKey), findsOneWidget);

      await t.enterText(find.byKey(LumeHabitsTool.nameField), 'Stretch');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeHabitsTool.saveKey));

      expect(find.byKey(LumeHabitsTool.habitKey), findsOneWidget);
      expect(w.repo.view().habits, hasLength(1));
      expect(w.repo.view().habits.single.name, 'Stretch');
      w.dispose();
    });

    testWidgets('an empty name is refused, on screen', (WidgetTester t) async {
      final HabitsWorld w = HabitsWorld();
      await pumpHabits(t, w);
      await tapShown(t, find.byKey(LumeHabitsTool.addKey));
      await tapShown(t, find.byKey(LumeHabitsTool.saveKey));

      expect(find.byKey(LumeHabitsTool.formKey), findsOneWidget);
      final LumeFormField nameField = t.widget<LumeFormField>(
        find.byKey(LumeHabitsTool.nameField),
      );
      expect(nameField.error, isNotNull);
      expect(w.repo.view().habits, isEmpty);
      w.dispose();
    });
  });

  group('toggling today — instant, no confirmation', () {
    testWidgets('checking the row logs today and shows a streak', (
      WidgetTester t,
    ) async {
      final HabitsWorld w = HabitsWorld();
      w.add('Read');
      await pumpHabits(t, w);
      expect(find.text('Read'), findsWidgets);

      await tapShown(t, find.bySemanticsLabel('Done today, Read'));

      final HabitsBook book = w.book();
      expect(book.habits.single.doneToday, isTrue);
      expect(book.habits.single.currentStreak, 1);
      w.dispose();
    });

    testWidgets('checking it again undoes it, with no dialog either way', (
      WidgetTester t,
    ) async {
      final HabitsWorld w = HabitsWorld();
      w.add('Read');
      await pumpHabits(t, w);
      await tapShown(t, find.bySemanticsLabel('Done today, Read'));
      await tapShown(t, find.bySemanticsLabel('Done today, Read'));

      expect(w.book().habits.single.doneToday, isFalse);
      w.dispose();
    });
  });

  group('editing', () {
    testWidgets('changing the name updates the record and its own history', (
      WidgetTester t,
    ) async {
      final HabitsWorld w = HabitsWorld().reference();
      await pumpHabits(t, w);
      await tapShown(
        t,
        find.byKey(LumeHabitsTool.row(w.habits['Read']!.value)),
      );
      await tapShown(t, find.text('Edit'));
      await t.enterText(find.byKey(LumeHabitsTool.nameField), 'Read daily');
      await t.pumpAndSettle();
      await tapShown(t, find.byKey(LumeHabitsTool.saveKey));

      expect(w.repo.view().habits.single.name, 'Read daily');
      // Its check-in history — and so its streak — survives the rename.
      expect(w.book().habits.single.currentStreak, 2);
      w.dispose();
    });
  });

  group('delete', () {
    testWidgets('removes it and its check-ins, and Undo brings both back', (
      WidgetTester t,
    ) async {
      final HabitsWorld w = HabitsWorld().reference();
      await pumpHabits(t, w);
      await tapShown(
        t,
        find.byKey(LumeHabitsTool.row(w.habits['Read']!.value)),
      );
      await tapShown(t, find.text('Delete'));
      expect(find.byType(LumeDeleteConfirmation), findsOneWidget);
      await tapShown(t, find.text('Delete').last);

      expect(w.repo.view().habits, isEmpty);
      expect(w.repo.view().checkins, isEmpty);

      await tapShown(t, find.text('Undo'));
      expect(w.repo.view().habits, hasLength(1));
      expect(w.repo.view().checkins, hasLength(2));
      w.dispose();
    });
  });

  group('language', () {
    testWidgets('Urdu: the form is translated', (WidgetTester t) async {
      final HabitsWorld w = HabitsWorld();
      await pumpHabits(t, w, locale: const Locale('ur'));
      await tapShown(t, find.byKey(LumeHabitsTool.addKey));
      expect(find.text('نام'), findsOneWidget); // "Name"
      w.dispose();
    });
  });
}
