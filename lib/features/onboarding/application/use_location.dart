/// "Use my current location" (claude.md §9), shared by the onboarding city
/// step and the personalisation sheet so the two can never disagree.
///
/// One position is asked for, turned into the nearest city the picker lists,
/// and dropped — nothing is stored but the country, region and city the
/// reader then confirms. Choosing by hand always remains possible, and every
/// way this can fail says so and leaves the current choice untouched.
library;

import 'package:flutter/foundation.dart';

import '../../../core/platform/lume_locator.dart';
import '../../../l10n/app_localizations.dart';
import '../data/country_fixture.dart';
import '../domain/city_picker_model.dart';
import '../domain/place_resolver.dart';

/// What the lookup found: a place, or why there is none.
@immutable
class LumeUseLocationResult {
  const LumeUseLocationResult.found({
    required String this.country,
    required String this.city,
    this.region,
  }) : outcome = LumeLocateOutcome.located;

  const LumeUseLocationResult.refused(this.outcome)
    : country = null,
      city = null,
      region = null;

  final LumeLocateOutcome outcome;
  final String? country;
  final String? city;
  final String? region;

  bool get found => country != null;

  /// What to tell the reader when nothing was found; `null` when something
  /// was. Every sentence ends by handing the choice back to the reader.
  String? message(AppLocalizations l) => switch (outcome) {
    LumeLocateOutcome.located => found ? null : l.persLocationUnavailable,
    LumeLocateOutcome.denied => l.persLocationDenied,
    LumeLocateOutcome.blocked => l.persLocationBlocked,
    LumeLocateOutcome.serviceOff => l.persLocationOff,
    LumeLocateOutcome.failed => l.persLocationUnavailable,
  };
}

abstract final class LumeUseLocation {
  static Future<LumeUseLocationResult> resolve({
    required LumeLocator locator,
    required LumeCountryFixture countries,
  }) async {
    final LumeLocateResult fix = await locator.locate();
    final double? lat = fix.latitude;
    final double? lon = fix.longitude;
    if (fix.outcome != LumeLocateOutcome.located ||
        lat == null ||
        lon == null) {
      return LumeUseLocationResult.refused(fix.outcome);
    }
    final LumeResolvedPlace? place = LumePlaceResolver.nearest(
      lat,
      lon,
      isKnown: (String country, String city) =>
          countries.placesOf(country).cities.contains(city),
    );
    if (place == null) {
      return const LumeUseLocationResult.refused(LumeLocateOutcome.failed);
    }
    return LumeUseLocationResult.found(
      country: place.country,
      city: place.city,
      region: LumeCityPicker.regionOf(
        countries.placesOf(place.country).regions,
        place.city,
      ),
    );
  }
}
