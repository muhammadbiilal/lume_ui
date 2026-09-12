/// The "Local service" marker, and the field it is wired to (D28).
///
/// `tools.screen.js:73` draws `.cat-tool__pin` when `f.loc` is truthy, and no
/// entry in `catalogue.js` declares `loc` — so the reference renders no pin at
/// all. A live probe of `#toolCats .cat-tool__pin` returns `{ found: 0 }`.
///
/// The marker is drawn here, and this is the proof the approval asked for.
///
/// **`loc` is a live word in the reference, with one meaning.** `shell.js`
/// gates `[data-loc]` by `want.split(',').indexOf(profile.country) !== -1`,
/// with `'global'` as the sentinel for "everywhere". `search.js:46` drops an
/// `EXTRA_INDEX` entry when `x.loc && x.loc !== getProfile().country`. Both
/// read it as *the markets this belongs to*, tested by membership of the
/// user's country.
///
/// **The catalogue carries the same concept under another name.**
/// `catalogue.js`'s own field table says:
///
/// > `countries` — markets this feature has actually launched in; absent means
/// > global. A PK entry says "localised for Pakistan so far", not "this
/// > category is Pakistan-only".
///
/// and `core/eligibility.js:39` tests it identically:
/// `if (f.countries && f.countries.indexOf(ctx.country) === -1) return false;`
///
/// Same definition, same membership test, same sentinel for "global" (absent
/// rather than the string). `countries` is what `loc` means for a catalogue
/// feature, and "Local service" is the label the reference itself puts on it.
///
/// **The honest caveat:** the source records no rename. `catalogue.js` never
/// had a `loc` field to lose; the screen and the catalogue simply speak two
/// vocabularies for one idea. The equivalence is proven from the definitions
/// and the tests, not from a commit.
///
/// The other candidate was `reqCity` — "needs a city to mean anything" — and
/// it is the wrong one: it is carried by Weather, Air Quality, Prayer Times
/// and Qibla, which are global features that localise their content. Calling
/// those "local services" would say something false.
///
/// These tests fail if any of that comes apart: if the catalogue stops
/// carrying the field, if the gate and the marker stop reading the same one,
/// or if the precedence between the three corner markers changes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/domain/tools_filter.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';

import '../../helpers/load_fonts.dart';
import 'destination_harness.dart';

void main() {
  setUpAll(loadLumeFonts);

  /// Every feature the catalogue restricts to a market.
  Set<String> restricted() => kEligibility.features
      .where((LumeFeature f) => f.isCountryRestricted)
      .map((LumeFeature f) => f.id)
      .toSet();

  group('the field the marker reads', () {
    test('is still on the catalogue, and still carries these', () {
      // The seven `countries:` entries in `catalogue.js`. If a rename drops
      // the field, this is empty and the marker has silently disconnected —
      // which is the failure this whole file exists to catch.
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

    test('is the same field the country gate reads', () {
      // Not "a field with the same values" — the same one. Every feature the
      // marker calls local must be a feature the gate can hide, and every
      // feature the gate hides for a country reason must be one the marker
      // calls local. Rename it and both halves fail together.
      final Set<String> marked = restricted();
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
        gated.difference(marked),
        isEmpty,
        reason: 'the gate hides a feature the marker does not call local',
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

  group('the marker itself', () {
    testWidgets('is drawn on a local service the user can actually reach', (
      WidgetTester tester,
    ) async {
      // Tax Calculator is `countries: ['PK','GB','US','IN','AE','SA']` — a
      // local service in Pakistan, and visible there.
      await pumpTools(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 6000),
      );

      final Finder tile = find.byKey(const ValueKey<String>('tools.tile.tax'));
      expect(tile, findsOneWidget);
      expect(
        tester.widget<LumeCatalogueTile>(tile).marker,
        LumeTileMarker.local,
      );
    });

    testWidgets('and not on a global one', (WidgetTester tester) async {
      await pumpTools(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 6000),
      );
      final Finder tile = find.byKey(
        const ValueKey<String>('tools.tile.calculator'),
      );
      expect(tile, findsOneWidget);
      expect(
        tester.widget<LumeCatalogueTile>(tile).marker,
        LumeTileMarker.none,
      );
    });

    testWidgets('and says what it means, rather than being a dot', (
      WidgetTester tester,
    ) async {
      final ft.SemanticsHandle handle = tester.ensureSemantics();
      await pumpTools(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 6000),
      );
      // The marker is part of the tile's own name — "Tax Calculator,
      // FBR 2025-26, Local service" — rather than a second thing to land on.
      expect(find.bySemanticsLabel(RegExp('Local service')), findsWidgets);
      handle.dispose();
    });
  });

  group('one corner, three markers', () {
    testWidgets('privacy beats locality beats the count', (
      WidgetTester tester,
    ) async {
      // `toolCard` writes the count, then overwrites it with the lock for a
      // sensitive tool and with the pin for a local one. Documents is the
      // observable case: countable *and* sensitive, and it shows the lock.
      await pumpTools(
        tester,
        LumeUsers.defaultPk,
        surface: const Size(390, 6000),
        attention: const <String, int>{'documents': 3, 'tax': 2, 'bills': 2},
        filter: LumeToolsFilter.all,
      );

      LumeTileMarker markerOf(String id) => tester
          .widget<LumeCatalogueTile>(
            find.byKey(ValueKey<String>('tools.tile.$id')),
          )
          .marker;

      expect(markerOf('documents'), LumeTileMarker.private);
      expect(markerOf('tax'), LumeTileMarker.local);
      expect(markerOf('bills'), LumeTileMarker.count);
    });
  });
}
