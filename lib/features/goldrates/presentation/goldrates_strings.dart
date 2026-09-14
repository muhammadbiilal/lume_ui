/// The words Currency & Gold draws that its data does not carry.
library;

import '../../../l10n/app_localizations.dart';

abstract final class LumeGoldratesStrings {
  /// `t('ccy.' + code.toLowerCase())` — a currency's name. A code the
  /// reference does not name is shown as its code.
  static String currency(AppLocalizations l, String code) => switch (code) {
    'USD' => l.ccyUsd,
    'EUR' => l.ccyEur,
    'GBP' => l.ccyGbp,
    'SAR' => l.ccySar,
    'AED' => l.ccyAed,
    _ => code,
  };
}
