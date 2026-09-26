/// Alarms — the reference's own decorative switch, ported honestly rather
/// than turned into a real scheduler it never was.
///
/// `tools/personal/alarms.tool.js` draws three fixture alarms (see
/// `alarms_fixtures.dart`) with a switch on each row and a "+" FAB. Neither
/// does what it looks like it does, in the reference itself:
///
/// * The switch's `act` is `alarmtoggle:<id>`, and `tool.screen.js` handles
///   it by reaching into the DOM for that one row and flipping a CSS class —
///   `sw.classList.toggle('is-on')` — never touching the `list`/`next` data
///   the summary card above was drawn from, and never calling `renderTool()`.
///   Leaving the tool and reopening it calls `alarms()` again, which
///   rebuilds the same three objects with their original `on` values — the
///   flip does not survive, because nothing durable was ever changed. It is
///   real in the sense that the pixel moves; it is not real in the sense
///   that it arms or disarms anything.
/// * The FAB is `act: 'toast:' + c.t('alarms.adding')` — the same
///   toast-only shape Parcel's Track button already ports in this
///   codebase. There is no reader-added alarm in the
///   reference to build one for here.
///
/// This port keeps both exactly that honest: the switch below flips in
/// [State] for as long as the tool stays mounted (so a press visibly
/// responds, the same as the reference's own CSS class does), the FAB says a
/// fixed line, and neither one changes the "Next alarm" summary — which, in
/// the reference, is worked out once from the untouched fixture and never
/// revisited either. `LumeDataCapability.fixture('alarms')` needs no entry
/// in `inputOnly`, `computed` or `readerRecords`: default fixture-display,
/// the same shape wave 9 gave Parcel and its fifteen siblings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/alarms_fixtures.dart';
import 'alarms_text.dart';

class LumeAlarmsTool extends ConsumerStatefulWidget {
  const LumeAlarmsTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeAlarmsTool(request: request);

  static const String id = 'alarms';

  static const Key summaryKey = ValueKey<String>('alarms.summary');
  static const Key listKey = ValueKey<String>('alarms.list');
  static const Key addKey = ValueKey<String>('alarms.add');

  static Key toggleKey(String alarmId) =>
      ValueKey<String>('alarms.toggle.$alarmId');

  @override
  ConsumerState<LumeAlarmsTool> createState() => _LumeAlarmsToolState();
}

class _LumeAlarmsToolState extends ConsumerState<LumeAlarmsTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();

  /// Which fixture alarms have been flipped from their starting `on`, for as
  /// long as this screen stays mounted. Never written anywhere durable —
  /// see the library note on why that is the honest port of the reference's
  /// own DOM-only class toggle, not a shortfall of this one.
  final Map<String, bool> _flipped = <String, bool>{};

  bool _isOn(LumeAlarm a) => _flipped[a.id] ?? a.on;

  void _toggle(LumeAlarm a) => setState(() => _flipped[a.id] = !_isOn(a));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeColors lume = context.lume;
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    const List<LumeAlarm> alarms = LumeAlarmBoard.alarms;

    // Worked out once, from the fixture's own starting values — the switch
    // below never feeds back into this, matching the reference's own frozen
    // summary card (see the library note).
    final LumeAlarm? next = LumeAlarmBoard.next(alarms);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      floating: LumeFab(
        key: LumeAlarmsTool.addKey,
        label: l.alarmsAdd,
        icon: LumeIcons.plus,
        // The reference's own fixed toast — no reader-added alarm exists to
        // build one for (library note). **Dayroz:** open a new-alarm form
        // and schedule the alarm with the platform's alarm service.
        onPressed: () => _host.currentState?.say(l.alarmsAdding),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeAlarmsTool.summaryKey,
              kicker: l.alarmsNext,
              value: next == null
                  ? '—'
                  : LumeAlarmText.time(f, next.hour, next.minute),
              caption: next == null
                  ? l.alarmsNone
                  : '${LumeAlarmText.label(l, next.label)} · '
                        '${l.alarmsInHours(LumeAlarmBoard.nextInHours)}',
            ),
          ),
          LumeToolSection(
            title: l.alarmsAll,
            child: LumeRows(
              key: LumeAlarmsTool.listKey,
              children: <Widget>[
                for (final LumeAlarm a in alarms)
                  LumeRichRow(
                    key: LumeAlarmsTool.toggleKey(a.id),
                    icon: LumeIcons.alarm,
                    iconTone: _isOn(a) ? lume.tintAccent : null,
                    iconInk: _isOn(a) ? lume.accent : null,
                    title: LumeAlarmText.time(f, a.hour, a.minute),
                    subtitle: LumeAlarmText.label(l, a.label),
                    meta: <String>[LumeAlarmText.repeat(l, a.repeat)],
                    trailing: LumeSwitch(
                      value: _isOn(a),
                      semanticLabel: LumeAlarmText.label(l, a.label),
                      // **Dayroz:** arm or disarm the scheduled alarm,
                      // and keep the choice.
                      onChanged: (_) => _toggle(a),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
