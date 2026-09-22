/// Focus in Urdu and Arabic: the words, the direction and the numerals.
///
/// Nothing here spells a translation out. Each assertion asks
/// [AppLocalizations] for the string the screen should be drawing and looks
/// for *that* — which is the test that no English is hard-coded, and which
/// keeps working when a translation is revised.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/localization/lume_format.dart';
import 'package:lume/core/navigation/lume_tool_frame.dart';
import 'package:lume/features/focus/application/focus_controller.dart';
import 'package:lume/features/focus/presentation/focus_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import 'focus_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  BuildContext ctx(WidgetTester tester) =>
      tester.element(find.byType(LumeFocusTool));

  for (final String code in <String>['ur', 'ar']) {
    group(code, () {
      testWidgets('every word comes from the translation, not from Dart', (
        WidgetTester tester,
      ) async {
        await pumpFocus(
          tester,
          FocusWorld(),
          profile: LumeBuildProfile.development,
          locale: Locale(code),
          surface: const Size(390, 6000),
        );
        final AppLocalizations l = AppLocalizations.of(ctx(tester));

        for (final String word in <String>[
          l.focusStart,
          l.focusReset,
          l.focusSkip,
          l.focusFocus,
          l.focusReady,
          l.focusLength,
          l.focusBreakLength,
          l.focusThisSession,
          l.focusKeptSession,
          l.focusNothingYet,
        ]) {
          expect(find.text(word), findsWidgets, reason: word);
        }

        // And none of the English the reference is written in.
        for (final String english in <String>[
          'Start focus',
          'Reset',
          'Skip',
          'This session',
          'Nothing yet — start a session and it will count here.',
        ]) {
          expect(find.text(english), findsNothing, reason: english);
        }
      });

      testWidgets('the session line and the lengths are in the reader\'s own '
          'numerals', (WidgetTester tester) async {
        await pumpFocus(
          tester,
          FocusWorld(),
          profile: LumeBuildProfile.development,
          locale: Locale(code),
          surface: const Size(390, 6000),
        );
        final BuildContext c = ctx(tester);
        final AppLocalizations l = AppLocalizations.of(c);
        final LumeFormatting f = LumeFormatting.of(c, countryCode: 'PK');

        expect(
          find.text(
            l.focusSession(
              f.integer(1),
              f.integer(LumeFocusController.sessionsPerCycle),
            ),
          ),
          findsOneWidget,
        );
        for (final Duration d in LumeFocusController.focusChoices) {
          expect(
            find.text(l.unitMinutesCount(f.integer(d.inMinutes))),
            findsWidgets,
            reason: '${d.inMinutes}',
          );
        }
      });

      testWidgets('the page reads right to left and the clock does not', (
        WidgetTester tester,
      ) async {
        await pumpFocus(
          tester,
          FocusWorld(),
          profile: LumeBuildProfile.development,
          locale: Locale(code),
          surface: const Size(390, 6000),
        );
        expect(
          Directionality.of(tester.element(find.byType(LumeToolFrame))),
          TextDirection.rtl,
        );
        expect(
          Directionality.of(
            tester.element(
              find.descendant(
                of: find.byKey(LumeFocusTool.timeKey),
                matching: find.byType(Text),
              ),
            ),
          ),
          TextDirection.ltr,
          reason: 'a time is not a sentence; it never reverses',
        );
        expect(focusTime(tester), '25:00');
        // The primary action leads, which right to left means from the right.
        expect(
          tester.getCenter(find.byKey(LumeFocusTool.startKey)).dx,
          greaterThan(tester.getCenter(find.byKey(LumeFocusTool.resetKey)).dx),
        );
      });

      testWidgets('it still works, and still fits, at twice the text', (
        WidgetTester tester,
      ) async {
        final FocusWorld world = FocusWorld();
        await pumpFocus(
          tester,
          world,
          profile: LumeBuildProfile.development,
          locale: Locale(code),
          textScale: 2,
          surface: const Size(390, 8000),
        );
        expectNoOverflow(tester);

        await tester.tap(find.byKey(LumeFocusTool.startKey));
        await tester.pump();
        world.advance(const Duration(minutes: 3));
        await tester.pump(const Duration(seconds: 1));
        expect(focusTime(tester), '22:00');
        expectNoOverflow(tester);
        await tester.tap(find.byKey(LumeFocusTool.startKey));
        await tester.pump();
      });
    });
  }

  testWidgets('the parity composition is translated too', (
    WidgetTester tester,
  ) async {
    await pumpFocus(
      tester,
      FocusWorld(),
      profile: LumeBuildProfile.parity,
      locale: const Locale('ur'),
      surface: const Size(390, 6000),
    );
    final BuildContext c = ctx(tester);
    final AppLocalizations l = AppLocalizations.of(c);
    final LumeFormatting f = LumeFormatting.of(c, countryCode: 'PK');
    expect(find.text(l.focusToday), findsOneWidget);
    expect(find.text(l.focusStreakLabel), findsOneWidget);
    expect(find.text(l.focusThisWeek), findsOneWidget);
    expect(
      find.text(f.integer(LumeFocusTool.sampleMinutesToday)),
      findsOneWidget,
      reason: 'the sample figure in the reader\'s own numerals',
    );
    expect(find.text('Minutes today'), findsNothing);
  });
}
