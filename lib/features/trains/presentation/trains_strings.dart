/// The words the Trains tool draws that its data does not carry.
///
/// The destination (`trains_screen.dart`) keeps its own copy of this same
/// switch, because it draws a different widget (`LumeStatusPill`, not
/// `LumeBadge`) with a different tone enum. Both read the same three ARB
/// keys — `trainsStatusOnTime`, `trainsStatusLate`, `trainsStatusDeparted` —
/// so a service reads the same word in both places.
library;

import '../../../core/widgets/lume/lume_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/trains_model.dart';

abstract final class LumeTrainsStrings {
  /// `t(train.statusKey, { n: train.delayMinutes })`.
  static String status(AppLocalizations l, LumeTrainService s) =>
      switch (s.status) {
        LumeTrainStatus.onTime => l.trainsStatusOnTime,
        LumeTrainStatus.departed => l.trainsStatusDeparted,
        LumeTrainStatus.late_ => l.trainsStatusLate(s.delayMinutes),
      };

  /// `t.tone === 'ok' ? 'ok' : 'late'` — badge tone follows the delay, not the
  /// three-way status: a departed service is drawn the same tone as one still
  /// running on time.
  static LumeBadgeTone tone(LumeTrainService s) =>
      s.isLate ? LumeBadgeTone.late_ : LumeBadgeTone.ok;
}
