/// Faraid, worked out the way the reference works it out — plus one
/// disclosure the reference itself never draws.
///
/// `context.js` `faraid()`: three heir categories only — wife/wives, sons
/// and daughters. Never father, mother, husband (a deceased *woman's* own
/// spouse), siblings, grandchildren or grandparents — this is a narrow,
/// three-category calculator, not a general Islamic inheritance engine, and
/// that scope is real and disclosed, not silently implied away.
///
/// The estate is reduced by debts (and funeral costs, folded into the same
/// field — the classical order: funeral costs and debts come off the estate
/// before anything else), then by a bequest (*wasiyyah*) capped at one third
/// of what remains after debts — the Sunnah's own limit, from the hadith of
/// Sa'd ibn Abi Waqqas ("a third, and even a third is much" — Bukhari 2742,
/// Muslim 1628). What is left (`net`) is what gets distributed.
///
/// **The classical fixed shares this scope actually needs (Qur'an 4:11-12).**
/// A wife (or wives, collectively — the fraction is shared *between* however
/// many survive, never multiplied by their count) takes 1/8 where the
/// deceased leaves children and 1/4 where he does not. Sons and daughters
/// together are *asaba* (residuary): from whatever remains once the wife's
/// fixed share is out, a son's share is twice a daughter's
/// ("`li-dhakari mithlu hazzi'l-unthayayn`" — 4:11).
///
/// **Verified by hand, combination by combination, because the input space
/// really is only three categories:**
///  - *wife + son(s) + daughter(s)*: wife 1/8, the residue split 2:1 between
///    sons and daughters as `asaba bi'l-ghayr` (a daughter becomes residuary
///    *through* a co-inheriting son). Textbook.
///  - *wife + son(s) only*, or *sons only*: sons are pure `asaba` and take
///    the entire residue (or the entire estate, with no wife). Textbook.
///  - *wife + daughter(s) only*, or *daughters only*: the reference's own
///    arithmetic still gives the daughter(s) the whole residue, exactly as
///    if they were residuary — which, taken literally, is **not** the
///    textbook route for a daughter with no co-inheriting son. A lone
///    daughter's own fixed share (`fard`) is 1/2; two or more collectively
///    take 2/3 — not "whatever residue is left". But worked by hand, the
///    *total* still comes out identical: with no other heir type this tool
///    can even express, any residue left after the fixed shares is
///    returned (`radd`) to the Qur'anic heirs present — excluding a
///    spouse, who does not take radd in the majority position — which,
///    with only daughters left to return it to, hands them the entire
///    residue anyway. Worked example: wife + 2 daughters, net = 24 units.
///    Fixed shares: wife 1/8 = 3, daughters 2/3 = 16. Leftover = 24 − 3 − 16
///    = 5, all returned to the daughters (the only non-spouse Qur'anic heir
///    present) = 16 + 5 = 21, i.e. 7/8 of net — the exact figure
///    `residue (net − wifeShare = 21) × 100%` already gives them. The same
///    holds for one daughter (1/2 fard instead of 2/3) and for daughters
///    with no wife at all. **So every number this tool can produce for a
///    supported combination is correct**, even though "asaba" is not the
///    correct classical label for what a daughter-only case actually is —
///    a labelling looseness in the reference, not a wrong figure.
///  - *wife alone, no children*: **this is where the reference is actually
///    incomplete, not just loosely labelled.** It gives the wife 1/4 and
///    then simply never mentions the other 3/4 — not to her (correct: most
///    schools exclude a spouse from radd), not to anyone else, and not as a
///    disclosed gap either. A reader would see a "distribution" that
///    silently accounts for only a quarter of the estate. **Flagged for
///    human review, not silently patched with an invented heir**: this
///    build discloses the undistributed remainder honestly instead
///    (`LumeFaraidShareKind.unallocated`) — it does not invent who receives
///    it, because with no father, siblings or extended family entered,
///    nothing here can honestly say.
///
/// **`awl` (fixed shares that together exceed the whole estate — the
/// textbook trigger is a husband plus two or more sisters) cannot arise
/// from this tool's three heir categories at all**, and is proved
/// unreachable by property test rather than asserted by comment alone
/// (`faraid_maths_test.dart`): a wife's fixed fraction never exceeds 1/4,
/// and sons/daughters only ever divide whatever residue is left — never
/// more. `radd` (shares falling short) *is* reachable — the wife-alone case
/// above — and is the one this library discloses rather than hides.
///
/// Money is [LumeMoney] throughout, exact to the minor unit. Heir counts are
/// non-negative integers — the reference's own `Number(f.wife)` accepts
/// anything (including a fractional or absurd count), but the field these
/// counts come from is a stepper, not free text, so an integer is what a
/// reader can ever actually produce.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_money.dart';

/// Which fraction rule produced a share — for display only; the amount is
/// always the one actually computed.
enum LumeFaraidFraction {
  /// `1/8` — a wife (or wives, collectively) where the deceased leaves
  /// children.
  eighth,

  /// `1/4` — a wife (or wives, collectively) where the deceased leaves no
  /// children.
  quarter,

  /// `asaba` — sons and daughters, from whatever residue remains.
  residuary,

  /// No rule produced this amount — it is the honest gap this build
  /// discloses (see the library doc's "wife alone" case), or the
  /// reference's own zero-heirs fallback.
  unallocated,
}

/// One row of the distribution — one heir category, or the disclosed
/// remainder.
enum LumeFaraidShareKind { wife, sons, daughters, unallocated }

@immutable
class LumeFaraidShare {
  const LumeFaraidShare({
    required this.kind,
    required this.fraction,
    required this.amount,
  });

  final LumeFaraidShareKind kind;
  final LumeFaraidFraction fraction;
  final LumeMoney amount;
}

/// What the reader typed — `fieldsFor('faraid', {...})`, plus the heir
/// steppers the reference declares alongside it.
@immutable
class LumeFaraidInputs {
  const LumeFaraidInputs({
    required this.gross,
    required this.debts,
    required this.bequestRequested,
    required this.wives,
    required this.sons,
    required this.daughters,
  });

  final LumeMoney gross;
  final LumeMoney debts;

  /// What the reader typed into the bequest field — before the one-third
  /// cap. Never clamped to zero or more here, matching how every money
  /// field in this codebase (Zakat's own fields, `_money()`) reads whatever
  /// `Number()` would make of the text, including a negative one; the
  /// one-third cap is applied in [LumeFaraidRules.compute], exactly as
  /// `Math.min(bequest, afterDebts / 3)` applies it in the reference.
  final LumeMoney bequestRequested;

  final int wives;
  final int sons;
  final int daughters;

  LumeCurrency get currency => gross.currency;
}

/// `faraid()`'s answer, for one set of inputs.
@immutable
class LumeFaraidResult {
  const LumeFaraidResult({
    required this.inputs,
    required this.afterDebts,
    required this.bequest,
    required this.net,
    required this.hasChildren,
    required this.shares,
  });

  final LumeFaraidInputs inputs;

  /// `Math.max(0, gross - debts)`.
  final LumeMoney afterDebts;

  /// `Math.min(bequestRequested, afterDebts / 3)` — the bequest actually
  /// applied, after the one-third cap.
  final LumeMoney bequest;

  /// `Math.max(0, afterDebts - bequest)` — what is actually distributed.
  final LumeMoney net;

  /// `sons + daughters > 0` — decides the wife's fraction (1/8 vs 1/4).
  final bool hasChildren;

  /// In the reference's own order: wife, sons, daughters — followed by
  /// [LumeFaraidShareKind.unallocated] only when the entered heirs do not
  /// account for the whole of [net].
  final List<LumeFaraidShare> shares;
}

/// The reference's arithmetic — a line-by-line port of `context.js`
/// `faraid()` — plus the one disclosure documented in this library's own
/// doc comment.
abstract final class LumeFaraidRules {
  /// `gross: Math.round(60000 * rate / 1000) * 1000`.
  static LumeMoney openingGross(double ratePerUsd, LumeCurrency currency) =>
      _fromMajor(_roundTo(60000 * ratePerUsd, 1000), currency);

  /// `debts: Math.round(5000 * rate / 1000) * 1000`.
  static LumeMoney openingDebts(double ratePerUsd, LumeCurrency currency) =>
      _fromMajor(_roundTo(5000 * ratePerUsd, 1000), currency);

  /// `bequest: 0`.
  static LumeMoney openingBequest(LumeCurrency currency) =>
      LumeMoney.zero(currency);

  /// `wife: 1, son: 2, daughter: 1` — the reference's own opening steppers.
  static const int defaultWives = 1;
  static const int defaultSons = 2;
  static const int defaultDaughters = 1;

  static double _roundTo(double v, double step) => (v / step).round() * step;

  static LumeMoney _fromMajor(double major, LumeCurrency currency) =>
      LumeMoney.sum((major * currency.scale).round(), currency);

  /// [m] scaled by a plain fraction, rounded to the nearest minor unit —
  /// the same pattern Zakat's own `scale()` uses for `net * 0.025`.
  static LumeMoney _scale(LumeMoney m, double factor) =>
      LumeMoney.sum((m.minor * factor).round(), m.currency);

  static LumeMoney _maxZero(LumeMoney m) =>
      m.isNegative ? LumeMoney.zero(m.currency) : m;

  /// `faraid()`, for [inputs].
  static LumeFaraidResult compute({required LumeFaraidInputs inputs}) {
    final LumeCurrency currency = inputs.currency;

    // `Math.max(0, Number(f.gross) - Number(f.debts))`.
    final LumeMoney afterDebts = _maxZero(inputs.gross - inputs.debts);

    // `Math.min(Number(f.bequest) || 0, afterDebts / 3)`. Rounded to the
    // nearest minor unit rather than carried as a fractional cent, the same
    // adaptation Zakat's `scale()` makes of the reference's own float math.
    final LumeMoney third = _scale(afterDebts, 1 / 3);
    final LumeMoney bequest = LumeMoney.min(inputs.bequestRequested, third);

    // `Math.max(0, afterDebts - bequest)`.
    final LumeMoney net = _maxZero(afterDebts - bequest);

    final int wives = inputs.wives < 0 ? 0 : inputs.wives;
    final int sons = inputs.sons < 0 ? 0 : inputs.sons;
    final int daughters = inputs.daughters < 0 ? 0 : inputs.daughters;
    final bool hasChildren = sons + daughters > 0;

    // A wife's fraction follows the heirs, not a constant (4:12).
    final LumeMoney wifeShare = wives > 0
        ? _scale(net, hasChildren ? 1 / 8 : 1 / 4)
        : LumeMoney.zero(currency);
    final LumeMoney residue = net - wifeShare;

    final int parts = sons * 2 + daughters;
    LumeMoney sonsShare = LumeMoney.zero(currency);
    LumeMoney daughtersShare = LumeMoney.zero(currency);
    if (parts > 0) {
      if (sons > 0 && daughters > 0) {
        // Split 2:1, sons rounded first and daughters taking the exact
        // remainder — so the pair always sums to `residue` to the minor
        // unit, with no rounding cent left unaccounted between them.
        sonsShare = _scale(residue, (sons * 2) / parts);
        daughtersShare = residue - sonsShare;
      } else if (sons > 0) {
        // The sole heir type left absorbs the whole residue exactly — no
        // division, so no rounding to introduce.
        sonsShare = residue;
      } else {
        daughtersShare = residue;
      }
    }

    final List<LumeFaraidShare> shares = <LumeFaraidShare>[
      if (wives > 0)
        LumeFaraidShare(
          kind: LumeFaraidShareKind.wife,
          fraction: hasChildren
              ? LumeFaraidFraction.eighth
              : LumeFaraidFraction.quarter,
          amount: wifeShare,
        ),
      if (sons > 0)
        LumeFaraidShare(
          kind: LumeFaraidShareKind.sons,
          fraction: LumeFaraidFraction.residuary,
          amount: sonsShare,
        ),
      if (daughters > 0)
        LumeFaraidShare(
          kind: LumeFaraidShareKind.daughters,
          fraction: LumeFaraidFraction.residuary,
          amount: daughtersShare,
        ),
    ];

    // What every pushed share actually accounts for — never assumed to be
    // `net`, so a genuine shortfall (the wife-alone case; the zero-heir
    // case) is caught rather than swallowed.
    final LumeMoney accounted = LumeMoney.total(
      shares.map((LumeFaraidShare s) => s.amount),
      currency,
    );
    final LumeMoney unallocated = net - accounted;
    if (unallocated.isPositive) {
      shares.add(
        LumeFaraidShare(
          kind: LumeFaraidShareKind.unallocated,
          fraction: LumeFaraidFraction.unallocated,
          amount: unallocated,
        ),
      );
    }

    return LumeFaraidResult(
      inputs: inputs,
      afterDebts: afterDebts,
      bequest: bequest,
      net: net,
      hasChildren: hasChildren,
      shares: shares,
    );
  }
}
