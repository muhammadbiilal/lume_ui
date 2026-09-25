/// Small string mappings for 99 Names — no state, no logic beyond formatting
/// the count and the words a card or a toast shows.
library;

import '../../../core/localization/lume_format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/names99_model.dart';

abstract final class Names99Text {
  /// "12 of 99" — the ring's accessible value, and the summary's reading.
  static String reading(AppLocalizations l, LumeFormatting f, int held, int total) =>
      l.names99Reading(f.integer(held), f.integer(total));

  /// "/ 99" — the small suffix beside the lead figure.
  static String ofTotal(AppLocalizations l, LumeFormatting f, int total) =>
      l.names99Total(f.integer(total));

  /// "The remaining 87 need a verified source." — said once, on the summary
  /// card, rather than left for a reader to work out by counting rows.
  static String caption(AppLocalizations l, LumeFormatting f, int held, int total) =>
      l.names99Caption(f.integer(total - held));

  /// "Ar-Rahman — The Most Compassionate" — the toast a tap on a card says,
  /// exactly as `names99.tool.js` composes it (`n.tl + ' — ' + n.meaning`).
  static String opened(AppLocalizations l, LumeName n) =>
      l.names99Opened(n.transliteration, n.meaning.text);

  /// "Ar-Rahman — Asma ul Husna" — the reference line a shared card carries.
  static String shareSource(AppLocalizations l, LumeName n) =>
      l.names99ShareSource(n.transliteration);
}
