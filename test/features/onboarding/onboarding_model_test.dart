/// The two steps' rules, without a widget in sight.
///
/// Every one of these is a line in `ui/pickers.js`. They are here rather than
/// in a widget test because a rule that can only be checked by tapping is a
/// rule nobody checks at the boundaries.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/onboarding/data/country_fixture.dart';
import 'package:lume/features/onboarding/data/interests_fixture.dart';
import 'package:lume/features/onboarding/domain/country_picker_model.dart';
import 'package:lume/features/onboarding/domain/interests_model.dart';

void main() {
  final LumeCountryFixture countries = LumeCountryFixture.parse(
    File('assets/data/countries.json').readAsStringSync(),
  );
  final LumeInterestsFixture interests = LumeInterestsFixture.parse(
    File('assets/data/interests.json').readAsStringSync(),
  );

  LumeCountryPickerModel pick({
    String query = '',
    String selected = 'PK',
    List<String> recent = const <String>[],
    String language = 'en',
  }) => LumeCountryPicker.build(
    all: countries.forLanguage(language),
    popularOrder: countries.popularOrder,
    allOrder: countries.orderFor(language),
    selected: selected,
    query: query,
    recent: recent,
    recentTitle: 'Recent',
    popularTitle: 'Popular',
    allTitle: 'All countries',
  );

  group('the country table', () {
    test('carries all 194 countries', () {
      expect(countries.count, 194);
    });

    test('carries the 20 popular codes in their declared order', () {
      expect(countries.popularOrder, <String>[
        'PK',
        'IN',
        'US',
        'GB',
        'AE',
        'SA',
        'CA',
        'AU',
        'DE',
        'FR',
        'TR',
        'ID',
        'MY',
        'BD',
        'EG',
        'NG',
        'ZA',
        'SG',
        'QA',
        'KW',
      ]);
    });

    test('names every country in all three languages', () {
      for (final String language in <String>['en', 'ur', 'ar']) {
        final List<LumeCountry> list = countries.forLanguage(language);
        expect(list.length, 194, reason: language);
        for (final LumeCountry c in list) {
          expect(c.name.trim(), isNotEmpty, reason: '${c.code} in $language');
          expect(
            c.name,
            isNot(c.code),
            reason: '${c.code} is unnamed in $language',
          );
          expect(c.currency.length, 3, reason: c.code);
        }
      }
    });

    test('Urdu and Arabic names are not the English ones', () {
      final LumeCountry pkEn = countries
          .forLanguage('en')
          .firstWhere((LumeCountry c) => c.code == 'PK');
      final LumeCountry pkUr = countries
          .forLanguage('ur')
          .firstWhere((LumeCountry c) => c.code == 'PK');
      expect(pkEn.name, 'Pakistan');
      expect(pkUr.name, isNot(pkEn.name));
    });

    test('each language has its own collation order', () {
      expect(countries.orderFor('en').length, 194);
      expect(countries.orderFor('ur').length, 194);
      expect(
        countries.orderFor('ur'),
        isNot(countries.orderFor('en')),
        reason: 'Urdu does not sort the way English does',
      );
      expect(
        countries.orderFor('en').toSet(),
        countries.orderFor('ur').toSet(),
        reason: 'the same 194, in a different order',
      );
    });
  });

  group('the country picker, at rest', () {
    test('a first run has no Recent section', () {
      final LumeCountryPickerModel m = pick();
      expect(
        m.sections.map((LumeCountrySection s) => s.title).toList(),
        <String>['Popular', 'All countries'],
      );
    });

    test('a returning user gets Recent first, capped at four', () {
      final LumeCountryPickerModel m = pick(
        recent: <String>['GB', 'AE', 'US', 'SA', 'DE', 'FR'],
      );
      expect(m.sections.first.title, 'Recent');
      expect(m.sections.first.countries.length, 4);
      expect(
        m.sections.first.countries.map((LumeCountry c) => c.code).toList(),
        <String>['GB', 'AE', 'US', 'SA'],
      );
    });

    test('a recent code that does not resolve is dropped, not blanked', () {
      final LumeCountryPickerModel m = pick(recent: <String>['GB', 'ZZ', 'AE']);
      expect(
        m.sections.first.countries.map((LumeCountry c) => c.code).toList(),
        <String>['GB', 'AE'],
      );
    });

    test('Popular keeps the declared order rather than sorting', () {
      final LumeCountrySection popular = pick().sections.firstWhere(
        (LumeCountrySection s) => s.title == 'Popular',
      );
      expect(
        popular.countries.map((LumeCountry c) => c.code).toList(),
        countries.popularOrder,
      );
    });

    test('All countries holds every one of the 194', () {
      final LumeCountrySection all = pick().sections.last;
      expect(all.countries.length, 194);
    });

    test('All countries follows the language’s collation', () {
      expect(
        pick().sections.last.countries.map((LumeCountry c) => c.code).toList(),
        countries.orderFor('en'),
      );
      expect(
        pick(
          language: 'ur',
        ).sections.last.countries.map((LumeCountry c) => c.code).toList(),
        countries.orderFor('ur'),
      );
    });
  });

  group('the country picker, searching', () {
    test('matches a name by substring', () {
      final LumeCountryPickerModel m = pick(query: 'king');
      expect(m.isSearching, isTrue);
      expect(m.sections.length, 1);
      expect(m.sections.single.title, isNull, reason: 'no heading on a search');
      expect(
        m.sections.single.countries.map((LumeCountry c) => c.code),
        contains('GB'),
      );
    });

    test('a code match is an equality, and it fires', () {
      // No English country name contains "gb", so the only way GB can be in
      // this result is the code branch.
      expect(
        countries
            .forLanguage('en')
            .where((LumeCountry c) => c.name.toLowerCase().contains('gb')),
        isEmpty,
        reason: 'the premise of this test',
      );
      expect(
        pick(
          query: 'gb',
        ).sections.single.countries.map((LumeCountry c) => c.code),
        contains('GB'),
      );
    });

    test('a partial code is not a code match', () {
      // `g` equals no code, so every hit has to have earned its place by name
      // or by currency.
      for (final LumeCountry c in pick(query: 'g').sections.single.countries) {
        expect(
          c.name.toLowerCase().contains('g') || c.currency.toLowerCase() == 'g',
          isTrue,
          reason: '${c.code} matched "g" without containing it',
        );
      }
    });

    test('matches a currency code exactly', () {
      final LumeCountryPickerModel m = pick(query: 'pkr');
      expect(
        m.sections.single.countries.map((LumeCountry c) => c.code),
        contains('PK'),
      );
    });

    test('caps the result at sixty', () {
      // A single letter matches far more than sixty names.
      final LumeCountryPickerModel m = pick(query: 'a');
      expect(m.sections.single.countries.length, 60);
    });

    test('is case-insensitive and trims', () {
      expect(pick(query: '  PAKISTAN ').hasResults, isTrue);
    });

    test('no match is the no-results state, not an empty list', () {
      final LumeCountryPickerModel m = pick(query: 'qqqqq');
      expect(m.sections, isEmpty);
      expect(m.hasResults, isFalse);
      expect(m.isSearching, isTrue);
    });

    test('Continue stays available throughout', () {
      expect(pick().canContinue, isTrue);
      expect(pick(query: 'qqqqq').canContinue, isTrue);
    });
  });

  group('the country controller', () {
    test('reports a change of selection once', () {
      final LumeCountryPickerController c = LumeCountryPickerController(
        selected: 'PK',
      );
      addTearDown(c.dispose);
      int calls = 0;
      c.addListener(() => calls++);

      c.selected = 'GB';
      c.selected = 'GB';
      expect(calls, 1);
      expect(c.selected, 'GB');
    });

    test('clearing the query is a change', () {
      final LumeCountryPickerController c = LumeCountryPickerController(
        selected: 'PK',
        query: 'pak',
      );
      addTearDown(c.dispose);
      c.clearQuery();
      expect(c.query, '');
    });
  });

  group('the interests controller', () {
    LumeInterestsController make({Set<String>? selected, bool? faith}) =>
        LumeInterestsController(
          selected: selected,
          faithOpen: faith,
          faithInterests: interests.faithInterests,
        );

    test('starts empty on a first run', () {
      final LumeInterestsController c = make();
      addTearDown(c.dispose);
      expect(c.count, 0);
      expect(c.faithOpen, isFalse, reason: 'never preselected for anyone');
    });

    test('accepts up to ten and refuses the eleventh', () {
      final LumeInterestsController c = make();
      addTearDown(c.dispose);
      final List<String> ids = interests.allIds;
      for (int i = 0; i < 10; i++) {
        expect(c.toggle(ids[i]), isTrue, reason: ids[i]);
      }
      expect(c.count, 10);
      expect(c.atCap, isTrue);
      expect(
        c.toggle(ids[10]),
        isFalse,
        reason: 'the eleventh is refused, and says so',
      );
      expect(c.count, 10);
    });

    test('at the cap an already-chosen one can still be removed', () {
      final LumeInterestsController c = make(
        selected: interests.allIds.take(10).toSet(),
      );
      addTearDown(c.dispose);
      expect(c.atCap, isTrue);
      expect(c.toggle(interests.allIds.first), isTrue);
      expect(c.count, 9);
    });

    test('clear empties the selection and leaves the switch alone', () {
      final LumeInterestsController c = make(
        selected: <String>{'prayer', 'weather'},
      );
      addTearDown(c.dispose);
      expect(c.faithOpen, isTrue, reason: 'inferred from a faith interest');
      c.clear();
      expect(c.count, 0);
      expect(c.faithOpen, isTrue, reason: 'clear is not the switch');
    });

    test('turning the switch on seeds prayer, Qur’an and duas', () {
      final LumeInterestsController c = make();
      addTearDown(c.dispose);
      c.setFaithOpen(true);
      expect(c.selected, <String>{'prayer', 'quran', 'duas'});
    });

    test('the seed respects the cap', () {
      final LumeInterestsController c = make(
        selected: interests.allIds
            .where((String id) => !interests.faithInterests.contains(id))
            .take(9)
            .toSet(),
      );
      addTearDown(c.dispose);
      c.setFaithOpen(true);
      expect(c.count, 10, reason: 'one seed fits, two do not');
    });

    test('turning it off removes every faith interest and nothing else', () {
      final LumeInterestsController c = make(
        selected: <String>{'weather', 'prayer', 'quran', 'zakat'},
      );
      addTearDown(c.dispose);
      c.setFaithOpen(false);
      expect(c.selected, <String>{'weather'});
    });

    test('an explicit faithOpen beats the inference', () {
      final LumeInterestsController c = make(
        selected: <String>{'prayer'},
        faith: false,
      );
      addTearDown(c.dispose);
      expect(c.faithOpen, isFalse);
    });

    test('restore brings a selection back', () {
      final LumeInterestsController c = make();
      addTearDown(c.dispose);
      c.restore(<String>{'weather', 'news', 'prayer'});
      expect(c.count, 3);
      expect(c.faithOpen, isTrue);
    });
  });

  group('the interests model', () {
    List<LumeInterestGroup> groups() => interests.build(
      label: (String id) => id,
      groupLabel: (String id) => id,
    );

    LumeInterestsModel model(Set<String> selected) => LumeInterestsModel(
      groups: groups(),
      selected: selected,
      faithOpen: false,
    );

    test('Continue is off below five and on at five', () {
      expect(model(<String>{'a', 'b', 'c', 'd'}).canContinue, isFalse);
      expect(model(<String>{'a', 'b', 'c', 'd', 'e'}).canContinue, isTrue);
    });

    test('the shortfall counts down to zero and stops', () {
      expect(model(const <String>{}).remaining, 5);
      expect(model(<String>{'a', 'b'}).remaining, 3);
      expect(model(<String>{'a', 'b', 'c', 'd', 'e', 'f'}).remaining, 0);
    });

    test('nothing is muted below the cap', () {
      final LumeInterestsModel m = model(<String>{'weather'});
      expect(m.isMuted('news'), isFalse);
      expect(m.isMuted('weather'), isFalse);
    });

    test('at the cap the unchosen are muted and the chosen are not', () {
      final Set<String> ten = interests.allIds.take(10).toSet();
      final LumeInterestsModel m = model(ten);
      expect(m.atCap, isTrue);
      expect(m.isMuted(ten.first), isFalse);
      expect(m.isMuted(interests.allIds[10]), isTrue);
    });

    test('the faith group survives the reachability filter', () {
      // `liveItems` exempts it: it is the switch that makes its own features
      // exist, so it cannot be filtered out for having none yet.
      final List<LumeInterestGroup> built = LumeInterests.offer(
        all: groups(),
        reachable: (String _) => false,
      );
      expect(built.length, 1);
      expect(built.single.faith, isTrue);
      expect(built.single.interests.length, 6);
    });

    test('an ordinary group with nothing reachable is not rendered', () {
      final List<LumeInterestGroup> built = LumeInterests.offer(
        all: groups(),
        reachable: (String id) => id == 'weather',
      );
      expect(built.map((LumeInterestGroup g) => g.id).toList(), <String>[
        'everyday',
        'faith',
      ]);
      expect(built.first.interests.single.id, 'weather');
    });
  });
}
