/// The Trains tool, on screen.
///
/// Pumped directly rather than through the router — see `trains_harness.dart`
/// for why. The literal English strings this file asserts against
/// (`trainsFind`, `trainsRunning`, `trainsDelayed`, `trainsPlatform`,
/// `trainsFareCaption`, `trainsSelected`, `trainsSpeed`, `trainsNextStop`,
/// `trainsDelay`, `trainsMap`, `trainsStops`, `trainsActual`,
/// `trainsScheduled`, `trainsFares`, `trainsClass`, `trainsFare`,
/// `trainsSeats`, `trainsRemind`, `trainsReminded`, `trainsSearching`,
/// `trainsNoMatch`, `trainsNoMatchText`, `trainsShareText`) are exactly what
/// this tool's report hands to
/// whoever adds them to `app_en.arb` — a mismatch there is a mismatch here
/// too. Every other string here (`trainsFrom`, `trainsTo`,
/// `trainsStatusOnTime`, `trainsStatusLate`, `trainsStatusDeparted`,
/// `trainsDuration`, `trainsUnavailableTitle`) already exists: the Trains
/// destination (`trains_screen.dart`) reads the same keys, so a service
/// cannot say one thing there and another here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/platform/lume_share.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_journey.dart';
import 'package:lume/core/widgets/lume/lume_map.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_progress.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_share_card.dart';
import 'package:lume/core/widgets/lume/lume_state.dart';
import 'package:lume/core/widgets/lume/lume_summary.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/features/trains/presentation/trains_tool.dart';
import 'package:lume/l10n/app_localizations.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import 'trains_harness.dart';

String editableTextIn(WidgetTester tester, Key key) => tester
    .widget<EditableText>(
      find.descendant(of: find.byKey(key), matching: find.byType(EditableText)),
    )
    .controller
    .text;

List<LumeRichRow> boardRows(WidgetTester tester) => tester
    .widgetList<LumeRichRow>(
      find.descendant(
        of: find.byKey(LumeTrainsTool.boardKey),
        matching: find.byType(LumeRichRow),
      ),
    )
    .toList();

void main() {
  setUpAll(loadLumeFonts);

  group('the departures list — the roster, shared with the destination', () {
    testWidgets('five rows, in the reference’s order, 5UP selected', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester);
      final List<LumeRichRow> rows = boardRows(tester);
      expect(rows.map((LumeRichRow r) => r.title).toList(), <String>[
        'Green Line Express',
        'Tezgam Express',
        'Karakoram Express',
        'Shalimar Express',
        'Pakistan Express',
      ]);
      expect(rows.first.selected, isTrue);
      expect(rows.first.logo, '5');
      expect(rows.first.subtitle, 'Karachi Cantt → Islamabad');
      expect(rows.first.badge!.tone, LumeBadgeTone.ok);
      expect(rows[1].badge!.tone, LumeBadgeTone.late_);
      expect(rows.first.valueSub, 'from');
    });

    testWidgets('the from/to fields mirror the selected service, read-only', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester);
      expect(editableTextIn(tester, LumeTrainsTool.searchKey), 'Karachi Cantt');
      final LumeToolField to = tester
          .widgetList<LumeToolField>(find.byType(LumeToolField))
          .last;
      expect(to.value, 'Islamabad');
      expect(to.enabled, isFalse);
    });

    testWidgets('"Find trains" always shows the same toast (C73)', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester);
      final Finder findButton = find.text('Find trains');
      await tester.ensureVisible(findButton);
      await tester.tap(findButton);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Searching services'),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('the status filter', () {
    testWidgets('Delayed narrows the board to the two late services', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester);
      // 'Delayed' also badges a late service's own row — tap the filter
      // bar's own chip, by scoping to its key.
      await tester.tap(
        find.descendant(
          of: find.byKey(LumeTrainsTool.filterKey),
          matching: find.text('Delayed'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        boardRows(tester).map((LumeRichRow r) => r.title).toList(),
        <String>['Tezgam Express', 'Pakistan Express'],
      );
    });

    testWidgets('On time narrows the board to on-time and departed', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester);
      // 'On time' also badges rows and the selected service's own detail —
      // tap the filter bar's own chip, by scoping to its key.
      await tester.tap(
        find.descendant(
          of: find.byKey(LumeTrainsTool.filterKey),
          matching: find.text('On time'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        boardRows(tester).map((LumeRichRow r) => r.title).toList(),
        <String>['Green Line Express', 'Karakoram Express', 'Shalimar Express'],
      );
    });
  });

  group('a train’s detail view — journey, map, stops and fares', () {
    testWidgets('selecting a service updates the journey and the map', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester);
      final Finder row = find.text('Tezgam Express');
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.text('Tezgam Express'), findsWidgets);
      final LumeJourney journey = tester.widget<LumeJourney>(
        find.byKey(LumeTrainsTool.journeyKey),
      );
      expect(journey.fromCode, 'KYC');
      expect(journey.from, 'Karachi Cantt');
      expect(journey.toCode, 'RWP');
      expect(journey.to, 'Rawalpindi');
      expect(journey.progress, 0.71);

      final LumeMap map = tester.widget<LumeMap>(
        find.byKey(LumeTrainsTool.mapKey),
      );
      expect(map.caption, 'Karachi Cantt → Rawalpindi');
      expect(map.pins, hasLength(3));
      expect(map.pins[1].active, isTrue);
      expect(map.pins[1].label, 'Tezgam Express');

      final List<LumeMetric> metrics = tester
          .widgetList<LumeMetric>(
            find.descendant(
              of: find.byKey(LumeTrainsTool.detailMetricsKey),
              matching: find.byType(LumeMetric),
            ),
          )
          .toList();
      expect(metrics[1].value, 'Khanewal Junction');
      expect(metrics[2].value, '35 min late');
    });

    testWidgets('the station timeline is the one fixed list (C73)', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester);
      final LumeTimeline tl = tester.widget<LumeTimeline>(
        find.byKey(LumeTrainsTool.stopsKey),
      );
      expect(
        tl.entries.map((LumeTimelineEntry e) => e.title).toList(),
        <String>[
          'Karachi Cantt',
          'Hyderabad Junction',
          'Rohri Junction',
          'Rahim Yar Khan',
          'Multan Cantt',
          'Lahore Junction',
          'Rawalpindi',
          'Islamabad',
        ],
      );
      expect(tl.entries[0].state, LumeTimelineState.done);
      // `trainsActual('{time}')` — a stop that has happened names when.
      expect(tl.entries[0].subtitle, startsWith('actual '));
      expect(tl.entries[2].state, LumeTimelineState.now);
      expect(tl.entries.last.state, LumeTimelineState.upcoming);
      expect(tl.entries.last.subtitle, 'Scheduled');

      // Selecting a different service leaves the timeline exactly as it was —
      // the reference draws this one fixed list under every service.
      final Finder row = find.text('Pakistan Express');
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      final LumeTimeline again = tester.widget<LumeTimeline>(
        find.byKey(LumeTrainsTool.stopsKey),
      );
      expect(
        again.entries.map((LumeTimelineEntry e) => e.title).toList(),
        tl.entries.map((LumeTimelineEntry e) => e.title).toList(),
      );
    });

    testWidgets('fares — the first tier at full fare, the next at 72%', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester);
      final Finder row = find.text('Karakoram Express');
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      final LumeTable table = tester.widget<LumeTable>(
        find.byKey(LumeTrainsTool.faresKey),
      );
      expect(table.columns.map((LumeColumn c) => c.label).toList(), <String>[
        'Class',
        'Fare',
        'Seats',
      ]);
      expect(table.rows, hasLength(2));
      expect(table.rows[0][0], 'AC Business');
      expect(table.rows[0][2], '48');
      expect(table.rows[1][0], 'Economy');
      expect(table.rows[1][2], '31');
    });
  });

  group('a country with no rail network', () {
    testWidgets('says so, rather than showing Pakistan’s (§64)', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester, country: 'US', city: 'New York');
      // `LumeToolFrame`'s own eligibility gate (catalogue `countries:
      // {'PK'}`) shows the generic unavailable state and skips `body`
      // entirely for a non-PK reader (§64) — the tool's own internal
      // `unavailableKey` widget is defence-in-depth for a future catalogue
      // change, never reached here (same finding as Loadshedding/National
      // Savings/Prize Bonds, wave 9).
      expect(find.byKey(LumeTrainsTool.unavailableKey), findsNothing);
      expect(find.byKey(LumeTrainsTool.boardKey), findsNothing);
      expect(find.byKey(LumeTrainsTool.journeyKey), findsNothing);
      final LumeToolState state = tester.widget<LumeToolState>(
        find.byType(LumeToolState),
      );
      final AppLocalizations l = AppLocalizations.of(
        tester.element(find.byType(LumeToolState)),
      );
      expect(state.title, l.toolUnavailableTitle);
    });
  });

  group('sharing and reminding', () {
    testWidgets('the share card is the tracked service', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester);
      final Finder share = find.descendant(
        of: find.byKey(LumeTrainsTool.actionsKey),
        matching: find.byType(LumeButton),
      );
      await tester.ensureVisible(share.last);
      await tester.tap(share.last);
      await tester.pumpAndSettle();
      final LumeShareCard card = tester
          .widget<LumeShareCardArt>(find.byType(LumeShareCardArt))
          .card;
      expect(card.kind, LumeShareKind.quote);
      expect(card.text, contains('Green Line Express'));
      expect(card.text, contains('Karachi Cantt'));
      expect(card.text, contains('Islamabad'));
      expect(card.source, startsWith('5UP · '));
    });

    testWidgets('Remind me names the tracked service', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester);
      final Finder remind = find.text('Remind me');
      await tester.ensureVisible(remind);
      await tester.tap(remind);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(LumeToast),
          matching: find.text('Tracking Green Line Express'),
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('localization', () {
    testWidgets('in Urdu the journey runs right to left', (
      WidgetTester tester,
    ) async {
      await pumpTrains(tester, locale: const Locale('ur'));
      final Rect from = tester.getRect(
        inKey(LumeTrainsTool.journeyKey, find.text('KYC')),
      );
      final Rect to = tester.getRect(
        inKey(LumeTrainsTool.journeyKey, find.text('ISL')),
      );
      // The ends trade sides in a right-to-left page (`lume_journey.dart`):
      // Karachi Cantt, the departure, now draws on the *right*.
      expect(from.left, greaterThan(to.left));
      expectNoOverflow(tester);
    });

    testWidgets('at 200%, nothing overflows', (WidgetTester tester) async {
      await pumpTrains(tester, textScale: 2);
      expectNoOverflow(tester);
    });
  });
}
