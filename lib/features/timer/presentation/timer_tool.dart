/// Timer — the reference tool for the clock-instrument archetype.
///
/// `tools/everyday/timer.tool.js` over `shared/clock.js` `clockScreen`: the
/// face with its time, hint and two actions; the presets; the history. The
/// stopwatch and the focus session are the same instrument with other faces,
/// which is why the face is its own widget ([LumeClockFace]).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_numerals.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_destination_cards.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/timer_controller.dart';

class LumeTimerTool extends ConsumerStatefulWidget {
  const LumeTimerTool({super.key, required this.request, this.periodic});

  final LumeToolRequest request;

  /// The interval, for a test that steps time itself.
  final LumePeriodicTimer? periodic;

  static Widget open(LumeToolRequest request) =>
      LumeTimerTool(request: request);

  static const Key timeKey = ValueKey<String>('timer.time');
  static const Key startKey = ValueKey<String>('timer.start');
  static const Key resetKey = ValueKey<String>('timer.reset');
  static const Key presetsKey = ValueKey<String>('timer.presets');
  static const Key historyKey = ValueKey<String>('timer.history');

  /// `timer()` — the four presets, in seconds.
  static const List<int> presets = <int>[60, 300, 600, 1500];

  @override
  ConsumerState<LumeTimerTool> createState() => _LumeTimerToolState();
}

class _LumeTimerToolState extends ConsumerState<LumeTimerTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeTimerController _clock = LumeTimerController(
    session: ref.read(toolSessionProvider),
    periodic: widget.periodic,
    onFinished: _finished,
  )..addListener(_changed);

  void _changed() => setState(() {});

  /// `toast(t('timer.done'))` and `navigator.vibrate([30, 60, 30])`.
  void _finished() {
    _host.currentState?.say(AppLocalizations.of(context).timerDone);
    HapticFeedback.vibrate();
  }

  @override
  void dispose() {
    _clock
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    String minutes(int n) => l.unitMinutesCount(f.integer(n));

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeClockFace(
            display: _clock.display,
            hint: l.timerHint,
            primary: LumeButton.accent(
              key: LumeTimerTool.startKey,
              label: l.commonStart,
              icon: LumeIcons.play,
              onPressed: _clock.toggle,
            ),
            reset: LumeButton(
              key: LumeTimerTool.resetKey,
              label: l.commonReset,
              icon: LumeIcons.refresh,
              onPressed: _clock.reset,
            ),
          ),
          LumeToolSection(
            title: l.timerPresets,
            child: LumeChipRow(
              key: LumeTimerTool.presetsKey,
              children: <Widget>[
                for (final int secs in LumeTimerTool.presets)
                  LumeChoiceChip(
                    label: minutes(secs ~/ 60),
                    selected: false,
                    onTap: () => _clock.set(secs),
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.commonHistory,
            child: LumeRows(
              key: LumeTimerTool.historyKey,
              children: <Widget>[
                LumeCompactRow(
                  icon: LumeIcons.timer,
                  label: minutes(25),
                  value: l.commonToday,
                  chevron: false,
                ),
                LumeCompactRow(
                  icon: LumeIcons.timer,
                  label: minutes(5),
                  value: l.commonYesterday,
                  chevron: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.clockface` — a running clock's time, its hint and its two actions.
///
/// Stylesheet: 28 above and 4 below inside the page gutter; 14 between the
/// parts, the hint pulled 8 closer; the time 58 / 800 / −0.055em in tabular
/// figures; the hint 12 / 600, muted; the actions 8 apart.
class LumeClockFace extends StatelessWidget {
  const LumeClockFace({
    super.key,
    required this.display,
    required this.primary,
    required this.reset,
    this.hint,
  });

  final String display;
  final String? hint;
  final Widget primary;
  final Widget reset;

  @override
  Widget build(BuildContext context) {
    final LumeColors lume = context.lume;
    final double gutter = LumeLayout.pageGutter(context.measureClass);
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 28, gutter, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // A live region, so a reader hears the minute it changes to — and
          // `.is-rtl .clockface__time { direction: ltr }`.
          Semantics(
            liveRegion: true,
            child: LumeNumerals(
              display,
              key: LumeTimerTool.timeKey,
              style: LumeType.numeric(
                LumeType.tracked(
                  LumeType.natural(
                    context,
                    context.lumeType.display,
                    size: 58,
                  ).copyWith(fontWeight: FontWeight.w800),
                  -0.055,
                ),
              ).copyWith(color: lume.text),
            ),
          ),
          if (hint != null) ...<Widget>[
            const SizedBox(height: 14 - 8),
            Text(
              hint!,
              textAlign: TextAlign.center,
              style: LumeType.natural(
                context,
                context.lumeType.meta,
              ).copyWith(color: lume.text3, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[primary, const SizedBox(width: 8), reset],
          ),
        ],
      ),
    );
  }
}

/// `.chips` — a scrolling row of chips 7 apart, inside its own page gutter.
class LumeChipRow extends StatelessWidget {
  const LumeChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsetsDirectional.only(
      start: LumeLayout.pageGutter(context.measureClass),
      end: LumeLayout.pageGutter(context.measureClass),
      bottom: 2,
    ),
    child: Row(
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: 7),
          children[i],
        ],
      ],
    ),
  );
}
