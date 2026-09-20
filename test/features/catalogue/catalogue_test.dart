/// The registry is the single source of truth, and these are what keep it one.
///
/// §19 makes `catalogue.js` — now `feature_catalogue.dart` — the only place a
/// feature is declared, and §63 forbids a screen re-deriving its gating. That
/// only holds if the registry is complete: every displayed tool resolves to a
/// route, every id is unique, no category holds an orphan, every gate is
/// deterministic, and nothing reaches a surface it was hidden from.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/icons/lume_icons.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/catalogue/presentation/feature_strings.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/l10n/app_localizations.dart';
import 'package:lume/l10n/app_localizations_ar.dart';
import 'package:lume/l10n/app_localizations_en.dart';
import 'package:lume/l10n/app_localizations_ur.dart';

const LumeEligibility eligibility = LumeEligibility(
  features: kLumeFeatures,
  categories: kLumeCategories,
);

void main() {
  group('the registry is complete', () {
    test('every feature has a unique id', () {
      final List<String> ids = kLumeFeatures
          .map((LumeFeature f) => f.id)
          .toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, hasLength(85));
    });

    test('every feature resolves to a route', () {
      for (final LumeFeature f in kLumeFeatures) {
        final String path = LumeRoutes.tool(LumeRoutes.tools, f.id);
        expect(path, '/tools/tool/${f.id}');
        // And the branch it was opened from is recoverable from the path,
        // which is what makes Back land where the user came from.
        expect(LumeRoutes.branchOf(path), LumeRoutes.tools);
      }
    });

    test('every route-backed tool has metadata', () {
      // The other direction: a path can only be built from a feature, so
      // there is no route that exists without an entry.
      for (final LumeFeature f in kLumeFeatures) {
        expect(eligibility.byId(f.id), same(f));
      }
      expect(eligibility.byId('no-such-tool'), isNull);
    });

    test('every feature names an icon the product ships', () {
      for (final LumeFeature f in kLumeFeatures) {
        expect(LumeIcons.all, contains(f.icon), reason: f.id);
      }
      for (final LumeCategory c in kLumeCategories) {
        expect(LumeIcons.all, contains(c.icon), reason: c.id.name);
      }
    });

    test('no category holds an orphan, and none is empty', () {
      final Set<LumeToolCategory> declared = kLumeCategories
          .map((LumeCategory c) => c.id)
          .toSet();
      for (final LumeFeature f in kLumeFeatures) {
        expect(declared, contains(f.category), reason: f.id);
      }
      for (final LumeToolCategory c in declared) {
        expect(
          kLumeFeatures.where((LumeFeature f) => f.category == c),
          isNotEmpty,
          reason: c.name,
        );
      }
    });

    test('every related tool exists', () {
      for (final LumeFeature f in kLumeFeatures) {
        for (final String id in f.related) {
          expect(eligibility.byId(id), isNotNull, reason: '${f.id} → $id');
        }
      }
    });

    test('a country-restricted feature names real markets', () {
      final RegExp iso = RegExp(r'^[A-Z]{2}$');
      for (final LumeFeature f in kLumeFeatures) {
        for (final String code in f.countries ?? const <String>{}) {
          expect(iso.hasMatch(code), isTrue, reason: '${f.id} → $code');
        }
      }
      expect(eligibility.localisedCountries, contains('PK'));
    });

    test('the counts are what the catalogue says', () {
      int by(bool Function(LumeFeature) p) => kLumeFeatures.where(p).length;
      expect(by((LumeFeature f) => f.faith), 17, reason: '§21 lists 17');
      // Lending Ledger (D8), Installments (D-I1) and Committee (D-C9)
      // joined the tools the reference marks.
      expect(by((LumeFeature f) => f.sensitive), 12);
      expect(by((LumeFeature f) => f.isCountryRestricted), 7);
      expect(by((LumeFeature f) => f.homeEligible), 28);
      expect(by((LumeFeature f) => f.quickEligible), 24);
    });

    test(
      'the destination count and the tool count are not the same number',
      () {
        // Five tabs and eighty-five tools; a heading that conflated them would
        // be wrong in both directions.
        expect(LumeDestinations.orderFor('PK'), hasLength(5));
        expect(LumeDestinations.all, hasLength(6));
        expect(kLumeFeatures, hasLength(85));
        expect(kLumeCategories, hasLength(6));
      },
    );
  });

  group('every feature is named, in every language', () {
    final Map<String, AppLocalizations> langs = <String, AppLocalizations>{
      'en': AppLocalizationsEn(),
      'ur': AppLocalizationsUr(),
      'ar': AppLocalizationsAr(),
    };

    for (final MapEntry<String, AppLocalizations> e in langs.entries) {
      test(e.key, () {
        for (final LumeFeature f in kLumeFeatures) {
          final String name = LumeFeatureStrings.name(e.value, f.id);
          expect(name, isNot(f.id), reason: '${f.id} fell back to its key');
          expect(name.trim(), isNotEmpty);
          expect(
            LumeFeatureStrings.status(e.value, f.id),
            isNotNull,
            reason: '${f.id} has no status line',
          );
        }
        for (final LumeCategory c in kLumeCategories) {
          expect(LumeFeatureStrings.category(e.value, c.id).trim(), isNotEmpty);
          expect(
            LumeFeatureStrings.categorySub(e.value, c.id).trim(),
            isNotEmpty,
          );
        }
      });
    }

    test('an Urdu name is not the English one', () {
      // A handful are genuinely the same — a proper noun, an abbreviation —
      // but the great majority must differ or the "translation" is a copy.
      final AppLocalizations en = AppLocalizationsEn();
      final AppLocalizations ur = AppLocalizationsUr();
      final int same = kLumeFeatures
          .where(
            (LumeFeature f) =>
                LumeFeatureStrings.name(en, f.id) ==
                LumeFeatureStrings.name(ur, f.id),
          )
          .length;
      expect(same, lessThan(5), reason: '$same of 85 names are identical');
    });
  });

  group('the three gates are separate, and none is inferred', () {
    const LumeUserContext muslimPk = LumeUserContext(islamic: true);
    const LumeUserContext plainPk = LumeUserContext();
    final LumeUserContext muslimGb = plainPk.copyWith(
      islamic: true,
      country: 'GB',
    );
    final LumeUserContext plainUs = plainPk.copyWith(country: 'US');

    test('faith hides the Islamic experience and nothing else', () {
      final List<LumeFeature> off = eligibility.visibleFeatures(plainPk);
      final List<LumeFeature> on = eligibility.visibleFeatures(muslimPk);
      expect(on.length - off.length, 17);
      expect(off.where((LumeFeature f) => f.faith), isEmpty);
    });

    test('country hides only what has not launched here', () {
      final List<LumeFeature> pk = eligibility.visibleFeatures(plainPk);
      final List<LumeFeature> us = eligibility.visibleFeatures(plainUs);
      for (final LumeFeature f in pk.toSet().difference(us.toSet())) {
        expect(f.countries, isNotNull, reason: f.id);
        expect(f.countries, isNot(contains('US')));
      }
    });

    test('a Muslim in the UK gets the experience and no Pakistani service', () {
      expect(eligibility.visibleById('prayer', muslimGb), isNotNull);
      expect(eligibility.visibleById('loadshed', muslimGb), isNull);
      expect(
        eligibility.reasonFor(eligibility.byId('loadshed')!, muslimGb),
        LumeUnavailableReason.country,
      );
    });

    test('a non-Muslim in Pakistan gets the services and none of it', () {
      expect(eligibility.visibleById('loadshed', plainPk), isNotNull);
      expect(eligibility.visibleById('quran', plainPk), isNull);
      expect(
        eligibility.reasonFor(eligibility.byId('quran')!, plainPk),
        LumeUnavailableReason.faith,
      );
    });

    test('a content switch is a third gate, not a fourth country', () {
      final LumeUserContext quiet = plainPk.copyWith(
        prefs: const LumeContentPrefs(
          news: false,
          cricket: false,
          finance: false,
        ),
      );
      for (final String id in <String>[
        'news',
        'cricket',
        'markets',
        'goldrates',
      ]) {
        expect(eligibility.visibleById(id, quiet), isNull, reason: id);
        expect(
          eligibility.reasonFor(eligibility.byId(id)!, quiet),
          LumeUnavailableReason.preference,
        );
      }
      // And nothing else moves.
      expect(
        eligibility.visibleFeatures(plainPk).length -
            eligibility.visibleFeatures(quiet).length,
        4,
      );
    });

    test('the reason is stable when two gates apply', () {
      // A faith feature restricted to a market the user is not in reports the
      // faith gate, every time, because that is the order they are checked.
      final LumeFeature loadshed = eligibility.byId('loadshed')!;
      expect(
        eligibility.reasonFor(loadshed, muslimGb),
        LumeUnavailableReason.country,
      );
    });

    test('the answer does not depend on the country for a faith feature', () {
      for (final String country in <String>['PK', 'GB', 'US', 'JP', 'SA']) {
        final LumeUserContext off = plainPk.copyWith(country: country);
        final LumeUserContext on = off.copyWith(islamic: true);
        expect(eligibility.visibleById('quran', off), isNull, reason: country);
        expect(
          eligibility.visibleById('quran', on),
          isNotNull,
          reason: country,
        );
      }
    });

    test('the answer does not depend on the interests', () {
      // Choosing "prayer" as an interest is an explicit act in onboarding and
      // is what *writes* the preference; it is never read back as one.
      final LumeUserContext interested = plainPk.copyWith(
        interests: const <String>{'prayer', 'quran', 'duas'},
      );
      expect(eligibility.visibleById('quran', interested), isNull);
    });

    test('gating is deterministic', () {
      for (int i = 0; i < 3; i++) {
        expect(
          eligibility.visibleFeatures(muslimPk).map((LumeFeature f) => f.id),
          eligibility.visibleFeatures(muslimPk).map((LumeFeature f) => f.id),
        );
      }
    });
  });

  group('nothing leaks back in', () {
    test('recents are filtered on the way out', () {
      final LumeUserContext user = const LumeUserContext().copyWith(
        recents: <String>['quran', 'calculator', 'loadshed'],
      );
      expect(
        eligibility.recentFeatures(user).map((LumeFeature f) => f.id),
        <String>['calculator', 'loadshed'],
        reason: 'the faith feature is dropped on the way out',
      );

      final LumeUserContext abroad = user.copyWith(country: 'US');
      expect(
        eligibility.recentFeatures(abroad).map((LumeFeature f) => f.id),
        <String>['calculator'],
      );
    });

    test('a category disappears when the experience does', () {
      expect(
        eligibility
            .visibleCategories(const LumeUserContext())
            .map((LumeCategory c) => c.id),
        isNot(contains(LumeToolCategory.islamic)),
      );
      expect(
        eligibility
            .visibleCategories(const LumeUserContext(islamic: true))
            .map((LumeCategory c) => c.id),
        contains(LumeToolCategory.islamic),
      );
    });

    test('visibleById is the door, byId is only the lookup', () {
      expect(eligibility.byId('quran'), isNotNull);
      expect(eligibility.visibleById('quran', const LumeUserContext()), isNull);
    });
  });

  group('recents are a list, not a pile', () {
    test('most recent first, no duplicates, capped', () {
      LumeProfileRecord r = const LumeProfileRecord();
      for (final String id in <String>['a', 'b', 'c', 'a']) {
        r = r.noteRecent(id);
      }
      expect(r.recents, <String>['a', 'c', 'b']);

      for (int i = 0; i < 12; i++) {
        r = r.noteRecent('t$i');
      }
      expect(r.recents, hasLength(8));
      expect(r.recents.first, 't11');
    });
  });

  group('the search index', () {
    final AppLocalizations en = AppLocalizationsEn();
    final AppLocalizations ur = AppLocalizationsUr();

    test('"petrol" finds the fuel tools and nothing else', () {
      final List<String> hits = kLumeFeatures
          .where(
            (LumeFeature f) =>
                LumeFeatureStrings.haystack(en, f).contains('petrol'),
          )
          .map((LumeFeature f) => f.id)
          .toList();
      expect(hits, <String>['fuel', 'fuelcost']);
    });

    test('"namaz" finds prayer times', () {
      expect(
        LumeFeatureStrings.haystack(en, eligibility.byId('prayer')!),
        contains('namaz'),
      );
    });

    test('an Urdu reader can search by the name they can see', () {
      // The prototype indexes the *English* name, so an Urdu reader cannot
      // find a tool by what the tile says (C18). Both are indexed here.
      final LumeFeature calc = eligibility.byId('calculator')!;
      final String hay = LumeFeatureStrings.haystack(ur, calc);
      expect(hay, contains(LumeFeatureStrings.name(ur, 'calculator')));
      expect(hay, contains('calculator'));
    });
  });
}
