/// Home's state: one load, one composition, one refresh.
///
/// The controller is the only thing that knows the clock, the repository and
/// the eligibility selector at the same time. The screen is handed a
/// [LumeHomeData] and draws it; the composer is handed values and picks; the
/// repository is handed a user and a moment and fetches. Nothing in that chain
/// reads a global.
library;

import 'package:flutter/foundation.dart';

import '../../../core/data/lume_feed.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../catalogue/domain/eligibility.dart';
import '../domain/home_composer.dart';
import '../domain/home_content.dart';
import '../domain/home_model.dart';
import '../domain/home_repository.dart';

/// What Home is showing, and whether it is still arriving.
@immutable
class LumeHomeState {
  const LumeHomeState({this.data, this.loading = true, this.failed = false});

  /// `null` until the first load returns.
  final LumeHomeData? data;

  final bool loading;

  /// The whole load failed — not one section of it.
  final bool failed;

  @override
  bool operator ==(Object other) =>
      other is LumeHomeState &&
      other.data == data &&
      other.loading == loading &&
      other.failed == failed;

  @override
  int get hashCode => Object.hash(data, loading, failed);
}

/// Loads and composes Home.
class LumeHomeController extends ChangeNotifier {
  LumeHomeController({
    required this.repository,
    required this.eligibility,
    required this.clock,
    required this.routes,
  });

  final LumeHomeRepository repository;
  final LumeEligibility eligibility;
  final LumeClock clock;

  /// The paths the composer needs, passed in so the domain holds no route
  /// literals.
  final LumeHomeRoutes routes;

  LumeHomeState _state = const LumeHomeState();
  LumeHomeState get state => _state;

  LumeUserContext? _user;
  bool _disposed = false;

  /// Load for [user], or recompose if the user has changed under a load that
  /// already happened.
  ///
  /// Idempotent for the same user: arriving on Home twice is not two fetches.
  Future<void> load(LumeUserContext user, {bool force = false}) async {
    if (!force && _user == user && !_state.loading) return;
    _user = user;
    _publish(LumeHomeState(data: _state.data, loading: true));

    try {
      final DateTime now = clock.now();
      final LumeHomeSnapshot snapshot = await repository.load(user, now: now);
      if (_disposed || _user != user) return;
      _publish(
        LumeHomeState(data: _compose(user, snapshot, now), loading: false),
      );
    } on Object {
      if (_disposed) return;
      // A failed load is a failed load. Nothing is invented to fill it, and
      // whatever was on screen stays there rather than being blanked.
      _publish(LumeHomeState(data: _state.data, loading: false, failed: true));
    }
  }

  /// Pull to refresh. Always refetches, even for the same user.
  Future<void> refresh() async {
    final LumeUserContext? user = _user;
    if (user == null) return;
    await load(user, force: true);
  }

  LumeHomeData _compose(
    LumeUserContext user,
    LumeHomeSnapshot snapshot,
    DateTime now,
  ) {
    final LumeHomeContent content = snapshot.content;

    LumeFeed<T> feed<T>(LumeHomeSection section, T Function() build) =>
        switch (snapshot.stateOf(section)) {
          LumeSourceState.failed => LumeFeed<T>.failed(),
          LumeSourceState.live => LumeFeed<T>.ready(
            build(),
            asOf: snapshot.fetchedAt,
          ),
          LumeSourceState.stale => LumeFeed<T>.ready(
            build(),
            freshness: LumeFeedFreshness.stale,
            asOf: snapshot.fetchedAt,
          ),
          LumeSourceState.offline => LumeFeed<T>.ready(
            build(),
            freshness: LumeFeedFreshness.offline,
            asOf: snapshot.fetchedAt,
          ),
        };

    return LumeHomeData(
      content: content,
      header: LumeHomeComposer.header(user: user, content: content, now: now),
      context: feed<LumeContextCard>(
        LumeHomeSection.context,
        () =>
            LumeHomeComposer.contextCard(
              user: user,
              content: content,
              now: now,
            ) ??
            LumeWeatherContext(weather: _blankWeather, nextAt: now),
      ),
      hero: LumeHomeComposer.hero(
        user: user,
        eligibility: eligibility,
        todayPath: routes.today,
        toolsPath: routes.tools,
        trainsPath: routes.trains,
      ),
      quickActions: LumeHomeComposer.quickActions(
        user: user,
        eligibility: eligibility,
      ),
      quickTools: LumeHomeComposer.quickTools(
        user: user,
        eligibility: eligibility,
      ),
      live: feed<List<LumeLiveCard>>(
        LumeHomeSection.live,
        () => LumeHomeComposer.live(
          user: user,
          eligibility: eligibility,
          content: content,
          now: now,
        ),
      ),
      glance: LumeHomeComposer.glance(
        user: user,
        eligibility: eligibility,
        content: content,
        todayPath: routes.today,
      ),
      upcoming: feed<List<LumeUpcomingItem>>(
        LumeHomeSection.upcoming,
        () => LumeHomeComposer.upcoming(
          user: user,
          eligibility: eligibility,
          content: content,
          now: now,
        ),
      ),
      discover: LumeHomeComposer.discover(
        user: user,
        eligibility: eligibility,
        content: content,
        explorePath: routes.explore,
      ),
    );
  }

  /// Only reached when the strip's source failed *and* the feed asked for a
  /// value anyway; the feed is `failed` so nothing draws it.
  static const LumeWeatherNow _blankWeather = LumeWeatherNow(
    temperatureC: 0,
    feelsLikeC: 0,
    conditionKey: 'clear',
    discoverTemperature: 0,
    discoverFeelsLike: 0,
    discoverConditionKey: 'clear',
    rainPercent: 0,
    windKph: 0,
    icon: 'cloud-sun',
    today: LumeDayForecast(
      highC: 0,
      lowC: 0,
      conditionKey: 'clear',
      rainPercent: 0,
    ),
    tomorrow: LumeDayForecast(
      highC: 0,
      lowC: 0,
      conditionKey: 'clear',
      rainPercent: 0,
    ),
  );

  void _publish(LumeHomeState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// The four paths Home's composer needs.
///
/// Passed rather than imported, so the domain layer holds no route literal and
/// a test can compose Home without a router.
@immutable
class LumeHomeRoutes {
  const LumeHomeRoutes({
    required this.today,
    required this.tools,
    required this.trains,
    required this.explore,
  });

  final String today;
  final String tools;
  final String trains;
  final String explore;
}
