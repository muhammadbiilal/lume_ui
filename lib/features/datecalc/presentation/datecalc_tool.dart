/// Date Calculator — rollout wave 1, on the Tax form-calculator reference.
///
/// `tools/everyday/datecalc.tool.js`: a mode; two dates, or a date and a day
/// count; the result with weeks, months and years; and the span's weekdays,
/// weekend days and the country's public holidays. Worked out by
/// [LumeDateSpan] on the injected clock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/localization/lume_iso_day.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_field_grid.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../calendar/data/calendar_fixtures.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/date_maths.dart';

class LumeDatecalcTool extends ConsumerStatefulWidget {
  const LumeDatecalcTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeDatecalcTool(request: request);

  static const String id = 'datecalc';

  static const Key modeKey = ValueKey<String>('datecalc.mode');
  static const Key fromKey = ValueKey<String>('datecalc.from');
  static const Key toKey = ValueKey<String>('datecalc.to');
  static const Key daysKey = ValueKey<String>('datecalc.days');
  static const Key summaryKey = ValueKey<String>('datecalc.summary');
  static const Key businessKey = ValueKey<String>('datecalc.business');

  @override
  ConsumerState<LumeDatecalcTool> createState() => _LumeDatecalcToolState();
}

class _LumeDatecalcToolState extends ConsumerState<LumeDatecalcTool> {
  static const String _id = LumeDatecalcTool.id;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _days = TextEditingController(
    text: _session.field(_id, 'days', () => '${LumeDateSpan.defaultDays}'),
  );

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  /// `parseISO(f[key]) || new Date()`, the field defaulting to today.
  DateTime _date(String key, DateTime today) =>
      lumeParseIsoDay(_session.field(_id, key, () => lumeIsoDate(today))) ??
      today;

  Future<void> _pick(String key, DateTime today) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date(key, today),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked == null || !mounted) return;
    setState(() => _session.write(_id, key, lumeIsoDate(picked)));
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
    final bool add = _session.read(_id, 'mode') == 'add';

    final DateTime from = _date('from', today);
    // `new Date(y, m, d + 2.5)` then `setHours(0, 0, 0, 0)` — a fraction of a
    // day falls to the day before it.
    final int days = (double.tryParse(_days.text.trim()) ?? 0).floor();
    final DateTime to = add
        ? LumeDateSpan.plus(from, days)
        : _date('to', today);
    final LumeDateSpan span = LumeDateSpan.of(from, to);
    final String arrow = Directionality.of(context) == TextDirection.rtl
        ? '←'
        : '→';

    LumeToolField dateField(Key key, String label, String name) =>
        LumeToolField(
          key: key,
          label: label,
          value: f.dateNumeric(_date(name, today)),
          kind: LumeFieldKind.date,
          onTap: () => _pick(name, today),
        );

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
            child: LumeSegmented(
              key: LumeDatecalcTool.modeKey,
              semanticLabel: l.datecalcMode,
              value: add ? 'add' : 'diff',
              onChanged: (String v) =>
                  setState(() => _session.write(_id, 'mode', v)),
              items: <LumeChoice>[
                LumeChoice(value: 'diff', label: l.datecalcDifference),
                LumeChoice(value: 'add', label: l.datecalcAddDays),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeCard(
              child: LumeFieldGrid(
                children: add
                    ? <Widget>[
                        dateField(
                          LumeDatecalcTool.fromKey,
                          l.datecalcStart,
                          'from',
                        ),
                        LumeToolField(
                          key: LumeDatecalcTool.daysKey,
                          label: l.datecalcDaysToAdd,
                          controller: _days,
                          kind: LumeFieldKind.number,
                          onChanged: (String v) =>
                              setState(() => _session.write(_id, 'days', v)),
                        ),
                      ]
                    : <Widget>[
                        dateField(
                          LumeDatecalcTool.fromKey,
                          l.datecalcFrom,
                          'from',
                        ),
                        dateField(LumeDatecalcTool.toKey, l.datecalcTo, 'to'),
                      ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeDatecalcTool.summaryKey,
              kicker: add ? l.datecalcResult : l.datecalcBetween,
              value: add
                  ? f.dateLongYear(to)
                  : l.datecalcDays(span.days, f.integer(span.days)),
              caption: add
                  ? l.datecalcFromStart(days.abs(), f.integer(days))
                  : '${f.dateMedium(from)} $arrow ${f.dateMedium(to)}',
              stats: <LumeStat>[
                LumeStat(
                  value: f.integer(span.weeks),
                  label: l.datecalcStatWeeks,
                ),
                LumeStat(
                  value: f.fixed(span.months, 1),
                  label: l.datecalcStatMonths,
                ),
                LumeStat(
                  value: f.fixed(span.years, 2),
                  label: l.datecalcStatYears,
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.datecalcBusiness,
            child: LumeRows(
              key: LumeDatecalcTool.businessKey,
              children: <Widget>[
                LumeCompactRow(
                  icon: LumeIcons.calendar,
                  label: l.datecalcWeekdays,
                  value: f.integer(span.weekdays),
                  chevron: false,
                ),
                LumeCompactRow(
                  icon: LumeIcons.sun,
                  label: l.datecalcWeekends,
                  value: f.integer(span.weekends),
                  chevron: false,
                ),
                LumeCompactRow(
                  icon: LumeIcons.star,
                  label: l.datecalcHolidays,
                  value: f.integer(
                    LumeCalendarFixtures.holidayCountFor(r.user.country),
                  ),
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
