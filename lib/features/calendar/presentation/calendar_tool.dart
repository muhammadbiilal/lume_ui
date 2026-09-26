/// Calendar — the reference tool for the planner archetype.
///
/// `tools/planning/calendar.tool.js` over `context.js` `calendar()` and
/// `monthGrid()`: where and when the reader is, the view, this month, today's
/// agenda, and the next public holidays, with an add action floating over it.
///
/// What the reference plans is small, and it is kept as it is (C71): the
/// grid is always this month, the view is stored and nothing reads it, and
/// the agenda is three fixed items. What is corrected: the agenda is in time
/// order, each day's Hijri date is its own, and Add — which in the reference
/// only says "New event" — opens Events' create form, where the reader's
/// events are kept.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../app/providers/time_zone_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/time/lume_hijri.dart';
import '../../../core/time/lume_solar.dart';
import '../../../core/time/lume_iana_zones.dart';
import '../../../core/time/lume_zone.dart';
import '../../../core/time/lume_zone_labels.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_month_grid.dart';
import '../../../core/widgets/lume/lume_progress.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../startup/domain/startup_state.dart';
import '../../records/presentation/record_tool.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/calendar_fixtures.dart';
import 'calendar_strings.dart';

class LumeCalendarTool extends ConsumerStatefulWidget {
  const LumeCalendarTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeCalendarTool(request: request);

  static const String id = 'calendar';

  static const Key viewKey = ValueKey<String>('calendar.view');
  static const Key gridKey = ValueKey<String>('calendar.grid');
  static const Key agendaKey = ValueKey<String>('calendar.agenda');
  static const Key holidaysKey = ValueKey<String>('calendar.holidays');
  static const Key addKey = ValueKey<String>('calendar.add');

  /// The next prayer at [now] for a reader in [country] and [city], in the
  /// reader's [zone] — or `null` where the city or the zone is not known,
  /// which shows no prayer rather than a guessed one.
  static LumeSolarTime? nextPrayer({
    required DateTime now,
    required String country,
    required String city,
    required LumeZone? zone,
  }) {
    final (double, double)? at = LumeSolar.coordsFor(country, city);
    if (at == null || zone == null) return null;
    // The zone's own date and minute: the instant read on its wall clock,
    // not the device's.
    final DateTime local = zone.wallClockAt(now);
    final List<LumeSolarTime> day = LumeSolar.prayerTimes(
      date: local,
      lat: at.$1,
      lon: at.$2,
      offsetHours: zone.offsetAt(now).inMinutes / 60,
    );
    return LumeSolar.nextPrayer(
      day,
      local.hour * 60 + local.minute + local.second / 60,
    );
  }

  @override
  ConsumerState<LumeCalendarTool> createState() => _LumeCalendarToolState();
}

class _LumeCalendarToolState extends ConsumerState<LumeCalendarTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);

  String get _view => _session.read(LumeCalendarTool.id, 'view') ?? 'month';

  void _setView(String v) =>
      setState(() => _session.write(LumeCalendarTool.id, 'view', v));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();
    final LumeStartupState startup = ref.watch(startupControllerProvider).state;
    // `L.timezone()` — the reader's zone as Account › Time resolves it.
    final LumeZoneResolution zone = ref
        .watch(timeZoneServiceProvider)
        .readerZone(
          startup.profile,
          ref.watch(deviceZoneProvider),
          country: r.user.country,
          city: r.user.city,
        );
    final LumeZoneLabel? label = zone.label(
      Localizations.localeOf(context).languageCode,
    );
    final String? zoneLabel = label?.display ?? zone.requested;
    final LumeHijriDate? hijri = r.user.islamic ? LumeHijriDate.of(now) : null;

    // `monthGrid()` — this month, the locale's week (Monday, C65).
    final DateTime first = DateTime(now.year, now.month);
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    // `calendar().agenda`, and a Muslim reader's next prayer, in time order.
    final List<(int, int, LumeTimelineEntry)> agenda =
        <(int, int, LumeTimelineEntry)>[
          for (int i = 0; i < LumeCalendarFixtures.agenda.length; i++)
            (
              LumeCalendarFixtures.agenda[i].minutes,
              i,
              _item(l, f, now, LumeCalendarFixtures.agenda[i]),
            ),
        ];
    if (r.user.islamic) {
      final LumeSolarTime? next = LumeCalendarTool.nextPrayer(
        now: now,
        country: r.user.country,
        city: r.user.city,
        zone: zone.zone,
      );
      if (next != null) {
        agenda.add((
          next.minutes,
          agenda.length,
          LumeTimelineEntry(
            time: f.time(
              DateTime(now.year, now.month, now.day, next.hour, next.minute),
            ),
            title: LumeCalendarStrings.prayer(l, next.key),
            subtitle: l.homeNextPrayer,
            icon: LumeIcons.prayer,
          ),
        ));
      }
    }
    agenda.sort(
      ((int, int, LumeTimelineEntry) a, (int, int, LumeTimelineEntry) b) =>
          a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      exportFile: () => LumeExportFile.record(
        tool: LumeCalendarTool.id,
        day: now,
        exported: now,
        locale:
            '${Localizations.localeOf(context).languageCode}-${r.user.country}',
        currency: startup.countries?.currencyOf(r.user.country) ?? '',
      ),
      floating: LumeFab(
        key: LumeCalendarTool.addKey,
        label: l.calendarAdd,
        icon: LumeIcons.plus,
        // The reference toasts "New event" and adds nothing. An event is the
        // reader's own record, and Events keeps them, so Add opens its
        // create form. (By id, not by import: a tool reaches another only
        // through the route, which gates it.)
        onPressed: r.onOpenRelatedWith == null
            ? null
            : () => r.onOpenRelatedWith!('events', const <String, String>{
                LumeRecordTool.newQuery: '1',
              }),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              items: <LumeContextItem>[
                LumeContextItem(
                  label: LumeToolScreen.countryName(
                    context,
                    ref,
                    r.user.country,
                  ),
                  icon: LumeIcons.globe,
                ),
                // The canonical identifier: a renamed zone the reader chose
                // before the rename is shown by its current name. No zone
                // (one to choose) shows none.
                if (zoneLabel != null)
                  LumeContextItem(
                    label: '\u2068$zoneLabel\u2069',
                    // "Pakistan Time, Asia/Karachi": the identifier is the
                    // zone's identity; a label alone can be shared.
                    semanticsLabel: label?.semantics,
                  ),
                if (hijri != null)
                  LumeContextItem(
                    label:
                        '${hijri.day} ${LumeCalendarStrings.hijriMonth(l, hijri.month)} ${hijri.year}',
                  ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSegmented(
              key: LumeCalendarTool.viewKey,
              semanticLabel: l.calendarView,
              value: _view,
              onChanged: _setView,
              items: <LumeChoice>[
                LumeChoice(value: 'month', label: l.calendarMonth),
                LumeChoice(value: 'week', label: l.calendarWeek),
                LumeChoice(value: 'day', label: l.calendarDay),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeMonthGrid(
              key: LumeCalendarTool.gridKey,
              title: f.monthYear(now),
              subtitle: hijri == null
                  ? null
                  : ' · ${LumeCalendarStrings.hijriMonth(l, hijri.month)} ${hijri.year}',
              heads: f.weekdayNarrowFromMonday(),
              leading: (first.weekday - DateTime.monday) % 7,
              days: <LumeMonthDay>[
                for (int d = 1; d <= daysInMonth; d++)
                  LumeMonthDay(
                    label: '$d',
                    spoken: f.dateFull(DateTime(now.year, now.month, d)),
                    sub: hijri == null
                        ? null
                        : '${LumeHijriDate.of(DateTime(now.year, now.month, d)).day}',
                    today: d == now.day,
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.calendarAgenda,
            child: LumeTimeline(
              key: LumeCalendarTool.agendaKey,
              entries: <LumeTimelineEntry>[
                for (final (int, int, LumeTimelineEntry) a in agenda) a.$3,
              ],
            ),
          ),
          LumeToolSection(
            title: l.calendarHolidays,
            child: LumeRows(
              key: LumeCalendarTool.holidaysKey,
              children: <Widget>[
                for (final LumeHoliday h in LumeCalendarFixtures.holidaysFor(
                  r.user.country,
                ))
                  LumeCompactRow(
                    icon: LumeIcons.star,
                    label: LumeCalendarStrings.holiday(l, h.name),
                    subtitle: LumeCalendarStrings.kind(l, h.kind),
                    value: f.dateMedium(DateTime(now.year, h.month, h.day)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LumeTimelineEntry _item(
    AppLocalizations l,
    LumeFormatting f,
    DateTime now,
    LumeCalendarItem item,
  ) => LumeTimelineEntry(
    time: f.time(
      DateTime(now.year, now.month, now.day, item.hour, item.minute),
    ),
    title: LumeCalendarStrings.itemTitle(l, item.id),
    subtitle: LumeCalendarStrings.itemWhere(l, item.id),
    icon: item.icon,
    state: switch (item.state) {
      LumeAgendaState.done => LumeTimelineState.done,
      LumeAgendaState.now => LumeTimelineState.now,
      LumeAgendaState.upcoming => LumeTimelineState.upcoming,
    },
  );
}
