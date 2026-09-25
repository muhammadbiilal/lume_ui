/// Taraweeh — `tools/islamic/taraweeh.tool.js`, as a real record-backed
/// tool.
///
/// The reference draws a nearby-mosque finder over a fully fabricated
/// `nearbyMosques()` fixture and has no real per-night log anywhere behind
/// it (see `taraweeh_model.dart`'s library doc for the full accounting of
/// what was dropped). This replaces it with the one honest thing worth
/// keeping: a reader's own Taraweeh nights, logged one at a time, with the
/// real rakaat count they prayed and, optionally, the Juz they reached —
/// every streak and completion figure computed from those nights in
/// `taraweeh_book.dart`, never a literal.
///
/// A single screen: a summary, tonight's toggle, tonight's rakaat and Juz
/// (once logged), the reader's own Khatm progress, and their last 35 nights.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/navigation/lume_tool_frame.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/values/lume_date.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_overlay.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/taraweeh_providers.dart';
import '../domain/taraweeh_book.dart';
import '../domain/taraweeh_failure.dart';
import '../domain/taraweeh_model.dart';
import '../domain/taraweeh_repository.dart';

abstract final class LumeTaraweehTool {
  static const String id = 'taraweeh';

  static const Key summaryKey = ValueKey<String>('taraweeh.summary');
  static const Key tonightKey = ValueKey<String>('taraweeh.tonight');
  static const Key rakaatKey = ValueKey<String>('taraweeh.rakaat');
  static const Key juzKey = ValueKey<String>('taraweeh.juz');
  static const Key progressKey = ValueKey<String>('taraweeh.progress');
  static const Key calendarKey = ValueKey<String>('taraweeh.calendar');

  static Widget open(LumeToolRequest request) =>
      TaraweehTool(request: request);
}

class TaraweehTool extends ConsumerStatefulWidget {
  const TaraweehTool({super.key, required this.request});

  final LumeToolRequest request;

  @override
  ConsumerState<TaraweehTool> createState() => _TaraweehToolState();
}

class _TaraweehToolState extends ConsumerState<TaraweehTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final TaraweehRepository _repo = ref.read(taraweehRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _repo.open();
    _repo.changes.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_changed);
    super.dispose();
  }

  void _say(
    String message, {
    LumeToastTone tone = LumeToastTone.success,
    String? actionLabel,
    VoidCallback? onAction,
  }) => _host.currentState?.say(
    message,
    tone: tone,
    actionLabel: actionLabel,
    onAction: onAction,
  );

  LumeDate? _today(BuildContext context) {
    final LumeStartupState startup = ref.watch(startupControllerProvider).state;
    final LumeZoneResolution zone = ref
        .watch(timeZoneServiceProvider)
        .readerZone(
          startup.profile,
          ref.watch(deviceZoneProvider),
          country: widget.request.user.country,
          city: widget.request.user.city,
        );
    final LumeZoneClock clock = ref
        .watch(timeZoneServiceProvider)
        .clock(LumeClockScope.of(context).now(), zone);
    return clock.ok ? LumeDate.ofWallClock(clock.local!) : null;
  }

  void _failed(AppLocalizations l, TaraweehFailure f) {
    _say(switch (f.kind) {
      TaraweehFailureKind.conflict ||
      TaraweehFailureKind.notFound => l.taraweehErrConflict,
      TaraweehFailureKind.storage ||
      TaraweehFailureKind.validation => l.taraweehErrFailed,
    }, tone: LumeToastTone.error);
  }

  Future<void> _setPrayed(AppLocalizations l, LumeDate date, bool value) async {
    final TaraweehResult<TaraweehWrite> r = value
        ? _repo.logTonight(date, rakaat: 20)
        : _repo.clear(date);
    if (r.failure != null) return _failed(l, r.failure!);
    if (r.value!.receipt.revision == 0) return;
    _say(
      value ? l.taraweehPrayedToast : l.taraweehClearedToast,
      actionLabel: l.recUndo,
      onAction: () {
        final TaraweehResult<void> u = _repo.undo(r.value!);
        if (u.failure != null) _failed(l, u.failure!);
      },
    );
  }

  void _setRakaat(AppLocalizations l, LumeDate date, int rakaat) {
    final TaraweehResult<TaraweehWrite> r = _repo.setRakaat(date, rakaat);
    if (r.failure != null) _failed(l, r.failure!);
  }

  void _setJuz(AppLocalizations l, LumeDate date, int? juz) {
    final TaraweehResult<TaraweehWrite> r = _repo.setJuz(date, juz);
    if (r.failure != null) _failed(l, r.failure!);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(context, countryCode: widget.request.user.country);
    final LumeDate? today = _today(context);
    final TaraweehSnapshot snapshot = _repo.view();

    LumeToolStatus status = LumeToolStatus.ready;
    TaraweehStats? stats;
    if (snapshot.loading) {
      status = LumeToolStatus.loading;
    } else if (snapshot.failed || today == null) {
      status = LumeToolStatus.error;
    } else {
      stats = snapshot.stats(today);
    }

    return LumeToolScreen(
      key: _host,
      feature: widget.request.feature,
      user: widget.request.user,
      onBack: widget.request.onBack,
      onOpenRelated: widget.request.onOpenRelated,
      status: status,
      onRetry: () => setState(_repo.retry),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: (stats == null || today == null)
            ? const <Widget>[]
            : _body(context, l, f, today, stats),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeDate today,
    TaraweehStats stats,
  ) => <Widget>[
    LumeToolSection(
      child: LumeSummaryCard(
        key: LumeTaraweehTool.summaryKey,
        kicker: l.taraweehSummaryKicker,
        value: f.integer(stats.current),
        valueSmall: l.taraweehNightsUnit,
        caption: l.taraweehBestCaption(stats.best),
        stats: <LumeStat>[
          LumeStat(value: f.integer(stats.totalNights), label: l.taraweehStatTotal),
          LumeStat(value: f.integer(stats.juzDone), label: l.taraweehStatJuz),
          LumeStat(
            value: stats.nextJuz == null ? '—' : f.integer(stats.nextJuz!),
            label: l.taraweehStatNextJuz,
          ),
        ],
      ),
    ),
    LumeToolSection(
      child: LumeRecordRow(
        key: LumeTaraweehTool.tonightKey,
        title: l.taraweehTonight,
        subtitle: f.dateMediumYear(today.toCalendarDateTime()),
        done: stats.prayedTonight,
        checkLabel: l.taraweehPrayedLabel,
        onToggle: (bool v) => unawaited(_setPrayed(l, today, v)),
      ),
    ),
    if (stats.tonight != null) ...<Widget>[
      LumeToolSection(
        title: l.taraweehRakaatTitle,
        child: LumeSegmented(
          key: LumeTaraweehTool.rakaatKey,
          semanticLabel: l.taraweehRakaatTitle,
          value: stats.tonight!.rakaat.toString(),
          items: <LumeChoice>[
            for (final int r in kTaraweehRakaatOptions)
              LumeChoice(value: r.toString(), label: l.taraweehRakaatOption(r)),
          ],
          onChanged: (String v) => _setRakaat(l, today, int.parse(v)),
        ),
      ),
      LumeToolSection(
        title: l.taraweehJuzTitle,
        child: _JuzStepper(
          key: LumeTaraweehTool.juzKey,
          juz: stats.tonight!.juz,
          f: f,
          l: l,
          onChanged: (int? v) => _setJuz(l, today, v),
        ),
      ),
    ],
    LumeToolSection(
      title: l.taraweehProgressTitle,
      child: LumeMeterRow(
        key: LumeTaraweehTool.progressKey,
        label: l.taraweehProgressLabel,
        value: l.taraweehProgressValue(stats.juzDone, kTaraweehJuzMax),
        progress: stats.progress,
        footnote: stats.khatmComplete ? l.taraweehKhatmComplete : null,
      ),
    ),
    LumeToolSection(
      title: l.taraweehCalendarTitle,
      child: _TaraweehHeatGrid(key: LumeTaraweehTool.calendarKey, days: stats.heat, l: l),
    ),
  ];
}

/// A bounded stepper over the Qur'an's 30 Juz — `null` (nothing noted) at
/// one end, 30 at the other. Chosen over a free-typed number field so a
/// keystroke never races the record write it would otherwise trigger.
class _JuzStepper extends StatelessWidget {
  const _JuzStepper({
    super.key,
    required this.juz,
    required this.f,
    required this.l,
    required this.onChanged,
  });

  final int? juz;
  final LumeFormatting f;
  final AppLocalizations l;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => LumeStepper(
    label: l.taraweehJuzTitle,
    value: juz == null ? l.taraweehJuzValueNone : f.integer(juz!),
    decrementLabel: l.taraweehJuzDecrementLabel,
    incrementLabel: l.taraweehJuzIncrementLabel,
    onDecrement: juz == null
        ? null
        : () => onChanged(juz == kTaraweehJuzMin ? null : juz! - 1),
    onIncrement: (juz ?? 0) >= kTaraweehJuzMax
        ? null
        : () => onChanged((juz ?? 0) + 1),
  );
}

/// The reader's own last 35 nights — a plain prayed/not-prayed grid, never a
/// graduated heat scale: a single nightly entry carries no intensity to show
/// one.
class _TaraweehHeatGrid extends StatelessWidget {
  const _TaraweehHeatGrid({super.key, required this.days, required this.l});

  final List<TaraweehHeatDay> days;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final int prayed = days.where((TaraweehHeatDay d) => d.prayed).length;
    return Semantics(
      label: l.taraweehCalendarA11y(prayed, days.length),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: <Widget>[
            for (final TaraweehHeatDay d in days)
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: d.prayed ? lume.accent : lume.tintNeutral,
                  borderRadius: BorderRadius.circular(LumeRadius.xs / 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
