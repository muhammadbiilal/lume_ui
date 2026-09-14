/// The words Flights draws that its data does not carry.
library;

import '../../../l10n/app_localizations.dart';
import '../data/flights_fixtures.dart';

abstract final class LumeFlightsStrings {
  /// `t(f.statusKey)`.
  static String status(AppLocalizations l, LumeFlightStatus s) => switch (s) {
    LumeFlightStatus.enroute => l.flightsStEnroute,
    LumeFlightStatus.landed => l.flightsStLanded,
    LumeFlightStatus.delayed => l.flightsStDelayed,
    LumeFlightStatus.scheduled => l.flightsStScheduled,
  };
}
