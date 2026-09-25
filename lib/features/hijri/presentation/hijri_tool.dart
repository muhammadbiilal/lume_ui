/// Islamic Calendar — a real Gregorian ⇄ Hijri conversion, computed on the
/// device, never read from a fixture.
///
/// `tools/islamic/hijri.tool.js` over `context.js` `hijri()` and
/// `monthGrid()`: today's Hijri date, this month on the Gregorian grid with
/// its Hijri day underneath, a short list of the calendar's own fixed dates,
/// a convert-a-date form, and the twelve month names. Faith-gated in the
/// catalogue (`faith: true`); nothing here re-decides that, exactly as Qibla
/// and Tasbih leave it to the frame (`tool_screen.dart`'s `eligible`).
///
/// **The calculation.** [LumeHijriDate.of] — already in `core/time/lume_hijri`
/// for Calendar and Today — is the tabular ("Kuwaiti") arithmetic Islamic
/// calendar: a fixed 30-year cycle of 354- and 355-day years, needing no
/// network, no table and no platform. It is reused here rather than
/// reimplemented, so the app has exactly one Hijri conversion rather than two
/// that could drift apart. [LumeHijriEvents] (`domain/hijri_events.dart`)
/// scans forward over the same function to find each of six fixed calendar
/// transitions for the reader's own today, rather than reproducing the
/// reference's five hard-coded rows (`tool-data.js:690-696`), which name one
/// specific year and are wrong for every other one.
///
/// **What this is not, and says so.** `lume_hijri.dart`'s own doc calls this
/// exactly what it is — *"a label, not a religious determination"* — and
/// warns that a release must say which authority a date actually comes from.
/// This tool is that disclosure: the screen's own subtitle and the notice
/// under the summary card both say "calculated" and name the tabular
/// algorithm, rather than reading as the officially adopted Umm al-Qura
/// calendar or a local moon-sighting committee's own ruling — neither of
/// which this build has any data for. The catalogue's
/// `fallbackSource: 'Umm al-Qura calculation'`
/// (`feature_catalogue.dart`) overclaims exactly this, and is out of this
/// change's scope to correct (`tool_capability.dart`, `feature_catalogue.dart`
/// and `source_claims.dart` are all outside `features/hijri`); it is flagged
/// in the rollout notes rather than left unsaid.
///
/// **What differs from the reference.** The "Convert a date" section is a
/// real, interactive Gregorian → Hijri converter — pick any date and its
/// Hijri equivalent is worked out on the spot — where the reference's own
/// fields are prefilled with today's date and never shown to change
/// (`hijri.tool.js:29-33` binds no handler). The reverse direction (typing a
/// Hijri date to read off its Gregorian one) is not offered: the tabular
/// algorithm's inverse is a second function this rollout wave does not add,
/// and the reference does not offer it either.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_iso_day.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/time/lume_hijri.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_field_grid.dart';
import '../../../core/widgets/lume/lume_month_grid.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/hijri_events.dart';
import 'hijri_strings.dart';

class LumeHijriTool extends ConsumerStatefulWidget {
  const LumeHijriTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeHijriTool(request: request);

  static const String id = 'hijri';

  static const Key summaryKey = ValueKey<String>('hijri.summary');
  static const Key noteKey = ValueKey<String>('hijri.note');
  static const Key gridKey = ValueKey<String>('hijri.grid');
  static const Key eventsKey = ValueKey<String>('hijri.events');
  static const Key convertKey = ValueKey<String>('hijri.convert');
  static const Key convertDateKey = ValueKey<String>('hijri.convert.date');
  static const Key convertResultKey = ValueKey<String>('hijri.convert.result');
  static const Key monthsKey = ValueKey<String>('hijri.months');

  @override
  ConsumerState<LumeHijriTool> createState() => _LumeHijriToolState();
}

class _LumeHijriToolState extends ConsumerState<LumeHijriTool> {
  static const String _id = LumeHijriTool.id;

  late final LumeToolSession _session = ref.read(toolSessionProvider);

  /// `f[greg] || isoToday()` — the date the converter shows, defaulting to
  /// today exactly as the reference's own field is prefilled.
  DateTime _convertDate(DateTime today) =>
      lumeParseIsoDay(_session.field(_id, 'greg', () => lumeIsoDate(today))) ??
      today;

  Future<void> _pickConvertDate(DateTime today) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _convertDate(today),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked == null || !mounted) return;
    setState(() => _session.write(_id, 'greg', lumeIsoDate(picked)));
  }

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final LumeHijriDate hijri = LumeHijriDate.of(now);
    final DateTime convertDate = _convertDate(today);

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // The frame's own archetype sub-line would say nothing about how these
      // dates are worked out; this replaces it with the one honest claim this
      // build can make; see the library doc for why that claim matters here.
      subtitle: l.hijriCalculatedSubtitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeHijriTool.summaryKey,
              kicker: l.clockToday,
              value:
                  '${f.integer(hijri.day)} ${LumeHijriStrings.month(l, hijri.month)}',
              unit: l.hijriYearAh(f.integer(hijri.year)),
              caption: f.dateFull(now),
            ),
          ),
          LumeToolSection(
            child: LumeNotice(
              key: LumeHijriTool.noteKey,
              kind: LumeNoticeKind.info,
              title: l.hijriNoteTitle,
              text: l.hijriNoteText,
            ),
          ),
          LumeToolSection(
            child: LumeMonthGrid(
              key: LumeHijriTool.gridKey,
              title: f.monthYear(now),
              subtitle:
                  ' · ${LumeHijriStrings.month(l, hijri.month)} ${f.integer(hijri.year)}',
              heads: f.weekdayNarrowFromMonday(),
              leading:
                  (DateTime(now.year, now.month).weekday - DateTime.monday) % 7,
              days: <LumeMonthDay>[
                for (
                  int d = 1;
                  d <= DateTime(now.year, now.month + 1, 0).day;
                  d++
                )
                  LumeMonthDay(
                    label: '$d',
                    spoken: f.dateFull(DateTime(now.year, now.month, d)),
                    sub:
                        '${LumeHijriDate.of(DateTime(now.year, now.month, d)).day}',
                    today: d == now.day,
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.hijriEventsTitle,
            child: LumeRows(
              key: LumeHijriTool.eventsKey,
              children: <Widget>[
                for (final LumeHijriEvent e in LumeHijriEvents.upcoming(today))
                  LumeRichRow(
                    icon: LumeIcons.moonStar,
                    iconTone: context.lume.tintAccent,
                    title: LumeHijriStrings.eventName(l, e.id),
                    subtitle: _hijriLabel(l, f, e.hijri),
                    meta: <String>[f.dateMedium(e.gregorian)],
                    value: e.daysAway == 0
                        ? l.clockToday
                        : l.commonInDays(f.integer(e.daysAway)),
                    // A day count can run to three digits (up to a lunar
                    // year away) — capped so it ellipsizes rather than
                    // pushing the row wider at 200% text scale.
                    valueMaxWidth: 90,
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.hijriConvertTitle,
            child: LumeCard(
              key: LumeHijriTool.convertKey,
              child: LumeFieldGrid(
                children: <Widget>[
                  LumeToolField(
                    key: LumeHijriTool.convertDateKey,
                    label: l.hijriGregorian,
                    value: f.dateNumeric(convertDate),
                    kind: LumeFieldKind.date,
                    onTap: () => _pickConvertDate(today),
                  ),
                  LumeToolField(
                    key: LumeHijriTool.convertResultKey,
                    label: l.hijriHijriDate,
                    value: _hijriLabel(l, f, LumeHijriDate.of(convertDate)),
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            title: l.hijriMonthsTitle,
            child: LumeRows(
              key: LumeHijriTool.monthsKey,
              flat: true,
              children: <Widget>[
                for (int m = 1; m <= 12; m++)
                  LumeCompactRow(
                    label: LumeHijriStrings.month(l, m),
                    value: f.integer(m),
                    chevron: false,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hijriLabel(AppLocalizations l, LumeFormatting f, LumeHijriDate h) =>
      '${f.integer(h.day)} ${LumeHijriStrings.month(l, h.month)} '
      '${l.hijriYearAh(f.integer(h.year))}';
}
