/// What the Trains destination is made of.
///
/// Read from `trains.screen.js` and the roster in `data/tool-data.js`, not
/// from the Trains *tool* — the two share a roster and the screen formats it
/// through the locale, so a fare or a departure cannot read differently in the
/// two places.
///
/// Everything here is numbers, keys and structured fields. Nothing holds a
/// sentence: "22:00 → 17:30 · 19h 30m · Rs 8,900" is assembled by the screen
/// from a formatter that knows the reader's locale, currency and clock.
library;

import 'package:flutter/foundation.dart';

/// Where a service is against its timetable.
///
/// `trains.st.onTime` / `trains.st.late` / `trains.st.departed` in the
/// reference, carried as a key rather than as the English it renders to.
enum LumeTrainStatus {
  onTime,

  /// Running behind. [LumeTrainService.delayMinutes] says by how much.
  late_,

  /// Already left. Not a delay and not a problem.
  departed,
}

/// One row of "Today's departures".
@immutable
class LumeTrainService {
  const LumeTrainService({
    required this.number,
    required this.name,
    required this.from,
    required this.to,
    required this.departMinute,
    required this.arriveMinute,
    required this.durationMinutes,
    required this.status,
    required this.delayMinutes,
    required this.fare,
  });

  /// `5UP`. A railway's own identifier, never translated and never reordered
  /// in a right-to-left line.
  final String number;

  final String name;
  final String from;
  final String to;

  /// Minutes past local midnight. Formatted at draw time, because a
  /// locale-formatted string cannot be sorted or compared.
  final int departMinute;
  final int arriveMinute;

  final int durationMinutes;

  final LumeTrainStatus status;

  /// Zero unless [status] is [LumeTrainStatus.late_].
  final int delayMinutes;

  /// In the market's own currency, unconverted. The reference passes it
  /// through `L.moneyRaw`, which formats and never converts.
  final int fare;

  @override
  bool operator ==(Object other) =>
      other is LumeTrainService &&
      other.number == number &&
      other.name == name &&
      other.from == from &&
      other.to == to &&
      other.departMinute == departMinute &&
      other.arriveMinute == arriveMinute &&
      other.durationMinutes == durationMinutes &&
      other.status == status &&
      other.delayMinutes == delayMinutes &&
      other.fare == fare;

  @override
  int get hashCode => Object.hash(
    number,
    name,
    from,
    to,
    departMinute,
    arriveMinute,
    durationMinutes,
    status,
    delayMinutes,
    fare,
  );
}

/// One of the three stops the tracked card names.
@immutable
class LumeTrainStop {
  const LumeTrainStop({
    required this.station,
    this.minuteOfDay,
    this.isNow = false,
  });

  final String station;

  /// `null` for the stop the train is between, which reads "Now" instead of a
  /// time — the reference's own middle column.
  final int? minuteOfDay;

  final bool isNow;

  @override
  bool operator ==(Object other) =>
      other is LumeTrainStop &&
      other.station == station &&
      other.minuteOfDay == minuteOfDay &&
      other.isNow == isNow;

  @override
  int get hashCode => Object.hash(station, minuteOfDay, isNow);
}

/// The service the reader is following.
@immutable
class LumeTrackedTrain {
  const LumeTrackedTrain({
    required this.number,
    required this.name,
    required this.from,
    required this.to,
    required this.status,
    required this.progress,
    required this.observedAt,
    required this.stops,
  });

  final String number;
  final String name;
  final String from;
  final String to;
  final LumeTrainStatus status;

  /// 0–1 along the line. `data-fill="62"` in the reference.
  final double progress;

  /// When the position was last read.
  ///
  /// The reference writes "Updated 2 minutes ago" into static markup. Carried
  /// here as a timestamp so the sentence is computed against the injected
  /// clock and a real feed makes it true without changing the screen.
  final DateTime observedAt;

  /// The three the card shows: where it started, where it is, where it ends.
  final List<LumeTrainStop> stops;

  int minutesAgoAt(DateTime now) {
    final int minutes = now.difference(observedAt).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }
}

/// One card in "Popular routes".
@immutable
class LumePopularRoute {
  const LumePopularRoute({
    required this.fromCode,
    required this.toCode,
    required this.fromName,
    required this.toName,
    required this.durationMinutes,
    required this.trainCount,
    required this.fromFare,
  });

  /// `KHI`, `LHR`. Station codes, carried and never translated.
  final String fromCode;
  final String toCode;

  /// The full names, for what a screen reader says and for the toast.
  final String fromName;
  final String toName;

  final int durationMinutes;
  final int trainCount;

  /// The cheapest fare on the route, in the market's own currency.
  final int fromFare;
}

/// Which day the search is for.
enum LumeJourneyDay {
  today,
  tomorrow,

  /// A date chosen from the picker.
  other,
}

/// What the route search is currently asking.
@immutable
class LumeJourneyQuery {
  const LumeJourneyQuery({
    required this.origin,
    required this.destination,
    this.day = LumeJourneyDay.today,
    this.date,
  });

  final String origin;
  final String destination;
  final LumeJourneyDay day;

  /// Set only when [day] is [LumeJourneyDay.other].
  final DateTime? date;

  /// The same journey, turned around.
  ///
  /// The day and the date come with it: swapping a route does not change
  /// *when* the reader is travelling, and R2 says so explicitly.
  LumeJourneyQuery swapped() => LumeJourneyQuery(
    origin: destination,
    destination: origin,
    day: day,
    date: date,
  );

  /// Both ends named.
  bool get hasBothEnds =>
      origin.trim().isNotEmpty && destination.trim().isNotEmpty;

  /// A journey from a station to itself is not a journey.
  bool get isSameStation =>
      origin.trim().toLowerCase() == destination.trim().toLowerCase();

  /// Whether this is a question a timetable can answer.
  bool get isAskable => hasBothEnds && !isSameStation;

  LumeJourneyQuery withDay(LumeJourneyDay next, {DateTime? on}) =>
      LumeJourneyQuery(
        origin: origin,
        destination: destination,
        day: next,
        date: on,
      );

  @override
  bool operator ==(Object other) =>
      other is LumeJourneyQuery &&
      other.origin == origin &&
      other.destination == destination &&
      other.day == day &&
      other.date == date;

  @override
  int get hashCode => Object.hash(origin, destination, day, date);
}

/// A journey the reader has kept.
///
/// The reference has no saved-journeys screen — its header control reports
/// the intention and nothing more — so this is the contract a real store will
/// satisfy, not a list anything draws yet.
@immutable
class LumeSavedJourney {
  const LumeSavedJourney({
    required this.id,
    required this.query,
    required this.savedAt,
  });

  final String id;
  final LumeJourneyQuery query;
  final DateTime savedAt;
}

/// Everything the Trains destination draws.
@immutable
class LumeTrainsData {
  const LumeTrainsData({
    required this.operatorName,
    required this.query,
    required this.serviceDate,
    required this.tracked,
    required this.departuresFrom,
    required this.departures,
    required this.routes,
  });

  /// "Pakistan Railways". The market's operator, not a fixed string: a country
  /// that gains this destination brings its own.
  final String operatorName;

  final LumeJourneyQuery query;

  /// Which day the departures are for.
  ///
  /// **Explicit, not implied.** R3 lets the fixture reuse one timetable for
  /// every selectable day — the prototype has no alternate-day data — but the
  /// *identity* of the answer has to be real: a list shown under "Tomorrow"
  /// must be able to say which date it is, so a real feed can replace the rows
  /// without the screen having to learn anything new.
  final DateTime serviceDate;

  /// `null` when the reader is following nothing, or when the status source
  /// could not answer.
  final LumeTrackedTrain? tracked;

  /// Which station the departures list is from.
  final String departuresFrom;

  final List<LumeTrainService> departures;
  final List<LumePopularRoute> routes;
}
