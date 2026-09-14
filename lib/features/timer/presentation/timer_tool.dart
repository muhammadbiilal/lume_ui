/// Timer — the reference tool for the clock-instrument archetype.
///
/// `tools/everyday/timer.tool.js` over `shared/clock.js` `clockScreen`: the
/// face with its time, hint and two actions; the presets; the history. The
/// stopwatch draws the same face ([LumeClockFace]).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_clock_face.dart';
import '../../../core/widgets/lume/lume_destination.dart';
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
            timeKey: LumeTimerTool.timeKey,
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
            child: LumeHorizontalStrip.chips(
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
