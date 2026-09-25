/// Loadshedding — `tools/daily/loadshed.tool.js` over `context.js`
/// `loadshed()`, ported.
///
/// Pakistan-only (`countries: ['PK']`, the catalogue's `loadshed` entry):
/// loadshedding — a rolling, scheduled power outage — is not a concept every
/// market shares, so this stays fixture data for one country rather than a
/// pattern invented for a reader elsewhere. `LumeToolScreen`'s own frame
/// already refuses the body to a reader `LumeEligibility` does not clear
/// (§64): a non-PK reader who somehow reaches this route sees the shared,
/// honest "not available where you are" surface (`LumeToolState`, the
/// frame's own `toolUnavailableTitle`/`toolUnavailableText`) every gated tool
/// already shows, rather than this tool guessing an outage schedule for a
/// country it has none for.
///
/// A summary card (the running outage, or the next one), the day's five-slot
/// timeline, the week's own hours-without-power bar chart, and two rows —
/// outage reminders, and a nudge towards Bills — the same composition
/// `loadshed.tool.js`'s `build()` draws.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_agenda.dart';
import '../../../core/widgets/lume/lume_chart.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../catalogue/presentation/feature_strings.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/loadshed_fixtures.dart';
import 'loadshed_text.dart';

class LumeLoadshedTool extends ConsumerStatefulWidget {
  const LumeLoadshedTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeLoadshedTool(request: request);

  static const String id = 'loadshed';

  static const Key summaryKey = ValueKey<String>('loadshed.summary');
  static const Key scheduleKey = ValueKey<String>('loadshed.schedule');
  static const Key weekKey = ValueKey<String>('loadshed.week');
  static const Key rowsKey = ValueKey<String>('loadshed.rows');

  @override
  ConsumerState<LumeLoadshedTool> createState() => _LumeLoadshedToolState();
}

class _LumeLoadshedToolState extends ConsumerState<LumeLoadshedTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();
    final int nowMinute = now.hour * 60 + now.minute;
    final LumeLoadshedToday ls = LumeLoadshedToday.at(
      nowMinute: nowMinute,
      weekday: now.weekday,
    );
    final int minutes = ls.minutesUntil(nowMinute);

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            // `ls.area` — the reader's own city (`P().city`), not the
            // country: loadshedding schedules are drawn by feeder/area, not
            // nationally.
            child: LumeContextBar(
              items: <LumeContextItem>[
                LumeContextItem(
                  label: r.user.city,
                  icon: LumeIcons.pin,
                  onTap: () => showLumePersonalise(context),
                ),
                LumeContextItem(label: l.loadshedProvider),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeLoadshedTool.summaryKey,
              gradient: ls.isNow
                  ? context.lumeGradients.warn
                  : context.lumeGradients.accent,
              kicker: ls.isNow ? l.loadshedCurrentlyOff : l.loadshedCurrentlyOn,
              value: LumeLoadshedText.hm(l, minutes),
              caption: ls.isNow
                  ? l.loadshedPowerBack(ls.slot.slot.to)
                  : l.loadshedNextOutage(ls.slot.slot.from, ls.slot.slot.to),
              stats: <LumeStat>[
                LumeStat(
                  value: '${f.integer(ls.hoursToday.round())}h',
                  label: l.loadshedToday,
                ),
                LumeStat(
                  value: f.integer(ls.slots.length),
                  label: l.loadshedSlots,
                ),
                LumeStat(
                  value: '${f.integer(ls.reliability)}%',
                  label: l.loadshedReliability,
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.loadshedSchedule,
            child: Column(
              key: LumeLoadshedTool.scheduleKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < ls.slots.length; i++)
                  LumeAgendaRow(
                    key: ValueKey<String>('loadshed.slot.$i'),
                    time: ls.slots[i].slot.from,
                    title: l.loadshedOutage,
                    meta: l.loadshedUntil(ls.slots[i].slot.to),
                    icon: LumeIcons.bolt,
                    tone: switch (ls.slots[i].state) {
                      LumeLoadshedState.done => LumeAgendaTone.done,
                      LumeLoadshedState.now => LumeAgendaTone.now,
                      LumeLoadshedState.next => LumeAgendaTone.upcoming,
                    },
                    isLast: i == ls.slots.length - 1,
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.loadshedWeek,
            child: LumeCard(
              child: LumeBarChart(
                key: LumeLoadshedTool.weekKey,
                label: l.loadshedWeek,
                values: <double>[for (final int h in ls.week) h.toDouble()],
                labels: f.weekdayNarrowFromMonday(),
                highlight: ls.todayIndex,
                caption: Text(
                  l.loadshedWeekCap,
                  style: LumeType.natural(
                    context,
                    context.lumeType.metaSmall,
                  ).copyWith(color: context.lume.text3),
                ),
              ),
            ),
          ),
          LumeToolSection(
            child: LumeRows(
              key: LumeLoadshedTool.rowsKey,
              children: <Widget>[
                LumeCompactRow(
                  icon: LumeIcons.bell,
                  label: l.loadshedNotify,
                  value: l.loadshedNotifyValue,
                  onTap: () => _host.currentState?.say(l.loadshedNotifyOn),
                ),
                LumeCompactRow(
                  icon: LumeIcons.receipt,
                  label: LumeFeatureStrings.name(l, 'bills'),
                  // A hint sentence, not a short value — the subtitle slot
                  // sits under the label with room to wrap/ellipsize; the
                  // trailing `value` slot is sized for a short reading, not
                  // a full phrase (overflowed at 200%/Urdu otherwise).
                  subtitle: l.loadshedBillHint,
                  onTap: () => r.onOpenRelated?.call('bills'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
