/// Zakat, worked out the way the reference works it out.
///
/// `context.js` `zakat()`: 2.5% of net zakatable wealth once it reaches the
/// lower of two nisab thresholds — 87.48 grams of gold or 612.36 grams of
/// silver, at the reference's own fixture prices per gram. Assets are cash,
/// gold, silver, investments and business holdings; liabilities come off the
/// total before the threshold is tested.
///
/// **The gold and silver prices are [LumeMetals]'s, not a second fixture.**
/// GoldRates already works out "88 dollars a gram" and "1.05 dollars a gram"
/// at the reader's currency ([LumeMetals.forCurrency]) — the same figures
/// `zakat()` multiplies by, so Zakat reuses that one calculation rather than
/// inventing a rate table of its own. Every price is still fixture data, as
/// GoldRates' own library doc says of itself: nothing here is fetched, and
/// `LumeToolScreen` draws that disclosure automatically from capability
/// metadata (`zakat` is not on any of [LumeDataCapability]'s
/// durable/computed/input-only lists, so a shipping build reads "Sample
/// data" over these figures exactly as it does over GoldRates' — nothing in
/// this tool repeats or overrides that).
///
/// **One correction.** The reference's own `zakat()` tests eligibility
/// against `Math.min(nisabGold, nisabSilver)` — its comment says plainly
/// that the silver threshold is the lower one and "the majority position,
/// the one this screen applies" — but the screen it draws (`zakat.tool.js`)
/// then *displays* `nisabGold` next to a plain "Nisab" label, in both the
/// context bar and the summary card. A reader would be shown a threshold
/// several times larger than the one actually tested against their assets.
/// Lume shows the number the calculation uses ([LumeZakatResult.nisab], the
/// minimum) under that label, the same kind of correction already made to
/// Loan's amortisation (a second `var principal` shadowing the first) and
/// GoldRates' converter (a fixed worth that never changed with the weight
/// typed) — a divergence from what the reference draws, not from what it
/// computes.
///
/// Money is [LumeMoney] throughout; grams are a weight, never a currency.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_money.dart';
import '../../goldrates/data/goldrates_fixtures.dart';

/// One row of the breakdown table, in the reference's own order.
enum LumeZakatLineKind {
  cash,
  gold,
  silver,
  investments,
  business,
  liabilities,
  netAssets,
  payable,
}

/// A breakdown row. [amount] is signed — negative for
/// [LumeZakatLineKind.liabilities], and only there — and [grams] is set only
/// for [LumeZakatLineKind.gold] and [LumeZakatLineKind.silver].
@immutable
class LumeZakatLine {
  const LumeZakatLine({required this.kind, required this.amount, this.grams});

  final LumeZakatLineKind kind;
  final LumeMoney amount;
  final double? grams;
}

/// What the reader typed — `fieldsFor('zakat', {...})`.
@immutable
class LumeZakatInputs {
  const LumeZakatInputs({
    required this.cash,
    required this.goldGrams,
    required this.silverGrams,
    required this.investments,
    required this.business,
    required this.liabilities,
  });

  final LumeMoney cash;

  /// Grams of gold held — a weight, not an amount of [LumeMoney.currency].
  final double goldGrams;
  final double silverGrams;
  final LumeMoney investments;
  final LumeMoney business;
  final LumeMoney liabilities;

  /// The currency every money field here is in — they are all entered in
  /// the reader's one currency, so any one of them names it.
  LumeCurrency get currency => cash.currency;
}

/// `zakat()`'s answer, for one set of inputs and one metals price.
@immutable
class LumeZakatResult {
  const LumeZakatResult({
    required this.inputs,
    required this.goldValue,
    required this.silverValue,
    required this.nisabGold,
    required this.nisabSilver,
    required this.nisab,
    required this.net,
    required this.eligible,
    required this.due,
    required this.lines,
  });

  final LumeZakatInputs inputs;

  /// `Number(f.gold) * goldPerGram`.
  final LumeMoney goldValue;
  final LumeMoney silverValue;

  /// `87.48 * goldPerGram`.
  final LumeMoney nisabGold;

  /// `612.36 * silverPerGram`.
  final LumeMoney nisabSilver;

  /// `Math.min(nisabGold, nisabSilver)` — what eligibility is actually
  /// tested against, and the figure Lume shows for it (see the library's
  /// "One correction").
  final LumeMoney nisab;

  /// Assets less liabilities. Signed: a reader whose liabilities exceed
  /// their assets sees a negative net, exactly as the reference computes
  /// (never clamped to zero).
  final LumeMoney net;

  /// `net >= nisab`.
  final bool eligible;

  /// `eligible ? net * 0.025 : 0`.
  final LumeMoney due;

  /// The eight rows `zakat()`'s own `lines` array draws, in its order.
  final List<LumeZakatLine> lines;
}

/// The reference's arithmetic — a line-by-line port of `context.js`
/// `zakat()`.
abstract final class LumeZakatRules {
  static const double rate = 0.025;

  /// 20 mithqal — the gold nisab, in grams.
  static const double nisabGoldGrams = 87.48;

  /// 200 dirham — the silver nisab, in grams.
  static const double nisabSilverGrams = 612.36;

  /// `gold: 40` — the field's own opening value, not derived from the rate.
  static const double defaultGoldGrams = 40;

  /// `silver: 0`.
  static const double defaultSilverGrams = 0;

  /// `Math.round(4000 * rate / 100) * 100`.
  static LumeMoney openingCash(double ratePerUsd, LumeCurrency currency) =>
      _fromMajor(_roundTo(4000 * ratePerUsd, 100), currency);

  /// `Math.round(2000 * rate / 100) * 100`.
  static LumeMoney openingInvestments(
    double ratePerUsd,
    LumeCurrency currency,
  ) => _fromMajor(_roundTo(2000 * ratePerUsd, 100), currency);

  /// `Math.round(500 * rate / 100) * 100`.
  static LumeMoney openingLiabilities(
    double ratePerUsd,
    LumeCurrency currency,
  ) => _fromMajor(_roundTo(500 * ratePerUsd, 100), currency);

  static double _roundTo(double v, double step) => (v / step).round() * step;

  /// An amount in major units (dollars, rupees — whole currency, not minor
  /// units) as [LumeMoney], rounded to the currency's own precision. Never
  /// negative here: every opening default and every gram-to-money
  /// conversion this rule works out is zero or more.
  static LumeMoney _fromMajor(double major, LumeCurrency currency) =>
      LumeMoney.sum((major * currency.scale).round(), currency);

  /// [m] scaled by a plain fraction — `net * 0.025` — rounded to the
  /// nearest minor unit directly, never through a display string or a
  /// second pass through [_fromMajor].
  static LumeMoney scale(LumeMoney m, double factor) =>
      LumeMoney.sum((m.minor * factor).round(), m.currency);

  /// `zakat()`, for [inputs] at [metals]'s gold and silver prices. [metals]
  /// must be [LumeMetals.forCurrency] of [LumeZakatInputs.currency] — the
  /// same price GoldRates would show the reader for their own currency.
  static LumeZakatResult compute({
    required LumeZakatInputs inputs,
    required LumeMetals metals,
  }) {
    final LumeCurrency currency = inputs.currency;
    final LumeMoney goldValue = _fromMajor(
      inputs.goldGrams * metals.goldPerGram,
      currency,
    );
    final LumeMoney silverValue = _fromMajor(
      inputs.silverGrams * metals.silverPerGram,
      currency,
    );
    final LumeMoney nisabGold = _fromMajor(
      nisabGoldGrams * metals.goldPerGram,
      currency,
    );
    final LumeMoney nisabSilver = _fromMajor(
      nisabSilverGrams * metals.silverPerGram,
      currency,
    );
    final LumeMoney nisab = LumeMoney.min(nisabGold, nisabSilver);
    final LumeMoney assets =
        inputs.cash +
        goldValue +
        silverValue +
        inputs.investments +
        inputs.business;
    final LumeMoney net = assets - inputs.liabilities;
    final bool eligible = net.compareTo(nisab) >= 0;
    final LumeMoney due = eligible
        ? scale(net, rate)
        : LumeMoney.zero(currency);

    return LumeZakatResult(
      inputs: inputs,
      goldValue: goldValue,
      silverValue: silverValue,
      nisabGold: nisabGold,
      nisabSilver: nisabSilver,
      nisab: nisab,
      net: net,
      eligible: eligible,
      due: due,
      lines: <LumeZakatLine>[
        LumeZakatLine(
          kind: LumeZakatLineKind.cash,
          amount: LumeMoney.sum(inputs.cash.minor, currency),
        ),
        LumeZakatLine(
          kind: LumeZakatLineKind.gold,
          amount: goldValue,
          grams: inputs.goldGrams,
        ),
        LumeZakatLine(
          kind: LumeZakatLineKind.silver,
          amount: silverValue,
          grams: inputs.silverGrams,
        ),
        LumeZakatLine(
          kind: LumeZakatLineKind.investments,
          amount: LumeMoney.sum(inputs.investments.minor, currency),
        ),
        LumeZakatLine(
          kind: LumeZakatLineKind.business,
          amount: LumeMoney.sum(inputs.business.minor, currency),
        ),
        LumeZakatLine(
          kind: LumeZakatLineKind.liabilities,
          amount: LumeMoney.sum(-inputs.liabilities.minor, currency),
        ),
        LumeZakatLine(kind: LumeZakatLineKind.netAssets, amount: net),
        LumeZakatLine(kind: LumeZakatLineKind.payable, amount: due),
      ],
    );
  }
}
