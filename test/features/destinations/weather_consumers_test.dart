/// The three surfaces that read weather, against the one port (C61).
///
/// `lume_reference_weather_test.dart` proves the port reproduces the
/// reference. This proves the surfaces read the port and nothing else: the
/// days Home shows are the generator's, a market the reference does not define
/// gets no weather anywhere, and Explore's card needs a real sunset as well as
/// a reading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/explore/data/explore_fixtures.dart';
import 'package:lume/features/explore/domain/explore_repository.dart';
import 'package:lume/features/home/data/home_fixtures.dart';
import 'package:lume/features/home/domain/home_content.dart';
import 'package:lume/features/home/domain/home_repository.dart';
import 'package:lume/features/account/domain/notification_prefs.dart';
import 'package:lume/features/notifications/data/notification_fixtures.dart';
import 'package:lume/features/notifications/domain/notification_model.dart';
import 'package:lume/l10n/app_localizations.dart';

import 'destination_harness.dart';

final DateTime kNow = DateTime(2026, 9, 7, 16, 41);

void main() {
  LumeWeatherNow? homeWeather(String country) => LumeFakeHomeRepository()
      .statusesFor(LumeUserContext(country: country), now: kNow)
      .weather;

  group('Home', () {
    test('Pakistan’s tomorrow is the generator’s: 36° / 27°, not 25°', () {
      final LumeWeatherNow w = homeWeather('PK')!;
      expect(w.tomorrow.highC, 36);
      expect(w.tomorrow.lowC, 27);
      expect(w.tomorrow.rainPercent, 1);
      expect(w.tomorrow.conditionKey, 'cloudBuilding');
      expect(w.today.highC, 34);
      expect(w.today.lowC, 23);
    });

    test('the UK’s days are generated, not typed', () {
      final LumeWeatherNow w = homeWeather('GB')!;
      expect((w.today.highC, w.today.lowC, w.today.rainPercent), (21, 10, 21));
      expect(
        (w.tomorrow.highC, w.tomorrow.lowC, w.tomorrow.rainPercent),
        (25, 17, 10),
      );
      expect(w.tomorrow.conditionKey, 'cloudBuilding');
    });

    test('the live row reads its own phrase’s first clause', () {
      expect(homeWeather('IN')!.conditionKey, 'humid');
      expect(homeWeather('AE')!.conditionKey, 'clear');
      expect(homeWeather('PK')!.conditionKey, 'hazySun');
    });

    test('a market the reference does not define has no weather', () async {
      expect(homeWeather('KE'), isNull);
      final LumeHomeSnapshot s = await LumeFakeHomeRepository().load(
        const LumeUserContext(country: 'KE', city: 'Nairobi'),
        now: kNow,
      );
      expect(s.content.weather, isNull);
    });
  });

  group('Explore', () {
    Future<LumeExploreSnapshot> explore(String country) =>
        LumeFakeExploreRepository(
          eligibility: kEligibility,
        ).load(LumeUserContext(country: country), now: kNow);

    test('draws a card where both a reading and a sunset exist', () async {
      for (final String c in <String>['PK', 'GB', 'US']) {
        final LumeExploreSnapshot s = await explore(c);
        expect(s.data.weather, isNotNull, reason: c);
        expect(s.of(LumeExploreSource.weather), LumeSourceFreshness.fixture);
      }
    });

    test('and nowhere its sunset would be invented', () async {
      for (final String c in <String>['IN', 'AE', 'SA', 'JP']) {
        final LumeExploreSnapshot s = await explore(c);
        expect(s.data.weather, isNull, reason: c);
        expect(
          s.of(LumeExploreSource.weather),
          LumeSourceFreshness.unavailable,
          reason: c,
        );
      }
    });

    test('nor another market’s reading, where there is none', () async {
      final LumeExploreSnapshot s = await explore('KE');
      expect(s.data.weather, isNull);
      expect(s.of(LumeExploreSource.weather), LumeSourceFreshness.unavailable);
    });
  });

  group('the notification forecast', () {
    LumeFixtureNotificationRepository feed(String country, String city) =>
        LumeFixtureNotificationRepository(
          eligibility: kEligibility,
          user: LumeUserContext(country: country, city: city),
          l: lookupAppLocalizations(const Locale('en')),
          readPrefs: () => const LumeNotificationPrefs(),
        );

    Future<LumeNotification?> forecast(String country, String city) async {
      final LumeNotificationFeed f = await feed(country, city).feed(now: kNow);
      for (final LumeNotification n in f.all) {
        if (n.tool == 'weather') return n;
      }
      return null;
    }

    test(
      'each market reads its own generated tomorrow, in its units',
      () async {
        expect(
          (await forecast('PK', 'Islamabad'))!.body,
          'High 36° · Low 27° · 1% Rain',
        );
        expect(
          (await forecast('US', 'New York'))!.body,
          'High 84° · Low 68° · 50% Rain',
        );
        expect(
          (await forecast('JP', 'Tokyo'))!.body,
          'High 31° · Low 21° · 53% Rain',
        );
      },
    );

    test('and a market the reference does not define builds no row', () async {
      expect(await forecast('KE', 'Nairobi'), isNull);
    });
  });
}
