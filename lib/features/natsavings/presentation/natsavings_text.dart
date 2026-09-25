/// Small string mappings for National Savings — no state, no logic beyond a
/// lookup.
library;

import '../../../l10n/app_localizations.dart';
import '../data/natsavings_fixtures.dart';

abstract final class LumeNatSavingsText {
  /// `c.t('savings.min') + ' ' + moneyRaw(p.min, ccy, 0)` — a row's minimum
  /// deposit note, already formatted by the caller.
  static String minNote(AppLocalizations l, String formattedMin) =>
      '${l.savingsMin} $formattedMin';

  /// `sortItems([rate, term, minimum], 'rate', 'desc')` — the sort bar's
  /// three dimensions, in the reference's own order.
  static String sortLabel(AppLocalizations l, String key) => switch (key) {
    'term' => l.savingsTerm,
    'min' => l.savingsMinimum,
    _ => l.savingsRate,
  };

  /// `act: 'toast:' + p.name + ' · ' + c.num(p.rate, …) + '%'` — what tapping
  /// a product row toasts.
  static String rowToast(LumeSavingsInstrument p, String formattedRate) =>
      '${p.name} · $formattedRate%';
}
