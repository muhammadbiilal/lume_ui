/// The words Cricket draws that its data does not carry.
library;

import '../../../l10n/app_localizations.dart';
import '../data/cricket_fixtures.dart';

abstract final class LumeCricketStrings {
  /// `c.t(m.statusKey, { team: m.t1full })` — the reference's one status key,
  /// with the batting side's full name in it. Every match the reference has
  /// opens the same way: the side batting first chose to.
  static String status(AppLocalizations l, LumeCricketMatch m) =>
      l.cricketChoseToBat(m.team1Full);
}
