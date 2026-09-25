/// The words Loadshedding draws that its data does not carry.
library;

import '../../../l10n/app_localizations.dart';

abstract final class LumeLoadshedText {
  /// `duration.hm` — "6h 05m", the shared duration key every tool that
  /// counts down to a clock time already uses (`sunmoon_tool.dart`'s
  /// `span`).
  static String hm(AppLocalizations l, int minutes) => l.durationHm(
    '${minutes ~/ 60}',
    (minutes % 60).toString().padLeft(2, '0'),
  );

  /// `duration.h` — "2h", a slot's own length. The reference's generic
  /// `duration.h` key is not otherwise in the catalogue, so this is scoped
  /// to Loadshedding rather than declared as a second shared key nobody
  /// else has asked for yet.
  static String hours(AppLocalizations l, int hours) =>
      l.loadshedSlotDuration('$hours');
}
