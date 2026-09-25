/// Small string mappings for Vaccinations — no state, no logic beyond a
/// lookup.
library;

import '../../../l10n/app_localizations.dart';
import '../domain/vaccines_model.dart';

abstract final class VaccinesText {
  /// "Done"/"Due" — the reference's own two words for
  /// [VaccineRecord.status] (`tool-data.js`'s `state: 'done' | 'due'`).
  static String status(AppLocalizations l, VaccineStatus s) => switch (s) {
    VaccineStatus.given => l.commonDone,
    VaccineStatus.due => l.commonDue,
  };
}
