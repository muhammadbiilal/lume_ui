/// Small string mappings for Prayer Tracker — no state, no logic beyond a
/// lookup.
library;

import '../../../l10n/app_localizations.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../domain/praytrack_model.dart';

abstract final class PrayTrackText {
  /// The reference's own `prayer.*` keys (`praytrack.tool.js:34`,
  /// `c.t('prayer.' + p.key)`). [LumeFeatureStrings.prayerName] already
  /// carries this exact lookup for Home's own prayer status line and the
  /// (also in this wave) Prayer Times tool — reused here rather than
  /// duplicated, so a prayer is named the same way everywhere in the app.
  static String name(AppLocalizations l, PrayerKey k) =>
      LumeFeatureStrings.prayerName(l, k.name);
}
