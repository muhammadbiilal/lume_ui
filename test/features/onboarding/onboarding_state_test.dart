/// The state machine, the persistence contract and the migration.
///
/// These are the tests a Dayroz store has to satisfy when it replaces the
/// in-memory one: nothing here touches a widget, so "does onboarding persist
/// the right thing at the right moment" is answerable without pumping a frame.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';

void main() {
  const LumeOnboardingDraft empty = LumeOnboardingDraft();

  group('the step machine', () {
    test('is nine steps, in the prototype’s order', () {
      expect(LumeOnboardingStep.count, 9);
      expect(LumeOnboardingStep.all.length, 9);
      expect(LumeOnboardingStep.all, <int>[0, 1, 2, 3, 4, 5, 6, 7, 8]);
      expect(LumeOnboardingStep.country, 3);
      expect(LumeOnboardingStep.interests, 5);
      expect(LumeOnboardingStep.done, 8);
    });

    test('the first step cannot go back and the last cannot skip', () {
      expect(LumeOnboardingStep.canGoBack(LumeOnboardingStep.welcome), isFalse);
      expect(LumeOnboardingStep.canGoBack(LumeOnboardingStep.plan), isTrue);
      expect(LumeOnboardingStep.canSkip(LumeOnboardingStep.done), isFalse);
      expect(LumeOnboardingStep.canSkip(LumeOnboardingStep.name), isTrue);
    });
  });

  group('the draft', () {
    test('seeds from the stored record', () {
      final LumeOnboardingDraft d = LumeOnboardingState.draftFrom(
        const LumeProfileRecord(
          country: 'GB',
          region: 'England',
          city: 'London',
          interests: <String>['weather', 'prayer'],
          islamic: true,
          displayName: 'Sam',
          method: 'ISNA',
        ),
      );
      expect(d.country, 'GB');
      expect(d.city, 'London');
      expect(d.interests, <String>{'weather', 'prayer'});
      expect(d.islamic, isTrue);
      expect(d.displayName, 'Sam');
      expect(d.method, 'ISNA');
    });

    test('an unexpressed preference seeds as off, and stays unexpressed', () {
      const LumeProfileRecord r = LumeProfileRecord();
      expect(r.islamic, isNull, reason: 'never expressed');
      expect(LumeOnboardingState.draftFrom(r).islamic, isFalse);
    });

    test('clearing a region is not the same as leaving it alone', () {
      const LumeOnboardingDraft withRegion = LumeOnboardingDraft(
        region: 'Punjab',
      );
      expect(withRegion.copyWith(city: 'Lahore').region, 'Punjab');
      expect(withRegion.copyWith(clearRegion: true).region, isNull);
    });
  });

  group('faith is chosen, never inferred', () {
    test('choosing any faith interest turns it on', () {
      expect(
        LumeOnboardingState.faithFrom(<String>{'weather'}, current: false),
        isFalse,
      );
      expect(
        LumeOnboardingState.faithFrom(<String>{
          'weather',
          'quran',
        }, current: false),
        isTrue,
      );
    });

    test('an explicit yes survives a selection holding none', () {
      // `syncFaithFromInterests` turns it on and never off.
      expect(
        LumeOnboardingState.faithFrom(<String>{'weather'}, current: true),
        isTrue,
      );
    });

    test('country and language are not consulted anywhere', () {
      for (final String country in <String>['PK', 'SA', 'AE', 'GB', 'US']) {
        final LumeProfileRecord r = LumeOnboardingState.commit(
          LumeProfileRecord(country: country),
          LumeOnboardingDraft(
            country: country,
            interests: const <String>{'weather', 'news'},
          ),
        );
        expect(
          r.islamic,
          isFalse,
          reason: '$country must not imply a religion',
        );
      }
    });

    test('turning it off removes the faith interests and nothing else', () {
      expect(
        LumeOnboardingState.withoutFaith(<String>{
          'weather',
          'prayer',
          'quran',
          'news',
        }),
        <String>{'weather', 'news'},
      );
    });
  });

  group('completing writes the whole draft', () {
    test('and sets the marker', () {
      final LumeProfileRecord r = LumeOnboardingState.commit(
        const LumeProfileRecord(),
        const LumeOnboardingDraft(
          country: 'GB',
          region: 'England',
          city: 'London',
          interests: <String>{'weather', 'news', 'tasks', 'notes', 'maths'},
          displayName: 'Sam',
          method: 'ISNA',
          wantsLocation: false,
          wantsReminders: true,
        ),
      );
      expect(r.onboarded, isTrue);
      expect(r.country, 'GB');
      expect(r.region, 'England');
      expect(r.city, 'London');
      expect(r.interests.length, 5);
      expect(r.displayName, 'Sam');
      expect(r.method, 'ISNA');
      expect(r.wantsLocation, isFalse);
      expect(r.wantsReminders, isTrue);
    });

    test('an empty city does not erase the stored one', () {
      final LumeProfileRecord r = LumeOnboardingState.commit(
        const LumeProfileRecord(city: 'Islamabad'),
        const LumeOnboardingDraft(city: ''),
      );
      expect(r.city, 'Islamabad');
    });

    test('a faith interest in the draft turns the preference on', () {
      final LumeProfileRecord r = LumeOnboardingState.commit(
        const LumeProfileRecord(),
        const LumeOnboardingDraft(interests: <String>{'quran'}),
      );
      expect(r.islamic, isTrue);
    });
  });

  group('skipping', () {
    test('with nothing chosen writes the defaults and a neutral faith', () {
      final LumeProfileRecord r = LumeOnboardingState.skip(
        const LumeProfileRecord(),
        empty,
      );
      expect(r.interests, LumeOnboardingState.defaultInterests);
      expect(
        r.islamic,
        isFalse,
        reason:
            'the one place the flow writes a faith value unasked, and it '
            'writes the neutral one',
      );
      expect(r.onboarded, isTrue);
    });

    test('with something chosen keeps it', () {
      final LumeProfileRecord r = LumeOnboardingState.skip(
        const LumeProfileRecord(
          interests: <String>['quran', 'weather'],
          islamic: true,
        ),
        empty,
      );
      expect(r.interests, <String>['quran', 'weather']);
      expect(r.islamic, isTrue);
      expect(r.onboarded, isTrue);
    });

    test('a draft with choices is respected even on a blank record', () {
      final LumeProfileRecord r = LumeOnboardingState.skip(
        const LumeProfileRecord(),
        const LumeOnboardingDraft(interests: <String>{'weather'}),
      );
      expect(
        r.interests,
        isNot(LumeOnboardingState.defaultInterests),
        reason: 'somebody who chose one thing did not choose nothing',
      );
    });
  });

  group('whether to show the flow at all', () {
    test('a fresh install sees it', () {
      expect(LumeOnboardingState.shouldShow(const LumeProfileRecord()), isTrue);
    });

    test('a completed one does not', () {
      expect(
        LumeOnboardingState.shouldShow(
          const LumeProfileRecord(onboarded: true),
        ),
        isFalse,
      );
    });

    test('unless something explicitly restarts it', () {
      expect(
        LumeOnboardingState.shouldShow(
          const LumeProfileRecord(onboarded: true),
          forced: true,
        ),
        isTrue,
      );
    });
  });

  group('the prayer method', () {
    test('defaults to the profile’s MWL', () {
      expect(LumePrayerMethod.defaultId, 'MWL');
      expect(const LumeProfileRecord().method, 'MWL');
      expect(const LumeOnboardingDraft().method, 'MWL');
    });

    test('an unknown id falls back rather than throwing', () {
      expect(LumePrayerMethod.fromId('nonsense'), LumePrayerMethod.mwl);
    });

    test('the five are the prototype’s, in its order', () {
      expect(
        LumePrayerMethod.values.map((LumePrayerMethod m) => m.id).toList(),
        <String>['Karachi', 'MWL', 'ISNA', 'UmmAlQura', 'Egyptian'],
      );
    });
  });

  group('the store', () {
    test('round-trips a record', () {
      final LumeMemoryOnboardingStore store = LumeMemoryOnboardingStore();
      expect(store.read().onboarded, isFalse);
      store.write(store.read().copyWith(onboarded: true, city: 'Lahore'));
      expect(store.read().onboarded, isTrue);
      expect(store.read().city, 'Lahore');
    });
  });
}
