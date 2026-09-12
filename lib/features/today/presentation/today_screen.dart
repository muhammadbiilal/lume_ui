/// Today — the day as a plan rather than a data dump.
///
/// Nine blocks, in the order the reference emits them:
///
/// 1. the page head — the date, and an Add control
/// 2. the day ring
/// 3. three statistics, the first two faith-swapped
/// 4. the reflection — an ayah, or a thought
/// 5. **Your day** — the agenda, with a Week link
/// 6. **Tasks** — with an Add link
/// 7. **Habits** — seven days each
/// 8. **Private** — a door, and nothing through it
///
/// **The inventory summary had this wrong**, which is why the contract was
/// re-read from source: it listed a separate "prayer timeline" section and put
/// the statistics nowhere. The prayers are not a section — they are merged
/// into the agenda and sorted with everything else, which is the whole idea of
/// the screen.
///
/// The screen holds no data and makes no decisions about *what* is shown:
/// `LumeTodayComposer` does that, purely, so the composition can be asserted
/// without pumping a frame.
library;

import 'package:flutter/material.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/widgets/lume/lume_agenda.dart';
import '../../../core/widgets/lume/lume_day.dart';
import '../../../core/widgets/lume/lume_destination.dart';
import '../../../core/widgets/lume/lume_explore.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalogue/domain/eligibility.dart';
import '../../home/domain/home_model.dart';
import '../data/today_fixtures.dart';
import '../domain/today_model.dart';
import 'today_art.dart';

/// What Today can ask the shell to do.
@immutable
class LumeTodayActions {
  const LumeTodayActions({
    required this.openTarget,
    required this.toggleTask,
    required this.openWeek,
    required this.addTask,
    required this.openPrivate,
  });

  final void Function(LumeHomeTarget target) openTarget;
  final void Function(String taskId, bool done) toggleTask;
  final VoidCallback openWeek;
  final VoidCallback addTask;
  final VoidCallback openPrivate;
}

/// The screen.
class LumeTodayScreen extends StatelessWidget {
  const LumeTodayScreen({
    super.key,
    required this.user,
    required this.actions,
    this.data,
    this.loading = false,
    this.failed = false,
    this.onRetry,
  });

  final LumeUserContext user;
  final LumeTodayActions actions;

  /// `null` until the first load returns.
  final LumeTodayData? data;

  final bool loading;

  /// The whole day failed to compose. The reference has no such state; a real
  /// aggregate of six stores can have one.
  final bool failed;

  final Future<void> Function()? onRetry;

  /// Keys the tests and the bounds comparison address elements by.
  static const String headKey = 'today.head';
  static const String ringKey = 'today.ring';
  static const String statsKey = 'today.stats';
  static const String reflectionKey = 'today.reflection';
  static const String agendaKey = 'today.agenda';
  static const String tasksKey = 'today.tasks';
  static const String habitsKey = 'today.habits';
  static const String privateKey = 'today.private';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: user.country,
    );
    final LumeTodayData? d = data;

    if (d == null) {
      return LumeDestinationPage(
        storageId: 'today',
        semanticLabel: l.navToday,
        slivers: <Widget>[
          SliverToBoxAdapter(child: _head(context, l, null)),
          SliverToBoxAdapter(
            child: failed
                ? LumeMeasure(
                    child: Padding(
                      padding: const EdgeInsets.only(top: LumeSpace.gapSection),
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
                : const _TodaySkeleton(),
          ),
        ],
      );
    }

    final int nowMinute = d.progress.minuteOfDay;

    return LumeDestinationPage(
      storageId: 'today',
      semanticLabel: l.navToday,
      onRefresh: onRetry,
      slivers: <Widget>[
        SliverToBoxAdapter(child: _head(context, l, d)),
        SliverToBoxAdapter(child: _ring(context, l, f, d)),
        SliverToBoxAdapter(child: _stats(context, l, f, d)),
        SliverToBoxAdapter(child: _reflection(context, l, f, d)),
        SliverToBoxAdapter(child: _agenda(context, l, f, d, nowMinute)),
        SliverToBoxAdapter(child: _tasks(context, l, f, d)),
        SliverToBoxAdapter(child: _habits(context, l, f, d)),
        if (d.showPrivate) SliverToBoxAdapter(child: _private(context, l)),
      ],
    );
  }

  // -- 1. the page head ----------------------------------------------------

  Widget _head(BuildContext context, AppLocalizations l, LumeTodayData? d) {
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: user.country,
    );
    final DateTime date = d?.header.date ?? LumeClockScope.of(context).now();
    // The reference joins the Gregorian date and the Hijri one with a dot.
    final String subtitle = d?.header.hijri == null
        ? f.dateFull(date)
        : '${f.dateFull(date)} · ${d!.header.hijri}';

    return KeyedSubtree(
      key: const ValueKey<String>(headKey),
      child: LumePageHead(
        title: l.navToday,
        subtitle: subtitle,
        action: LumeHeaderButton(
          icon: LumeIcons.plus,
          semanticLabel: l.actionAdd,
          onTap: actions.addTask,
        ),
      ),
    );
  }

  // -- 2. the ring ---------------------------------------------------------

  Widget _ring(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTodayData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(ringKey),
    child: LumePageSection(
      // `style="margin-top:18px"` on this one section, inline in the markup.
      topGap: 18,
      child: LumeMeasure(
        child: LumeRingCard(
          sticker: const LumeTodaySticker(),
          ring: LumeDayRing(
            fraction: d.progress.fraction,
            label: f.percent(d.progress.percent, decimals: 0),
            unit: l.todayOfDay,
          ),
          title: l.todayOnTrack,
          text: l.todayRingSummary(
            d.progress.summary.tasksDone,
            d.progress.summary.taskCount,
            d.progress.summary.meetingsLeft,
          ),
        ),
      ),
    ),
  );

  // -- 3. the statistics ---------------------------------------------------

  Widget _stats(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTodayData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(statsKey),
    child: LumePageSection(
      child: LumeMeasure(
        child: LumeStatRowGrid(
          children: <Widget>[
            for (final LumeTodayStat s in d.stats)
              LumeStatCard(
                key: ValueKey<String>('today.stat.${s.id.name}'),
                icon: _statIcon(s.id),
                value: f.number(s.value, decimals: s.value is int ? 0 : 1),
                unit: _statUnit(l, f, s),
                label: _statLabel(l, s.id),
              ),
          ],
        ),
      ),
    ),
  );

  static String _statIcon(LumeTodayStatId id) => switch (id) {
    LumeTodayStatId.prayerStreak ||
    LumeTodayStatId.dailyStreak => LumeIcons.flame,
    LumeTodayStatId.readToday => LumeIcons.book,
    LumeTodayStatId.steps => LumeIcons.pulse,
    LumeTodayStatId.tasksDone => LumeIcons.checkCircle,
  };

  static String _statLabel(AppLocalizations l, LumeTodayStatId id) =>
      switch (id) {
        LumeTodayStatId.prayerStreak => l.todayPrayerStreak,
        LumeTodayStatId.readToday => l.todayReadToday,
        LumeTodayStatId.dailyStreak => l.todayDailyStreak,
        LumeTodayStatId.steps => l.todaySteps,
        LumeTodayStatId.tasksDone => l.todayTasksDone,
      };

  /// The unit is its own string in its own face — `.stat__value span`.
  static String? _statUnit(
    AppLocalizations l,
    LumeFormatting f,
    LumeTodayStat s,
  ) => switch (s.id) {
    LumeTodayStatId.prayerStreak ||
    LumeTodayStatId.dailyStreak => ' ${l.unitDays}',
    LumeTodayStatId.readToday => ' ${l.unitMinutes}',
    LumeTodayStatId.steps => ' ${l.unitThousand}',
    LumeTodayStatId.tasksDone => l.unitOfTotal((s.secondary ?? 0).toInt()),
  };

  // -- 4. the reflection ---------------------------------------------------

  Widget _reflection(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTodayData d,
  ) {
    final LumeReflection r = d.reflection;
    // The reference writes the citation twice and differently: the section
    // subtitle is "Ar-Ra’d · 13:28" and the card's attribution is
    // "Ar-Ra’d 13:28". Both are composed here from the same three fields.
    final String? verse = r is LumeAyahReflection
        ? '${f.integer(r.chapter)}:${f.integer(r.verse)}'
        : null;
    final (String title, String sub) = switch (r) {
      LumeAyahReflection(:final String surah) => (
        l.todayAyah,
        l.todayAyahReference(surah, verse!),
      ),
      LumeThoughtReflection() => (l.todayThought, l.todayThoughtSub),
    };

    return KeyedSubtree(
      key: const ValueKey<String>(reflectionKey),
      child: LumePageSection(
        title: title,
        subtitle: sub,
        child: LumeMeasure(
          child: LumeQuoteCard(
            key: ValueKey<String>(
              r is LumeAyahReflection ? 'today.ayah' : 'today.thought',
            ),
            arabic: r is LumeAyahReflection ? r.arabic : null,
            text: switch (r) {
              LumeAyahReflection(:final String translation) => translation,
              LumeThoughtReflection(:final String text) => text,
            },
            attribution: switch (r) {
              LumeAyahReflection(:final String surah) => l.todayAyahCitation(
                surah,
                verse!,
              ),
              LumeThoughtReflection(:final String attribution) => attribution,
            },
            actions: <LumeCardAction>[
              LumeCardAction(
                icon: LumeIcons.bookmark,
                semanticLabel: l.actionBookmark,
                onPressed: () {},
              ),
              LumeCardAction(
                icon: LumeIcons.share,
                semanticLabel: l.actionShare,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- 5. the agenda -------------------------------------------------------

  Widget _agenda(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTodayData d,
    int nowMinute,
  ) => KeyedSubtree(
    key: const ValueKey<String>(agendaKey),
    child: LumePageSection(
      title: l.todayYourDay,
      subtitle: user.islamic ? l.todayAgendaMuslim : l.todayAgendaGeneral,
      link: l.actionWeek,
      onLinkTap: actions.openWeek,
      child: LumeMeasure(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < d.agenda.length; i++)
              _agendaRow(context, l, f, d.agenda[i], nowMinute, i),
          ],
        ),
      ),
    ),
  );

  Widget _agendaRow(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeAgendaEntry e,
    int nowMinute,
    int index,
  ) {
    final LumeAgendaState state = e.stateAt(nowMinute);
    final (String title, String meta) = _agendaText(l, f, e, state);

    return LumeAgendaRow(
      key: ValueKey<String>('today.agenda.${e.id}'),
      time: f.time(_at(e.minuteOfDay)),
      title: title,
      meta: meta,
      icon: LumeTodayComposer.iconFor(e, state),
      tone: switch (state) {
        LumeAgendaState.done => LumeAgendaTone.done,
        LumeAgendaState.now => LumeAgendaTone.now,
        LumeAgendaState.upcoming => LumeAgendaTone.upcoming,
      },
      isLast: index == (data?.agenda.length ?? 0) - 1,
      onTap: e.target == null ? null : () => actions.openTarget(e.target!),
    );
  }

  /// A time of day as a `DateTime`, so the formatter can do the work.
  static DateTime _at(int minuteOfDay) =>
      DateTime(2026, 1, 1, minuteOfDay ~/ 60, minuteOfDay % 60);

  (String, String) _agendaText(
    AppLocalizations l,
    LumeFormatting f,
    LumeAgendaEntry e,
    LumeAgendaState state,
  ) => switch (e.kind) {
    LumeAgendaKind.prayer => (
      _prayerName(l, e.detail ?? 'fajr'),
      state == LumeAgendaState.done ? l.agendaPrayed : l.agendaAdhanOn,
    ),
    LumeAgendaKind.outage => (
      l.agendaOutage,
      l.agendaOutageMeta(e.detail ?? '', 1),
    ),
    LumeAgendaKind.errand => (l.agendaGroceries, l.agendaGroceriesMeta),
    LumeAgendaKind.event when e.id == 'standup' => (
      l.agendaStandup,
      l.agendaStandupMeta,
    ),
    LumeAgendaKind.event => (l.agendaReview, l.agendaReviewMeta),
  };

  static String _prayerName(AppLocalizations l, String key) => switch (key) {
    'fajr' => l.prayerFajr,
    'dhuhr' => l.prayerDhuhr,
    'asr' => l.prayerAsr,
    'maghrib' => l.prayerMaghrib,
    'isha' => l.prayerIsha,
    _ => key,
  };

  // -- 6. the tasks --------------------------------------------------------

  Widget _tasks(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTodayData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(tasksKey),
    child: LumePageSection(
      title: l.todayTasks,
      subtitle: l.todayTasksSub,
      link: l.actionAdd,
      linkIcon: LumeIcons.plus,
      onLinkTap: actions.addTask,
      child: LumeMeasure(
        child: LumeCard(
          padded: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < d.tasks.length; i++)
                LumeTaskRow(
                  key: ValueKey<String>('today.task.${d.tasks[i].id}'),
                  label: _taskLabel(l, d.tasks[i]),
                  done: d.tasks[i].done,
                  time: d.tasks[i].minuteOfDay == null
                      ? l.taskEvening
                      : f.time(_at(d.tasks[i].minuteOfDay!)),
                  isLast: i == d.tasks.length - 1,
                  onToggle: () =>
                      actions.toggleTask(d.tasks[i].id, !d.tasks[i].done),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  String _taskLabel(AppLocalizations l, LumeTodayTask t) => switch (t.id) {
    // `data-loc` in the reference: the market's own utility, or a plain line.
    'electricity' =>
      user.country == t.countryLabel ? l.taskElectricityPk : l.taskElectricity,
    'email' => l.taskEmail,
    'summary' => l.taskSummary,
    'alKahf' => l.taskAlKahf,
    'callHome' => l.taskCallHome,
    _ => t.id,
  };

  // -- 7. the habits -------------------------------------------------------

  Widget _habits(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTodayData d,
  ) => KeyedSubtree(
    key: const ValueKey<String>(habitsKey),
    child: LumePageSection(
      title: l.todayHabits,
      subtitle: l.todayHabitsSub,
      child: LumeMeasure(
        child: LumeHabitCard(
          children: <Widget>[
            for (final LumeHabit h in d.habits)
              LumeHabitRow(
                key: ValueKey<String>('today.habit.${h.id}'),
                name: _habitName(l, h.id),
                days: h.days,
                streak: f.integer(h.streak),
                todayIndex: h.days.length - 1,
                semanticLabel: l.todayHabitSummary(
                  _habitName(l, h.id),
                  h.days.where((bool on) => on).length,
                  h.streak,
                ),
              ),
          ],
        ),
      ),
    ),
  );

  static String _habitName(AppLocalizations l, String id) => switch (id) {
    'fajr' => l.habitFajr,
    'quran' => l.habitQuran,
    'steps' => l.habitSteps,
    'water' => l.habitWater,
    _ => id,
  };

  // -- 8. the private card -------------------------------------------------

  Widget _private(BuildContext context, AppLocalizations l) => KeyedSubtree(
    key: const ValueKey<String>(privateKey),
    child: LumePageSection(
      title: l.todayPrivate,
      subtitle: l.todayPrivateSub,
      child: LumeMeasure(
        child: LumePrivateCard(
          title: l.todayPrivateTitle,
          text: l.todayPrivateText,
          onTap: actions.openPrivate,
        ),
      ),
    ),
  );
}

/// Today while it is still arriving.
///
/// The shape of what is coming, not a spinner (§11). The reference has no
/// loading state because it has nothing to load; a real aggregate does.
class _TodaySkeleton extends StatelessWidget {
  const _TodaySkeleton();

  @override
  Widget build(BuildContext context) => LumeMeasure(
    child: Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const LumeSkeleton(kind: LumeSkeletonKind.metric),
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
