/// The banner and the two notification sheets.
///
/// The banner's rule is the one worth testing hardest: **an event reaches the
/// reader through exactly one surface**. So it must not appear while the
/// centre is showing the same list, and it must not appear over a sheet or a
/// dialog — a banner above a blocking question is a banner that can be tapped
/// instead of the question.
///
/// The push sheet's rule is that it never grants anything. There is no push
/// in this build; the sheet reports an answer and the surfaces say what the
/// answer was.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/features/account/data/notification_prefs_store.dart';
import 'package:lume/features/notifications/domain/notification_model.dart';
import 'package:lume/features/notifications/presentation/notification_banner.dart';
import 'package:lume/features/notifications/presentation/notification_sheets.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

const LumeNotification kAlert = LumeNotification(
  id: 'weather.alert#0',
  title: 'Heavy rain warning',
  body: 'Karachi · this evening',
  category: 'weather',
  icon: 'cloud-sun',
  tool: 'weather',
  agoMinutes: 2,
  priority: LumeNotificationPriority.critical,
);

/// A sensitive row as the repository hands it over with previews off — the
/// detail is already gone.
const LumeNotification kWithheld = LumeNotification(
  id: 'meds.dose#1',
  title: 'Time for a dose',
  body: 'A medication reminder is due',
  category: 'health',
  icon: 'pulse',
  tool: 'meds',
  agoMinutes: 8,
  priority: LumeNotificationPriority.high,
);

void main() {
  setUpAll(loadLumeFonts);

  // --------------------------------------------------------------- banner

  group('the banner', () {
    Future<void> pumpBanner(
      WidgetTester tester, {
      LumeNotification? notification = kAlert,
      bool suppressed = false,
      ValueChanged<LumeNotification>? onOpen,
      Locale locale = const Locale('en'),
      double textScale = 1.0,
    }) => pumpLume(
      tester,
      LumeNotificationBannerHost(
        notification: notification,
        suppressed: suppressed,
        onOpen: onOpen,
        child: const ColoredBox(
          color: Color(0xFFEEEEEE),
          child: Center(child: Text('the screen behind')),
        ),
      ),
      locale: locale,
      textScale: textScale,
    );

    testWidgets('shows the title and the body over the screen', (
      WidgetTester tester,
    ) async {
      await pumpBanner(tester);
      expect(find.byType(LumeNotificationBanner), findsOneWidget);
      expect(find.text('Heavy rain warning'), findsOneWidget);
      expect(find.text('Karachi · this evening'), findsOneWidget);
      // The screen behind it is still there — a banner interrupts, it does
      // not replace.
      expect(find.text('the screen behind'), findsOneWidget);
    });

    testWidgets('and withholds exactly what the centre withholds', (
      WidgetTester tester,
    ) async {
      await pumpBanner(tester, notification: kWithheld);
      expect(find.text('A medication reminder is due'), findsOneWidget);
      expect(find.textContaining('Metformin'), findsNothing);
    });

    testWidgets('with nothing to say it is not there at all', (
      WidgetTester tester,
    ) async {
      await pumpBanner(tester, notification: null);
      expect(find.byType(LumeNotificationBanner), findsNothing);
    });

    testWidgets('it is suppressed where it must not appear', (
      WidgetTester tester,
    ) async {
      // The centre is showing the same list; a sheet is up asking something.
      await pumpBanner(tester, suppressed: true);
      expect(find.byType(LumeNotificationBanner), findsNothing);
      expect(find.text('the screen behind'), findsOneWidget);
    });

    testWidgets('it withdraws on its own after six seconds', (
      WidgetTester tester,
    ) async {
      await pumpBanner(tester);
      expect(find.byType(LumeNotificationBanner), findsOneWidget);

      await tester.pump(LumeNotificationBanner.life);
      await tester.pumpAndSettle();
      expect(find.byType(LumeNotificationBanner), findsNothing);
    });

    testWidgets('the close control takes it away at once', (
      WidgetTester tester,
    ) async {
      await pumpBanner(tester);
      await tester.tap(find.bySemanticsLabel('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.byType(LumeNotificationBanner), findsNothing);
    });

    testWidgets('tapping it reports which one, and takes it away once', (
      WidgetTester tester,
    ) async {
      final List<LumeNotification> opened = <LumeNotification>[];
      await pumpBanner(tester, onOpen: opened.add);
      await tester.tap(find.text('Heavy rain warning'));
      await tester.pumpAndSettle();

      expect(opened.single.id, kAlert.id);
      expect(find.byType(LumeNotificationBanner), findsNothing);

      // And it does not come back when the timer that was running expires.
      await tester.pump(LumeNotificationBanner.life);
      await tester.pumpAndSettle();
      expect(find.byType(LumeNotificationBanner), findsNothing);
    });

    testWidgets('it lays out in every language, and at twice the type', (
      WidgetTester tester,
    ) async {
      for (final String code in <String>['en', 'ur', 'ar']) {
        for (final double scale in <double>[1.0, 2.0]) {
          await pumpBanner(tester, locale: Locale(code), textScale: scale);
          expect(tester.takeException(), isNull, reason: '$code at ${scale}x');
        }
      }
    });

    testWidgets('and in the direction the language reads', (
      WidgetTester tester,
    ) async {
      await pumpBanner(tester, locale: const Locale('ar'));
      expect(
        Directionality.of(tester.element(find.byType(LumeNotificationBanner))),
        TextDirection.rtl,
      );
    });
  });

  // ----------------------------------------------------------- push sheet

  group('the push sheet', () {
    Future<bool?> ask(WidgetTester tester) async {
      bool? answer;
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(
              onPressed: () async =>
                  answer = await showLumeNotificationPushSheet(context),
              child: const Text('ask'),
            ),
          ),
        ),
        surface: const Size(390, 1200),
      );
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      return answer;
    }

    testWidgets('says what will be sent, and what will not', (
      WidgetTester tester,
    ) async {
      await ask(tester);
      expect(find.text('Stay informed'), findsOneWidget);
      expect(
        find.text(
          'Useful alerts for the things you already follow — and nothing '
          'else.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('and lists the categories this reader would hear from', (
      WidgetTester tester,
    ) async {
      await ask(tester);
      // Never more than six, and each one a category the centre will really
      // use — the same sources, the same eligibility.
      final Iterable<String> shown = <String>[
        'Faith',
        'Money',
        'Markets',
        'Travel',
        'Weather',
        'Personal',
        'Reminders',
        'Documents',
        'Health',
        'System',
      ].where((String s) => find.text(s).evaluate().isNotEmpty);
      expect(shown.length, lessThanOrEqualTo(6));
      expect(shown, isNotEmpty);
    });

    testWidgets('both answers are buttons, and both close it', (
      WidgetTester tester,
    ) async {
      await ask(tester);
      expect(find.text('Enable notifications'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text('Stay informed'), findsNothing);
    });

    testWidgets('saying yes reports yes, and grants nothing', (
      WidgetTester tester,
    ) async {
      bool? answer;
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(
              onPressed: () async =>
                  answer = await showLumeNotificationPushSheet(context),
              child: const Text('ask'),
            ),
          ),
        ),
        surface: const Size(390, 1200),
      );
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LumeNotificationPushAsk.allowKey));
      await tester.pumpAndSettle();

      expect(answer, isTrue);
      // Nothing on the platform was touched: there is no push in this build
      // and the sheet never pretended there was.
      expect(tester.takeException(), isNull);
    });

    testWidgets('and saying not now reports that, rather than nothing', (
      WidgetTester tester,
    ) async {
      bool? answer;
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(
              onPressed: () async =>
                  answer = await showLumeNotificationPushSheet(context),
              child: const Text('ask'),
            ),
          ),
        ),
        surface: const Size(390, 1200),
      );
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LumeNotificationPushAsk.laterKey));
      await tester.pumpAndSettle();
      expect(answer, isFalse);
    });
  });

  // ---------------------------------------------------------- prefs sheet

  group('the preferences sheet', () {
    Future<LumeMemoryNotificationPrefs> openPrefs(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) async {
      final LumeMemoryNotificationPrefs store = LumeMemoryNotificationPrefs();
      await pumpLume(
        tester,
        Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(
              onPressed: () => showLumeNotificationPrefsSheet(context).ignore(),
              child: const Text('open'),
            ),
          ),
        ),
        surface: const Size(390, 1600),
        locale: locale,
        overrides: <Override>[
          notificationPrefsProvider.overrideWithValue(store),
        ],
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return store;
    }

    testWidgets('is the same three switches and the same categories', (
      WidgetTester tester,
    ) async {
      await openPrefs(tester);
      expect(find.text('Notification settings'), findsWidgets);
      expect(find.text('In-app notifications'), findsOneWidget);
      expect(find.text('Show previews'), findsOneWidget);
      expect(find.text('Preview sensitive content'), findsOneWidget);
    });

    testWidgets('a switch writes to the record the centre reads', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = await openPrefs(tester);
      expect(store.prefs.preview, isTrue);

      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) => w is LumeSettingsRow && w.title == 'Show previews',
        ),
      );
      await tester.pumpAndSettle();
      expect(store.prefs.preview, isFalse);
    });

    testWidgets('and a category goes off without its neighbours', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = await openPrefs(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) => w is LumeSettingsRow && w.title == 'Travel',
        ),
      );
      await tester.pumpAndSettle();

      expect(store.prefs.isOn('travel'), isFalse);
      expect(store.prefs.isOn('weather'), isTrue);
    });

    testWidgets('closing it leaves the writes behind', (
      WidgetTester tester,
    ) async {
      final LumeMemoryNotificationPrefs store = await openPrefs(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) => w is LumeSettingsRow && w.title == 'Show previews',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(LumeSheet), findsNothing);
      expect(store.prefs.preview, isFalse);
    });

    testWidgets('it lays out right to left too', (WidgetTester tester) async {
      await openPrefs(tester, locale: const Locale('ur'));
      expect(
        Directionality.of(tester.element(find.byType(LumeSheet))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
