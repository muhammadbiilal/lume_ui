/// Which currency a country uses for a *new* amount, and since when.
///
/// **What this decides, and what it never does.** A country's currency is
/// only a default: the one a new Bulgarian profile shows and a new Ledger
/// entry starts in. A stored amount carries its own ISO code and minor
/// units ([LumeMoney]) and is never re-read through this table, so a change
/// here never reinterprets old data — a lev entry stays a lev entry.
///
/// **Where it comes from.** [reference] is the web reference's own table
/// (`assets/js/data/geo.js`, bundled as `assets/data/countries.json`), as it
/// was captured; the reference is not edited. [changes] lists every
/// correction made on top of it, each with the date it took effect and the
/// legal source, and [current] is the reference with those applied. The
/// table is versioned by [asOf]: the newest change it includes. A future
/// change is a new [LumeCurrencyChange] with its own date, never an edit to
/// an old one. See `docs/conversion_archive/CURRENCY_DATA.md`.
///
/// **No conversion.** A change names the legally fixed rate where there is
/// one, for the record. Nothing here applies it: a conversion would be an
/// explicit migration or reader action that keeps the original record.
library;

import 'package:flutter/foundation.dart';

import 'lume_date.dart';

/// One country's move from one currency to another.
@immutable
class LumeCurrencyChange {
  const LumeCurrencyChange({
    required this.country,
    required this.from,
    required this.to,
    required this.effectiveIso,
    required this.source,
    this.fixedRate,
  });

  /// ISO 3166-1 alpha-2.
  final String country;

  /// The currency the reference table still names.
  final String from;

  /// The currency a new amount defaults to from [effective].
  final String to;

  /// The day the change took effect, `yyyy-mm-dd`.
  final String effectiveIso;

  /// The day the change took effect.
  LumeDate get effective => LumeDate.parse(effectiveIso);

  /// Units of [from] per one [to], exactly as the law fixes it — or `null`
  /// where no rate was fixed. Recorded; never applied.
  final String? fixedRate;

  /// The legal instrument, so the entry can be checked.
  final String source;
}

abstract final class LumeCountryCurrency {
  /// Every correction to the reference table, oldest first.
  static const List<LumeCurrencyChange> changes = <LumeCurrencyChange>[
    LumeCurrencyChange(
      country: 'BG',
      from: 'BGN',
      to: 'EUR',
      effectiveIso: '2026-01-01',
      fixedRate: '1.95583',
      source:
          'Council of the European Union, 8 July 2025: the decision that '
          'Bulgaria adopts the euro on 1 January 2026, and Council '
          'Regulation (EU) 2025/1409 amending Regulation (EC) No 2866/98 to '
          'fix the rate at 1.95583 lev per euro',
    ),
  ];

  /// The table's version: the date of the newest change it includes.
  static const String asOf = '2026-01-01';

  /// The currency a new amount in [country] starts in, or `null` for a code
  /// the table does not carry.
  static String? current(String country) {
    final String? base = reference[country];
    if (base == null) return null;
    return correct(country, base);
  }

  /// [code] for [country] with every change applied — what the bundled
  /// country table is read through, so a stale code there is never offered.
  static String correct(String country, String code) {
    String out = code;
    for (final LumeCurrencyChange c in changes) {
      if (c.country == country && c.from == out) out = c.to;
    }
    return out;
  }

  /// The web reference's table as captured (`geo.js`), 194 countries.
  /// `lume_country_currency_test.dart` holds it to `assets/data/countries.json`.
  static const Map<String, String> reference = <String, String>{
    'AD': 'EUR',
    'AE': 'AED',
    'AF': 'AFN',
    'AG': 'XCD',
    'AL': 'ALL',
    'AM': 'AMD',
    'AO': 'AOA',
    'AR': 'ARS',
    'AT': 'EUR',
    'AU': 'AUD',
    'AZ': 'AZN',
    'BA': 'BAM',
    'BB': 'BBD',
    'BD': 'BDT',
    'BE': 'EUR',
    'BF': 'XOF',
    'BG': 'BGN',
    'BH': 'BHD',
    'BI': 'BIF',
    'BJ': 'XOF',
    'BN': 'BND',
    'BO': 'BOB',
    'BR': 'BRL',
    'BS': 'BSD',
    'BT': 'BTN',
    'BW': 'BWP',
    'BY': 'BYN',
    'BZ': 'BZD',
    'CA': 'CAD',
    'CD': 'CDF',
    'CF': 'XAF',
    'CG': 'XAF',
    'CH': 'CHF',
    'CI': 'XOF',
    'CL': 'CLP',
    'CM': 'XAF',
    'CN': 'CNY',
    'CO': 'COP',
    'CR': 'CRC',
    'CU': 'CUP',
    'CV': 'CVE',
    'CY': 'EUR',
    'CZ': 'CZK',
    'DE': 'EUR',
    'DJ': 'DJF',
    'DK': 'DKK',
    'DM': 'XCD',
    'DO': 'DOP',
    'DZ': 'DZD',
    'EC': 'USD',
    'EE': 'EUR',
    'EG': 'EGP',
    'ER': 'ERN',
    'ES': 'EUR',
    'ET': 'ETB',
    'FI': 'EUR',
    'FJ': 'FJD',
    'FM': 'USD',
    'FR': 'EUR',
    'GA': 'XAF',
    'GB': 'GBP',
    'GD': 'XCD',
    'GE': 'GEL',
    'GH': 'GHS',
    'GM': 'GMD',
    'GN': 'GNF',
    'GQ': 'XAF',
    'GR': 'EUR',
    'GT': 'GTQ',
    'GW': 'XOF',
    'GY': 'GYD',
    'HN': 'HNL',
    'HR': 'EUR',
    'HT': 'HTG',
    'HU': 'HUF',
    'ID': 'IDR',
    'IE': 'EUR',
    'IL': 'ILS',
    'IN': 'INR',
    'IQ': 'IQD',
    'IR': 'IRR',
    'IS': 'ISK',
    'IT': 'EUR',
    'JM': 'JMD',
    'JO': 'JOD',
    'JP': 'JPY',
    'KE': 'KES',
    'KG': 'KGS',
    'KH': 'KHR',
    'KI': 'AUD',
    'KM': 'KMF',
    'KN': 'XCD',
    'KR': 'KRW',
    'KW': 'KWD',
    'KZ': 'KZT',
    'LA': 'LAK',
    'LB': 'LBP',
    'LC': 'XCD',
    'LI': 'CHF',
    'LK': 'LKR',
    'LR': 'LRD',
    'LS': 'LSL',
    'LT': 'EUR',
    'LU': 'EUR',
    'LV': 'EUR',
    'LY': 'LYD',
    'MA': 'MAD',
    'MC': 'EUR',
    'MD': 'MDL',
    'ME': 'EUR',
    'MG': 'MGA',
    'MH': 'USD',
    'MK': 'MKD',
    'ML': 'XOF',
    'MM': 'MMK',
    'MN': 'MNT',
    'MR': 'MRU',
    'MT': 'EUR',
    'MU': 'MUR',
    'MV': 'MVR',
    'MW': 'MWK',
    'MX': 'MXN',
    'MY': 'MYR',
    'MZ': 'MZN',
    'NA': 'NAD',
    'NE': 'XOF',
    'NG': 'NGN',
    'NI': 'NIO',
    'NL': 'EUR',
    'NO': 'NOK',
    'NP': 'NPR',
    'NR': 'AUD',
    'NZ': 'NZD',
    'OM': 'OMR',
    'PA': 'PAB',
    'PE': 'PEN',
    'PG': 'PGK',
    'PH': 'PHP',
    'PK': 'PKR',
    'PL': 'PLN',
    'PS': 'ILS',
    'PT': 'EUR',
    'PW': 'USD',
    'PY': 'PYG',
    'QA': 'QAR',
    'RO': 'RON',
    'RS': 'RSD',
    'RU': 'RUB',
    'RW': 'RWF',
    'SA': 'SAR',
    'SB': 'SBD',
    'SC': 'SCR',
    'SD': 'SDG',
    'SE': 'SEK',
    'SG': 'SGD',
    'SI': 'EUR',
    'SK': 'EUR',
    'SL': 'SLE',
    'SM': 'EUR',
    'SN': 'XOF',
    'SO': 'SOS',
    'SR': 'SRD',
    'SS': 'SSP',
    'ST': 'STN',
    'SV': 'USD',
    'SY': 'SYP',
    'SZ': 'SZL',
    'TD': 'XAF',
    'TG': 'XOF',
    'TH': 'THB',
    'TJ': 'TJS',
    'TL': 'USD',
    'TM': 'TMT',
    'TN': 'TND',
    'TO': 'TOP',
    'TR': 'TRY',
    'TT': 'TTD',
    'TV': 'AUD',
    'TW': 'TWD',
    'TZ': 'TZS',
    'UA': 'UAH',
    'UG': 'UGX',
    'US': 'USD',
    'UY': 'UYU',
    'UZ': 'UZS',
    'VC': 'XCD',
    'VE': 'VES',
    'VN': 'VND',
    'VU': 'VUV',
    'WS': 'WST',
    'YE': 'YER',
    'ZA': 'ZAR',
    'ZM': 'ZMW',
    'ZW': 'ZWG',
  };
}
