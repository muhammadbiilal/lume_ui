/// Quiet hours, on both of their doors.
///
/// The reference draws the account's Notifications route and the notification
/// centre's preferences sheet from one function, so both carry the switch and
/// its "from" and "Until" steppers. Flutter builds both from
/// `lumeQuietHoursRows` over the one preference store: a window stepped on
/// one door is the window the other shows. The store is the nondurable
/// fixture (`LumeMemoryNotificationPrefs`), and says so.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icon.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/features/account/data/notification_prefs_store.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/domain/notification_prefs.dart';
import 'package:lume/features/account/presentation/account_host.dart';
import 'package:lume/features/account/presentation/account_parts.dart';
import 'package:lume/features/notifications/presentation/notification_sheets.dart';

import '../../helpers/load_fonts.dart';
import 'account_harness.dart';

const Size kTall = Size(390, 6000);

void main() {
  setUpAll(loadLumeFonts);

  Future<LumeMemoryNotificationPrefs> openRoute(
    WidgetTester tester, {
    LumeNotificationPrefs initial = const LumeNotificationPrefs(),
    Locale locale = const Locale('en'),
    double textScale = 1.0,
  }) async {
    final LumeMemoryNotificationPrefs store = LumeMemoryNotificationPrefs(
      initial,
    );
    await pumpAccountHost(
      tester,
      route: LumeAccountRoute.notifications,
      gate: await bootedGate(),
      notify: store,
      surface: kTall,
      locale: locale,
      textScale: textScale,
    );
    return store;
  }

  List<LumeStepper> steppers(WidgetTester tester) => tester
      .widgetList<LumeStepper>(find.byType(LumeStepper))
      .toList(growable: false);

  group('the rule', () {
    test('an hour at a time, round the clock in both directions', () {
      const LumeNotificationPrefs p = LumeNotificationPrefs(
        quietFrom: 23,
        quietTo: 0,
      );
      expect(p.quietStepped(from: true, by: 1).quietFrom, 0);
      expect(p.quietStepped(from: false, by: -1).quietTo, 23);
      expect(p.quietStepped(from: true, by: -1).quietFrom, 22);
      // Neither bound is held against the other: a window may cross midnight.
      expect(p.quietStepped(from: false, by: 1).quietTo, 1);
      expect(p.quietStepped(from: true, by: 1).quietTo, 0);
    });
  });

  group('the account route', () {
    testWidgets('carries the switch and both steppers', (
      WidgetTester tester,
    ) async {
      await openRoute(tester);
      expect(find.text('Quiet hours'), findsWidgets);
      expect(find.text('from'), findsOneWidget);
      expect(find.text('Until'), findsOneWidget);
      expect(steppers(tester), hasLength(2));
    });

    testWidgets('steps and wraps, and the store hears each step', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = await openRoute(tester);
      expect(store.prefs.quietFrom, 22);
      for (final int want in <int>[23, 0, 1]) {
        await tester.tap(find.bySemanticsLabel('Later from'));
        await tester.pumpAndSettle();
        expect(store.prefs.quietFrom, want);
      }
      for (final int want in <int>[6, 5]) {
        await tester.tap(find.bySemanticsLabel('Earlier Until'));
        await tester.pumpAndSettle();
        expect(store.prefs.quietTo, want);
      }
    });

    testWidgets('and midnight steps back to eleven', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = await openRoute(
        tester,
        initial: const LumeNotificationPrefs(quietTo: 0),
      );
      await tester.tap(find.bySemanticsLabel('Earlier Until'));
      await tester.pumpAndSettle();
      expect(store.prefs.quietTo, 23);
    });

    testWidgets('the steppers stay live with quiet hours off', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = await openRoute(tester);
      expect(store.prefs.quiet, isFalse);
      for (final LumeStepper s in steppers(tester)) {
        expect(s.onIncrement, isNotNull);
        expect(s.onDecrement, isNotNull);
      }
    });

    testWidgets('each button is heard on its own', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openRoute(tester);
      for (final String label in <String>[
        'Earlier from',
        'Later from',
        'Earlier Until',
        'Later Until',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      }
      handle.dispose();
    });
  });

  group('one store, two doors', () {
    testWidgets('a step on the route is the value the sheet opens on', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = await openRoute(tester);
      await tester.tap(find.bySemanticsLabel('Later from'));
      await tester.pumpAndSettle();
      final String onRoute = steppers(tester).first.value;

      // The sheet, raised over the route.
      showLumeNotificationPrefsSheet(
        tester.element(find.byType(LumeAccountHost)),
      ).ignore();
      await tester.pumpAndSettle();
      // Four steppers now: the route's two, then the sheet's "from" and
      // "Until". The sheet's "from" is the third.
      expect(steppers(tester), hasLength(4));
      expect(steppers(tester)[2].value, onRoute);
      expect(store.prefs.quietFrom, 23);
    });

    testWidgets('and a step in the sheet is on the route when it closes', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = await openRoute(tester);
      showLumeNotificationPrefsSheet(
        tester.element(find.byType(LumeAccountHost)),
      ).ignore();
      await tester.pumpAndSettle();

      final Finder later = find.bySemanticsLabel('Later from').last;
      await tester.ensureVisible(later);
      await tester.pumpAndSettle();
      await tester.tap(later);
      await tester.pumpAndSettle();
      // The sheet's "from", after the route's two steppers.
      final String inSheet = steppers(tester)[2].value;
      expect(store.prefs.quietFrom, 23);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LumeStepper), findsNWidgets(2));
      expect(steppers(tester).first.value, inSheet);
    });
  });

  group('measured against the reference', () {
    // `measure_destinations.mjs --screen profile --route notifications`,
    // with `stepper` and `stepper.row` as targets: the "from" row and its
    // pill, wherever the page puts them.
    Map<String, dynamic> bounds() =>
        (jsonDecode(
                  File(
                    'docs/conversion_archive/measurements/'
                    'account_notifications_390x844_light_en.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)['bounds']
            as Map<String, dynamic>;

    testWidgets('the row, the pill, and where the pill ends', (
      WidgetTester tester,
    ) async {
      await openRoute(tester, initial: const LumeNotificationPrefs());
      final Map<String, dynamic> b = bounds();
      final Map<String, dynamic> row = b['stepper.row'] as Map<String, dynamic>;
      final Map<String, dynamic> pill = b['stepper'] as Map<String, dynamic>;

      final Rect r = tester.getRect(find.byType(LumeStepperRow).first);
      final Rect s = tester.getRect(find.byType(LumeStepper).first);
      // The widget's box reaches `overhang` past the pill at each end, for
      // the buttons' 44-point targets.
      final double pillLeft = s.left + LumeStepper.overhang;
      final double pillRight = s.right - LumeStepper.overhang;

      expect(r.height, closeTo((row['height'] as num).toDouble(), 1));
      expect(r.left, closeTo((row['x'] as num).toDouble(), 1));
      expect(r.width, closeTo((row['width'] as num).toDouble(), 1));
      // The stepper's box is its 44-point targets; the pill is 32 inside it,
      // and sits as far below the row's top as the reference's does.
      expect(s.height, LumeStepper.targetSize);
      final double pillTop =
          s.top + (LumeStepper.targetSize - LumeStepper.height) / 2;
      expect(
        pillTop - r.top,
        closeTo(
          (pill['y'] as num).toDouble() - (row['y'] as num).toDouble(),
          1,
        ),
      );
      expect(LumeStepper.height, (pill['height'] as num).toDouble());
      expect(
        pillRight - pillLeft,
        closeTo((pill['width'] as num).toDouble(), 1.5),
      );
      expect(
        pillRight,
        closeTo(
          (pill['x'] as num).toDouble() + (pill['width'] as num).toDouble(),
          1.5,
        ),
      );
      expect(steppers(tester).first.value, pill['text']);
    });
  });

  group('direction and scale', () {
    testWidgets('in Urdu the steppers read from the right', (
      WidgetTester tester,
    ) async {
      await openRoute(tester, locale: const Locale('ur'));
      final Finder stepper = find.byType(LumeStepper).first;
      Finder glyph(String name) => find.descendant(
        of: stepper,
        matching: find.byWidgetPredicate(
          (Widget w) => w is LumeIcon && w.name == name,
        ),
      );
      // Decrease sits at the reading start — the right-hand end in RTL.
      expect(
        tester.getCenter(glyph(LumeIcons.minus)).dx,
        greaterThan(tester.getCenter(glyph(LumeIcons.plus)).dx),
      );
    });

    testWidgets('at twice the type size nothing overflows', (
      WidgetTester tester,
    ) async {
      await openRoute(tester, textScale: 2);
      expect(steppers(tester), hasLength(2));
      expect(tester.takeException(), isNull);
    });
  });
}
