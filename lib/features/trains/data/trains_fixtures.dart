/// Trains, as a deterministic fixture.
///
/// The roster is `data/tool-data.js`'s `TRAINS`, which is the same one the
/// Trains *tool* reads — the reference shares it on purpose so a fare cannot
/// read differently in two places. The tracked service, the three route cards
/// and the search's two stations are `trains.screen.js`'s own static markup.
///
/// **Nothing here is labelled live.** Every source reports
/// `LumeTrainsFreshness.fixture`, which is what it is. The reference's
/// "Updated 2 minutes ago" is reproduced through a pinned observation time
/// rather than as the words, so a real feed makes it true without touching the
/// screen.
library;

import 'dart:async';

import '../../catalogue/domain/eligibility.dart';
import '../domain/trains_model.dart';
import '../domain/trains_repository.dart';

/// `TRAINS` in `tool-data.js`, in the order it declares them.
const List<LumeTrainService> _roster = <LumeTrainService>[
  LumeTrainService(
    number: '5UP',
    name: 'Green Line Express',
    from: 'Karachi Cantt',
    to: 'Islamabad',
    departMinute: 22 * 60,
    arriveMinute: 17 * 60 + 30,
    durationMinutes: 19 * 60 + 30,
    status: LumeTrainStatus.onTime,
    delayMinutes: 0,
    fare: 8900,
    fromCode: 'KYC',
    toCode: 'ISL',
    platform: '4',
    speedKmh: 96,
    next: 'Rohri Junction',
    progress: 0.48,
    classes: <String>['AC Sleeper', 'AC Business'],
  ),
  LumeTrainService(
    number: '7UP',
    name: 'Tezgam Express',
    from: 'Karachi Cantt',
    to: 'Rawalpindi',
    departMinute: 17 * 60,
    arriveMinute: 16 * 60 + 15,
    durationMinutes: 23 * 60 + 15,
    status: LumeTrainStatus.late_,
    delayMinutes: 35,
    fare: 6300,
    fromCode: 'KYC',
    toCode: 'RWP',
    platform: '2',
    speedKmh: 78,
    next: 'Khanewal Junction',
    progress: 0.71,
    classes: <String>['AC Standard', 'Economy'],
  ),
  LumeTrainService(
    number: '41UP',
    name: 'Karakoram Express',
    from: 'Karachi Cantt',
    to: 'Lahore',
    departMinute: 15 * 60,
    arriveMinute: 8 * 60 + 45,
    durationMinutes: 17 * 60 + 45,
    status: LumeTrainStatus.onTime,
    delayMinutes: 0,
    fare: 7100,
    fromCode: 'KYC',
    toCode: 'LHR',
    platform: '1',
    speedKmh: 104,
    next: 'Multan Cantt',
    progress: 0.62,
    classes: <String>['AC Business', 'Economy'],
  ),
  LumeTrainService(
    number: '27DN',
    name: 'Shalimar Express',
    from: 'Lahore',
    to: 'Karachi City',
    departMinute: 6 * 60 + 15,
    arriveMinute: 1 * 60 + 30,
    durationMinutes: 19 * 60 + 15,
    status: LumeTrainStatus.departed,
    delayMinutes: 0,
    fare: 5400,
    fromCode: 'LHR',
    toCode: 'KYC',
    platform: '6',
    speedKmh: 88,
    next: 'Sahiwal',
    progress: 0.14,
    classes: <String>['AC Standard', 'Economy'],
  ),
  LumeTrainService(
    number: '101UP',
    name: 'Pakistan Express',
    from: 'Karachi Cantt',
    to: 'Rawalpindi',
    departMinute: 11 * 60 + 30,
    arriveMinute: 13 * 60,
    durationMinutes: 25 * 60 + 30,
    status: LumeTrainStatus.late_,
    delayMinutes: 70,
    fare: 4850,
    fromCode: 'KYC',
    toCode: 'RWP',
    platform: '3',
    speedKmh: 62,
    next: 'Bahawalpur',
    progress: 0.36,
    classes: <String>['Economy'],
  ),
];

/// `D.TRAIN_STOPS` — the Trains tool's own fixed station timeline, shown
/// under whichever service in [_roster] is selected (see
/// `LumeTrainTimelineStop`'s own doc comment for why it is one list rather
/// than one per service).
const List<LumeTrainTimelineStop> _timelineStops = <LumeTrainTimelineStop>[
  LumeTrainTimelineStop(
    name: 'Karachi Cantt',
    scheduledMinute: 22 * 60,
    actualMinute: 22 * 60,
    state: LumeTrainTimelineState.done,
    km: 0,
  ),
  LumeTrainTimelineStop(
    name: 'Hyderabad Junction',
    scheduledMinute: 5,
    actualMinute: 11,
    state: LumeTrainTimelineState.done,
    km: 165,
  ),
  LumeTrainTimelineStop(
    name: 'Rohri Junction',
    scheduledMinute: 4 * 60 + 20,
    actualMinute: 4 * 60 + 20,
    state: LumeTrainTimelineState.now,
    km: 480,
  ),
  LumeTrainTimelineStop(
    name: 'Rahim Yar Khan',
    scheduledMinute: 7 * 60 + 5,
    state: LumeTrainTimelineState.next,
    km: 660,
  ),
  LumeTrainTimelineStop(
    name: 'Multan Cantt',
    scheduledMinute: 10 * 60 + 15,
    state: LumeTrainTimelineState.next,
    km: 890,
  ),
  LumeTrainTimelineStop(
    name: 'Lahore Junction',
    scheduledMinute: 14 * 60 + 40,
    state: LumeTrainTimelineState.next,
    km: 1210,
  ),
  LumeTrainTimelineStop(
    name: 'Rawalpindi',
    scheduledMinute: 16 * 60 + 55,
    state: LumeTrainTimelineState.next,
    km: 1480,
  ),
  LumeTrainTimelineStop(
    name: 'Islamabad',
    scheduledMinute: 17 * 60 + 30,
    state: LumeTrainTimelineState.next,
    km: 1505,
  ),
];

/// `.section__sub` on the tracked card: "Updated 2 minutes ago".
///
/// **A literal in the reference**, like Explore's "updated 4 min ago" (C24).
/// Reproduced as an age against the injected clock so the sentence is computed
/// rather than written down. A real running-status feed supplies the real
/// observation time here and the label follows it.
const int kTrackedAgeMinutes = 2;

/// `data-fill="62"` on the tracked card's track.
const double kTrackedProgress = 0.62;

/// The three stops the tracked card names, from its static markup.
const List<LumeTrainStop> _trackedStops = <LumeTrainStop>[
  LumeTrainStop(station: 'Karachi', minuteOfDay: 22 * 60),
  LumeTrainStop(station: 'Near Rohri', isNow: true),
  LumeTrainStop(station: 'Islamabad', minuteOfDay: 17 * 60 + 30),
];

/// The three `.routecard`s, with the figures their toasts quote.
const List<LumePopularRoute> _routes = <LumePopularRoute>[
  LumePopularRoute(
    fromCode: 'KHI',
    toCode: 'LHR',
    fromName: 'Karachi',
    toName: 'Lahore',
    durationMinutes: 17 * 60 + 45,
    trainCount: 4,
    fromFare: 2400,
  ),
  LumePopularRoute(
    fromCode: 'KHI',
    toCode: 'ISB',
    fromName: 'Karachi',
    toName: 'Islamabad',
    durationMinutes: 19 * 60 + 30,
    trainCount: 2,
    fromFare: 3100,
  ),
  LumePopularRoute(
    fromCode: 'LHR',
    toCode: 'RWP',
    fromName: 'Lahore',
    toName: 'Rawalpindi',
    durationMinutes: 4 * 60 + 20,
    trainCount: 6,
    fromFare: 1150,
  ),
];

/// The two stations the search opens on, and the station the departures list
/// is from.
const String kDefaultOrigin = 'Karachi Cantt';
const String kDefaultDestination = 'Lahore Junction';

/// The operator a market's rail service belongs to.
///
/// One entry, because one market has this destination. It is a map rather than
/// a constant so the second market to gain rail brings its own name instead of
/// inheriting Pakistan's.
const Map<String, String> _operators = <String, String>{
  'PK': 'Pakistan Railways',
};

/// Composes Trains. Pure, so the composition can be asserted without a frame.
abstract final class LumeTrainsComposer {
  /// Which date a query is asking about, against the injected clock.
  ///
  /// Midnight rollover falls out of this rather than being handled: "today" is
  /// whatever day `now` is on, so a reader who leaves the screen open past
  /// midnight and taps Today gets the new day.
  static DateTime dateFor(LumeJourneyQuery query, {required DateTime now}) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    return switch (query.day) {
      LumeJourneyDay.today => today,
      LumeJourneyDay.tomorrow => today.add(const Duration(days: 1)),
      LumeJourneyDay.other =>
        query.date == null
            ? today
            : DateTime(query.date!.year, query.date!.month, query.date!.day),
    };
  }

  /// What "Today's departures" lists.
  ///
  /// **The whole roster, in declaration order — not the origin's services,
  /// and not the day's.**
  ///
  /// R1, reproduced for Stage 1. The heading reads "From Karachi Cantt" and
  /// four of the five rows depart there; `27DN` leaves Lahore and is listed
  /// anyway, because `renderRoster` maps the roster without filtering it.
  /// Filtering would drop a row the reference draws, which is a visible
  /// departure and not this conversion's to take.
  ///
  /// The date is taken and ignored for the same reason: the prototype has no
  /// alternate-day data, so every selectable day answers with this timetable.
  /// The *answer* still carries the date it is for — see
  /// [LumeTrainsData.serviceDate] — so a real feed replaces the rows without
  /// the screen learning anything new.
  ///
  /// **Dayroz obligation.** Whether this list is the operator's whole roster,
  /// the searched route's services, or the origin station's departures is a
  /// product question with three different answers, and the heading has to
  /// agree with whichever one is chosen.
  static List<LumeTrainService> departures(
    String origin, {
    required DateTime on,
  }) => _roster;

  static List<LumePopularRoute> routes() => _routes;

  /// `D.TRAIN_STOPS` — the Trains tool's one fixed station timeline, shown
  /// under whichever service is selected. See [LumeTrainTimelineStop]'s own
  /// doc comment for why it is one list rather than one per service.
  static List<LumeTrainTimelineStop> timelineStops() => _timelineStops;

  static LumeTrackedTrain tracked({required DateTime now}) => LumeTrackedTrain(
    number: '5UP',
    name: 'Green Line Express',
    from: 'Karachi Cantt',
    to: 'Islamabad',
    status: LumeTrainStatus.onTime,
    progress: kTrackedProgress,
    observedAt: now.subtract(const Duration(minutes: kTrackedAgeMinutes)),
    stops: _trackedStops,
  );

  static String operatorFor(String country) => _operators[country] ?? '';

  // -- Trains-tool pure helpers ----------------------------------------------
  //
  // Kept here rather than on the tool's own widget class so a test can assert
  // them — and the roster and the timeline they work over — without pulling
  // in `AppLocalizations` at all. `LumeTrainsTool.speed`/`.distance`/
  // `.duration` stay on the widget: they format through the reader's locale,
  // which is exactly what these three never do.

  /// What [status] leaves of [all] — `status === 'all' || (status ===
  /// 'ontime' ? !t.delay : !!t.delay)`. Filtered on [LumeTrainService.isLate],
  /// not the three-way status label: the reference's "late" chip catches
  /// nothing among the departed services either, because they have no delay.
  static List<LumeTrainService> filterByStatus(
    List<LumeTrainService> all, {
    required String status,
  }) {
    return <LumeTrainService>[
      for (final LumeTrainService s in all)
        if (status == 'all' || (status == 'ontime' ? !s.isLate : s.isLate)) s,
    ];
  }

  /// A fare tier's price — `fare * (i ? 0.72 : 1)`. Every tier after the
  /// first is the reference's own fixed 72%, not data of its own.
  static double fareForTier(LumeTrainService s, int tier) =>
      s.fare * (tier == 0 ? 1 : 0.72);

  /// A fare tier's seats — `48 - i * 17`.
  static int seatsForTier(int tier) => 48 - tier * 17;
}

/// A fixture that answers like a feed and says it is not one.
class LumeFakeTrainsRepository implements LumeTrainsRepository {
  LumeFakeTrainsRepository({
    required this.eligibility,
    this.delay = Duration.zero,
    this.pending = false,
    this.fails = false,
    this.failing = const <LumeTrainsSource>{},
    this.emptyOn = const <DateTime>{},
    List<Duration>? searchDelays,
    this.failSearches = 0,
  }) : _searchDelays = List<Duration>.of(searchDelays ?? const <Duration>[]);

  /// A load that never returns, for the loading state.
  factory LumeFakeTrainsRepository.slow({
    required LumeEligibility eligibility,
  }) => LumeFakeTrainsRepository(eligibility: eligibility, pending: true);

  final LumeEligibility eligibility;
  final Duration delay;
  final bool pending;

  /// Nothing could be read at all.
  final bool fails;

  /// Sources that could not answer on their own.
  final Set<LumeTrainsSource> failing;

  /// Days with no service.
  ///
  /// R3 lets one timetable answer every selectable day, so an *empty* day has
  /// to be asked for explicitly. Compared by calendar date, not by instant.
  final Set<DateTime> emptyOn;

  /// How long each search takes, consumed in order.
  ///
  /// A test that wants a late answer to a superseded question needs the first
  /// search slower than the second, which is the whole of the stale-response
  /// problem.
  final List<Duration> _searchDelays;

  /// How many of the next searches refuse. Counted down.
  int failSearches;

  int loads = 0;
  int searches = 0;

  /// Whatever the search last asked, so a reload keeps it.
  LumeJourneyQuery? _query;

  @override
  Future<LumeTrainsSnapshot> load(
    LumeUserContext user, {
    required DateTime now,
  }) async {
    loads++;
    return _compose(user, now: now, query: _query);
  }

  @override
  Future<LumeTrainsSnapshot> search(
    LumeUserContext user, {
    required DateTime now,
    required LumeJourneyQuery query,
  }) async {
    searches++;
    // Refused before anything is composed: a journey with one end, or with
    // the same station twice, is not a question a timetable can answer.
    if (!query.isAskable) {
      throw const LumeTrainsException(LumeTrainsFailure.invalidRoute);
    }
    if (_searchDelays.isNotEmpty) {
      await Future<void>.delayed(_searchDelays.removeAt(0));
    }
    if (failSearches > 0) {
      failSearches--;
      throw const LumeTrainsException(LumeTrainsFailure.unreachable);
    }
    final LumeTrainsSnapshot out = await _compose(user, now: now, query: query);
    // Kept only once it has been answered, so a refused search does not
    // become the query a later reload repeats.
    _query = query;
    return out;
  }

  Future<LumeTrainsSnapshot> _compose(
    LumeUserContext user, {
    required DateTime now,
    LumeJourneyQuery? query,
  }) async {
    if (pending) return Completer<LumeTrainsSnapshot>().future;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (fails) {
      throw const LumeTrainsException(LumeTrainsFailure.unreachable);
    }
    // The same gate every other surface asks. A market without rail has no
    // roster to hand back, and says so rather than returning an empty one.
    if (eligibility.visibleById('trains', user) == null) {
      throw const LumeTrainsException(LumeTrainsFailure.unsupported);
    }

    final LumeJourneyQuery q =
        query ??
        const LumeJourneyQuery(
          origin: kDefaultOrigin,
          destination: kDefaultDestination,
        );

    final DateTime on = LumeTrainsComposer.dateFor(q, now: now);

    return LumeTrainsSnapshot(
      fetchedAt: now,
      freshness: <LumeTrainsSource, LumeTrainsFreshness>{
        for (final LumeTrainsSource s in LumeTrainsSource.values)
          s: failing.contains(s)
              ? LumeTrainsFreshness.unavailable
              // Never `live`: this is a fixture and says so.
              : LumeTrainsFreshness.fixture,
      },
      data: LumeTrainsData(
        operatorName: LumeTrainsComposer.operatorFor(user.country),
        query: q,
        serviceDate: on,
        tracked: failing.contains(LumeTrainsSource.tracked)
            ? null
            : LumeTrainsComposer.tracked(now: now),
        departuresFrom: q.origin,
        departures:
            failing.contains(LumeTrainsSource.departures) ||
                emptyOn.any((DateTime d) => _sameDay(d, on))
            ? const <LumeTrainService>[]
            : LumeTrainsComposer.departures(q.origin, on: on),
        routes: failing.contains(LumeTrainsSource.routes)
            ? const <LumePopularRoute>[]
            : LumeTrainsComposer.routes(),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Saved journeys, for as long as the process lives.
class LumeMemoryJourneyStore implements LumeJourneyStore {
  final List<LumeSavedJourney> _saved = <LumeSavedJourney>[];
  int _next = 0;

  @override
  bool get isDurable => false;

  @override
  Future<List<LumeSavedJourney>> saved() async =>
      List<LumeSavedJourney>.unmodifiable(_saved);

  @override
  Future<List<LumeSavedJourney>> save(
    LumeJourneyQuery query, {
    required DateTime now,
  }) async {
    _saved.removeWhere((LumeSavedJourney j) => j.query == query);
    _saved.insert(
      0,
      LumeSavedJourney(id: 'journey-${_next++}', query: query, savedAt: now),
    );
    return saved();
  }

  @override
  Future<List<LumeSavedJourney>> remove(String id) async {
    _saved.removeWhere((LumeSavedJourney j) => j.id == id);
    return saved();
  }
}
