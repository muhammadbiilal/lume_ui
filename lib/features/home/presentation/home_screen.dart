/// Home.
///
/// Nine blocks in a fixed order, three of which can be absent:
///
/// 1. the app bar — greeting, date, city, search, notifications, avatar
/// 2. the context strip — next prayer, or the weather
/// 3. the hero carousel — two to four ranked slides
/// 4. quick actions — hidden below three
/// 5. quick tools — eight tiles
/// 6. "Right now" — hidden when nothing is live
/// 7. "At a glance" — up to three cards, each gated differently
/// 8. "Coming up" — hidden when there is nothing
/// 9. "Discover" — a horizontal strip
///
/// The order is the reference's and is not personalised (§49: *"do not
/// constantly move entire sections around"*). What is personalised is what goes
/// *in* each block, and every one of those decisions is in
/// [LumeHomeComposer] rather than here — this file turns data into widgets and
/// makes no choices about what the data should be.
library;

import 'package:flutter/material.dart';

import '../../../core/data/lume_feed.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_hero.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../catalogue/domain/lume_feature.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../markets/domain/market_session.dart';
import '../domain/home_content.dart';
import '../domain/home_model.dart';
import '../domain/home_repository.dart';
import 'home_art.dart';

/// What Home does when something is tapped.
@immutable
class LumeHomeActions {
  const LumeHomeActions({
    required this.openTarget,
    required this.openSearch,
    required this.openNotifications,
    required this.openProfile,
    required this.openTools,
    required this.openToday,
    required this.openExplore,
  });

  final void Function(LumeHomeTarget target) openTarget;
  final VoidCallback openSearch;
  final VoidCallback openNotifications;
  final VoidCallback openProfile;
  final VoidCallback openTools;
  final VoidCallback openToday;
  final VoidCallback openExplore;
}

/// The screen.
class LumeHomeScreen extends StatelessWidget {
  const LumeHomeScreen({
    super.key,
    required this.data,
    required this.user,
    required this.actions,
    this.loading = false,
    this.failed = false,
    this.onRefresh,
  });

  final LumeHomeData? data;
  final LumeUserContext user;
  final LumeHomeActions actions;

  /// The first load has not returned. Home draws its skeleton.
  final bool loading;

  /// The load failed outright, with nothing to show.
  final bool failed;

  final Future<void> Function()? onRefresh;

  /// Keys the tests and the bounds comparison address elements by.
  static const String appBarKey = 'home.appbar';
  static const String contextKey = 'home.ctx';
  static const String heroKey = 'home.hero';
  static const String quickActionsKey = 'home.qactions';
  static const String quickToolsKey = 'home.quickTools';
  static const String liveKey = 'home.live';
  static const String glanceKey = 'home.glance';
  static const String upcomingKey = 'home.upcoming';
  static const String discoverKey = 'home.discover';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeHomeData? d = data;

    if (d == null) {
      return LumeDestinationPage(
        storageId: 'home',
        semanticLabel: l.navHome,
        onRefresh: onRefresh,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: failed
                ? Padding(
                    padding: const EdgeInsets.only(top: LumeSpace.x10),
                    child: LumeToolState.error(
                      title: l.toolErrorTitle,
                      text: l.toolErrorText,
                      action: LumeButton(
                        label: l.actionTryAgain,
                        onPressed: onRefresh,
                      ),
                    ),
                  )
                : const _HomeSkeleton(),
          ),
        ],
      );
    }

    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: user.country,
    );
    // The strip already named the next prayer; the tile must not name a
    // different one. Both read the same resolver.
    final LumeToolStatuses statuses = LumeToolStatuses(
      prayer: d.context.valueOrNull is LumePrayerContext
          ? (d.context.valueOrNull! as LumePrayerContext).next
          : null,
      weather: d.content.weather,
    );

    return LumeDestinationPage(
      storageId: 'home',
      semanticLabel: l.navHome,
      onRefresh: onRefresh,
      slivers: <Widget>[
        SliverToBoxAdapter(child: _appBar(context, l, f, d)),
        SliverToBoxAdapter(child: _contextStrip(context, l, f, d)),
        SliverToBoxAdapter(
          // `.hero { margin-top: 14px }` — the page's gap, not the carousel's
          // own box, so the measured `.hero` is what the carousel is.
          child: Padding(
            padding: const EdgeInsets.only(top: LumeHeroMetrics.topGap),
            child: KeyedSubtree(
              key: const ValueKey<String>(heroKey),
              child: _hero(context, l, f, d),
            ),
          ),
        ),
        if (d.showQuickActions)
          SliverToBoxAdapter(child: _quickActions(context, l, d)),
        SliverToBoxAdapter(child: _quickTools(context, l, f, statuses, d)),
        if (d.showLive) SliverToBoxAdapter(child: _live(context, l, f, d)),
        SliverToBoxAdapter(child: _glance(context, l, f, d)),
        if (d.showUpcoming)
          SliverToBoxAdapter(child: _upcoming(context, l, f, d)),
        SliverToBoxAdapter(child: _discover(context, l, f, d)),
      ],
    );
  }

  // -- 1. the app bar -----------------------------------------------------

  Widget _appBar(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeHomeData d,
  ) {
    final LumeHomeHeader h = d.header;
    final String greeting = switch (h.greeting) {
      LumeGreeting.late => l.greetLate,
      LumeGreeting.morning => l.greetMorning,
      LumeGreeting.afternoon => l.greetAfternoon,
      LumeGreeting.evening => l.greetEvening,
      LumeGreeting.windDown => l.greetWindDown,
    };

    return KeyedSubtree(
      key: const ValueKey<String>(appBarKey),
      child: LumeGreetingBar(
        // The name is used when Lume has one, and the greeting stands alone
        // when it does not. There is no third branch that invents one.
        greeting: h.isNamed ? l.greetNamed(greeting, h.displayName) : greeting,
        emoji: '👋',
        subtitle: f.dateShort(h.date),
        place: h.city,
        actions: <Widget>[
          LumeHeaderButton(
            icon: LumeIcons.search,
            semanticLabel: l.homeSearchEverything,
            onTap: actions.openSearch,
          ),
          LumeHeaderButton(
            icon: LumeIcons.bell,
            semanticLabel: l.navNotifications,
            badgeCount: h.notificationCount,
            onTap: actions.openNotifications,
          ),
          LumeAvatarButton(
            initials: h.initials,
            semanticLabel: l.homeYourProfile,
            onTap: actions.openProfile,
          ),
        ],
      ),
    );
  }

  // -- 2. the context strip ------------------------------------------------

  Widget _contextStrip(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeHomeData d,
  ) {
    return KeyedSubtree(
      key: const ValueKey<String>(contextKey),
      child: LumePageSection(
        topGap: 14,
        child: LumeMeasure(
          child: switch (d.context) {
            LumeFeedLoading<LumeContextCard>() => const LumeSkeleton(
              kind: LumeSkeletonKind.row,
            ),
            LumeFeedFailed<LumeContextCard>() => LumeNotice(
              kind: LumeNoticeKind.offline,
              title: l.toolErrorTitle,
              text: l.toolErrorText,
            ),
            LumeFeedReady<LumeContextCard>(:final LumeContextCard value) =>
              switch (value) {
                LumePrayerContext(
                  :final LumePrayerTime next,
                  :final Duration remaining,
                ) =>
                  LumeContextStrip(
                    icon: LumeIcons.prayer,
                    label: l.homeNextPrayer,
                    semanticLabel:
                        '${l.homeNextPrayer}, ${_prayerName(l, next.key)}, '
                        '${f.time(next.at)}',
                    value: LumeFormatting.shortCountdown(remaining),
                    unit: l.homeToGo,
                    background: const LumeContextArt(islamic: true),
                    onTap: () =>
                        actions.openTarget(const LumeHomeTarget.tool('prayer')),
                    title: _contextTitle(
                      context,
                      strong: _prayerName(l, next.key),
                      rest: f.time(next.at),
                    ),
                  ),
                LumeWeatherContext(
                  :final LumeWeatherNow weather,
                  :final DateTime nextAt,
                ) =>
                  LumeContextStrip(
                    icon: LumeIcons.cloudSun,
                    tone: LumeCardTone.sky,
                    label: l.homeRightNow,
                    semanticLabel:
                        '${l.homeRightNow}, '
                        '${f.temperature(weather.temperatureC)}, '
                        '${_condition(l, weather.conditionKey)}',
                    value: f.time(nextAt),
                    unit: l.homeNextUp,
                    background: const LumeContextArt(islamic: false),
                    onTap: actions.openToday,
                    title: _contextTitle(
                      context,
                      strong: f.temperature(weather.temperatureC),
                      rest: _condition(l, weather.conditionKey),
                    ),
                  ),
              },
          },
        ),
      ),
    );
  }

  /// `.ctx__title` — an 800 fragment, a separator and a 600 one.
  Widget _contextTitle(
    BuildContext context, {
    required String strong,
    required String rest,
  }) {
    final LumeColors lume = context.lume;
    final TextStyle base = LumeType.tracked(
      LumeType.fit(context, context.lumeType.cardTitle),
      -0.028,
    ).copyWith(color: lume.text2, fontWeight: FontWeight.w600);

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: strong,
            style: base.copyWith(color: lume.text, fontWeight: FontWeight.w800),
          ),
          TextSpan(text: ' · $rest'),
        ],
      ),
      style: base,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // -- 3. the hero --------------------------------------------------------

  Widget _hero(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeHomeData d,
  ) {
    final LumePrayerTimetable? timetable = d.content.prayer;
    final LumeContextCard? ctx = d.context.valueOrNull;
    final Duration? remaining = ctx is LumePrayerContext ? ctx.remaining : null;

    return LumeHeroCarousel(
      semanticLabel: l.heroHighlights,
      dotLabel: (int n, int total) => l.slideOf(n, total),
      slides: <Widget>[
        for (final LumeHeroCard card in d.hero)
          LumeHeroSlide(
            key: ValueKey<String>('home.slide.${card.id.name}'),
            art: LumeHeroArt(slide: card.id),
            onTap: () => actions.openTarget(card.target),
            kicker: switch (card.id) {
              LumeHeroSlideId.prayer => l.slidePrayerKicker,
              LumeHeroSlideId.plan => l.slidePlanKicker,
              LumeHeroSlideId.read => l.slideReadKicker,
              LumeHeroSlideId.money => l.slideMoneyKicker,
              LumeHeroSlideId.trains => l.slideTrainsKicker,
              LumeHeroSlideId.tools => l.slideToolsKicker,
            },
            title: switch (card.id) {
              // The prayer slide's title is the prayer's name, which is why it
              // is the one slide whose heading is not a fixed string.
              LumeHeroSlideId.prayer =>
                timetable == null
                    ? l.homeNextPrayer
                    : _prayerName(
                        l,
                        (ctx is LumePrayerContext
                                ? ctx.next
                                : timetable.times.first)
                            .key,
                      ),
              LumeHeroSlideId.plan => l.slidePlanTitle,
              LumeHeroSlideId.read => l.slideReadTitle,
              LumeHeroSlideId.money => l.slideMoneyTitle,
              LumeHeroSlideId.trains => l.slideTrainsTitle,
              LumeHeroSlideId.tools => l.slideToolsTitle,
            },
            text: switch (card.id) {
              LumeHeroSlideId.prayer => l.slidePrayerLine(
                f.time(
                  (ctx is LumePrayerContext ? ctx.next : timetable!.times.first)
                      .at,
                ),
                user.city,
              ),
              LumeHeroSlideId.plan => l.slidePlanText,
              LumeHeroSlideId.read => l.slideReadText,
              LumeHeroSlideId.money => l.slideMoneyText,
              LumeHeroSlideId.trains => l.slideTrainsText,
              LumeHeroSlideId.tools => l.slideToolsText,
            },
            cta: switch (card.id) {
              LumeHeroSlideId.prayer => l.slidePrayerCta,
              LumeHeroSlideId.plan => l.slidePlanCta,
              LumeHeroSlideId.read => l.slideReadCta,
              LumeHeroSlideId.money => l.slideMoneyCta,
              LumeHeroSlideId.trains => l.slideTrainsCta,
              LumeHeroSlideId.tools => l.slideToolsCta,
            },
            badge: card.id == LumeHeroSlideId.prayer && remaining != null
                ? LumeHeroBadge(text: LumeFormatting.countdown(remaining))
                : null,
          ),
      ],
    );
  }

  // -- 4. quick actions ----------------------------------------------------

  Widget _quickActions(
    BuildContext context,
    AppLocalizations l,
    LumeHomeData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(quickActionsKey),
    child: LumePageSection(
      child: LumeHorizontalStrip.actions(
        children: <Widget>[
          for (final LumeQuickAction a in d.quickActions)
            LumeQuickActionPill(
              key: ValueKey<String>('home.qaction.${a.id}'),
              icon: a.icon,
              label: _quickActionLabel(l, a.id),
              onTap: () => actions.openTarget(LumeHomeTarget.tool(a.featureId)),
            ),
        ],
      ),
    ),
  );

  static String _quickActionLabel(AppLocalizations l, String id) =>
      switch (id) {
        'expense' => l.qaExpense,
        'task' => l.qaTask,
        'scan' => l.qaScan,
        'note' => l.qaNote,
        'water' => l.qaWater,
        'tasbih' => l.qaTasbih,
        'timer' => l.qaTimer,
        'shop' => l.qaShop,
        'parcel' => l.qaParcel,
        'docscan' => l.qaDocscan,
        _ => id,
      };

  // -- 5. quick tools ------------------------------------------------------

  Widget _quickTools(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeToolStatuses live,
    LumeHomeData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(quickToolsKey),
    child: LumePageSection(
      title: l.homeQuickTools,
      subtitle: user.interests.isEmpty
          ? l.homeQuickDefault
          : l.homeQuickFromInterests,
      link: l.actionAll,
      onLinkTap: actions.openTools,
      child: LumeMeasure(
        child: LumeTileGrid(
          columns: _quickColumns(context),
          children: <Widget>[
            for (final LumeFeature t in d.quickTools)
              LumeToolTile(
                key: ValueKey<String>('home.tool.${t.id}'),
                icon: t.icon,
                label: LumeFeatureStrings.name(l, t.id),
                status: LumeFeatureStrings.tileStatus(l, f, t.id, live),
                accent: t.faith,
                onTap: () => actions.openTarget(LumeHomeTarget.tool(t.id)),
              ),
          ],
        ),
      ),
    ),
  );

  /// `.tools-grid { grid-template-columns: repeat(4, 1fr) }`, and two below
  /// 360 where four tiles would be 70 wide with an 11-point label in them.
  static int _quickColumns(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 2;
    return context.measureClass == LumeWidthClass.compact ? 4 : 6;
  }

  // -- 6. Right now --------------------------------------------------------

  Widget _live(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeHomeData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(liveKey),
    child: LumePageSection(
      title: l.homeLiveNow,
      subtitle: l.homeLiveNowSub(f.time(d.header.date)),
      child: LumeMeasure(
        child: switch (d.live) {
          LumeFeedLoading<List<LumeLiveCard>>() => const Column(
            children: <Widget>[
              LumeSkeleton(kind: LumeSkeletonKind.row),
              SizedBox(height: LumeSpace.gapCard),
              LumeSkeleton(kind: LumeSkeletonKind.row),
            ],
          ),
          LumeFeedFailed<List<LumeLiveCard>>() => LumeNotice(
            kind: LumeNoticeKind.offline,
            title: l.toolErrorTitle,
            text: l.toolErrorText,
          ),
          LumeFeedReady<List<LumeLiveCard>>(
            :final List<LumeLiveCard> value,
            :final LumeFeedFreshness freshness,
          ) =>
            Column(
              children: <Widget>[
                if (freshness != LumeFeedFreshness.live)
                  Padding(
                    padding: const EdgeInsets.only(bottom: LumeSpace.x3),
                    child: LumeSectionFreshness(freshness: freshness),
                  ),
                for (int i = 0; i < value.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: LumeSpace.gapCard),
                  _liveCard(context, l, f, value[i]),
                ],
              ],
            ),
        },
      ),
    ),
  );

  Widget _liveCard(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeLiveCard card,
  ) {
    void open() => actions.openTarget(LumeHomeTarget.tool(card.featureId));

    return switch (card) {
      LumeWeatherLive(
        :final LumeWeatherNow weather,
        :final String city,
        :final bool forTomorrow,
      ) =>
        LumeLiveRow(
          key: const ValueKey<String>('home.live.weather'),
          icon: weather.icon,
          tone: LumeCardTone.sky,
          title: forTomorrow ? l.homeTomorrowIn(city) : city,
          meta:
              '${_condition(l, card.day.conditionKey)} · '
              '${l.weatherRain} ${card.day.rainPercent}%',
          value: f.temperature(
            forTomorrow ? card.day.highC : weather.temperatureC,
          ),
          subValue: l.weatherHighLow(
            f.temperature(card.day.highC),
            f.temperature(card.day.lowC),
          ),
          onTap: open,
        ),
      LumeMarketLive(:final LumeMarketSnapshot market) => LumeLiveRow(
        key: const ValueKey<String>('home.live.markets'),
        icon: LumeIcons.trending,
        tone: market.index.isUp ? LumeCardTone.up : LumeCardTone.down,
        title: market.index.name,
        meta: '${market.exchange.name} · ${_session(l, market)}',
        value: f.integer(market.index.value),
        trailing: LumeDelta(
          text: f.percent(market.index.percent),
          direction: market.index.isUp
              ? LumeDeltaDirection.up
              : LumeDeltaDirection.down,
        ),
        onTap: open,
      ),
      LumeOutageLive(
        :final LumeOutage outage,
        :final LumeOutageSlot slot,
        :final Duration remaining,
      ) =>
        LumeLiveRow(
          key: const ValueKey<String>('home.live.loadshed'),
          icon: LumeIcons.bolt,
          tone: LumeCardTone.warn,
          title: l.loadshedOff,
          meta: '${outage.area} · ${l.loadshedUntil(f.time(slot.to))}',
          value: LumeFormatting.shortCountdown(remaining),
          onTap: open,
        ),
      LumeBillsLive(:final LumeBillsSummary bills, :final String currency) =>
        LumeLiveRow(
          key: const ValueKey<String>('home.live.bills'),
          icon: LumeIcons.receipt,
          tone: LumeCardTone.warn,
          title: l.billsNeedAttention(bills.overdueCount),
          meta:
              '${l.billsDueThisMonth} · '
              '${f.money(bills.dueThisMonth, code: currency)}',
          value: f.money(bills.overdueTotal, code: currency),
          onTap: open,
        ),
    };
  }

  String _session(AppLocalizations l, LumeMarketSnapshot m) =>
      switch (m.state.closure) {
        null => l.marketsOpen,
        LumeMarketClosure.outsideHours => l.marketsClosed,
        LumeMarketClosure.weekend => l.marketsWeekend,
        LumeMarketClosure.holiday => l.marketsClosed,
      };

  // -- 7. At a glance ------------------------------------------------------

  Widget _glance(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeHomeData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(glanceKey),
    child: LumePageSection(
      title: l.homeGlance,
      subtitle: user.islamic ? l.homeGlanceMuslim : l.homeGlanceGeneral,
      link: l.navToday,
      onLinkTap: actions.openToday,
      child: LumeMeasure(
        child: Column(
          children: <Widget>[
            for (int i = 0; i < d.glance.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: LumeSpace.gapCard),
              _glanceCard(context, l, f, d.glance[i]),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _glanceCard(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeGlanceCard card,
  ) => switch (card) {
    LumeReadingGlance(:final LumeReadingProgress progress) => LumeProgressCard(
      key: const ValueKey<String>('home.glance.reading'),
      icon: LumeIcons.book,
      title: l.homeContinueSurah(_surah(l, progress.surahKey)),
      meta: l.homeAyahProgress(
        progress.ayah,
        progress.ayahCount,
        progress.minutesLeft,
      ),
      progress: progress.fraction,
      actionIcon: LumeIcons.play,
      onTap: () => actions.openTarget(card.target),
    ),
    LumeFuelGlance(:final LumeFuelPrice fuel) => LumeStatRow(
      key: const ValueKey<String>('home.glance.fuel'),
      icon: LumeIcons.fuel,
      title: _fuelGrade(l, fuel.gradeKey),
      tag: l.marketPk,
      meta: l.homeEffective(
        f.dateLong(fuel.effectiveOn),
        _fuelSource(l, fuel.sourceKey),
      ),
      value: f.rupeeSign(fuel.price),
      delta:
          '${fuel.isUp ? '+' : '−'}${f.number(fuel.change.abs(), decimals: 2)}',
      deltaUp: fuel.isUp,
      onTap: () => actions.openTarget(card.target),
    ),
    LumeTasksGlance(:final LumeTaskSummary tasks) => LumeProgressCard(
      key: const ValueKey<String>('home.glance.tasks'),
      icon: LumeIcons.checkSquare,
      title: l.homeTasksLeft(tasks.remaining),
      meta: l.homeTasksNext(tasks.nextTitle, f.time(tasks.nextAt)),
      progress: tasks.fraction,
      onTap: () => actions.openTarget(card.target),
    ),
  };

  // -- 8. Coming up --------------------------------------------------------

  Widget _upcoming(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeHomeData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(upcomingKey),
    child: LumePageSection(
      title: l.homeUpcoming,
      subtitle: l.homeUpcomingSub,
      child: LumeMeasure(
        child: switch (d.upcoming) {
          LumeFeedLoading<List<LumeUpcomingItem>>() => const LumeSkeleton(
            kind: LumeSkeletonKind.card,
          ),
          LumeFeedFailed<List<LumeUpcomingItem>>() => LumeNotice(
            kind: LumeNoticeKind.offline,
            title: l.toolErrorTitle,
            text: l.toolErrorText,
          ),
          LumeFeedReady<List<LumeUpcomingItem>>(
            :final List<LumeUpcomingItem> value,
          ) =>
            LumeRows(
              children: <Widget>[
                for (final LumeUpcomingItem i in value)
                  _upcomingRow(context, l, f, i),
              ],
            ),
        },
      ),
    ),
  );

  Widget _upcomingRow(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeUpcomingItem item,
  ) {
    void open() => actions.openTarget(LumeHomeTarget.tool(item.featureId));

    return switch (item) {
      LumePrayerUpcoming(:final LumePrayerTime prayer) => LumeCompactRow(
        key: const ValueKey<String>('home.upcoming.prayer'),
        icon: LumeIcons.prayer,
        label: _prayerName(l, prayer.key),
        subtitle: l.homeNextPrayer,
        value: f.time(prayer.at),
        onTap: open,
        chevron: false,
      ),
      LumeBillUpcoming(:final LumeBillDue bill, :final String currency) =>
        LumeCompactRow(
          key: ValueKey<String>('home.upcoming.bill.${bill.name}'),
          icon: bill.icon,
          label: bill.name,
          subtitle: bill.isOverdue
              ? l.billsOverdueBy(
                  f.dateLong(bill.dueOn) == ''
                      ? 0
                      : _daysBetween(bill.dueOn, _today(item)),
                )
              : l.billsDueIn(_daysBetween(_today(item), bill.dueOn)),
          value: f.money(bill.amount, code: currency),
          onTap: open,
          chevron: false,
        ),
      LumeSubscriptionUpcoming(:final LumeSubscriptionRenewal renewal) =>
        LumeCompactRow(
          key: const ValueKey<String>('home.upcoming.subs'),
          icon: LumeIcons.refresh,
          label: renewal.name,
          subtitle: l.subsRenews(f.dateMedium(renewal.renewsOn)),
          value: f.dateMedium(renewal.renewsOn),
          onTap: open,
          chevron: false,
        ),
      LumeBirthdayUpcoming(:final LumeBirthdayNext birthday) => LumeCompactRow(
        key: const ValueKey<String>('home.upcoming.birthday'),
        icon: LumeIcons.cake,
        label: birthday.name,
        subtitle:
            '${birthday.kindKey == 'anniversary' ? l.anniversaryKind : l.birthdayKind}'
            ' · ${l.commonInDays(birthday.days)}',
        value: f.dateMedium(birthday.on),
        onTap: open,
        chevron: false,
      ),
      LumeDocumentUpcoming(:final LumeDocumentRenewal renewal) =>
        LumeCompactRow(
          key: const ValueKey<String>('home.upcoming.document'),
          icon: LumeIcons.folder,
          label: l.docsRenewSoon(renewal.name),
          subtitle: l.commonInDays(renewal.days),
          value: f.dateMedium(renewal.expiresOn),
          onTap: open,
          chevron: false,
        ),
    };
  }

  /// The day the screen is composed for, carried so a row's "in 4 days" is
  /// arithmetic rather than a second reading of the clock.
  DateTime _today(LumeUpcomingItem item) => data!.header.date;

  static int _daysBetween(DateTime a, DateTime b) => DateTime(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime(a.year, a.month, a.day)).inDays;

  // -- 9. Discover ---------------------------------------------------------

  Widget _discover(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeHomeData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(discoverKey),
    child: LumePageSection(
      title: l.homeDiscover,
      subtitle: l.homeDiscoverSub,
      link: l.navExplore,
      onLinkTap: actions.openExplore,
      child: LumeHorizontalStrip(
        children: <Widget>[
          for (final LumeDiscoverCard c in d.discover)
            _discoverCard(context, l, f, d, c),
        ],
      ),
    ),
  );

  Widget _discoverCard(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeHomeData d,
    LumeDiscoverCard card,
  ) {
    final LumeHomeContent c = d.content;
    final (String title, String meta) text = switch (card.id) {
      LumeDiscoverId.cricket => (
        l.cricketScore(c.cricket!.team, c.cricket!.runs, c.cricket!.wickets),
        l.cricketSecondTest(c.cricket!.day),
      ),
      LumeDiscoverId.weather => (
        l.homeWeatherAnd(
          f.temperature(c.weather?.temperatureC ?? 0),
          _condition(l, c.weather?.conditionKey ?? 'clear').toLowerCase(),
        ),
        l.homeFeelsLike(f.temperature(c.weather?.feelsLikeC ?? 0)),
      ),
      LumeDiscoverId.outage => _outageText(l, f, c),
      LumeDiscoverId.duas => (l.discoverDuasTitle, l.discoverDuasMeta),
      LumeDiscoverId.parcel => (
        l.parcelOutForDelivery,
        l.parcelArrivesToday(c.parcel!.carrier),
      ),
    };

    return LumeMiniCard(
      key: ValueKey<String>('home.discover.${card.id.name}'),
      art: LumeDiscoverArt(card: card.id),
      title: text.$1,
      meta: text.$2,
      onTap: () => actions.openTarget(card.target),
    );
  }

  /// The prototype writes "Next outage 14:00 / Gulshan · 2 hours" into fixed
  /// markup, and its own schedule has that slot ending at 16:00 — so at 16:41
  /// the card named an outage that was already over. Derived here (C17).
  (String, String) _outageText(
    AppLocalizations l,
    LumeFormatting f,
    LumeHomeContent c,
  ) {
    final LumeOutage outage = c.outage!;
    final LumeOutageSlot? next = outage.nextAfter(data!.header.date);
    if (next == null) return (l.loadshedOff, outage.area);
    return (
      l.homeNextOutage(f.time(next.from)),
      l.homeOutageArea(outage.area, LumeFormatting.wholeHours(next.length)),
    );
  }

  // -- shared vocabulary ---------------------------------------------------

  static String _prayerName(AppLocalizations l, String key) =>
      LumeFeatureStrings.prayerName(l, key);

  static String _condition(AppLocalizations l, String key) =>
      LumeFeatureStrings.weatherCondition(l, key);

  static String _surah(AppLocalizations l, String key) =>
      key == 'alKahf' ? l.surahAlKahf : key;

  static String _fuelGrade(AppLocalizations l, String key) =>
      key == 'petrol' ? l.fuelPetrol : key;

  static String _fuelSource(AppLocalizations l, String key) =>
      key == 'ogra' ? l.fuelSourceOgra : key;
}

/// The line a stale or offline section wears, so §108's rule holds: a cached
/// figure and a live one must not look the same.
class LumeSectionFreshness extends StatelessWidget {
  const LumeSectionFreshness({super.key, required this.freshness});

  final LumeFeedFreshness freshness;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: LumeFreshness(
        label: freshness == LumeFeedFreshness.offline
            ? l.commonOffline
            : l.commonStale,
        quality: freshness == LumeFeedFreshness.offline
            ? LumeFreshnessQuality.cached
            : LumeFreshnessQuality.delayed,
      ),
    );
  }
}

/// What Home draws while its first load is in flight.
///
/// The *shape* of Home, not a spinner: the same blocks in the same places, so
/// nothing moves when the content lands.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) => const LumeMeasure(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(height: LumeSpace.x3),
        LumeSkeleton(kind: LumeSkeletonKind.row),
        SizedBox(height: LumeSpace.x5),
        LumeSkeleton(kind: LumeSkeletonKind.chart),
        SizedBox(height: LumeSpace.x6),
        LumeSkeleton(kind: LumeSkeletonKind.metric),
        SizedBox(height: LumeSpace.x6),
        LumeSkeleton(kind: LumeSkeletonKind.card),
        SizedBox(height: LumeSpace.gapCard),
        LumeSkeleton(kind: LumeSkeletonKind.card),
      ],
    ),
  );
}
