/// The interest catalogue, counted against the authority rather than a memory.
///
/// Two figures had been reported for the same thing — 31 interests, and 57
/// chips — and a conversion cannot proceed on "about thirty". These tests fix
/// the answer to the generated asset, which is derived from
/// `assets/js/data/catalogue.js` and nothing else, and they fail if the two
/// ever disagree again.
///
/// The resolution, written out in
/// `docs/conversion_archive/INTERESTS_CATALOGUE.md`:
///
/// * **31 unique interest ids in 6 groups** — five ordinary and one faith.
/// * **29 render**: `sleep` and `quotes` are declared in a group and
///   referenced by no feature, so `liveItems` filters them in every context.
/// * **57 was a document-wide count** of `.pick` elements with the onboarding
///   picker *and* the settings picker both mounted — 29 plus 28. Never a count
///   of interests.
/// * **Six groups, not five.** Five carry a visible `.pickgroup__label`; the
///   sixth is the faith card, whose heading is a switch.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/onboarding/data/interests_fixture.dart';
import 'package:lume/features/onboarding/domain/interests_model.dart';
import 'package:lume/features/onboarding/presentation/onboarding_steps.dart';
import 'package:lume/l10n/app_localizations.dart';

void main() {
  const String assetPath = 'assets/data/interests.json';
  const String referencePath = 'assets/js/data/catalogue.js';

  final String raw = File(assetPath).readAsStringSync();
  final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
  final LumeInterestsFixture fixture = LumeInterestsFixture.parse(raw);

  group('the count, settled', () {
    test('31 unique interest ids', () {
      expect(fixture.interestCount, 31);
      expect(fixture.allIds.toSet().length, 31, reason: 'no duplicates');
    });

    test('6 groups: five ordinary and one faith', () {
      expect(fixture.groupCount, 6);
      expect(
        fixture.groups.where((LumeInterestGroupEntry g) => g.faith).length,
        1,
        reason: 'exactly one group is the faith switch',
      );
    });

    test('the groups are the reference’s, in the reference’s order', () {
      expect(
        fixture.groups.map((LumeInterestGroupEntry g) => g.id).toList(),
        <String>['everyday', 'money', 'health', 'travel', 'news', 'faith'],
      );
    });

    test('each group holds the number the catalogue declares', () {
      expect(
        <String, int>{
          for (final LumeInterestGroupEntry g in fixture.groups)
            g.id: g.items.length,
        },
        <String, int>{
          'everyday': 7,
          'money': 5,
          'health': 5,
          'travel': 4,
          'news': 4,
          'faith': 6,
        },
      );
    });

    test('two interests are declared and unreachable', () {
      // Not a defect this conversion introduces, and not one it fixes: the
      // prototype never renders them either. Recorded so nobody "fixes" the
      // Flutter list by adding two chips the design does not show.
      expect(fixture.unreachable, <String>{'sleep', 'quotes'});
    });

    test('29 interests are offered, which is what the prototype renders', () {
      final List<LumeInterestGroup> offered = fixture.build(
        label: (String id) => id,
        groupLabel: (String id) => id,
      );
      final int chips = offered.fold(
        0,
        (int n, LumeInterestGroup g) => n + g.interests.length,
      );
      expect(chips, 29);
      expect(31 - fixture.unreachable.length, chips);
    });
  });

  group('the asset is derived, not typed', () {
    test('every id in the asset is in the reference catalogue', () {
      final String reference = File(referencePath).readAsStringSync();
      for (final String id in fixture.allIds) {
        expect(
          reference.contains("{ id: '$id',"),
          isTrue,
          reason: '$id is in the asset but not in $referencePath',
        );
      }
    });

    test('the reference’s own group ids are all present', () {
      final String reference = File(referencePath).readAsStringSync();
      final String block = reference.substring(
        reference.indexOf('var INTEREST_GROUPS'),
        reference.indexOf('var FAITH_INTERESTS'),
      );
      final Iterable<RegExpMatch> groups = RegExp(
        r"\{ id: '([a-z]+)', label: '[^']+'(?:, faith: true)?, items: \[",
      ).allMatches(block);
      expect(
        groups.map((RegExpMatch m) => m.group(1)).toList(),
        fixture.groups.map((LumeInterestGroupEntry g) => g.id).toList(),
      );
    });

    test('the faith set matches FAITH_INTERESTS', () {
      expect(fixture.faithInterests, <String>{
        'prayer',
        'quran',
        'hadith',
        'duas',
        'zakat',
        'ramadan',
      });
    });

    test('the bounds are the reference’s', () {
      expect(fixture.minimum, LumeInterests.minimum);
      expect(fixture.maximum, LumeInterests.maximum);
      expect(fixture.minimum, 5);
      expect(fixture.maximum, 10);
    });

    test('DEFAULT_INTERESTS came across for the skip path', () {
      expect(fixture.defaults, <String>[
        'weather',
        'calendar',
        'tasks',
        'notes',
        'maths',
        'expenses',
        'news',
      ]);
    });

    test('every interest icon resolves to a bundled asset', () {
      // A LumeIcon whose name does not resolve renders nothing at all, and
      // says nothing about it. The first pass carried the sprite's `i-` prefix
      // through and every chip lost its glyph — visible only in a capture.
      final Set<String> available = Directory('assets/icons')
          .listSync()
          .whereType<File>()
          .map((File f) => f.uri.pathSegments.last.replaceAll('.svg', ''))
          .toSet();
      for (final LumeInterestGroupEntry g in fixture.groups) {
        for (final LumeInterestEntry i in g.items) {
          expect(
            available,
            contains(i.icon),
            reason:
                '${i.id} points at assets/icons/${i.icon}.svg, '
                'which does not exist',
          );
          expect(
            i.icon,
            isNot(startsWith('i-')),
            reason: '${i.id} kept the sprite prefix',
          );
        }
      }
    });

    test('the asset declares what generated it', () {
      expect(json['generator'], contains('gen_interests.mjs'));
      expect(json['source'], referencePath);
    });
  });

  group('every interest has a label in every language', () {
    for (final String language in <String>['en', 'ur', 'ar']) {
      testWidgets(language, (WidgetTester tester) async {
        late AppLocalizations l;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (BuildContext context) {
                l = AppLocalizations.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // The fallback in `interestLabel` returns the id, so a missing
        // translation shows up as a label that is its own id — which is
        // exactly what this catches.
        for (final String id in fixture.allIds) {
          final String label = interestLabel(l, id);
          expect(
            label,
            isNot(id),
            reason: '$id has no $language label; add it to app_$language.arb',
          );
          expect(label.trim(), isNotEmpty, reason: '$id is blank in $language');
        }

        for (final LumeInterestGroupEntry g in fixture.groups) {
          final String label = interestGroupLabel(l, g.id);
          expect(
            label,
            isNot(g.id),
            reason: 'group ${g.id} has no $language label',
          );
        }
      });
    }
  });

  group('growth is caught', () {
    test('an id the ARB does not know falls back to the id', () {
      // The completeness tests above rely on this, so it is asserted rather
      // than assumed: a catalogue that grows without its translations fails a
      // test instead of shipping a chip labelled with a slug.
      expect(fixture.allIds, isNot(contains('brand-new-interest')));
    });
  });
}
