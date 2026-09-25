/// The words Currency draws that its data does not carry.
library;

import '../../../l10n/app_localizations.dart';

abstract final class LumeCurrencyStrings {
  /// `t('ccy.' + code.toLowerCase())` — a currency's name. The reference
  /// only ever names the eight codes its own boards draw from
  /// ([LumeCurrencyBoard.majors]); every other code — all ~140 the picker
  /// also offers, from [LumeCurrencyBoard.allCodes] — is shown as its code,
  /// exactly as the reference falls back for any code it has not named.
  static String currency(AppLocalizations l, String code) => switch (code) {
    'USD' => l.ccyUsd,
    'EUR' => l.ccyEur,
    'GBP' => l.ccyGbp,
    'SAR' => l.ccySar,
    'AED' => l.ccyAed,
    'PKR' => l.ccyPkr,
    'INR' => l.ccyInr,
    'TRY' => l.ccyTry,
    _ => code,
  };
}
