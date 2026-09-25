/// Vehicle & Fines — `tools/daily/vehicle.tool.js` over `D.VEHICLES` and
/// `context.js`'s `vehicleCosts()`, typed.
///
/// `countries: {'PK'}` (the catalogue's `vehicle` entry): the reference's own
/// two fixture vehicles are Pakistani plates (`ABC-124`, `LEB-8842`) with
/// Pakistani excise concepts — token tax, not road tax or an MOT — so this is
/// fixture data for one country rather than a fleet invented for a reader
/// elsewhere. Unlike National Savings or Prize Bonds, the reference's own
/// `vehicle.tool.js` has **no internal "unsupported country" branch at
/// all** — it always renders these same two Pakistani vehicles regardless of
/// `P().country` — so the catalogue's `countries` restriction is the *only*
/// thing keeping a non-Pakistani reader from seeing someone else's plates;
/// `LumeToolScreen`'s own eligibility gate (§64) is what actually does that,
/// exactly as it does for Loadshedding, this wave's closest sibling by shape
/// (also no internal country branch of its own).
///
/// **The two vehicles, exactly as `D.VEHICLES` has them:**
/// * `ABC-124` — Toyota Corolla, 2019, token due 30 Sep (in 22 days), 1 open
///   fine, insured to 14 Dec, 84,200 km on the clock.
/// * `LEB-8842` — Honda CD-70, 2022, token due 11 Nov (in 64 days), no open
///   fines, no insurance on record (the reference's own `insurance: '—'`),
///   21,400 km on the clock.
///
/// **Money — a documented scope decision.** `vehicle.tool.js` prices its
/// token/insurance costs and its fine total through `c.money()`, the
/// reference's *converting* helper (`services/locale.js`'s `L.money`): every
/// figure it touches is authored in USD and multiplied by a ~190-currency
/// `RATES` table keyed to whatever currency the reader has chosen (their
/// country's, or a manual override), then rounded to a "nice" number by the
/// same file's `tidy()`. That table and that conversion pipeline are shared
/// infrastructure nothing in this port has built yet, and this tool's own
/// catalogue gate (`countries: {'PK'}`) means only its `PKR` entry (`283`)
/// can ever be exercised through this screen — duplicating the other 189
/// entries here, in a single feature's own directory, would only ever be
/// dead code. [LumeVehicleCosts] therefore carries just that one rate and
/// the reference's own `tidy()` algorithm, ported faithfully, rather than
/// the shared table it is one entry of.
///
/// **Dayroz obligation:** every figure here — the fleet, the token-tax and
/// insurance costs, the demo USD→PKR rate — is fixture data, frozen at the
/// reference's own numbers. A real integration needs Pakistan's excise and
/// taxation department's own token-tax schedule and challan/fine records for
/// the reader's actual registered vehicles, and the reader's own insurer for
/// renewal dates — nothing here is fetched, and nothing here is a live
/// lookup for a plate the reader types (see the tool's own doc comment on
/// its "Check any registration" field).
library;

import 'package:flutter/foundation.dart';

import '../../../core/values/lume_currency.dart';
import '../../../core/values/lume_money.dart';

/// The row's own icon tint — `v.tone` in the reference's fixture, one of two
/// colours the two demo vehicles use.
enum LumeVehicleTone { sky, amber }

@immutable
class LumeVehicle {
  const LumeVehicle({
    required this.plate,
    required this.make,
    required this.year,
    required this.tone,
    required this.token,
    required this.tokenDays,
    required this.insurance,
    required this.fines,
    required this.fineAmount,
    required this.odometerKm,
  });

  final String plate;
  final String make;
  final int year;
  final LumeVehicleTone tone;

  /// `v.token` — the token's due date, exactly as the reference writes it
  /// (`30 Sep`), never parsed into a [DateTime]: the reference only ever
  /// displays it, the same choice already made for Prize Bonds' own draw
  /// dates.
  final String token;

  /// `v.tokenDays` — days until [token] is due.
  final int tokenDays;

  /// `v.insurance` — the renewal date, or `null` where the reference has no
  /// record at all (`'—'`; `LEB-8842` carries none).
  final String? insurance;

  /// `v.fines` — the open-fine count the badge and the summary caption read.
  final int fines;

  /// `v.fineAmount` — a demo figure authored in USD, before
  /// [LumeVehicleCosts]'s conversion; never shown per vehicle by the
  /// reference, only summed across the fleet.
  final double fineAmount;

  /// `v.odo`, in kilometres — the reference's own unit regardless of the
  /// reader's [LumeUnits] preference; [LumeVehicleDistance] converts it for
  /// display.
  final int odometerKm;

  /// `v.plate.slice(0, 3)` — the row's own logo initials.
  String get logo => plate.length >= 3 ? plate.substring(0, 3) : plate;
}

/// `D.VEHICLES` — the reference's own two-vehicle demo fleet, in its own
/// order (the order [LumeVehicleCosts.tokenFor] keys off).
const List<LumeVehicle> kVehicles = <LumeVehicle>[
  LumeVehicle(
    plate: 'ABC-124',
    make: 'Toyota Corolla',
    year: 2019,
    tone: LumeVehicleTone.sky,
    token: '30 Sep',
    tokenDays: 22,
    insurance: '14 Dec',
    fines: 1,
    fineAmount: 12,
    odometerKm: 84200,
  ),
  LumeVehicle(
    plate: 'LEB-8842',
    make: 'Honda CD-70',
    year: 2022,
    tone: LumeVehicleTone.amber,
    token: '11 Nov',
    tokenDays: 64,
    insurance: null,
    fines: 0,
    fineAmount: 0,
    odometerKm: 21400,
  ),
];

/// `context.js`'s `VEHICLE_COSTS.PK` and `L.money()`'s conversion pipeline,
/// narrowed to the one currency this PK-only tool can reach — see this
/// file's own doc comment for why the reference's other five countries and
/// its ~190-currency `RATES` table are not reproduced here.
abstract final class LumeVehicleCosts {
  /// `RATES.PKR` — approximate PKR per 1 USD, the reference's own demo rate.
  static const double _pkrPerUsd = 283;

  /// `tidy(v)` — rounds a converted demo figure to a "nice" number instead
  /// of showing raw cents of arithmetic on a made-up rate, ported exactly:
  /// nearest thousand from 100,000, nearest hundred from 10,000, nearest ten
  /// from 1,000, nearest whole from 100, nearest half from 10, else nearest
  /// tenth.
  static double _tidy(double v) {
    if (v >= 100000) return (v / 1000).round() * 1000;
    if (v >= 10000) return (v / 100).round() * 100;
    if (v >= 1000) return (v / 10).round() * 10;
    if (v >= 100) return v.roundToDouble();
    if (v >= 10) return (v * 2).round() / 2;
    return (v * 10).round() / 10;
  }

  static LumeMoney _fromUsd(double usd, LumeCurrency currency) {
    final double major = _tidy(usd * _pkrPerUsd);
    return LumeMoney.entry((major * currency.scale).round(), currency);
  }

  /// `VEHICLE_COSTS.PK.tokenCar: 43` (USD), converted and tidied.
  static LumeMoney tokenCar(LumeCurrency currency) => _fromUsd(43, currency);

  /// `VEHICLE_COSTS.PK.tokenBike: 6` (USD), converted and tidied.
  static LumeMoney tokenBike(LumeCurrency currency) => _fromUsd(6, currency);

  /// `VEHICLE_COSTS.PK.insurance: 150` (USD), converted and tidied.
  static LumeMoney insurance(LumeCurrency currency) => _fromUsd(150, currency);

  /// `i === 0 ? cfg.tokenCar : cfg.tokenBike` — the reminders timeline charges
  /// the fleet's first vehicle the car rate and every other the bike rate,
  /// exactly as the reference's own ternary does (it never actually checks
  /// what kind of vehicle a row is).
  static LumeMoney tokenFor(int vehicleIndex, LumeCurrency currency) =>
      vehicleIndex == 0 ? tokenCar(currency) : tokenBike(currency);

  /// `D.VEHICLES.reduce((a, v) => a + v.fineAmount, 0)`, converted and
  /// tidied — the summary card's "Outstanding" stat.
  static LumeMoney fineTotal(
    List<LumeVehicle> vehicles,
    LumeCurrency currency,
  ) {
    final double usd = vehicles.fold<double>(
      0,
      (double a, LumeVehicle v) => a + v.fineAmount,
    );
    return _fromUsd(usd, currency);
  }
}

/// `query = (c.state('q') || '').trim().toLowerCase()`;
/// `vehicles.filter(v => (v.plate + ' ' + v.make).toLowerCase().indexOf(query) !== -1)`
/// — a real filter over the fleet, unlike the "Check any registration"
/// field below it (see the tool's own doc comment).
List<LumeVehicle> lumeVehicleFilter(List<LumeVehicle> vehicles, String query) {
  final String q = query.trim().toLowerCase();
  if (q.isEmpty) return vehicles;
  return vehicles
      .where(
        (LumeVehicle v) => '${v.plate} ${v.make}'.toLowerCase().contains(q),
      )
      .toList();
}
