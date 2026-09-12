/// Everything Explore draws.
///
/// Explore is the outward-facing half of the product: the weather where the
/// reader actually is, the services their market actually has, the news their
/// country actually gets. The reference is explicit about the standard —
/// *"this screen must never show a market, a unit or a venue from somewhere
/// the user is not"* — and about half of it meets that standard.
///
/// The half that does not is reproduced rather than repaired, and each piece
/// says so where it is declared. See `TODAY_EXPLORE_CONTRACT.md` §3.
library;

import 'package:flutter/foundation.dart';

import '../../home/domain/home_model.dart';

/// The featured collection at the top — faith-swapped, like Today's
/// reflection.
enum LumeFeatureId { duas, calmWeek }

@immutable
class LumeFeaturedCollection {
  const LumeFeaturedCollection({required this.id, required this.target});

  final LumeFeatureId id;
  final LumeHomeTarget target;

  @override
  bool operator ==(Object other) =>
      other is LumeFeaturedCollection &&
      other.id == id &&
      other.target == target;

  @override
  int get hashCode => Object.hash(id, target);
}

/// The weather card's own reading.
///
/// Honest, and per country: the temperature follows the reader's units, the
/// wind follows them too, and the sunset comes from the same solar
/// calculation the prayer times use, so the two cannot disagree about when
/// the sun goes down.
///
/// [updatedMinutesAgo] is the exception and is **not** honest. The reference
/// writes `L.num(4)` into the subtitle — the same claim in every state,
/// forever, with no fetch behind it (E1). Reproduced by decision; Dayroz's
/// weather adapter must replace it with a real fetch timestamp.
@immutable
class LumeExploreWeather {
  const LumeExploreWeather({
    required this.city,
    required this.temperatureC,
    required this.feelsLikeC,
    required this.conditionKey,
    required this.rainPercent,
    required this.windKph,
    required this.icon,
    required this.sunsetMinute,
    required this.updatedMinutesAgo,
  });

  final String city;
  final int temperatureC;
  final int feelsLikeC;

  /// The *raw* condition — `hazySun`, which reads "Hazy sun · humid". Explore
  /// shows this one; Home's Discover card shows a literal instead (C21).
  final String conditionKey;

  final int rainPercent;
  final int windKph;
  final String icon;

  /// Minutes past local midnight.
  final int sunsetMinute;

  /// A claim with nothing behind it. See the class comment.
  final int updatedMinutesAgo;

  @override
  bool operator ==(Object other) =>
      other is LumeExploreWeather &&
      other.city == city &&
      other.temperatureC == temperatureC &&
      other.feelsLikeC == feelsLikeC &&
      other.conditionKey == conditionKey &&
      other.rainPercent == rainPercent &&
      other.windKph == windKph &&
      other.icon == icon &&
      other.sunsetMinute == sunsetMinute &&
      other.updatedMinutesAgo == updatedMinutesAgo;

  @override
  int get hashCode => Object.hash(
    city,
    temperatureC,
    feelsLikeC,
    conditionKey,
    rainPercent,
    windKph,
    icon,
    sunsetMinute,
    updatedMinutesAgo,
  );
}

/// One row of "Around you" — a local service the reader's market actually has.
///
/// The most honest section on the screen. Six candidates are declared in a
/// fixed order; each is dropped when its feature is not visible to this
/// reader, and dropped again when its own data cannot answer — *"a service
/// that cannot answer right now is left out rather than shown with a blank
/// where its number should be."*
@immutable
class LumeAroundService {
  const LumeAroundService({
    required this.featureId,
    required this.icon,
    required this.subtitle,
    this.value,
  });

  final String featureId;
  final String icon;

  /// Already composed, because each service says something different in a
  /// different shape — fuel grades, an outage window, a helpline's name.
  final String subtitle;

  /// The figure at the end. `null` for a service that has none: Trains shows
  /// only a status.
  final String? value;

  @override
  bool operator ==(Object other) =>
      other is LumeAroundService &&
      other.featureId == featureId &&
      other.icon == icon &&
      other.subtitle == subtitle &&
      other.value == value;

  @override
  int get hashCode => Object.hash(featureId, icon, subtitle, value);
}

/// One story in "Today's reads".
@immutable
class LumeNewsArticle {
  const LumeNewsArticle({
    required this.id,
    required this.tone,
    required this.categoryKey,
  });

  final String id;

  /// Which of the three gradients the artwork uses.
  final LumeArticleTone tone;

  /// "Money", "Energy", "Sport" — a key, so an Urdu reader gets an Urdu
  /// category above an Urdu headline.
  final String categoryKey;

  @override
  bool operator ==(Object other) =>
      other is LumeNewsArticle &&
      other.id == id &&
      other.tone == tone &&
      other.categoryKey == categoryKey;

  @override
  int get hashCode => Object.hash(id, tone, categoryKey);
}

enum LumeArticleTone { accent, violet, amber }

/// One card in the Collections strip.
@immutable
class LumeCollectionCard {
  const LumeCollectionCard({
    required this.id,
    required this.target,
    this.faithOnly = false,
  });

  final String id;
  final LumeHomeTarget target;

  /// The first card is the Qur'an's, and it is gated like everything else
  /// faith-bound.
  final bool faithOnly;

  @override
  bool operator ==(Object other) =>
      other is LumeCollectionCard &&
      other.id == id &&
      other.target == target &&
      other.faithOnly == faithOnly;

  @override
  int get hashCode => Object.hash(id, target, faithOnly);
}

/// One row of "Nearby".
///
/// **This is fabricated content, reproduced deliberately.** The reference
/// hard-codes three Karachi venues with metre distances, gives the section no
/// city gate and no source, and shows it unchanged in London and New York
/// (E2). Decided: reproduce Lume exactly, record the defect, and make Dayroz
/// responsible for a real places source before it ships.
///
/// Nothing here is computed. [distanceMetres] is a number the prototype
/// wrote down, not a measurement.
@immutable
class LumeNearbyPlace {
  const LumeNearbyPlace({
    required this.id,
    required this.icon,
    required this.distanceMetres,
    this.faithOnly = false,
  });

  final String id;
  final String icon;
  final int distanceMetres;
  final bool faithOnly;

  @override
  bool operator ==(Object other) =>
      other is LumeNearbyPlace &&
      other.id == id &&
      other.icon == icon &&
      other.distanceMetres == distanceMetres &&
      other.faithOnly == faithOnly;

  @override
  int get hashCode => Object.hash(id, icon, distanceMetres, faithOnly);
}

/// The live cricket card.
@immutable
class LumeExploreScore {
  const LumeExploreScore({
    required this.homeTeam,
    required this.homeRuns,
    required this.homeWickets,
    required this.homeOvers,
    required this.awayTeam,
    required this.awayRuns,
    required this.trailBy,
    required this.topScorer,
    required this.topScore,
  });

  final String homeTeam;
  final int homeRuns;
  final int homeWickets;
  final double homeOvers;
  final String awayTeam;
  final int awayRuns;
  final int trailBy;
  final String topScorer;
  final int topScore;

  @override
  bool operator ==(Object other) =>
      other is LumeExploreScore &&
      other.homeTeam == homeTeam &&
      other.homeRuns == homeRuns &&
      other.homeWickets == homeWickets &&
      other.homeOvers == homeOvers &&
      other.awayTeam == awayTeam &&
      other.awayRuns == awayRuns &&
      other.trailBy == trailBy &&
      other.topScorer == topScorer &&
      other.topScore == topScore;

  @override
  int get hashCode => Object.hash(
    homeTeam,
    homeRuns,
    homeWickets,
    homeOvers,
    awayTeam,
    awayRuns,
    trailBy,
    topScorer,
    topScore,
  );
}

/// Everything Explore draws.
@immutable
class LumeExploreData {
  const LumeExploreData({
    required this.countryCode,
    required this.countryName,
    required this.localised,
    required this.featured,
    required this.weather,
    required this.around,
    required this.score,
    required this.news,
    required this.collections,
    required this.nearby,
  });

  final String countryCode;

  /// For the tag beside "Around you".
  final String countryName;

  /// Whether this market has localised services of its own, which decides
  /// which subtitle the page head carries.
  final bool localised;

  final LumeFeaturedCollection featured;
  final LumeExploreWeather weather;

  /// Already filtered by eligibility and by whether each service could
  /// answer.
  final List<LumeAroundService> around;

  /// `null` when the reader has no cricket interest — the section is gated,
  /// not empty.
  final LumeExploreScore? score;

  final List<LumeNewsArticle> news;
  final List<LumeCollectionCard> collections;
  final List<LumeNearbyPlace> nearby;

  /// *"One local service is not a section."*
  bool get showAround => around.length >= 2;

  @override
  bool operator ==(Object other) =>
      other is LumeExploreData &&
      other.countryCode == countryCode &&
      other.countryName == countryName &&
      other.localised == localised &&
      other.featured == featured &&
      other.weather == weather &&
      other.score == score &&
      listEquals(other.around, around) &&
      listEquals(other.news, news) &&
      listEquals(other.collections, collections) &&
      listEquals(other.nearby, nearby);

  @override
  int get hashCode => Object.hash(
    countryCode,
    countryName,
    localised,
    featured,
    weather,
    score,
    Object.hashAll(around),
    Object.hashAll(news),
    Object.hashAll(collections),
    Object.hashAll(nearby),
  );
}
