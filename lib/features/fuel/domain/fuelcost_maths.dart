/// Fuel Cost, worked out the way the reference works it out —
/// `context.js` `fuelCost()`.
///
/// Distance divided by economy is fuel used; fuel used times price is the
/// trip's cost. Split it and the round trip doubles it. The reference's own
/// arithmetic is untouched by whether the reader is on kilometres or miles —
/// `used = imperial ? dist / econ : dist / econ`, the same division either
/// way, because a mile per gallon and a kilometre per litre are both
/// "distance per unit of fuel".
///
/// **The default price is [LumeFuel]'s, not a second fixture.** Fuel Prices
/// already works out the reader's own market's current price per litre or
/// gallon; `fuelCost()` reads `D.fuelFor(P().country).items[0].v` for its own
/// opening figure, and so does [LumeFuelCostRules.defaultPrice] — the same
/// value, so the two tools never quote different pump prices for the same
/// reader.
///
/// **One correction: no fabricated history.** The reference's own `fuelCost()`
/// also returns two `history` rows — past trips, dated `relDate(-4)` and
/// `relDate(-11)`, at costs derived from the *current* total (`total * 0.82`,
/// `total * 1.44`) rather than any trip the reader actually made. That is
/// the same pattern already declined elsewhere in this port — BMI's five-point
/// "history" and Focus Timer's invented week are both "offsets from the
/// current reading, not a real past record", and neither is reproduced
/// (`tool_capability.dart`). Fuel Cost keeps the reference's real
/// arithmetic — the total, the split, the round trip — and drops only the
/// two rows dressed up as a reader's own past trips when they are actually
/// today's figure multiplied by a constant.
///
/// Money is [LumeMoney] throughout; distance and economy are plain numbers,
/// never a currency.
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_money.dart';
import '../data/fuel_fixtures.dart';

/// One row of `fc.scenarios`, in the reference's own order.
enum LumeFuelCostScenarioKind { solo, shared, roundTrip }

@immutable
class LumeFuelCostScenario {
  const LumeFuelCostScenario({
    required this.kind,
    required this.fuelUsed,
    required this.cost,
  });

  final LumeFuelCostScenarioKind kind;
  final double fuelUsed;
  final LumeMoney cost;
}

/// `fieldsFor('fuelcost', {...})` — what the reader typed.
@immutable
class LumeFuelCostInputs {
  const LumeFuelCostInputs({
    required this.distance,
    required this.economy,
    required this.price,
    required this.people,
  });

  /// Kilometres or miles, whichever the field is labelled in.
  final double distance;

  /// Kilometres per litre, or miles per gallon.
  final double economy;

  /// Per litre or per gallon, matching [LumeFuelMarket.unit].
  final LumeMoney price;

  /// `Math.max(1, Number(f.people))` is applied where this is used, not
  /// here — the raw figure is kept so a screen can still show what the
  /// reader typed.
  final double people;

  LumeCurrency get currency => price.currency;
}

/// `fuelCost()`'s answer, for one set of inputs.
@immutable
class LumeFuelCostResult {
  const LumeFuelCostResult({
    required this.inputs,
    required this.fuelUsed,
    required this.total,
    required this.perPerson,
    required this.perUnit,
    required this.scenarios,
  });

  final LumeFuelCostInputs inputs;

  /// `used = dist / econ`. Zero when [LumeFuelCostInputs.economy] is not a
  /// usable, positive number — the reference divides by whatever `Number()`
  /// makes of the field and would show `Infinity`/`NaN`; Lume shows nothing
  /// owed instead of a broken figure.
  final double fuelUsed;

  /// `total = used * price`.
  final LumeMoney total;

  /// `total / Math.max(1, people)`.
  final LumeMoney perPerson;

  /// `total / Math.max(1, dist)`.
  final LumeMoney perUnit;

  /// `fc.scenarios` — solo, shared, return, in that order.
  final List<LumeFuelCostScenario> scenarios;
}

abstract final class LumeFuelCostRules {
  /// `dist: imperial ? 250 : 400`.
  static double defaultDistance({required bool imperial}) =>
      imperial ? 250 : 400;

  /// `econ: imperial ? 32 : 12`.
  static double defaultEconomy({required bool imperial}) =>
      imperial ? 32 : 12;

  /// `people: 2`.
  static const double defaultPeople = 2;

  /// `price: fuel.items[0].v` — [LumeFuel.forCountry]'s own leading grade,
  /// in its own currency. The one place Fuel Cost reads Fuel Prices' fixture
  /// rather than a table of its own.
  static double defaultPrice(String country) =>
      LumeFuel.forCountry(country).main.price;

  static LumeMoney _scale(LumeMoney m, double factor) =>
      LumeMoney.sum((m.minor * factor).round(), m.currency);

  /// `fuelCost()`, for [inputs].
  static LumeFuelCostResult compute(LumeFuelCostInputs inputs) {
    final bool usable =
        inputs.economy.isFinite &&
        inputs.economy > 0 &&
        inputs.distance.isFinite;
    final double used = usable ? inputs.distance / inputs.economy : 0;
    final LumeMoney total = _scale(inputs.price, used);
    final double people = inputs.people.isFinite && inputs.people >= 1
        ? inputs.people
        : 1;
    final double distDivisor = inputs.distance.isFinite && inputs.distance >= 1
        ? inputs.distance
        : 1;
    final LumeMoney perPerson = _scale(total, 1 / people);
    final LumeMoney perUnit = _scale(total, 1 / distDivisor);

    return LumeFuelCostResult(
      inputs: inputs,
      fuelUsed: used,
      total: total,
      perPerson: perPerson,
      perUnit: perUnit,
      scenarios: <LumeFuelCostScenario>[
        LumeFuelCostScenario(
          kind: LumeFuelCostScenarioKind.solo,
          fuelUsed: used,
          cost: total,
        ),
        LumeFuelCostScenario(
          kind: LumeFuelCostScenarioKind.shared,
          fuelUsed: used,
          cost: _scale(total, 1 / people),
        ),
        LumeFuelCostScenario(
          kind: LumeFuelCostScenarioKind.roundTrip,
          fuelUsed: used * 2,
          cost: _scale(total, 2),
        ),
      ],
    );
  }
}
