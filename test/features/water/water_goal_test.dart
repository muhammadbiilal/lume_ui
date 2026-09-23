/// The daily goal: a default nobody chose, a figure the reader can change,
/// and the range it is held to.
///
/// The goal is a record in the tool's own store, so these tests watch the
/// store as well as the screen — one record, never two, and every figure on
/// the screen measured against whatever it currently says.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/domain/record_model.dart';
import 'package:lume/features/water/domain/water_goal.dart';
import 'package:lume/features/water/presentation/water_tool.dart';

import '../../helpers/load_fonts.dart';
import 'water_harness.dart';

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

LumeRichRow goalRow(WidgetTester t) => t.widget<LumeRichRow>(
  inKey(LumeWaterTool.goalKey, find.byType(LumeRichRow)),
);

LumeSummaryCard summary(WidgetTester t) =>
    t.widget<LumeSummaryCard>(find.byKey(LumeWaterTool.summaryKey));

/// Open the goal sheet, type [typed], and press Save.
Future<void> setGoal(WidgetTester t, String typed) async {
  await tapWater(t, find.byKey(LumeWaterTool.goalEditKey));
  await t.enterText(find.byKey(LumeWaterTool.goalFieldKey), typed);
  await t.pumpAndSettle();
  await tapWater(t, find.byKey(LumeWaterTool.goalSaveKey));
}

void main() {
  setUpAll(loadLumeFonts);

  group('what a typed goal has to be', () {
    test('a whole number of millilitres, greater than zero', () {
      expect(LumeWaterGoalEntry.parse('2000').ml, 2000);
      expect(LumeWaterGoalEntry.parse(' 1500 ').ml, 1500);
      expect(LumeWaterGoalEntry.parse('1').ml, 1);
    });

    test('nothing typed is nothing, not the default', () {
      expect(
        LumeWaterGoalEntry.parse('').problem,
        LumeWaterGoalProblem.missing,
      );
      expect(
        LumeWaterGoalEntry.parse('   ').problem,
        LumeWaterGoalProblem.missing,
      );
    });

    test('zero, a negative and a fraction are refused', () {
      for (final String bad in <String>['0', '-1', '-2000', '250.5', '0.5']) {
        expect(
          LumeWaterGoalEntry.parse(bad).problem,
          LumeWaterGoalProblem.notPositive,
          reason: bad,
        );
      }
    });

    test('something that is not a number at all is refused', () {
      for (final String bad in <String>['two litres', 'abc', '2,000', '2e3']) {
        expect(LumeWaterGoalEntry.parse(bad).ok, isFalse, reason: bad);
      }
    });

    test('an absurd figure is refused rather than clamped', () {
      expect(LumeWaterGoalEntry.parse('10000').ml, kLumeWaterMaxGoalMl);
      // A slipped extra zero on the default.
      expect(
        LumeWaterGoalEntry.parse('20000').problem,
        LumeWaterGoalProblem.tooLarge,
      );
      expect(
        LumeWaterGoalEntry.parse('999999999').problem,
        LumeWaterGoalProblem.tooLarge,
      );
      // Nothing is quietly turned into the bound.
      expect(LumeWaterGoalEntry.parse('20000').ml, isNull);
    });

    test('the reader\'s own digits read as numbers', () {
      expect(LumeWaterGoalEntry.parse('٢٥٠٠').ml, 2500);
      expect(LumeWaterGoalEntry.parse('۳۰۰۰').ml, 3000);
      expect(lumeLatinDigits('١٢x'), '12x');
    });
  });

  group('what a stored goal means', () {
    test('an unread, failed or empty collection is the default', () {
      for (final LumeCollectionView v in <LumeCollectionView>[
        const LumeCollectionView(LumeCollectionStatus.loading),
        const LumeCollectionView(LumeCollectionStatus.error),
        const LumeCollectionView(LumeCollectionStatus.ready),
      ]) {
        final LumeWaterGoal g = LumeWaterGoal.from(v);
        expect(g.ml, kLumeWaterDefaultGoalMl);
        expect(g.ml, 2000);
        expect(g.chosen, isFalse);
        expect(g.recordId, isNull);
      }
    });

    test('a stored figure is the reader\'s, and is marked as chosen', () {
      final LumeMemoryRecordRepository store = waterStore(seeded: false)
        ..open(kLumeWaterGoalCollection);
      store.create(kLumeWaterGoalCollection, <String, Object?>{'ml': 3000});

      final LumeWaterGoal g = LumeWaterGoal.from(
        store.view(kLumeWaterGoalCollection),
      );
      expect(g.ml, 3000);
      expect(g.chosen, isTrue);
      expect(g.recordId, isNotNull);
      expect(g.version, 1);
    });

    test('a stored figure the form would refuse is not honoured', () {
      for (final Object? bad in <Object?>[0, -1, 'lots', 99999, null]) {
        final LumeMemoryRecordRepository store = waterStore(seeded: false)
          ..open(kLumeWaterGoalCollection);
        store.create(kLumeWaterGoalCollection, <String, Object?>{'ml': bad});

        final LumeWaterGoal g = LumeWaterGoal.from(
          store.view(kLumeWaterGoalCollection),
        );
        expect(g.ml, kLumeWaterDefaultGoalMl, reason: '$bad');
        expect(g.chosen, isFalse, reason: '$bad');
        // The record is still there to be overwritten, not left beside a new
        // one.
        expect(g.recordId, isNotNull, reason: '$bad');
      }
    });
  });

  group('on screen', () {
    testWidgets('the default is 2000 ml, and is marked as the default', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = waterStore();
      await pumpWater(t, store: store);

      expect(goalRow(t).value, '2.0 L');
      expect(goalRow(t).subtitle, 'Default goal');
      expect(summary(t).caption, 'of the default 2.0 L goal');
      // Nothing was stored to say so.
      expect(store.view(kLumeWaterGoalCollection).items, isEmpty);
    });

    testWidgets('setting a goal moves every figure derived from it', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = waterStore();
      await pumpWater(t, store: store);

      await setGoal(t, '5000');

      // The write went to a second collection, and the whole tool redrew from
      // it without anything else being touched.
      expect(store.view(kLumeWaterGoalCollection).items.single['ml'], 5000);
      expect(goalRow(t).value, '5.0 L');
      expect(goalRow(t).subtitle, isNull);
      expect(find.text('Default goal'), findsNothing);

      final LumeSummaryCard card = summary(t);
      expect(card.caption, 'of a 5.0 L goal');
      // The day's total has not changed; everything measured against the goal
      // has. 1250 of 5000 is 25 %, and 3750 ml are left.
      expect(card.value, '1.3 L');
      expect(card.stats.first.value, '3.8 L');
      final LumeProgressRing ring = t.widget<LumeProgressRing>(
        find.byKey(LumeWaterTool.ringKey),
      );
      expect(ring.value, closeTo(0.25, 1e-12));
      expect(ring.centreValue, '25%');
    });

    testWidgets('setting it again updates the one record', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = waterStore();
      await pumpWater(t, store: store);

      await setGoal(t, '3000');
      expect(goalRow(t).value, '3.0 L');
      await setGoal(t, '4000');

      final List<LumeRecord> goals = store.view(kLumeWaterGoalCollection).items;
      expect(goals.length, 1);
      expect(goals.single['ml'], 4000);
      expect(goals.single.version, 2);
      expect(goalRow(t).value, '4.0 L');
    });

    testWidgets('the sheet opens on the goal as it stands', (
      WidgetTester t,
    ) async {
      await pumpWater(t);

      await tapWater(t, find.byKey(LumeWaterTool.goalEditKey));
      expect(
        t
            .widget<EditableText>(
              inKey(LumeWaterTool.goalFieldKey, find.byType(EditableText)),
            )
            .controller
            .text,
        '2000',
      );
      // And says what the figure is, under the field that sets it.
      expect(
        find.text('A goal to fill, not a health recommendation.'),
        findsOneWidget,
      );
    });

    testWidgets('zero is refused, and the goal does not move', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = waterStore();
      await pumpWater(t, store: store);

      await setGoal(t, '0');

      expect(find.text('Enter an amount greater than zero'), findsOneWidget);
      // The sheet is still open and nothing was written.
      expect(find.byKey(LumeWaterTool.goalFieldKey), findsOneWidget);
      expect(store.view(kLumeWaterGoalCollection).items, isEmpty);
    });

    testWidgets('an absurd figure is refused, and nothing is clamped', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = waterStore();
      await pumpWater(t, store: store);

      await setGoal(t, '20000');

      expect(
        find.text('That figure is too large to work with'),
        findsOneWidget,
      );
      expect(find.byKey(LumeWaterTool.goalFieldKey), findsOneWidget);
      expect(store.view(kLumeWaterGoalCollection).items, isEmpty);
    });

    testWidgets('an emptied field is refused', (WidgetTester t) async {
      final LumeMemoryRecordRepository store = waterStore();
      await pumpWater(t, store: store);

      await setGoal(t, '');

      expect(find.text('Goal in ml is required'), findsOneWidget);
      expect(store.view(kLumeWaterGoalCollection).items, isEmpty);
    });

    testWidgets('the goal survives logging a drink', (WidgetTester t) async {
      final LumeMemoryRecordRepository store = waterStore();
      await pumpWater(t, store: store);

      await setGoal(t, '3000');
      await tapWater(t, find.byKey(LumeWaterTool.addSmallKey));

      expect(store.view(kLumeWaterGoalCollection).items.single['ml'], 3000);
      expect(goalRow(t).value, '3.0 L');
      expect(goalRow(t).subtitle, isNull);
      // 1500 of 3000.
      expect(summary(t).caption, 'of a 3.0 L goal');
      expect(summary(t).value, '1.5 L');
      expect(summary(t).stats.first.value, '1.5 L');
    });

    testWidgets('a goal set before the tool opens is read, not overwritten', (
      WidgetTester t,
    ) async {
      final LumeMemoryRecordRepository store = waterStore()
        ..open(kLumeWaterGoalCollection);
      store.create(kLumeWaterGoalCollection, <String, Object?>{'ml': 1000});

      await pumpWater(t, store: store, now: kFixtureInstant);

      expect(goalRow(t).value, '1.0 L');
      expect(goalRow(t).subtitle, isNull);
      // 1250 of 1000: past it, so nothing is left and the ring stops at one.
      expect(summary(t).stats.first.value, '0.0 L');
    });
  });
}
