/// Focus, used.
///
/// The clock is [FocusWorld]: the test moves it and then pumps, so a stretch
/// that takes twenty-five minutes takes no time at all here and takes exactly
/// twenty-five minutes as far as the tool is concerned.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/features/focus/application/focus_controller.dart';
import 'package:lume/features/focus/presentation/focus_tool.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../tools/tool_parity.dart';
import 'focus_harness.dart';

/// The words on the primary control.
String _primary(WidgetTester tester) =>
    textsUnder(tester, find.byKey(LumeFocusTool.startKey)).first;

Finder _chip(Key strip, String label) => find.descendant(
  of: find.byKey(strip),
  matching: find.widgetWithText(LumeChoiceChip, label),
);

void main() {
  setUpAll(loadLumeFonts);

  /// A development build: the honest path, which is what a reader runs.
  Future<FocusWorld> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size surface = const Size(390, 5000),
  }) async {
    final FocusWorld world = FocusWorld();
    await pumpFocus(
      tester,
      world,
      profile: LumeBuildProfile.development,
      locale: locale,
      textScale: textScale,
      surface: surface,
    );
    return world;
  }

  group('the clock, on screen', () {
    testWidgets('start, pause, resume, reset', (WidgetTester tester) async {
      final FocusWorld world = await open(tester);
      expect(focusTime(tester), '25:00');
      expect(_primary(tester), 'Start focus');
      expect(find.text('Ready'), findsOneWidget);

      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      expect(_primary(tester), 'Pause');
      expect(find.text('Running'), findsOneWidget);

      world.advance(const Duration(minutes: 2, seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(focusTime(tester), '22:30');

      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      expect(_primary(tester), 'Resume');
      expect(find.text('Paused'), findsOneWidget);
      world.advance(const Duration(minutes: 5));
      await tester.pump();
      expect(focusTime(tester), '22:30', reason: 'a pause stops the clock');

      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      world.advance(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(focusTime(tester), '22:00');

      await tester.tap(find.byKey(LumeFocusTool.resetKey));
      await tester.pump();
      expect((focusTime(tester), _primary(tester)), ('25:00', 'Start focus'));
    });

    testWidgets('the face repaints while running and does not drift', (
      WidgetTester tester,
    ) async {
      final FocusWorld world = await open(tester);
      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      // Sixty separate half-seconds, each with its own frame.
      for (int i = 0; i < 60; i++) {
        world.advance(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(focusTime(tester), '24:30');
    });

    testWidgets('choosing a focus length and a break length', (
      WidgetTester tester,
    ) async {
      await open(tester);
      await tester.tap(_chip(LumeFocusTool.focusLengthKey, '45 min'));
      await tester.pump();
      expect(focusTime(tester), '45:00');

      await tester.tap(_chip(LumeFocusTool.breakLengthKey, '15 min'));
      await tester.pump();
      expect(focusTime(tester), '45:00', reason: 'the focus stretch is intact');

      await tester.tap(find.byKey(LumeFocusTool.skipKey));
      await tester.pump();
      expect(focusTime(tester), '15:00');
      expect(find.text('Break'), findsWidgets);
    });

    testWidgets('skip moves to the break, and then to the next session', (
      WidgetTester tester,
    ) async {
      await open(tester);
      expect(find.text('Session 1 of 4'), findsOneWidget);
      await tester.tap(find.byKey(LumeFocusTool.skipKey));
      await tester.pump();
      expect(focusTime(tester), '05:00');
      expect(_primary(tester), 'Start');
      expect(find.text('Session 1 of 4'), findsOneWidget);

      await tester.tap(find.byKey(LumeFocusTool.skipKey));
      await tester.pump();
      expect(find.text('Session 2 of 4'), findsOneWidget);
      expect(focusTime(tester), '25:00');
      expect(_primary(tester), 'Start focus');
    });
  });

  group('finishing', () {
    testWidgets('toasts, vibrates, tells a reader, and offers the break', (
      WidgetTester tester,
    ) async {
      final List<MethodCall> calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final FocusWorld world = await open(tester);
      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      world.advance(const Duration(minutes: 25));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Focus finished'), findsOneWidget);
      expect(
        calls.where((MethodCall c) => c.method == 'HapticFeedback.vibrate'),
        hasLength(1),
      );
      expect(focusTime(tester), '05:00');
      expect(find.text('Break'), findsWidgets);
      expect(
        _primary(tester),
        'Start',
        reason: 'the break is offered, never sprung',
      );

      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(LumeToast), findsNothing);
    });

    testWidgets('a finished break says so, in its own words', (
      WidgetTester tester,
    ) async {
      final FocusWorld world = await open(tester);
      await tester.tap(find.byKey(LumeFocusTool.skipKey));
      await tester.pump();
      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      world.advance(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Break over'), findsOneWidget);
      expect(find.text('Session 2 of 4'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('lifecycle', () {
    testWidgets('backgrounding stops the repainting, not the elapsing', (
      WidgetTester tester,
    ) async {
      final FocusWorld world = await open(tester);
      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      world.advance(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(focusTime(tester), '24:00');

      for (final AppLifecycleState s in <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);

      // Nine minutes with the screen off.
      world.advance(const Duration(minutes: 9));
      for (final AppLifecycleState s in <AppLifecycleState>[
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(focusTime(tester), '15:00');
      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
    });

    testWidgets('a stretch that ran out in the background is settled on the '
        'way back, and not announced before', (WidgetTester tester) async {
      final FocusWorld world = await open(tester);
      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      // The framework only allows inactive -> hidden -> paused on the way
      // out and hidden -> inactive -> resumed on the way back; a direct
      // hop trips its own assertion once a real router is mounted.
      for (final AppLifecycleState s in <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump();
      world.advance(const Duration(minutes: 40));
      expect(find.text('Focus finished'), findsNothing);

      for (final AppLifecycleState s in <AppLifecycleState>[
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump();
      expect(find.text('Focus finished'), findsOneWidget);
      expect(focusTime(tester), '05:00');
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('everyone can use it', () {
    testWidgets('the time is a live region', (WidgetTester tester) async {
      await open(tester);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
        tester
            .getSemantics(find.byKey(LumeFocusTool.timeKey))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      h.dispose();
    });

    testWidgets('finishing is announced to a screen reader', (
      WidgetTester tester,
    ) async {
      final List<String> announced = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
            dynamic message,
          ) async {
            final Map<dynamic, dynamic> m = message as Map<dynamic, dynamic>;
            if (m['type'] == 'announce') {
              announced.add(
                (m['data'] as Map<dynamic, dynamic>)['message'] as String,
              );
            }
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );
      final SemanticsHandle h = tester.ensureSemantics();
      final FocusWorld world = await open(tester);
      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      world.advance(const Duration(minutes: 25));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(announced, contains('Focus finished'));
      await tester.pump(const Duration(seconds: 3));
      h.dispose();
    });

    testWidgets('skip says which phase it is leaving', (
      WidgetTester tester,
    ) async {
      await open(tester);
      final SemanticsHandle h = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byKey(LumeFocusTool.skipKey)).label,
        'Skip, Focus',
      );
      h.dispose();
    });

    testWidgets('the keyboard reaches the clock and works it', (
      WidgetTester tester,
    ) async {
      final FocusWorld world = await open(tester);
      // The control takes focus and Space presses it, without a pointer.
      Focus.of(
        tester.element(
          find
              .descendant(
                of: find.byKey(LumeFocusTool.startKey),
                matching: find.byType(Text),
              )
              .first,
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(_primary(tester), 'Pause');
      world.advance(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(focusTime(tester), '24:30');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
    });

    testWidgets('nothing overflows at 390 and twice the text', (
      WidgetTester tester,
    ) async {
      await open(tester, textScale: 2, surface: const Size(390, 6000));
      expectNoOverflow(tester);
    });

    testWidgets('it settles with motion turned down', (
      WidgetTester tester,
    ) async {
      // `pumpLume` asks the platform for less motion by default; a screen
      // with an endless animation would never settle, and this one does.
      await open(tester);
      await tester.pumpAndSettle();
      expect(find.byType(LumeFocusTool), findsOneWidget);
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'a stopped clock schedules no frames at all',
      );
    });
  });

  group('the session store', () {
    testWidgets('what the tool knows is only ever this run of the app', (
      WidgetTester tester,
    ) async {
      expect(LumeFocusController.maxCounted, const Duration(days: 999));
      final FocusWorld world = await open(tester);
      await tester.tap(find.byKey(LumeFocusTool.startKey));
      await tester.pump();
      world.advance(const Duration(minutes: 25));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(LumeFocusTool.countedKey), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));

      // A fresh pump is a fresh `ProviderScope`, and so a fresh session.
      await open(tester);
      expect(find.byKey(LumeFocusTool.emptyKey), findsOneWidget);
      expect(focusTime(tester), '25:00');
      expect(find.text('Session 1 of 4'), findsOneWidget);
    });
  });
}
