/// What Home is made of.
///
/// Home answers one question — *what matters to me now* — and the reference
/// states the two rules that shape every list below:
///
/// * **nothing sensitive is promoted here.** A private tool can be a quick
///   action, because adding an expense is a task; it is never a card that says
///   what is in it (§61).
/// * **nothing hidden can leak in.** Every candidate goes through the same
///   [LumeEligibility] the catalogue uses, so a faith or country feature that
///   is off cannot arrive through the carousel, the grid, the live row or
///   upcoming (§64).
///
/// These are data types only. Nothing here carries a sentence, a colour or a
/// locale: a card holds the *values* it is about, and the presentation layer
/// turns them into text in the reader's language. That is what lets Home's
/// composition be asserted without pumping a frame, and what stops a
/// repository quietly becoming the place English lives.
library;

import 'package:flutter/foundation.dart';

import '../../../core/data/lume_feed.dart';
import '../../catalogue/domain/lume_feature.dart';
import 'home_content.dart';

/// Where a Home element goes when tapped.
@immutable
sealed class LumeHomeTarget {
  const LumeHomeTarget();

  /// A tool, by feature id.
  const factory LumeHomeTarget.tool(String featureId) = LumeToolTarget;

  /// Another primary destination, by its route path.
  const factory LumeHomeTarget.destination(String path) = LumeDestinationTarget;
}

final class LumeToolTarget extends LumeHomeTarget {
  const LumeToolTarget(this.featureId);
  final String featureId;

  @override
  bool operator ==(Object other) =>
      other is LumeToolTarget && other.featureId == featureId;

  @override
  int get hashCode => featureId.hashCode;
}

final class LumeDestinationTarget extends LumeHomeTarget {
  const LumeDestinationTarget(this.path);
  final String path;

  @override
  bool operator ==(Object other) =>
      other is LumeDestinationTarget && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// Which greeting the hour calls for. The reference's `greetingKey`.
enum LumeGreeting {
  /// Before 05:00.
  late,
  morning,
  afternoon,
  evening,

  /// From 21:00.
  windDown;

  static LumeGreeting forHour(int hour) {
    if (hour < 5) return LumeGreeting.late;
    if (hour < 12) return LumeGreeting.morning;
    if (hour < 17) return LumeGreeting.afternoon;
    if (hour < 21) return LumeGreeting.evening;
    return LumeGreeting.windDown;
  }
}

/// The app bar's content.
@immutable
class LumeHomeHeader {
  const LumeHomeHeader({
    required this.greeting,
    required this.date,
    required this.city,
    this.displayName = '',
    this.notificationCount = 0,
  });

  final LumeGreeting greeting;

  /// The day the header names. Formatted by the presentation layer, which is
  /// the only layer that knows the locale.
  final DateTime date;

  final String city;

  /// Empty when Lume has no name. The greeting then stands alone — *"there is
  /// no third branch that invents one"*.
  final String displayName;

  final int notificationCount;

  /// Initials from a real name, or empty. Never invented letters: an anonymous
  /// avatar draws the neutral glyph instead.
  String get initials {
    final List<String> words = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return _first(words.first);
    return '${_first(words.first)}${_first(words.last)}';
  }

  bool get isNamed => displayName.trim().isNotEmpty;

  static String _first(String w) => w.isEmpty ? '' : w[0].toUpperCase();
}

// ---------------------------------------------------------------------------
// Context strip
// ---------------------------------------------------------------------------

/// The strip under the header. Exactly one of the two — the faith dimension
/// swaps it, which is `data-faith` in the reference.
@immutable
sealed class LumeContextCard {
  const LumeContextCard();
}

/// The Muslim strip: the next prayer and how long is left.
final class LumePrayerContext extends LumeContextCard {
  const LumePrayerContext({required this.next, required this.remaining});

  final LumePrayerTime next;
  final Duration remaining;

  @override
  bool operator ==(Object other) =>
      other is LumePrayerContext &&
      other.next.key == next.key &&
      other.next.at == next.at &&
      other.remaining == remaining;

  @override
  int get hashCode => Object.hash(next.key, next.at, remaining);
}

/// Everyone else's strip: the weather now, and when the next thing is.
final class LumeWeatherContext extends LumeContextCard {
  const LumeWeatherContext({required this.weather, required this.nextAt});

  final LumeWeatherNow weather;
  final DateTime nextAt;

  @override
  bool operator ==(Object other) =>
      other is LumeWeatherContext &&
      other.weather.temperatureC == weather.temperatureC &&
      other.weather.conditionKey == weather.conditionKey &&
      other.nextAt == nextAt;

  @override
  int get hashCode =>
      Object.hash(weather.temperatureC, weather.conditionKey, nextAt);
}

// ---------------------------------------------------------------------------
// Hero carousel
// ---------------------------------------------------------------------------

/// The six slides the reference declares. §26 caps the carousel at four, so
/// they compete and the most relevant four win.
enum LumeHeroSlideId { prayer, plan, read, money, trains, tools }

/// One slide, already chosen and ranked.
@immutable
class LumeHeroCard {
  const LumeHeroCard({required this.id, required this.target, this.score = 0});

  final LumeHeroSlideId id;
  final LumeHomeTarget target;

  /// What won it its place. Carried so a test can assert the ranking rather
  /// than the order that happened to come out.
  final int score;

  @override
  bool operator ==(Object other) =>
      other is LumeHeroCard && other.id == id && other.score == score;

  @override
  int get hashCode => Object.hash(id, score);
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

/// §118 — an action performs a task; it does not just open a screen.
@immutable
class LumeQuickAction {
  const LumeQuickAction({
    required this.id,
    required this.featureId,
    required this.icon,
  });

  /// Identifies both the label and the action. `expense`, `task`, `scan`, …
  final String id;

  /// The feature whose eligibility governs it.
  final String featureId;

  final String icon;
}

// ---------------------------------------------------------------------------
// Live now
// ---------------------------------------------------------------------------

/// One "Right now" card. Sealed, so the screen cannot draw a market card with
/// weather in it, and so each kind carries exactly the values it needs.
@immutable
sealed class LumeLiveCard {
  const LumeLiveCard();

  /// The feature this card opens, and whose eligibility admitted it.
  String get featureId;
}

/// Today's weather — or, after 19:00 and before 05:00, tomorrow's.
final class LumeWeatherLive extends LumeLiveCard {
  const LumeWeatherLive({
    required this.weather,
    required this.city,
    required this.forTomorrow,
  });

  final LumeWeatherNow weather;
  final String city;
  final bool forTomorrow;

  LumeDayForecast get day => forTomorrow ? weather.tomorrow : weather.today;

  @override
  String get featureId => 'weather';
}

/// A market snapshot, shown while a market the user follows is open — or from
/// 08:00 local, so an early riser sees where it closed.
final class LumeMarketLive extends LumeLiveCard {
  const LumeMarketLive({required this.market});

  final LumeMarketSnapshot market;

  @override
  String get featureId => 'markets';
}

/// A live outage. Outranks the others and goes to the front.
final class LumeOutageLive extends LumeLiveCard {
  const LumeOutageLive({
    required this.outage,
    required this.slot,
    required this.remaining,
  });

  final LumeOutage outage;
  final LumeOutageSlot slot;
  final Duration remaining;

  @override
  String get featureId => 'loadshed';
}

/// Bills past their date.
final class LumeBillsLive extends LumeLiveCard {
  const LumeBillsLive({required this.bills, required this.currency});

  final LumeBillsSummary bills;
  final String currency;

  @override
  String get featureId => 'bills';
}

// ---------------------------------------------------------------------------
// At a glance
// ---------------------------------------------------------------------------

/// One "At a glance" card. Three kinds, three different gates.
@immutable
sealed class LumeGlanceCard {
  const LumeGlanceCard();
  LumeHomeTarget get target;
}

/// Faith-gated: continue reading.
final class LumeReadingGlance extends LumeGlanceCard {
  const LumeReadingGlance(this.progress);
  final LumeReadingProgress progress;

  @override
  LumeHomeTarget get target => const LumeHomeTarget.tool('quran');
}

/// Country-gated: the local pump price.
final class LumeFuelGlance extends LumeGlanceCard {
  const LumeFuelGlance(this.fuel, {required this.countryCode});
  final LumeFuelPrice fuel;
  final String countryCode;

  @override
  LumeHomeTarget get target => const LumeHomeTarget.tool('fuel');
}

/// Everyone: what is left today.
final class LumeTasksGlance extends LumeGlanceCard {
  const LumeTasksGlance(this.tasks, {required this.todayPath});
  final LumeTaskSummary tasks;
  final String todayPath;

  @override
  LumeHomeTarget get target => LumeHomeTarget.destination(todayPath);
}

// ---------------------------------------------------------------------------
// Coming up
// ---------------------------------------------------------------------------

/// One row under "Coming up", drawn from whatever the user actually has.
@immutable
sealed class LumeUpcomingItem {
  const LumeUpcomingItem();

  String get featureId;

  /// Sort key. The reference's own bands: the next prayer by its minutes, then
  /// bills, subscriptions, birthdays and documents in fixed order.
  int get order;
}

final class LumePrayerUpcoming extends LumeUpcomingItem {
  const LumePrayerUpcoming(this.prayer, {required this.minutes});
  final LumePrayerTime prayer;
  final int minutes;

  @override
  String get featureId => 'prayer';
  @override
  int get order => minutes;
}

final class LumeBillUpcoming extends LumeUpcomingItem {
  const LumeBillUpcoming(this.bill, {required this.currency});
  final LumeBillDue bill;
  final String currency;

  @override
  String get featureId => 'bills';
  @override
  int get order => 500;
}

final class LumeSubscriptionUpcoming extends LumeUpcomingItem {
  const LumeSubscriptionUpcoming(this.renewal);
  final LumeSubscriptionRenewal renewal;

  @override
  String get featureId => 'subs';
  @override
  int get order => 600 + renewal.days;
}

final class LumeBirthdayUpcoming extends LumeUpcomingItem {
  const LumeBirthdayUpcoming(this.birthday);
  final LumeBirthdayNext birthday;

  @override
  String get featureId => 'birthdays';
  @override
  int get order => 700 + birthday.days;
}

/// A document is sensitive, so Home names the renewal, not the number.
final class LumeDocumentUpcoming extends LumeUpcomingItem {
  const LumeDocumentUpcoming(this.renewal);
  final LumeDocumentRenewal renewal;

  @override
  String get featureId => 'documents';
  @override
  int get order => 800;
}

// ---------------------------------------------------------------------------
// Discover
// ---------------------------------------------------------------------------

/// The five cards in the Discover strip, each gated by the feature it opens.
enum LumeDiscoverId { cricket, weather, outage, duas, parcel }

@immutable
class LumeDiscoverCard {
  const LumeDiscoverCard({required this.id, required this.target});

  final LumeDiscoverId id;
  final LumeHomeTarget target;

  @override
  bool operator ==(Object other) => other is LumeDiscoverCard && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// The whole screen
// ---------------------------------------------------------------------------

/// Everything Home draws, one feed per section.
///
/// Per-section feeds are the point: a failed weather fetch beside a live market
/// card is a *partial* Home, and that is a state the screen has to draw
/// honestly rather than collapsing into "something went wrong".
@immutable
class LumeHomeData {
  const LumeHomeData({
    required this.header,
    required this.context,
    required this.hero,
    required this.quickActions,
    required this.quickTools,
    required this.live,
    required this.glance,
    required this.upcoming,
    required this.discover,
    required this.content,
  });

  final LumeHomeHeader header;
  final LumeFeed<LumeContextCard> context;
  final List<LumeHeroCard> hero;
  final List<LumeQuickAction> quickActions;
  final List<LumeFeature> quickTools;
  final LumeFeed<List<LumeLiveCard>> live;
  final List<LumeGlanceCard> glance;
  final LumeFeed<List<LumeUpcomingItem>> upcoming;
  final List<LumeDiscoverCard> discover;

  /// The values behind the cards, so the Discover strip and the hero can quote
  /// them without a second fetch.
  final LumeHomeContent content;

  /// §118: the strip appears only with three or more actions. Two pills
  /// floating under a hero is not a row.
  bool get showQuickActions => quickActions.length >= 3;

  /// No live content is a reason to show nothing, not a reason to show an
  /// empty section explaining that there is nothing.
  bool get showLive =>
      live.isLoading ||
      live.hasFailed ||
      (live.valueOrNull?.isNotEmpty ?? false);

  bool get showUpcoming =>
      upcoming.isLoading ||
      upcoming.hasFailed ||
      (upcoming.valueOrNull?.isNotEmpty ?? false);
}
