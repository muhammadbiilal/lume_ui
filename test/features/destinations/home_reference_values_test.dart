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
/// `home.screen.js:834–839` writes the whole card as a literal — "34° and
/// hazy" over "Feels like 38°" — with no `data-loc` gate, so it renders
/// unchanged in every market while the live row above it reads the real
/// `WEATHER_BY_COUNTRY` entry and disagrees everywhere but Pakistan.
///
/// That is a defect in the prototype's presentation (C21) and it is
/// **reproduced, not repaired**. A first pass derived the card's phrase from
/// the live row's condition and rendered "34° and hazy sun"; a second set only
/// the condition and rendered "21° and hazy" in London — matching neither Lume
/// nor the weather. A reference fixture renders what Lume renders.
///
/// So all three of the card's values are its own fields, fixed once in
/// `_referenceDiscover`, and the sentence is still built from localizable keys
/// rather than hard-coded. Dayroz's weather adapter must replace those
/// constants with a real location-specific display condition.
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
      expect(d.content.weather!.temperatureC, 34);
      // The card's own three, which in Pakistan happen to agree with the
      // weather and nowhere else do.
      expect(d.content.weather!.discoverConditionKey, 'hazy');
      expect(d.content.weather!.discoverTemperature, 34);
      expect(d.content.weather!.discoverFeelsLike, 38);
    });

    testWidgets('in English, Urdu and Arabic: one line, one card height', (
      WidgetTester tester,
    ) async {
      final Map<String, ({int lines, double card})> seen =
          <String, ({int lines, double card})>{};

      for (final Locale locale in <Locale>[
        const Locale('en'),
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

        final Finder card = find.byKey(
          const ValueKey<String>('home.discover.weather'),
        );
        // The phrase is a key in all three languages, so the card is
        // translated where the reference's literal is English everywhere.
        expect(card, findsOneWidget, reason: '$locale');

        final RenderParagraph title = tester.renderObject<RenderParagraph>(
          find.descendant(of: card, matching: find.byType(Text)).first,
        );
        expect(
          title.didExceedMaxLines,
          isFalse,
          reason: '$locale truncated the title',
        );
        final Size size = tester.getSize(card);
        expect(size.width, closeTo(148, 0.5), reason: '$locale');
        // `RenderParagraph` does not expose its line metrics, so the same
        // span is laid out again in the same 124-point region the card gives
        // it — 148 less two borders and two 11-point paddings.
        final TextPainter painter = TextPainter(
          text: title.text,
          textDirection: title.textDirection,
          textScaler: title.textScaler,
          maxLines: title.maxLines,
        )..layout(maxWidth: 124);
        final int lines = painter.computeLineMetrics().length;
        painter.dispose();

        seen['$locale'] = (lines: lines, card: size.height);
      }

      // Counted, not inferred from the height: a tall script sets on a taller
      // line — 23 points against English's 16.25 — so a height ceiling would
      // read Urdu's single line as two.
      for (final MapEntry<String, ({int lines, double card})> e
          in seen.entries) {
        expect(e.value.lines, 1, reason: '${e.key} took more than one line');
        expect(
          e.value.card,
          greaterThan(120),
          reason: '${e.key} collapsed the card',
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

    testWidgets('including in London, where Lume says the same wrong thing', (
      WidgetTester tester,
    ) async {
      // The whole card is a literal with no country gate, so a reader in
      // London is shown Karachi's weather. Reproduced deliberately: a
      // reference fixture that "fixed" this would match neither Lume nor the
      // forecast. C21, and an obligation on Dayroz's adapter.
      for (final String state in <String>[
        'muslim_gb',
        'default_us',
        'prefs_off_pk',
        'named_pk',
        'default_pk',
        'no_interests_pk',
      ]) {
        await pumpHome(
          tester,
          LumeUsers.all[state]!,
          surface: const Size(390, 8000),
        );
        expect(
          find.byKey(const ValueKey<String>('home.discover.weather')),
          findsOneWidget,
          reason: state,
        );
        expect(find.text('34° and hazy'), findsOneWidget, reason: state);
        expect(find.text('Feels like 38°'), findsOneWidget, reason: state);
      }
    });

    testWidgets('while the live row still reads the real country entry', (
      WidgetTester tester,
    ) async {
      // The half that is *not* reproduced-as-broken: the row above reads
      // London's own weather, as the reference's does.
      await pumpHome(
        tester,
        LumeUsers.muslimGb,
        surface: const Size(390, 6000),
      );
      expect(find.text('21°'), findsWidgets);
      expect(
        find.text('34° and hazy'),
        findsOneWidget,
        reason: 'the card and the row disagree, exactly as Lume has them',
      );
    });
  });
}
