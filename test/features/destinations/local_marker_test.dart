/// The "Local service" marker, and why no tile wears one (D28).
///
/// `tools.screen.js:73` draws `.cat-tool__pin` when `f.loc` is truthy;
/// `grep "loc:" assets/js/data/catalogue.js` returns nothing, and a live probe
/// of `#toolCats .cat-tool__pin` returns `{ found: 0 }`. The reference renders
/// no pin anywhere, in any state.
///
/// An earlier F5A implementation drew one, reasoning that `countries` means
/// what `loc` means. The two *are* semantically close — `shell.js` gates
/// `[data-loc]` by `want.split(',').indexOf(profile.country) !== -1`, and
/// `catalogue.js` documents `countries` as "markets this feature has actually
/// launched in" with `eligibility.js:39` testing it the same way — but:
///
/// * no source history records a rename, and `catalogue.js` never had a `loc`
///   field to lose;
/// * the production catalogue never exposes `loc`;
/// * the rendered screen shows no marker;
/// * and nothing about a missing decorative dot is a security, privacy,
///   data-accuracy or accessibility failure that would justify departing from
///   what Lume draws.
///
/// So the marker is not drawn. **The country gate is untouched** — that is the
/// half that matters, and the first group here is what makes sure removing the
/// pin did not quietly weaken it. The stale-field defect is recorded in
/// `KNOWN_DIFFERENCES.md` for reconsideration at Dayroz integration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/domain/tools_filter.dart';

import '../../helpers/load_fonts.dart';
import 'destination_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// Every feature the catalogue restricts to a market.
  Set<String> restricted() => kEligibility.features
      .where((LumeFeature f) => f.isCountryRestricted)
      .map((LumeFeature f) => f.id)
      .toSet();

  group('the country gate, which the marker never fed and still does not', () {
    test('reads a field the catalogue still carries', () {
      // The seven `countries:` entries in `catalogue.js`. If a rename drops
      // the field this is empty, and country gating has silently stopped —
      // which is the failure that actually matters.
      expect(restricted(), <String>{
        'tax',
        'natsavings',
        'prizebonds',
        'packages',
        'loadshed',
        'trains',
        'vehicle',
      });
    });

    test('and hides exactly those features outside their markets', () {
      final Set<String> gated = kEligibility.features
          .where(
            (LumeFeature f) =>
                kEligibility.reasonFor(f, LumeUsers.defaultUs) ==
                LumeUnavailableReason.country,
          )
          .map((LumeFeature f) => f.id)
          .toSet();
      expect(gated, isNotEmpty);
      expect(
        gated.difference(restricted()),
        isEmpty,
        reason: 'the gate hid something that is not country-restricted',
      );
      // Loadshedding is `countries: ['PK']`: visible at home, gone abroad.
      expect(
        kEligibility.isVisible(
          kEligibility.byId('loadshed')!,
          LumeUsers.defaultPk,
        ),
        isTrue,
      );
      expect(
        kEligibility.isVisible(
          kEligibility.byId('loadshed')!,
          LumeUsers.muslimGb,
        ),
        isFalse,
      );
    });

    test('and absent still means global', () {
      final LumeFeature calculator = kEligibility.byId('calculator')!;
      expect(calculator.countries, isNull);
      expect(calculator.isCountryRestricted, isFalse);
      // `catalogue.js`: "absent means global".
      expect(kEligibility.isVisible(calculator, LumeUsers.defaultUs), isTrue);
    });
  });

  group('no rendered tile wears the marker', () {
    testWidgets('not a country-restricted one', (WidgetTester tester) async {
      await pumpTools(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 12000),
        filter: LumeToolsFilter.all,
      );
      for (final String id in restricted()) {
        final Finder tile = find.byKey(ValueKey<String>('tools.tile.$id'));
        if (tile.evaluate().isEmpty) continue;
        expect(
          tester.widget<LumeCatalogueTile>(tile).marker,
          isNot(LumeTileMarker.local),
          reason: '$id wears a pin the reference does not draw',
        );
      }
    });

    testWidgets('and not any other one either, in any state', (
      WidgetTester tester,
    ) async {
      for (final LumeUserContext user in <LumeUserContext>[
        LumeUsers.defaultPk,
        LumeUsers.muslimPk,
        LumeUsers.muslimGb,
        LumeUsers.defaultUs,
      ]) {
        await pumpTools(
          tester,
          user,
          surface: const Size(390, 12000),
          filter: LumeToolsFilter.all,
        );
        final Iterable<LumeCatalogueTile> tiles = tester
            .widgetList<LumeCatalogueTile>(find.byType(LumeCatalogueTile));
        expect(tiles, isNotEmpty);
        expect(
          tiles.where(
            (LumeCatalogueTile t) => t.marker == LumeTileMarker.local,
          ),
          isEmpty,
          reason: 'a pin appeared for $user',
        );
      }
    });

    testWidgets('and nothing announces one', (WidgetTester tester) async {
      final ft.SemanticsHandle handle = tester.ensureSemantics();
      await pumpTools(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 12000),
        filter: LumeToolsFilter.all,
      );
      expect(find.bySemanticsLabel(RegExp('Local service')), findsNothing);
      handle.dispose();
    });
  });

  group('the markers that are drawn', () {
    testWidgets('a sensitive tool keeps its lock, a countable one its count', (
      WidgetTester tester,
    ) async {
      await pumpTools(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 12000),
        attention: const <String, int>{'documents': 3, 'bills': 2},
        filter: LumeToolsFilter.all,
      );

      LumeTileMarker markerOf(String id) => tester
          .widget<LumeCatalogueTile>(
            find.byKey(ValueKey<String>('tools.tile.$id')),
          )
          .marker;

      // `documents` is countable *and* sensitive, and `toolCard`'s overwrite
      // makes it the lock. The one precedence step the reference can show.
      expect(markerOf('documents'), LumeTileMarker.private);
      expect(markerOf('bills'), LumeTileMarker.count);
      expect(markerOf('calculator'), LumeTileMarker.none);
      // Country-restricted, countable by nothing, not sensitive: bare.
      expect(markerOf('tax'), LumeTileMarker.none);
    });
  });

  group('the precedence contract, on synthetic inputs', () {
    // Unit-level, because the rendered fixtures must stay faithful to the
    // states Lume can actually reach — and none of them is both countable and
    // country-restricted, so no production fixture is manufactured to show it.
    test('privacy beats locality beats the number', () {
      expect(
        LumeCatalogueTile.markerFor(sensitive: true, local: true, count: 9),
        LumeTileMarker.private,
      );
      expect(
        LumeCatalogueTile.markerFor(sensitive: true, local: false, count: 9),
        LumeTileMarker.private,
      );
      expect(
        LumeCatalogueTile.markerFor(sensitive: false, local: true, count: 9),
        LumeTileMarker.local,
      );
      expect(
        LumeCatalogueTile.markerFor(sensitive: false, local: false, count: 9),
        LumeTileMarker.count,
      );
      expect(
        LumeCatalogueTile.markerFor(sensitive: false, local: false, count: 0),
        LumeTileMarker.none,
      );
    });

    test('and a zero count is not a marker', () {
      expect(
        LumeCatalogueTile.markerFor(sensitive: false, local: false, count: 0),
        LumeTileMarker.none,
      );
      expect(
        LumeCatalogueTile.markerFor(sensitive: false, local: true, count: 0),
        LumeTileMarker.local,
      );
    });
  });
}
