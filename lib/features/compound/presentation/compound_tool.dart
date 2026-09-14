/// Compound Interest — rollout wave 1, on the Tax form-calculator reference.
///
/// `tools/money/compound.tool.js`: the starting amount, the monthly addition,
/// the return and the years; the projected value with what went in, the
/// growth and the return; the projection as a line; the value year by year.
/// Worked out by [LumeCompound].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/fixtures/lume_reference_rates.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_field_grid.dart';
import '../../../core/widgets/lume/lume_spark.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_numbers.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/compound_maths.dart';

class LumeCompoundTool extends ConsumerStatefulWidget {
  const LumeCompoundTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeCompoundTool(request: request);

  static const String id = 'compound';

  static const Key initialKey = ValueKey<String>('compound.initial');
  static const Key monthlyKey = ValueKey<String>('compound.monthly');
  static const Key rateKey = ValueKey<String>('compound.rate');
  static const Key yearsKey = ValueKey<String>('compound.years');
  static const Key summaryKey = ValueKey<String>('compound.summary');
  static const Key chartKey = ValueKey<String>('compound.chart');
  static const Key tableKey = ValueKey<String>('compound.table');

  @override
  ConsumerState<LumeCompoundTool> createState() => _LumeCompoundToolState();
}

class _LumeCompoundToolState extends ConsumerState<LumeCompoundTool> {
  static const String _id = LumeCompoundTool.id;

  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{};

  TextEditingController _field(String key, String Function() fallback) =>
      _fields[key] ??= TextEditingController(
        text: _session.field(_id, key, fallback),
      );

  @override
  void dispose() {
    for (final TextEditingController c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _edited(String key, String value) =>
      setState(() => _session.write(_id, key, value));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final String ccy = f.currency;
    final double perUsd = lumeRatePerUsd(ccy);
    final TextEditingController initial = _field(
      'initial',
      () => lumeJsNumber(LumeCompound.openingInitial(perUsd)),
    );
    final TextEditingController monthly = _field(
      'monthly',
      () => lumeJsNumber(LumeCompound.openingMonthly(perUsd)),
    );
    final TextEditingController rate = _field(
      'rate',
      () => lumeJsNumber(LumeCompound.defaultRate),
    );
    final TextEditingController years = _field(
      'years',
      () => lumeJsNumber(LumeCompound.defaultYears),
    );
    final double term = lumeFieldNumber(years.text);
    final LumeCompound c = LumeCompound.of(
      initial: lumeFieldNumber(initial.text),
      monthly: lumeFieldNumber(monthly.text),
      rate: lumeFieldNumber(rate.text),
      years: term,
    );
    String money(double v) => f.money(v, code: ccy);
    final String after = l.compoundAfter(term.round(), f.number(term));
    final DateTime now = LumeClockScope.of(context).now();

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // The reference shares an unrelated quote (C68); this shares the
      // projection and its term.
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.reminder,
        text: '${l.compoundFinalValue}: ${money(c.total)} · $after',
        source: f.dateLongYear(now),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            title: l.toolInputs,
            child: LumeCard(
              child: LumeFieldGrid(
                children: <Widget>[
                  LumeToolField(
                    key: LumeCompoundTool.initialKey,
                    label: l.compoundInitial,
                    controller: initial,
                    prefix: ccy,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('initial', v),
                  ),
                  LumeToolField(
                    key: LumeCompoundTool.monthlyKey,
                    label: l.compoundMonthly,
                    controller: monthly,
                    prefix: ccy,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('monthly', v),
                  ),
                  LumeToolField(
                    key: LumeCompoundTool.rateKey,
                    label: l.compoundRate,
                    controller: rate,
                    suffix: '%',
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('rate', v),
                  ),
                  LumeToolField(
                    key: LumeCompoundTool.yearsKey,
                    label: l.compoundYears,
                    controller: years,
                    suffix: l.unitYearsSuffix,
                    kind: LumeFieldKind.number,
                    onChanged: (String v) => _edited('years', v),
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeCompoundTool.summaryKey,
              gradient: context.lumeGradients.accent,
              kicker: l.compoundFinalValue,
              value: money(c.total),
              caption: after,
              stats: <LumeStat>[
                LumeStat(
                  value: money(c.contributed),
                  label: l.compoundContributed,
                ),
                LumeStat(value: money(c.growth), label: l.compoundGrowth),
                LumeStat(
                  value: '${f.integer(c.returnPercent)}%',
                  label: l.compoundReturn,
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.compoundProjection,
            child: LumeCard(
              child: LumeLineChart(
                key: LumeCompoundTool.chartKey,
                values: c.series,
                label: l.compoundProjection,
                labels: <String>[
                  f.integer(0),
                  l.compoundAxisYears(f.integer((term / 2).round())),
                  l.compoundAxisYears(f.number(term)),
                ],
                summary: '${money(c.series.first)} → ${money(c.series.last)}',
              ),
            ),
          ),
          LumeToolSection(
            title: l.compoundByYear,
            child: LumeTable(
              key: LumeCompoundTool.tableKey,
              label: l.compoundByYear,
              columns: <LumeColumn>[
                LumeColumn(label: l.commonYear),
                LumeColumn(label: l.compoundContributed, numeric: true),
                LumeColumn(label: l.compoundValue, numeric: true),
              ],
              rows: <List<String>>[
                for (final LumeCompoundYear y in c.table)
                  <String>[
                    f.integer(y.year),
                    money(y.contributed),
                    money(y.value),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
