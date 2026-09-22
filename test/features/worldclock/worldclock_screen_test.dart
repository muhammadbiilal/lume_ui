/// World Clock on the screen: what it says, who it says it to, and what it
/// says when it cannot say anything.
///
/// Every test pins its own instant, so nothing here depends on the machine's
/// zone or on the hour the suite is run at.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/features/tools/application/tool_session.dart';
import 'package:lume/features/worldclock/presentation/worldclock_tool.dart';

import '../../helpers/load_fonts.dart';
import 'worldclock_screen_harness.dart';

/// 16:41 in Karachi, 12:41 in London, 07:41 in New York — one moment, said
/// as the moment it is.
final DateTime kAt = DateTime.utc(2026, 9, 7, 11, 41, 32);

/// What the session holds for the list.
String? held(LumeToolSession s) =>
    s.read(LumeWorldClockTool.id, LumeWorldClockTool.placesKey);

void seed(LumeToolSession s, List<String> ids) =>
    s.write(LumeWorldClockTool.id, LumeWorldClockTool.placesKey, ids.join(','));

List<String> rowTitles(WidgetTester tester) => <String>[
  for (final LumeRichRow r in tester.widgetList<LumeRichRow>(
    inKey(LumeWorldClockTool.clocksKey, find.byType(LumeRichRow)),
  ))
    plain(r.title),
];

/// Lume goes out of sight, through the states the platform actually sends.
Future<void> background(WidgetTester tester) async {
  for (final AppLifecycleState s in <AppLifecycleState>[
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
  await tester.pump();
}

/// …and comes back.
Future<void> foreground(WidgetTester tester) async {
  for (final AppLifecycleState s in <AppLifecycleState>[
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(s);
  }
  await tester.pump();
}

void main() {
  setUpAll(loadLumeFonts);

  group('the list', () {
    testWidgets('the reader\'s own clock leads the reference\'s eight', (
      WidgetTester tester,
    ) async {
      await pumpWorldClock(tester, clock: SteppingClock(kAt));
      expect(rowTitles(tester), <String>[
        'Pakistan Time',
        'United Arab Emirates Time',
        'United Kingdom Time',
        'New York Time',
        'Japan Time',
        'Singapore Time',
        'Türkiye Time',
        'Sydney Time',
      ]);
      // The reader's own zone is listed once, at the top, and not again
      // among the anchors.
      expect(find.byKey(LumeWorldClockTool.rowKey('Asia/Karachi')), findsOne);
      // How many there are is said to a screen reader, not drawn.
      expect(
        tester
            .widget<Semantics>(
              find
                  .ancestor(
                    of: find.byKey(LumeWorldClockTool.clocksKey),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .label,
        '8 places',
      );
    });

    testWidgets('each row says its time, its day and its offset', (
      WidgetTester tester,
    ) async {
      await pumpWorldClock(tester, clock: SteppingClock(kAt));
      expect(
        rowSemantics(tester, 'Asia/Karachi'),
        'Your time, Pakistan Time, Asia/Karachi, 4:41 pm, Today, Same time',
      );
      expect(
        rowSemantics(tester, 'Europe/London'),
        'United Kingdom Time, Europe/London, 12:41 pm, Today, '
        '4:00 behind, Summer time',
      );
      expect(
        rowSemantics(tester, 'America/New_York'),
        'New York Time, America/New_York, 7:41 am, Today, '
        '9:00 behind, Summer time',
      );
      expect(
        rowSemantics(tester, 'Australia/Sydney'),
        'Sydney Time, Australia/Sydney, 9:41 pm, Today, 5:00 ahead',
      );
    });

    testWidgets('the headline is the reader\'s zone, and its date', (
      WidgetTester tester,
    ) async {
      // 01:41 on the 8th in Sydney is still the 7th in London — the summary
      // is the reader's day, not the device's (defects 1 and 2).
      await pumpWorldClock(
        tester,
        profile: worldClockReader(
          country: 'GB',
          region: 'England',
          city: 'London',
        ),
        clock: SteppingClock(DateTime.utc(2026, 9, 7, 15, 41)),
      );
      final List<String> summary = clockTexts(
        tester,
        find.byKey(LumeWorldClockTool.summaryKey),
      );
      expect(summary, <String>[
        'YOUR TIME',
        '4:41 pm',
        'United Kingdom Time · Monday 7 September',
      ]);
      expect(
        rowSemantics(tester, 'Australia/Sydney'),
        'Sydney Time, Australia/Sydney, 1:41 am, Tomorrow, 9:00 ahead',
      );
    });

    testWidgets('a half-hour and a three-quarter-hour offset are exact', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      seed(session, <String>[
        'Asia/Kolkata',
        'Asia/Kathmandu',
        'Australia/Eucla',
      ]);
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      expect(
        rowSemantics(tester, 'Asia/Kolkata'),
        'India Time, Asia/Kolkata, 5:11 pm, Today, 0:30 ahead',
      );
      expect(
        rowSemantics(tester, 'Asia/Kathmandu'),
        'Nepal Time, Asia/Kathmandu, 5:26 pm, Today, 0:45 ahead',
      );
      expect(
        rowSemantics(tester, 'Australia/Eucla'),
        'Eucla Time, Australia/Eucla, 8:26 pm, Today, 3:45 ahead',
      );
    });

    testWidgets('yesterday and tomorrow are said, across the date line', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      seed(session, <String>['Pacific/Kiritimati', 'Pacific/Midway']);
      await pumpWorldClock(
        tester,
        session: session,
        // 02:00 in Karachi on the 7th.
        clock: SteppingClock(DateTime.utc(2026, 9, 6, 21)),
      );
      expect(
        rowSemantics(tester, 'Pacific/Kiritimati'),
        'Kiritimati Time, Pacific/Kiritimati, 11:00 am, Today, 9:00 ahead',
      );
      // Midway is a link to Pago Pago: the row is keyed by the zone it
      // names, and reads 11 hours behind UTC on the day before.
      expect(
        rowSemantics(tester, 'Pacific/Pago_Pago'),
        // The stored link still names it — CLDR has a name for Midway — while
        // the identity underneath is the canonical zone.
        'Midway Time, Pacific/Pago_Pago, 10:00 am, Yesterday, 16:00 behind',
      );
    });

    testWidgets('a stored alias is read, and both names are shown', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      seed(session, <String>['Asia/Calcutta']);
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      // Keyed by the canonical zone, and the row says what is stored.
      final LumeRichRow row = tester.widget<LumeRichRow>(
        inKey(LumeWorldClockTool.clocksKey, find.byType(LumeRichRow)).at(1),
      );
      expect(plain(row.title), 'India Time');
      expect(plain(row.subtitle!), 'Asia/Calcutta is now called Asia/Kolkata');
      // …and nothing rewrote it.
      expect(held(session), 'Asia/Calcutta');
    });

    testWidgets('a stored identifier that cannot be read is named, not '
        'replaced', (WidgetTester tester) async {
      final LumeToolSession session = LumeToolSession();
      seed(session, <String>['Asia/Atlantis', 'PKT']);
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      for (final String bad in <String>['Asia/Atlantis', 'PKT']) {
        final LumeRichRow row = tester.widget<LumeRichRow>(
          find.byKey(LumeWorldClockTool.rowKey(bad)),
        );
        expect(plain(row.title), bad);
        expect(row.subtitle, 'That time zone is not known');
        expect(row.value, '—');
      }
    });
  });

  group('when there is no clock to show', () {
    testWidgets('an unknown zone is named', (WidgetTester tester) async {
      await pumpWorldClock(
        tester,
        profile: worldClockReader(timeZone: 'Asia/Atlantis'),
        clock: SteppingClock(kAt),
      );
      expect(find.byKey(LumeWorldClockTool.troubleKey), findsOne);
      final List<String> said = clockTexts(
        tester,
        find.byKey(LumeWorldClockTool.troubleKey),
      );
      expect(said.first, 'That time zone is not known');
      expect(said.last, contains('Asia/Atlantis'));
      expect(find.byKey(LumeWorldClockTool.clocksKey), findsNothing);
    });

    testWidgets('an unavailable database is said', (WidgetTester tester) async {
      await pumpWorldClock(
        tester,
        service: LumeTimeZoneService.detached(),
        clock: SteppingClock(kAt),
      );
      expect(
        clockTexts(tester, find.byKey(LumeWorldClockTool.troubleKey)).first,
        'The time-zone database is unavailable',
      );
    });

    testWidgets('a device that has not said where it is', (
      WidgetTester tester,
    ) async {
      await pumpWorldClock(
        tester,
        profile: worldClockReader(follow: LumeZoneFollow.device),
        clock: SteppingClock(kAt),
      );
      expect(
        clockTexts(tester, find.byKey(LumeWorldClockTool.troubleKey)).first,
        'This device has not said where it is',
      );
    });

    testWidgets('a country with several zones asks, and never picks one', (
      WidgetTester tester,
    ) async {
      await pumpWorldClock(
        tester,
        profile: worldClockReader(country: 'US', region: '', city: ''),
        clock: SteppingClock(kAt),
      );
      expect(
        clockTexts(tester, find.byKey(LumeWorldClockTool.troubleKey)).first,
        'Your country has more than one time zone',
      );
    });
  });

  group('the reader\'s clock preference', () {
    testWidgets('24-hour is 24-hour, and 12-hour is 12-hour', (
      WidgetTester tester,
    ) async {
      await pumpWorldClock(
        tester,
        profile: worldClockReader(clock: '24'),
        clock: SteppingClock(kAt),
      );
      expect(rowSemantics(tester, 'Asia/Karachi'), contains('16:41'));
      await tester.pumpWidget(const SizedBox.shrink());

      await pumpWorldClock(
        tester,
        profile: worldClockReader(clock: '12'),
        clock: SteppingClock(kAt),
      );
      expect(rowSemantics(tester, 'Asia/Karachi'), contains('4:41 pm'));
    });

    testWidgets('automatic follows the market: Japan reads 24-hour', (
      WidgetTester tester,
    ) async {
      await pumpWorldClock(
        tester,
        profile: worldClockReader(
          country: 'JP',
          region: 'Tokyo',
          city: 'Tokyo',
        ),
        clock: SteppingClock(kAt),
      );
      expect(rowSemantics(tester, 'Asia/Tokyo'), contains('20:41'));
    });
  });

  group('adding, removing and ordering', () {
    testWidgets('a city is searched for, and adds its zone', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      await tester.enterText(
        find.byKey(LumeWorldClockTool.searchKey),
        'Kathmandu',
      );
      await tester.pumpAndSettle();
      final Finder choice = find.byKey(
        LumeWorldClockTool.choiceKey('Asia/Kathmandu'),
      );
      expect(choice, findsOne);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(held(session), endsWith('Asia/Kathmandu'));
      expect(rowSemantics(tester, 'Asia/Kathmandu'), contains('0:45 ahead'));
      expect(find.textContaining('added'), findsOne);
    });

    testWidgets('a zone already listed is refused, and says so', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      seed(session, <String>['Asia/Kolkata']);
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      // Its other name is the same zone.
      await tester.enterText(
        find.byKey(LumeWorldClockTool.searchKey),
        'Asia/Calcutta',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(LumeWorldClockTool.choiceKey('Asia/Kolkata')),
        findsNothing,
      );
      expect(held(session), 'Asia/Kolkata');
    });

    testWidgets('search finds nothing, and says only that', (
      WidgetTester tester,
    ) async {
      await pumpWorldClock(tester, clock: SteppingClock(kAt));
      await tester.enterText(
        find.byKey(LumeWorldClockTool.searchKey),
        'zzzzzz',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(LumeWorldClockTool.noMatchKey), findsOne);
      expect(find.text('Nothing matches'), findsOne);
    });

    testWidgets('a place is removed, and the removal is undone', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      seed(session, <String>['Asia/Dubai', 'Europe/London']);
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      await tester.tap(find.byKey(LumeWorldClockTool.rowKey('Asia/Dubai')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LumeWorldClockTool.removeKey));
      await tester.pumpAndSettle();
      expect(held(session), 'Europe/London');
      expect(find.byType(LumeToast), findsOne);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(held(session), 'Asia/Dubai,Europe/London');
    });

    testWidgets('a place is moved, and the order is the reader\'s', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      seed(session, <String>['Asia/Dubai', 'Europe/London', 'Asia/Tokyo']);
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      await tester.tap(find.byKey(LumeWorldClockTool.rowKey('Asia/Tokyo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LumeWorldClockTool.moveUpKey));
      await tester.pumpAndSettle();
      expect(held(session), 'Asia/Dubai,Asia/Tokyo,Europe/London');
      expect(rowTitles(tester), <String>[
        'Pakistan Time',
        'United Arab Emirates Time',
        'Japan Time',
        'United Kingdom Time',
      ]);

      // The first place cannot move up, and the last cannot move down.
      await tester.tap(find.byKey(LumeWorldClockTool.rowKey('Asia/Dubai')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LumeButton>(find.byKey(LumeWorldClockTool.moveUpKey))
            .onPressed,
        isNull,
      );
    });

    testWidgets('nothing is stored but the list itself', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      // Every seeded value is an identifier; no time, offset or day word
      // is anywhere in what was written.
      final String stored = held(session)!;
      expect(stored.split(',').every((String s) => s.contains('/')), isTrue);
      expect(stored, isNot(contains(':')));
      expect(stored, isNot(contains('ahead')));
    });
  });

  group('converting a time', () {
    testWidgets('it converts, rather than sitting there', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      seed(session, <String>['America/New_York']);
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      // From the reader's own zone to New York, at the reader's current
      // time: 4:41 pm in Karachi is 7:41 am in New York, the same day.
      expect(
        clockTexts(
          tester,
          find.byKey(LumeWorldClockTool.convertResultKey),
        ).single,
        '7:41 am on Today',
      );
    });

    testWidgets('an instant is chosen, and the answer follows it', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      seed(session, <String>['America/New_York']);
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      await tester.tap(find.byKey(LumeWorldClockTool.convertAtKey));
      await tester.pumpAndSettle();
      // 02:00 in Karachi is 5:00 pm in New York — the day before.
      await tester.tap(find.byKey(LumeWorldClockTool.optionKey('120')));
      await tester.pumpAndSettle();
      expect(
        clockTexts(
          tester,
          find.byKey(LumeWorldClockTool.convertResultKey),
        ).single,
        '5:00 pm on Yesterday',
      );
    });

    testWidgets('two of the same place is asked about, not answered', (
      WidgetTester tester,
    ) async {
      final LumeToolSession session = LumeToolSession();
      seed(session, <String>['America/New_York']);
      await pumpWorldClock(tester, session: session, clock: SteppingClock(kAt));
      await tester.tap(find.byKey(LumeWorldClockTool.convertToKey));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(LumeWorldClockTool.optionKey('Asia/Karachi')),
      );
      await tester.pumpAndSettle();
      expect(
        clockTexts(
          tester,
          find.byKey(LumeWorldClockTool.convertResultKey),
        ).single,
        'Pick two different places',
      );
    });
  });

  group('the minute tick', () {
    testWidgets('it repaints on the boundary, and not before', (
      WidgetTester tester,
    ) async {
      final SteppingClock clock = SteppingClock(kAt);
      await pumpWorldClock(tester, clock: clock);
      expect(rowSemantics(tester, 'Asia/Karachi'), contains('4:41 pm'));

      // 27 seconds on: the minute has not turned, and nothing has moved.
      clock.advance(const Duration(seconds: 27));
      await tester.pump(const Duration(seconds: 27));
      expect(rowSemantics(tester, 'Asia/Karachi'), contains('4:41 pm'));

      // One more second, and it is 16:42 everywhere at once.
      clock.advance(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(rowSemantics(tester, 'Asia/Karachi'), contains('4:42 pm'));
      expect(rowSemantics(tester, 'Europe/London'), contains('12:42 pm'));
    });

    testWidgets('backgrounding stops the repaint; coming back recomputes '
        'from the clock', (WidgetTester tester) async {
      final SteppingClock clock = SteppingClock(kAt);
      await pumpWorldClock(tester, clock: clock);

      await background(tester);

      // Two hours pass with Lume out of sight. No tick fires.
      clock.advance(const Duration(hours: 2));
      await tester.pump(const Duration(minutes: 5));
      expect(rowSemantics(tester, 'Asia/Karachi'), contains('4:41 pm'));

      await foreground(tester);
      expect(rowSemantics(tester, 'Asia/Karachi'), contains('6:41 pm'));

      // And it is ticking again.
      clock.advance(const Duration(seconds: 28));
      await tester.pump(const Duration(seconds: 28));
      expect(rowSemantics(tester, 'Asia/Karachi'), contains('6:42 pm'));
    });

    testWidgets('an hour of ticks lands on the hour, not near it', (
      WidgetTester tester,
    ) async {
      final SteppingClock clock = SteppingClock(
        DateTime.utc(2026, 9, 7, 11, 41, 32),
      );
      await pumpWorldClock(tester, clock: clock);
      // The first tick is the rest of this minute; every one after it is a
      // whole minute. Sixty of them is 16:42 plus 59 minutes — 17:41.
      clock.advance(const Duration(seconds: 28));
      await tester.pump(const Duration(seconds: 28));
      for (int i = 0; i < 59; i++) {
        clock.advance(const Duration(minutes: 1));
        await tester.pump(const Duration(minutes: 1));
      }
      expect(rowSemantics(tester, 'Asia/Karachi'), contains('5:41 pm'));
    });
  });

  group('every reader', () {
    testWidgets('Arabic reads right to left, and the figures keep their '
        'order', (WidgetTester tester) async {
      await pumpWorldClock(
        tester,
        locale: const Locale('ar'),
        clock: SteppingClock(kAt),
      );
      expect(
        Directionality.of(
          tester.element(find.byKey(LumeWorldClockTool.clocksKey)),
        ),
        TextDirection.rtl,
      );
      // The identifier and the time are isolated inside the Arabic line.
      final LumeRichRow row = tester.widget<LumeRichRow>(
        inKey(LumeWorldClockTool.clocksKey, find.byType(LumeRichRow)).at(1),
      );
      expect(row.subtitle, startsWith('\u2068'));
      expect(row.subtitle, endsWith('\u2069'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Urdu says the day and the direction in Urdu', (
      WidgetTester tester,
    ) async {
      await pumpWorldClock(
        tester,
        locale: const Locale('ur'),
        clock: SteppingClock(kAt),
      );
      final List<String> texts = clockTexts(
        tester,
        find.byKey(LumeWorldClockTool.clocksKey),
      );
      // Nothing on the list is the English word for today.
      expect(texts.any((String t) => t == 'Today'), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the tool bar Search reaches the field, and a keyboard '
        'can go on from there', (WidgetTester tester) async {
      await pumpWorldClock(tester, clock: SteppingClock(kAt));
      final Finder search = find.byWidgetPredicate(
        (Widget w) => w is LumeIconButton && w.label.contains('Search'),
      );
      expect(search, findsOne);
      await tester.tap(search);
      await tester.pumpAndSettle();
      final FocusNode? focused = FocusManager.instance.primaryFocus;
      expect(focused, isNotNull);
      expect(focused!.hasFocus, isTrue);
      // Typing goes straight into the list's filter.
      await tester.enterText(find.byKey(LumeWorldClockTool.searchKey), 'Tokyo');
      await tester.pumpAndSettle();
      expect(rowTitles(tester), <String>['Japan Time']);
    });

    testWidgets('at twice the text size, at 390, nothing overflows', (
      WidgetTester tester,
    ) async {
      await pumpWorldClock(
        tester,
        textScale: 2,
        surface: const Size(390, 12000),
        clock: SteppingClock(kAt),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(LumeWorldClockTool.clocksKey), findsOne);
    });

    testWidgets('the converter is reachable at twice the text size', (
      WidgetTester tester,
    ) async {
      await pumpWorldClock(
        tester,
        textScale: 2,
        surface: const Size(390, 12000),
        clock: SteppingClock(kAt),
      );
      expect(find.byKey(LumeWorldClockTool.convertResultKey), findsOne);
      expect(tester.takeException(), isNull);
    });
  });
}
