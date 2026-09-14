/// Loan / EMI — rollout wave 1, on the Tax form-calculator reference.
///
/// `tools/money/loan.tool.js`: amount, rate and tenure; the monthly payment
/// with total interest, total repaid and the interest's share; principal and
/// interest as a donut; the amortisation table; the payment two points either
/// side of the rate. Export writes the table. Worked out by [LumeLoan].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_clock.dart';
import '../../../core/fixtures/lume_reference_rates.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_export.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_chart.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_field_grid.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../tools/application/tool_numbers.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../domain/loan_maths.dart';

class LumeLoanTool extends ConsumerStatefulWidget {
  const LumeLoanTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) => LumeLoanTool(request: request);

  static const String id = 'loan';

  static const Key principalKey = ValueKey<String>('loan.principal');
  static const Key rateKey = ValueKey<String>('loan.rate');
  static const Key yearsKey = ValueKey<String>('loan.years');
  static const Key summaryKey = ValueKey<String>('loan.summary');
  static const Key splitKey = ValueKey<String>('loan.split');
  static const Key scheduleKey = ValueKey<String>('loan.schedule');
  static const Key compareKey = ValueKey<String>('loan.compare');

  @override
  ConsumerState<LumeLoanTool> createState() => _LumeLoanToolState();
}

class _LumeLoanToolState extends ConsumerState<LumeLoanTool> {
  static const String _id = LumeLoanTool.id;

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
    final LumeColors lume = context.lume;
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final String ccy = f.currency;
    final TextEditingController principal = _field(
      'principal',
      () => lumeJsNumber(LumeLoan.openingPrincipal(lumeRatePerUsd(ccy))),
    );
    final TextEditingController rate = _field(
      'rate',
      () => lumeJsNumber(LumeLoan.defaultRate),
    );
    final TextEditingController years = _field(
      'years',
      () => lumeJsNumber(LumeLoan.defaultYears),
    );
    final LumeLoan loan = LumeLoan.of(
      principal: lumeFieldNumber(principal.text),
      rate: lumeFieldNumber(rate.text),
      years: lumeFieldNumber(years.text),
    );
    String money(double v) => f.money(v, code: ccy);
    final String over = l.loanOver(
      loan.payments.round(),
      f.number(loan.payments),
    );
    final DateTime now = LumeClockScope.of(context).now();

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // The reference shares an unrelated quote (C68); this shares the
      // payment and its term.
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.reminder,
        text: '${l.loanMonthly}: ${money(loan.emi)} · $over',
        source: f.dateLongYear(now),
      ),
      // `exportRows('loan')` — the schedule, figures rounded.
      exportFile: () => LumeExportFile.csv(
        tool: _id,
        day: now,
        rows: <List<Object?>>[
          <Object?>[
            l.commonYear,
            l.loanPrincipalShort,
            l.loanInterest,
            l.loanBalance,
          ],
          for (final LumeLoanYear y in loan.schedule)
            <Object?>[
              y.year,
              y.principal.round(),
              y.interest.round(),
              y.balance.round(),
            ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            title: l.toolInputs,
            child: LumeCard(
              child: LumeFieldGrid(
                wide: const <int>{0},
                children: <Widget>[
                  LumeToolField(
                    key: LumeLoanTool.principalKey,
                    label: l.loanPrincipal,
                    controller: principal,
                    prefix: ccy,
                    kind: LumeFieldKind.money,
                    wide: true,
                    onChanged: (String v) => _edited('principal', v),
                  ),
                  LumeToolField(
                    key: LumeLoanTool.rateKey,
                    label: l.loanRate,
                    controller: rate,
                    suffix: '%',
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('rate', v),
                  ),
                  LumeToolField(
                    key: LumeLoanTool.yearsKey,
                    label: l.loanTenure,
                    controller: years,
                    suffix: l.unitYearsSuffix,
                    kind: LumeFieldKind.money,
                    onChanged: (String v) => _edited('years', v),
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeLoanTool.summaryKey,
              gradient: context.lumeGradients.accent,
              kicker: l.loanMonthly,
              value: money(loan.emi),
              caption: over,
              stats: <LumeStat>[
                LumeStat(
                  value: money(loan.totalInterest),
                  label: l.loanTotalInterest,
                ),
                LumeStat(value: money(loan.totalPaid), label: l.loanTotalPaid),
                LumeStat(
                  value: '${f.integer(loan.interestShare * 100)}%',
                  label: l.loanInterestShare,
                ),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeCard(
              child: LumeDonut(
                key: LumeLoanTool.splitKey,
                label: l.loanSplit,
                centre: money(loan.totalPaid),
                centreSub: l.loanTotalPaid,
                slices: <LumeDonutSlice>[
                  LumeDonutSlice(
                    label: l.loanPrincipalShort,
                    value: loan.principal,
                    color: lume.accent,
                  ),
                  LumeDonutSlice(
                    label: l.loanInterest,
                    value: loan.totalInterest,
                    color: lume.violet,
                  ),
                ],
              ),
            ),
          ),
          LumeToolSection(
            title: l.loanAmortisation,
            child: LumeTable(
              key: LumeLoanTool.scheduleKey,
              label: l.loanAmortisation,
              columns: <LumeColumn>[
                LumeColumn(label: l.commonYear),
                LumeColumn(label: l.loanPrincipalShort, numeric: true),
                LumeColumn(label: l.loanInterest, numeric: true),
                LumeColumn(label: l.loanBalance, numeric: true),
              ],
              rows: <List<String>>[
                for (final LumeLoanYear y in loan.schedule)
                  <String>[
                    f.integer(y.year),
                    money(y.principal),
                    money(y.interest),
                    money(y.balance),
                  ],
              ],
            ),
          ),
          LumeToolSection(
            title: l.loanCompare,
            child: LumeRows(
              key: LumeLoanTool.compareKey,
              children: <Widget>[
                for (final (double delta, String sub) in <(double, String)>[
                  (-2, l.loanLowerRate),
                  (0, l.loanYourRate),
                  (2, l.loanHigherRate),
                ])
                  LumeCompactRow(
                    icon: LumeIcons.bank,
                    label: l.loanRateAt(f.fixed(loan.rate + delta, 1)),
                    subtitle: sub,
                    value: money(loan.at(delta)),
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
