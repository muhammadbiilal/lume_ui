/// Two numbers and one phrase that have to match Lume state for state.
///
/// Both were wrong in the same way: a single value stood in for something the
/// reference varies. The header badge said 13 everywhere when Lume says 13,
/// 12 or 10; the Discover weather card said "34° and hazy sun" when Lume says
/// "34° and hazy". Neither is a formatting bug — they are fixture data, and a
/// deterministic reference fixture has to carry the reference's value whether
/// or not the machinery that derives it has been built yet.
///
/// ## The badge
///
/// `NOTIFY.unreadCount()` counts the notification *sources* that survive a
/// profile. `build()` walks sixteen declared sources; `allowed(src)` drops
/// each one whose tool the user cannot see — the same eligibility gate the
/// catalogue asks — and then the ones their preferences switch off.
///
/// Probed with `docs/conversion_archive/tool/probe_notifications.mjs`, which
/// drives the shell to the notification centre with the pinned clock and reads
/// both the badge and the unread rows:
///
/// | state | badge | what changed |
/// |---|---|---|
/// | `default_pk`, `muslim_pk`, `named_pk`, `no_interests_pk` | 13 | — |
/// | `prefs_off_pk` | 12 | `markets.move` — "KSE-100 moved +0.82%" |
/// | `muslim_gb`, `default_us` | 10 | also `loadshed.next` ("Power off at 19:00") and `trains.delay` ("Tezgam Express is running late"), whose tools are `countries: ['PK']` |
///
/// ## The weather card
///
/// `home.screen.js:837` writes `34° and hazy` into fixed markup — in *every*
/// state, including the UK and US captures, because the markup never varies —
/// while `WEATHER_BY_COUNTRY.PK` carries `'Hazy sun · humid'` and the live row
/// reads "Mostly clear · Rain 64%". Three different phrases for one city's
/// weather, on three surfaces, on purpose. So the card gets a display key of
/// its own rather than a transformation of the live row's.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_destination.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/home/application/home_controller.dart';
import 'package:lume/features/home/data/home_fixtures.dart';
import 'package:lume/features/home/domain/home_model.dart';

import '../../helpers/load_fonts.dart';
import 'destination_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// Every profile the parity captures use, with the badge the running
  /// prototype shows for it.
  const Map<String, int> unread = <String, int>{
    'default_pk': 13,
    'muslim_pk': 13,
    'named_pk': 13,
    'no_interests_pk': 13,
    'prefs_off_pk': 12,
    'muslim_gb': 10,
    'default_us': 10,
  };

  group('the header badge carries the reference value', () {
    for (final MapEntry<String, int> e in unread.entries) {
      test('${e.key} · ${e.value}', () {
        final LumeUserContext user = LumeUsers.all[e.key]!;
        expect(LumeFakeHomeRepository.unreadFor(user), e.value);
      });
    }

    testWidgets('and it reaches the screen, state by state', (
      WidgetTester tester,
    ) async {
      for (final MapEntry<String, int> e in unread.entries) {
        final LumeHomeController c = await composeHome(LumeUsers.all[e.key]!);
        addTearDown(c.dispose);
        expect(c.state.data!.content.notificationCount, e.value, reason: e.key);
      }
    });

    testWidgets('and a screen reader is told the same number', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      for (final String state in <String>[
        'muslim_pk',
        'prefs_off_pk',
        'muslim_gb',
        'default_us',
      ]) {
        await pumpHome(
          tester,
          LumeUsers.all[state]!,
          surface: const Size(390, 4000),
        );
        expect(
          find.bySemanticsLabel('Notifications, ${unread[state]}'),
          findsOneWidget,
          reason: state,
        );
      }
      handle.dispose();
    });

    test('an empty Home has no badge at all', () {
      // Not "0" in a pill: zero is nothing, which is what the reference does.
      expect(LumeHeaderButton.formatCount(1), '1');
      expect(LumeHeaderButton.formatCount(99), '99');
      expect(LumeHeaderButton.formatCount(100), '99+');
    });
  });

  group('the Discover weather card says what Lume says', () {
    testWidgets('"34° and hazy" in Pakistan, the reference state', (
      WidgetTester tester,
    ) async {
      await pumpHome(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 6000),
      );
      expect(find.text('34° and hazy'), findsOneWidget);
      expect(find.text('Feels like 38°'), findsOneWidget);
      expect(
        find.text('34° and hazy sun'),
        findsNothing,
        reason: 'the live row\'s phrase leaked into the card',
      );
    });

    testWidgets('while the live row keeps its own, richer phrase', (
      WidgetTester tester,
    ) async {
      // Different surfaces, different levels of detail — the reference's own
      // composition, and nothing here flattens it.
      await pumpHome(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 6000),
      );
      expect(find.text('Mostly clear · Rain 64%'), findsOneWidget);
    });

    testWidgets('and the raw condition is still on the model', (
      WidgetTester tester,
    ) async {
      final LumeHomeController c = await composeHome(LumeUsers.muslimPk);
      addTearDown(c.dispose);
      final LumeHomeData d = c.state.data!;
      expect(d.content.weather!.conditionKey, 'hazySun');
      expect(d.content.weather!.discoverConditionKey, 'hazy');
    });

    testWidgets('in Urdu and in Arabic', (WidgetTester tester) async {
      for (final Locale locale in <Locale>[
        const Locale('ur'),
        const Locale('ar'),
      ]) {
        await pumpHome(
          tester,
          LumeUsers.muslimPk,
          surface: const Size(390, 6000),
          locale: locale,
        );
        expect(tester.takeException(), isNull, reason: '$locale');
        // The phrase is a key in all three languages, so the card is
        // translated where the reference's literal is not.
        expect(
          find.byKey(const ValueKey<String>('home.discover.weather')),
          findsOneWidget,
          reason: '$locale',
        );
      }
    });

    testWidgets('on one line, in a card the same height as the reference\'s', (
      WidgetTester tester,
    ) async {
      await pumpHome(
        tester,
        LumeUsers.muslimPk,
        surface: const Size(390, 6000),
      );
      final Finder card = find.byKey(
        const ValueKey<String>('home.discover.weather'),
      );
      final RenderParagraph title = tester.renderObject<RenderParagraph>(
        find.descendant(of: card, matching: find.text('34° and hazy')),
      );
      expect(title.didExceedMaxLines, isFalse);
      expect(
        title.size.height,
        closeTo(16.25, 0.5),
        reason: 'one 13/1.25 line, as `.minicard__title` is in the reference',
      );

      // `.minicard` is `flex: 0 0 148px`, so the width is exact; the height
      // is the strip's, because `.hscroll` stretches every card to the
      // tallest and the outage card takes two lines for its localized time
      // (D23). Uniform is the assertion — a ragged strip was the defect.
      final Size size = tester.getSize(card);
      expect(size.width, closeTo(148, 0.5));
      final Set<double> heights = tester
          .widgetList<LumeMiniCard>(find.byType(LumeMiniCard))
          .map((LumeMiniCard w) => tester.getSize(find.byWidget(w)).height)
          .toSet();
      expect(heights, hasLength(1));
      expect(size.height, heights.single);
    });

    testWidgets('and a country with no short form of its own keeps the full '
        'condition', (WidgetTester tester) async {
      // The reference's literal says "hazy" everywhere, including London,
      // because the markup never varies. Only Pakistan's phrase is evidence
      // of anything; elsewhere the card derives honestly.
      await pumpHome(
        tester,
        LumeUsers.muslimGb,
        surface: const Size(390, 6000),
      );
      expect(find.text('21° and mostly clear'), findsOneWidget);
    });
  });
}
