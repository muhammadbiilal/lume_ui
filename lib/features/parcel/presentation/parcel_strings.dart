/// The words Parcel draws that its data does not carry.
library;

import '../../../l10n/app_localizations.dart';
import '../data/parcel_fixtures.dart';

abstract final class LumeParcelStrings {
  /// A stage's label — worn by the active list's badge and, again, by
  /// whichever of a parcel's own events shares that stage.
  ///
  /// "Out for delivery" reuses the Home Discover card's own word
  /// ([AppLocalizations.parcelOutForDelivery]) rather than a second copy of
  /// the same English sentence under a different key.
  static String stage(AppLocalizations l, LumeParcelStage s) => switch (s) {
    LumeParcelStage.booked => l.parcelStBooked,
    LumeParcelStage.inTransit => l.parcelStInTransit,
    LumeParcelStage.arrived => l.parcelStArrived,
    LumeParcelStage.outForDelivery => l.parcelOutForDelivery,
    LumeParcelStage.delivered => l.parcelStDelivered,
    LumeParcelStage.arriving => l.parcelStArriving,
  };
}
