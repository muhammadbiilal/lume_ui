/// Mobile Packages — the reference tool for a single-country comparison
/// explorer.
///
/// `tools/money/packages.tool.js` over `tool-data.js` `MOBILE_PACKAGES`: one
/// bundle per Pakistani operator (Jazz, Zong, Ufone, Telenor), filtered by
/// operator, sorted by price, data or validity, then shown as a compare table
/// and each bundle's own expandable detail. The reference reads
/// `MOBILE_PACKAGES[c.profile.country]` and draws its own unavailable state
/// when the key is missing — every market but Pakistan, at present.
///
/// **Dayroz obligation:** every bundle here is fixture data, frozen at the
/// reference's own capture. A real integration needs each carrier's own live
/// tariff API — Jazz, Zong, Ufone and Telenor each publish (or do not
/// publish) their own bundle catalogue and prices, and there is no single
/// licensed source across them the way there is for, say, gold. Prices and
/// bundle contents change often enough that this list should be treated as a
/// sample, not a quote.
library;

import 'package:flutter/foundation.dart';

@immutable
class LumeMobilePackage {
  const LumeMobilePackage({
    required this.operatorName,
    required this.name,
    required this.data,
    required this.mins,
    required this.sms,
    required this.valid,
    required this.price,
  });

  /// The carrier — a proper noun, carried as the reference spells it, never
  /// translated.
  final String operatorName;

  /// The bundle's own marketing name — a proper noun, never translated.
  final String name;

  /// `'15 GB'` — the reference's own display string, not a bare number.
  final String data;

  /// `'3000 On-net'`.
  final String mins;

  /// `'3000'`.
  final String sms;

  /// `'30 days'`.
  final String valid;

  /// PKR. The reference's `c.moneyRaw(p.price, ccy, 0)` reads the *country's*
  /// currency, not a fixed one — but since this list exists only for
  /// Pakistan, `ccy` is always PKR in practice.
  final int price;

  /// `parseFloat(p.data)` — the number the reference's own sort reads out of
  /// [data] ("15 GB" sorts on 15).
  double get dataGb =>
      double.tryParse(RegExp(r'[\d.]+').stringMatch(data) ?? '') ?? 0;

  /// `parseInt(p.valid, 10)` — the number the reference's own sort reads out
  /// of [valid] ("30 days" sorts on 30).
  int get validDays =>
      int.tryParse(RegExp(r'\d+').stringMatch(valid) ?? '') ?? 0;
}

/// `D.MOBILE_PACKAGES` — keyed by country, one Pakistani list at present.
abstract final class LumeMobilePackages {
  /// `D.MOBILE_PACKAGES[country]` — `null` when this market has no carriers
  /// listed. The tool draws its own honest unavailable state on `null` rather
  /// than showing another market's operators.
  static List<LumeMobilePackage>? forCountry(String countryCode) =>
      countryCode == 'PK' ? _pk : null;

  static const List<LumeMobilePackage> _pk = <LumeMobilePackage>[
    LumeMobilePackage(
      operatorName: 'Jazz',
      name: 'Super Duper Card',
      data: '15 GB',
      mins: '3000 On-net',
      sms: '3000',
      valid: '30 days',
      price: 1150,
    ),
    LumeMobilePackage(
      operatorName: 'Zong',
      name: 'Super Card Max',
      data: '20 GB',
      mins: '3000 On-net',
      sms: '3000',
      valid: '30 days',
      price: 1200,
    ),
    LumeMobilePackage(
      operatorName: 'Ufone',
      name: 'Super Card Plus',
      data: '12 GB',
      mins: '2000 On-net',
      sms: '2000',
      valid: '30 days',
      price: 1050,
    ),
    LumeMobilePackage(
      operatorName: 'Telenor',
      name: 'Super Card',
      data: '10 GB',
      mins: '2500 On-net',
      sms: '2500',
      valid: '30 days',
      price: 1000,
    ),
  ];
}
