/// Water in Urdu and Arabic: the words, the direction, and the numerals.
///
/// The reference's Water strings exist in all three languages, but its
/// figures do not: `toFixed` and string concatenation give every reader Latin
/// digits and an English decimal point. Every figure here goes through
/// [LumeFormatting], so the assertions below are written against what the
/// formatter produces for that reader rather than against glyphs typed into
/// a test.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/localization/lume_numerals.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/features/water/presentation/water_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/load_fonts.dart';
import 'water_harness.dart';

BuildContext ctx(WidgetTester t) =>
    t.element(find.byKey(LumeWaterTool.summaryKey));

void main() {
  setUpAll(loadLumeFonts);

  for (final String code in <String>['ur', 'ar']) {
    group(code, () {
      testWidgets('every word on the screen is translated', (
        WidgetTester t,
      ) async {
        await pumpWater(t, locale: Locale(code));
        final AppLocalizations l = AppLocalizations.of(ctx(t));

        final LumeSummaryCard card = t.widget<LumeSummaryCard>(
          find.byKey(LumeWaterTool.summaryKey),
        );
        expect(card.kicker, l.waterToday);
        expect(card.stats[0].label, l.waterRemaining);
        expect(card.stats[1].label, l.waterGlasses);
        expect(card.stats[2].label, l.waterLogged);

        expect(find.text(l.waterTimeline), findsOneWidget);
        expect(find.text(l.waterKindWater), findsWidgets);
        expect(find.text(l.waterKindTea), findsWidgets);
        expect(find.text(l.waterGoal), findsOneWidget);
        expect(find.text(l.waterGoalDefault), findsOneWidget);
        expect(find.text(l.waterSetGoal), findsOneWidget);

        // And none of the English the reference is written in.
        for (final String english in <String>[
          'Today',
          'Remaining',
          'Glasses',
          'Logged',
          'Progress',
          'Daily goal',
          'Default goal',
          'Change goal',
          'Water',
          'Tea',
        ]) {
          expect(find.text(english), findsNothing, reason: english);
        }
      });

      testWidgets('the figures go through the reader\'s own formatting', (
        WidgetTester t,
      ) async {
        await pumpWater(t, locale: Locale(code));
        final BuildContext c = ctx(t);
        final AppLocalizations l = AppLocalizations.of(c);
        final LumeFormatting f = LumeFormatting.of(c, countryCode: 'PK');

        final LumeSummaryCard card = t.widget<LumeSummaryCard>(
          find.byKey(LumeWaterTool.summaryKey),
        );
        expect(card.value, '${f.fixed(1.3, 1)} L');
        expect(card.caption, l.waterOfDefault('${f.fixed(2, 1)} L'));
        expect(card.stats[0].value, '${f.fixed(0.8, 1)} L');
        expect(card.stats[1].value, f.integer(5));
        expect(card.stats[2].value, f.integer(4));

        final LumeRichRow goal = t.widget<LumeRichRow>(
          find.descendant(
            of: find.byKey(LumeWaterTool.goalKey),
            matching: find.byType(LumeRichRow),
          ),
        );
        expect(goal.value, '${f.fixed(2, 1)} L');

        // The buttons and the timeline count millilitres the same way.
        expect(find.text('+ ${f.integer(250)} ml'), findsOneWidget);
        expect(find.text('+ ${f.integer(500)} ml'), findsOneWidget);
      });

      testWidgets('the page reads right to left, and the figures do not', (
        WidgetTester t,
      ) async {
        await pumpWater(t, locale: Locale(code));

        expect(Directionality.of(ctx(t)), TextDirection.rtl);
        expect(
          Directionality.of(t.element(find.byKey(LumeWaterTool.timelineKey))),
          TextDirection.rtl,
        );
        // A total and a time in the same card must not swap places.
        expect(
          find.descendant(
            of: find.byKey(LumeWaterTool.summaryKey),
            matching: find.byType(LumeNumerals),
          ),
          findsWidgets,
        );
      });

      testWidgets('logging a glass says so in the reader\'s language', (
        WidgetTester t,
      ) async {
        await pumpWater(t, locale: Locale(code));
        final BuildContext c = ctx(t);
        final AppLocalizations l = AppLocalizations.of(c);
        final LumeFormatting f = LumeFormatting.of(c, countryCode: 'PK');

        await tapWater(t, find.byKey(LumeWaterTool.addSmallKey));
        expect(find.text(l.waterAdded('${f.integer(250)} ml')), findsOneWidget);
      });

      testWidgets('the goal sheet is translated, and its hint is the one '
          'sentence that says what the figure is', (WidgetTester t) async {
        await pumpWater(t, locale: Locale(code));
        final AppLocalizations l = AppLocalizations.of(ctx(t));

        await tapWater(t, find.byKey(LumeWaterTool.goalEditKey));
        expect(find.text(l.waterGoalMl), findsOneWidget);
        expect(find.text(l.waterGoalHint), findsOneWidget);
      });

      testWidgets('200 % text scale, right to left, does not overflow', (
        WidgetTester t,
      ) async {
        await pumpWater(
          t,
          locale: Locale(code),
          textScale: 2,
          surface: const Size(390, 9000),
        );
        expect(find.byKey(LumeWaterTool.summaryKey), findsOneWidget);
        expect(find.byKey(LumeWaterTool.timelineKey), findsOneWidget);
        expect(find.byKey(LumeWaterTool.goalEditKey), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    });
  }
}
