/// Explore — what is around the reader, rather than what they wrote down.
///
/// Nine blocks, in the order the reference emits them:
///
/// 1. the page head — a subtitle that knows whether this market is localised
/// 2. the featured collection, faith-swapped
/// 3. **Weather** — the reading, in the reader's units, with a Refresh link
/// 4. **Around you** — the local services this market actually has
/// 5. **Cricket** — gated by the reader's interests
/// 6. **Today's reads** — the news edition for their country
/// 7. **Collections**
/// 8. **Nearby**
///
/// The standard the reference sets for itself: *"this screen must never show a
/// market, a unit or a venue from somewhere the user is not."* Weather and
/// Around you meet it. Nearby does not, and is reproduced anyway by decision —
/// see `TODAY_EXPLORE_CONTRACT.md` §3 and C22.
library;

import 'package:flutter/material.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_explore.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../home/domain/home_model.dart';
import '../domain/explore_model.dart';
import '../domain/explore_repository.dart';
import 'explore_art.dart';

/// What Explore can ask the shell to do.
@immutable
class LumeExploreActions {
  const LumeExploreActions({
    required this.openTarget,
    required this.openSearch,
    required this.refreshWeather,
    required this.say,
  });

  final void Function(LumeHomeTarget target) openTarget;
  final VoidCallback openSearch;
  final VoidCallback refreshWeather;

  /// A line said as a toast — a Nearby row says its own, as the reference's
  /// `data-toast` does. **Dayroz:** the row opens that place.
  final void Function(String message) say;
}

/// The screen.
class LumeExploreScreen extends StatelessWidget {
  const LumeExploreScreen({
    super.key,
    required this.user,
    required this.eligibility,
    required this.actions,
    this.snapshot,
    this.failed = false,
    this.onRetry,
    this.onBack,
  });

  final LumeUserContext user;
  final LumeEligibility eligibility;
  final LumeExploreActions actions;

  /// `null` until the first load returns.
  final LumeExploreSnapshot? snapshot;

  final bool failed;
  final Future<void> Function()? onRetry;

  /// Where "back" goes, or `null` for a market where Explore is a tab.
  ///
  /// `explore.screen.js`: *"Explore is reachable in Pakistan even though it is
  /// not a tab there, so it carries its own way back. The router shows it only
  /// when no tab is selected."* The decision is the caller's, because only the
  /// caller knows which destinations this market presents.
  final VoidCallback? onBack;

  static const String headKey = 'explore.head';
  static const String featuredKey = 'explore.featured';
  static const String weatherKey = 'explore.weather';
  static const String aroundKey = 'explore.around';
  static const String cricketKey = 'explore.cricket';
  static const String newsKey = 'explore.news';
  static const String collectionsKey = 'explore.collections';
  static const String nearbyKey = 'explore.nearby';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: user.country,
    );
    final LumeExploreSnapshot? s = snapshot;

    if (s == null) {
      return LumeDestinationPage(
        storageId: 'explore',
        semanticLabel: l.navExplore,
        slivers: <Widget>[
          SliverToBoxAdapter(child: _head(context, l, null)),
          SliverToBoxAdapter(
            child: failed
                ? LumeMeasure(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: LumeNotice(
                        kind: LumeNoticeKind.error,
                        title: l.toolErrorTitle,
                        text: l.toolErrorText,
                        actions: <Widget>[
                          if (onRetry != null)
                            LumeNoticeAction(
                              label: l.actionTryAgain,
                              onPressed: () => onRetry!(),
                            ),
                        ],
                      ),
                    ),
                  )
                : const _ExploreSkeleton(),
          ),
        ],
      );
    }

    final LumeExploreData d = s.data;

    return LumeDestinationPage(
      storageId: 'explore',
      semanticLabel: l.navExplore,
      onRefresh: onRetry,
      slivers: <Widget>[
        SliverToBoxAdapter(child: _head(context, l, d)),
        SliverToBoxAdapter(child: _featured(context, l, d)),
        // A market the weather source cannot answer for draws no card. The
        // reference defines no unavailable weather state, so none is invented.
        if (d.weather != null)
          SliverToBoxAdapter(child: _weather(context, l, f, d, s)),
        if (d.showAround)
          SliverToBoxAdapter(child: _around(context, l, d))
        else if (s.of(LumeExploreSource.around) ==
            LumeSourceFreshness.unavailable)
          SliverToBoxAdapter(child: _aroundUnavailable(context, l)),
        if (d.score != null)
          SliverToBoxAdapter(child: _cricket(context, l, f, d.score!)),
        if (d.news.isNotEmpty)
          SliverToBoxAdapter(child: _news(context, l, f, d))
        else if (s.of(LumeExploreSource.news) ==
            LumeSourceFreshness.unavailable)
          SliverToBoxAdapter(child: _newsUnavailable(context, l)),
        SliverToBoxAdapter(child: _collections(context, l, f, d)),
        if (d.nearby.isNotEmpty)
          SliverToBoxAdapter(child: _nearby(context, l, f, d))
        else if (s.of(LumeExploreSource.nearby) ==
            LumeSourceFreshness.unavailable)
          SliverToBoxAdapter(child: _nearbyUnavailable(context, l)),
      ],
    );
  }

  // -- 1. the page head ----------------------------------------------------

  Widget _head(BuildContext context, AppLocalizations l, LumeExploreData? d) =>
      KeyedSubtree(
        key: const ValueKey<String>(headKey),
        child: LumePageHead(
          title: l.navExplore,
          subtitle: (d?.localised ?? true)
              ? l.exploreSubLocal
              : l.exploreSubGlobal,
          leading: onBack == null
              ? null
              : LumeHeaderButton(
                  icon: LumeIcons.chevL,
                  semanticLabel: l.exploreBackToHome,
                  onTap: onBack!,
                ),
          action: LumeHeaderButton(
            icon: LumeIcons.search,
            semanticLabel: l.homeSearchEverything,
            onTap: actions.openSearch,
          ),
        ),
      );

  // -- 2. the featured collection ------------------------------------------

  Widget _featured(
    BuildContext context,
    AppLocalizations l,
    LumeExploreData d,
  ) {
    final bool duas = d.featured.id == LumeFeatureId.duas;
    return KeyedSubtree(
      key: const ValueKey<String>(featuredKey),
      child: LumePageSection(
        // `style="margin-top:18px"`, inline on this one section.
        topGap: 18,
        child: LumeMeasure(
          child: LumeFeatureCard(
            key: ValueKey<String>('explore.featured.${d.featured.id.name}'),
            tag: l.exploreFeatured,
            title: duas ? l.featuredDuasTitle : l.featuredCalmTitle,
            text: duas ? l.featuredDuasText : l.featuredCalmText,
            meta: duas
                ? <String>[
                    l.featuredDuasCount(40),
                    l.featuredDuasAudio,
                    l.featuredMinutes(12),
                  ]
                : <String>[
                    l.featuredCalmDays(7),
                    l.featuredCalmEach(3),
                    l.featuredFree,
                  ],
            art: LumeFeaturedArt(id: d.featured.id),
            onTap: () => actions.openTarget(d.featured.target),
          ),
        ),
      ),
    );
  }

  // -- 3. the weather ------------------------------------------------------

  Widget _weather(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeExploreData d,
    LumeExploreSnapshot s,
  ) {
    final LumeExploreWeather w = d.weather!;
    return KeyedSubtree(
      key: const ValueKey<String>(weatherKey),
      child: LumePageSection(
        title: l.exploreWeather,
        // Computed from the reading's own timestamp against the injected
        // clock, so the sentence is never written down anywhere (C24).
        subtitle: l.exploreWeatherSub(
          w.city,
          w.minutesAgoAt(LumeClockScope.of(context).now()),
        ),
        link: l.actionRefresh,
        linkIcon: LumeIcons.refresh,
        onLinkTap: actions.refreshWeather,
        child: LumeMeasure(
          child: LumeWeatherCard(
            icon: w.icon,
            // The figure and its degree sign are set separately — the sign is
            // smaller and raised, which is `.weather__temp sup`.
            temperature: f.number(f.degreesValue(w.temperatureC)),
            degreeSign: '°',
            description: l.exploreWeatherDesc(
              LumeFeatureStrings.weatherCondition(l, w.conditionKey),
              f.temperature(w.feelsLikeC),
            ),
            stats: <LumeWeatherStat>[
              LumeWeatherStat(
                icon: LumeIcons.droplet,
                value: f.percent(w.rainPercent, decimals: 0),
                semanticLabel: l.exploreRainLabel(
                  f.percent(w.rainPercent, decimals: 0),
                ),
              ),
              LumeWeatherStat(
                icon: LumeIcons.wind,
                value: _wind(l, f, w.windKph),
                semanticLabel: l.exploreWindLabel(_wind(l, f, w.windKph)),
              ),
              LumeWeatherStat(
                icon: LumeIcons.moon,
                value: f.time(_at(w.sunsetMinute)),
                semanticLabel: l.exploreSunsetLabel(
                  f.time(_at(w.sunsetMinute)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime _at(int minuteOfDay) =>
      DateTime(2026, 1, 1, minuteOfDay ~/ 60, minuteOfDay % 60);

  /// The wind, converted and then labelled — the unit is a key, because a
  /// market that measures in miles says so in its own language.
  static String _wind(AppLocalizations l, LumeFormatting f, int kph) =>
      l.exploreWindValue(
        f.speed(kph),
        f.units == LumeUnits.imperial ? l.unitMph : l.unitKmh,
      );

  // -- 4. around you -------------------------------------------------------

  Widget _around(BuildContext context, AppLocalizations l, LumeExploreData d) =>
      KeyedSubtree(
        key: const ValueKey<String>(aroundKey),
        child: LumePageSection(
          title: l.exploreAround,
          subtitle: l.exploreAroundSub,
          // The market's name sits where a link would, which is where
          // `<span class="tag tag--neutral" id="aroundTag">` sits in the head.
          trailing: LumeTag(label: d.countryName),
          child: LumeMeasure(
            child: LumeCard(
              padded: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < d.around.length; i++)
                    LumeListRow(
                      key: ValueKey<String>(
                        'explore.around.${d.around[i].featureId}',
                      ),
                      icon: d.around[i].icon,
                      title: LumeFeatureStrings.name(l, d.around[i].featureId),
                      subtitle: d.around[i].subtitle,
                      value: d.around[i].value,
                      isLast: i == d.around.length - 1,
                      onTap: () => actions.openTarget(
                        LumeHomeTarget.tool(d.around[i].featureId),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  /// A source that could not answer says so, rather than vanishing.
  ///
  /// The reference has no such state — its services are synchronous reads —
  /// but a real provider can fail, and a section that disappears leaves the
  /// reader wondering whether their market has local services at all.
  Widget _aroundUnavailable(BuildContext context, AppLocalizations l) =>
      KeyedSubtree(
        key: const ValueKey<String>(aroundKey),
        child: LumePageSection(
          title: l.exploreAround,
          subtitle: l.exploreAroundSub,
          child: LumeMeasure(
            child: LumeNotice(
              kind: LumeNoticeKind.offline,
              title: l.toolUnavailableTitle,
              text: l.toolErrorText,
              actions: <Widget>[
                if (onRetry != null)
                  LumeNoticeAction(
                    label: l.actionTryAgain,
                    onPressed: () => onRetry!(),
                  ),
              ],
            ),
          ),
        ),
      );

  // -- 5. the cricket ------------------------------------------------------

  Widget _cricket(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeExploreScore s,
  ) => KeyedSubtree(
    key: const ValueKey<String>(cricketKey),
    child: LumePageSection(
      title: l.exploreCricket,
      subtitle: l.exploreCricketSub,
      link: l.exploreScorecard,
      onLinkTap: () => actions.openTarget(const LumeHomeTarget.tool('cricket')),
      child: LumeMeasure(
        child: LumeScoreCard(
          homeTeam: s.homeTeam,
          homeRuns: f.integer(s.homeRuns),
          homeWickets: '/${f.integer(s.homeWickets)}',
          homeOvers: l.scoreOvers(f.number(s.homeOvers, decimals: 1)),
          awayTeam: s.awayTeam,
          awayRuns: f.integer(s.awayRuns),
          awayOvers: l.scoreAllOut,
          versus: l.scoreVersus,
          note: l.scoreTrail(s.homeTeam, s.trailBy, s.topScorer, s.topScore),
          onTap: () => actions.openTarget(const LumeHomeTarget.tool('cricket')),
        ),
      ),
    ),
  );

  // -- 6. the news ---------------------------------------------------------

  Widget _news(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeExploreData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(newsKey),
    child: LumePageSection(
      title: l.exploreReads,
      subtitle: l.exploreReadsSub,
      link: l.actionAll,
      onLinkTap: () => actions.openTarget(const LumeHomeTarget.tool('news')),
      child: LumeMeasure(
        child: LumeCard(
          padded: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < d.news.length; i++)
                LumeArticleRow(
                  key: ValueKey<String>('explore.news.${d.news[i].id}'),
                  category: _newsCategory(l, d.news[i].categoryKey),
                  title: _newsTitle(l, d.news[i].id),
                  meta: l.newsReadTime(_readMinutes(d.news[i].id)),
                  art: LumeArticleArt(tone: d.news[i].tone),
                  isLast: i == d.news.length - 1,
                  onTap: () =>
                      actions.openTarget(const LumeHomeTarget.tool('news')),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  /// Nearby, when the places source cannot answer.
  ///
  /// The reference has no such state — its three rows are static markup with
  /// no source at all (C22). This exists because the repository contract they
  /// arrive through has one, and a places source that cannot locate the reader
  /// must be able to say so rather than fall back to somebody else's city.
  Widget _nearbyUnavailable(BuildContext context, AppLocalizations l) =>
      KeyedSubtree(
        key: const ValueKey<String>(nearbyKey),
        child: LumePageSection(
          title: l.exploreNearby,
          subtitle: l.exploreNearbySub,
          child: LumeMeasure(
            child: LumeNotice(
              kind: LumeNoticeKind.offline,
              title: l.toolUnavailableTitle,
              text: l.toolErrorText,
              actions: <Widget>[
                if (onRetry != null)
                  LumeNoticeAction(
                    label: l.actionTryAgain,
                    onPressed: () => onRetry!(),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _newsUnavailable(BuildContext context, AppLocalizations l) =>
      KeyedSubtree(
        key: const ValueKey<String>(newsKey),
        child: LumePageSection(
          title: l.exploreReads,
          subtitle: l.exploreReadsSub,
          child: LumeMeasure(
            child: LumeNotice(
              kind: LumeNoticeKind.offline,
              title: l.toolUnavailableTitle,
              text: l.toolErrorText,
              actions: <Widget>[
                if (onRetry != null)
                  LumeNoticeAction(
                    label: l.actionTryAgain,
                    onPressed: () => onRetry!(),
                  ),
              ],
            ),
          ),
        ),
      );

  static String _newsCategory(AppLocalizations l, String key) => switch (key) {
    'business' => l.newsCatBusiness,
    'karachi' => l.newsCatKarachi,
    'sport' => l.newsCatSport,
    'wellbeing' => l.newsCatWellbeing,
    'productivity' => l.newsCatProductivity,
    'money' => l.newsCatMoney,
    _ => key,
  };

  static String _newsTitle(AppLocalizations l, String id) => switch (id) {
    'rupee' => l.newsRupee,
    'loadshed' => l.newsLoadshed,
    'squad' => l.newsSquad,
    'reset' => l.newsReset,
    'shortList' => l.newsShortList,
    'savings' => l.newsSavings,
    _ => id,
  };

  /// `NEWS[].meta` in the catalogue: "4 min read", and so on.
  static int _readMinutes(String id) => switch (id) {
    'rupee' => 4,
    'loadshed' => 3,
    'squad' => 5,
    'reset' => 4,
    'shortList' => 6,
    'savings' => 8,
    _ => 4,
  };

  // -- 7. the collections --------------------------------------------------

  Widget _collections(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeExploreData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(collectionsKey),
    child: LumePageSection(
      title: l.exploreCollections,
      subtitle: l.exploreCollectionsSub,
      link: l.actionAll,
      onLinkTap: () =>
          actions.openTarget(const LumeHomeTarget.tool('learning')),
      child: LumeHorizontalStrip(
        children: <Widget>[
          for (final LumeCollectionCard c in d.collections)
            LumeMiniCard(
              key: ValueKey<String>('explore.collection.${c.id}'),
              art: LumeCollectionArt(id: c.id),
              title: _collectionTitle(l, c.id),
              meta: _collectionMeta(l, f, c.id),
              onTap: () => actions.openTarget(c.target),
            ),
        ],
      ),
    ),
  );

  static String _collectionTitle(AppLocalizations l, String id) => switch (id) {
    'nightSurahs' => l.collectionNightSurahs,
    'focus' => l.collectionFocus,
    'gratitude' => l.collectionGratitude,
    'budget' => l.collectionBudget,
    _ => id,
  };

  static String _collectionMeta(
    AppLocalizations l,
    LumeFormatting f,
    String id,
  ) => switch (id) {
    'nightSurahs' => l.collectionNightSurahsMeta(6, 9),
    'focus' => l.collectionFocusMeta(8),
    'gratitude' => l.collectionGratitudeMeta(30),
    'budget' => l.collectionBudgetMeta(5),
    _ => '',
  };

  // -- 8. nearby -----------------------------------------------------------

  Widget _nearby(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeExploreData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(nearbyKey),
    child: LumePageSection(
      title: l.exploreNearby,
      subtitle: l.exploreNearbySub,
      child: LumeMeasure(
        child: LumeCard(
          padded: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < d.nearby.length; i++)
                LumeListRow(
                  key: ValueKey<String>('explore.nearby.${d.nearby[i].id}'),
                  icon: d.nearby[i].icon,
                  title: _placeTitle(l, d.nearby[i].id),
                  subtitle: _placeSub(l, f, d.nearby[i].id),
                  value: _distance(l, f, d.nearby[i].distanceMetres),
                  isLast: i == d.nearby.length - 1,
                  onTap: () => actions.say(
                    '${_placeTitle(l, d.nearby[i].id)} · '
                    '${_placeSub(l, f, d.nearby[i].id)}',
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  static String _placeTitle(AppLocalizations l, String id) => switch (id) {
    'tooba' => l.nearbyTooba,
    'chaiShai' => l.nearbyChaiShai,
    'hillPark' => l.nearbyHillPark,
    _ => id,
  };

  String _placeSub(AppLocalizations l, LumeFormatting f, String id) =>
      switch (id) {
        'tooba' => l.nearbyToobaSub(f.time(_at(16 * 60 + 15))),
        'chaiShai' => l.nearbyChaiShaiSub(f.time(_at(60))),
        'hillPark' => l.nearbyHillParkSub,
        _ => '',
      };

  /// Under a kilometre in metres, over it in kilometres to one decimal —
  /// which is what the reference writes, and the unit follows the locale.
  static String _distance(AppLocalizations l, LumeFormatting f, int metres) =>
      metres < 1000
      ? l.nearbyMetres(metres)
      : l.nearbyKilometres(f.number(metres / 1000, decimals: 1));
}

/// Explore while it is still arriving.
class _ExploreSkeleton extends StatelessWidget {
  const _ExploreSkeleton();

  @override
  Widget build(BuildContext context) => LumeMeasure(
    child: Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const LumeSkeleton(kind: LumeSkeletonKind.card),
          const SizedBox(height: LumeSpace.gapSection),
          const LumeSkeleton(kind: LumeSkeletonKind.metric),
          const SizedBox(height: LumeSpace.gapSection),
          for (int i = 0; i < 3; i++) ...<Widget>[
            const LumeSkeleton(kind: LumeSkeletonKind.row),
            const SizedBox(height: LumeSpace.gapCard),
          ],
        ],
      ),
    ),
  );
}
