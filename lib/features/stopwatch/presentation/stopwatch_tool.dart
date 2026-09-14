/// Stopwatch — rollout wave 1, on the Timer clock-instrument reference.
///
/// `tools/everyday/stopwatch.tool.js` over `shared/clock.js` `clockScreen`:
/// the face, and the laps or a state saying there are none. The face is
/// Timer's ([LumeClockFace]); the counting is [LumeStopwatchController], which
/// moves the hundredths and keeps laps the reference never records (C83).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_clock_face.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../timer/application/timer_controller.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../application/stopwatch_controller.dart';

class LumeStopwatchTool extends ConsumerStatefulWidget {
  const LumeStopwatchTool({
    super.key,
    required this.request,
    this.periodic,
    this.elapsed,
  });

  final LumeToolRequest request;

  /// The repaint interval and the elapsed-time source, for a test that steps
  /// time itself.
  final LumePeriodicTimer? periodic;
  final LumeElapsed? elapsed;

  static Widget open(LumeToolRequest request) =>
      LumeStopwatchTool(request: request);

  static const String id = 'stopwatch';

  static const Key timeKey = ValueKey<String>('stopwatch.time');
  static const Key startKey = ValueKey<String>('stopwatch.start');
  static const Key resetKey = ValueKey<String>('stopwatch.reset');
  static const Key lapKey = ValueKey<String>('stopwatch.lap');
  static const Key lapsKey = ValueKey<String>('stopwatch.laps');
  static const Key emptyKey = ValueKey<String>('stopwatch.empty');

  @override
  ConsumerState<LumeStopwatchTool> createState() => _LumeStopwatchToolState();
}

class _LumeStopwatchToolState extends ConsumerState<LumeStopwatchTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeStopwatchController _clock = LumeStopwatchController(
    session: ref.read(toolSessionProvider),
    periodic: widget.periodic,
    elapsed: widget.elapsed,
  )..addListener(_changed);

  void _changed() => setState(() {});

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
    final bool running = _clock.running;
    final List<int> laps = _clock.laps;

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
            timeKey: LumeStopwatchTool.timeKey,
            display: _clock.display,
            hint: l.stopwatchHint,
            primary: running
                ? LumeButton.accent(
                    key: LumeStopwatchTool.startKey,
                    label: l.stopwatchPause,
                    onPressed: _clock.toggle,
                  )
                : LumeButton.accent(
                    key: LumeStopwatchTool.startKey,
                    label: l.commonStart,
                    icon: LumeIcons.play,
                    onPressed: _clock.toggle,
                  ),
            reset: running
                ? LumeButton(
                    key: LumeStopwatchTool.lapKey,
                    label: l.stopwatchLapAction,
                    icon: LumeIcons.plus,
                    onPressed: _clock.lap,
                  )
                : LumeButton(
                    key: LumeStopwatchTool.resetKey,
                    label: l.commonReset,
                    icon: LumeIcons.refresh,
                    onPressed: _clock.reset,
                  ),
          ),
          LumeToolSection(
            title: l.stopwatchLaps,
            child: laps.isEmpty
                ? LumeToolState(
                    key: LumeStopwatchTool.emptyKey,
                    icon: LumeIcons.stopwatch,
                    title: l.stopwatchEmptyTitle,
                    text: l.stopwatchEmptyText,
                  )
                : LumeRows(
                    key: LumeStopwatchTool.lapsKey,
                    children: <Widget>[
                      for (int i = 0; i < laps.length; i++)
                        LumeCompactRow(
                          icon: LumeIcons.stopwatch,
                          label: l.stopwatchLap(f.integer(i + 1)),
                          value: LumeStopwatchController.format(laps[i]),
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
