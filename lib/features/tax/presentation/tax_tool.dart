/// Tax Calculator — the reference tool for the form-calculator archetype.
///
/// `tools/money/tax.tool.js`, composed from the shared pieces in the order the
/// module writes them. Three compositions, as the module has three:
///
/// * **taxable** — context strip, period, inputs, the result, the bands, the
///   split, and the two actions;
/// * **no income tax** (UAE, Saudi Arabia) — the take-home figure, one input,
///   what does apply, and a note on what the rates mean;
/// * **unsupported** — a market with no schedule. Tax is gated to the six
///   markets that have one, so the route never reaches this; it is kept
///   because the module defines it and a direct build must not crash.
///
/// Figures recompute as the reader types. The reference redraws 280 ms after a
/// keystroke; the result it draws is the same.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_reference_rates.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/theme/lume/lume_colors.dart';
import '../../../core/theme/lume/lume_space.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/theme/lume/lume_type.dart';
import '../../../core/widgets/lume/lume_button.dart';
import '../../../core/widgets/lume/lume_chart.dart';
import '../../../core/widgets/lume/lume_chip.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_state.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/application/tool_session.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/tax_fixtures.dart';
import '../domain/tax_rules.dart';

/// The tool.
class LumeTaxTool extends ConsumerStatefulWidget {
  const LumeTaxTool({super.key, required this.request});

  final LumeToolRequest request;

  /// The registry's builder.
  static Widget build(LumeToolRequest request) => LumeTaxTool(request: request);

  static const String id = 'tax';

  static const Key periodKey = ValueKey<String>('tax.period');
  static const Key incomeKey = ValueKey<String>('tax.income');
  static const Key deductionsKey = ValueKey<String>('tax.deductions');
  static const Key resultKey = ValueKey<String>('tax.result');
  static const Key bandsKey = ValueKey<String>('tax.bands');
  static const Key splitKey = ValueKey<String>('tax.split');
  static const Key leviesKey = ValueKey<String>('tax.levies');

  /// A number the way `String(n)` writes it: no trailing `.0` on a whole
  /// number, every digit of one that is not.
  static String jsNumber(double v) =>
      v == v.truncateToDouble() && v.abs() < 1e15
      ? v.toInt().toString()
      : v.toString();

  /// `Number(text)` — an empty field is zero.
  static double parse(String text) => double.tryParse(text.trim()) ?? 0;

  @override
  ConsumerState<LumeTaxTool> createState() => _LumeTaxToolState();
}

class _LumeTaxToolState extends ConsumerState<LumeTaxTool> {
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _income;
  late final TextEditingController _deductions;

  LumeTaxConfig? get _config => lumeTaxConfigFor(widget.request.user.country);

  @override
  void initState() {
    super.initState();
    final LumeTaxConfig? cfg = _config;
    final double rate = lumeRatePerUsd(cfg?.currency ?? 'USD');
    // `fieldsFor('tax', { income, deductions })` for a taxable market; the
    // untaxed composition reads `field('income') || 3000 * rate` instead, so
    // its default is not remembered until the reader types.
    _income = TextEditingController(
      text: cfg == null || !cfg.taxable
          ? (_session.read(LumeTaxTool.id, 'income') ??
                LumeTaxTool.jsNumber(LumeTaxRules.openingGross(rate)))
          : _session.field(
              LumeTaxTool.id,
              'income',
              () => LumeTaxTool.jsNumber(LumeTaxRules.openingIncome(rate)),
            ),
    );
    _deductions = TextEditingController(
      text: _session.field(LumeTaxTool.id, 'deductions', () => '0'),
    );
  }

  @override
  void dispose() {
    _income.dispose();
    _deductions.dispose();
    super.dispose();
  }

  LumeTaxPeriod get _period => _session.read(LumeTaxTool.id, 'period') == 'year'
      ? LumeTaxPeriod.year
      : LumeTaxPeriod.month;

  void _setPeriod(String value) =>
      setState(() => _session.write(LumeTaxTool.id, 'period', value));

  void _edited(String key, String value) =>
      setState(() => _session.write(LumeTaxTool.id, key, value));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final String country = LumeToolScreen.countryName(
      context,
      ref,
      r.user.country,
    );
    final LumeTaxConfig? cfg = _config;

    final List<Widget> sections = cfg == null
        ? _unsupported(context, l, country)
        : cfg.taxable
        ? _taxable(context, l, f, cfg, country)
        : _untaxed(context, l, f, cfg, country);

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections,
      ),
    );
  }

  String _authority(AppLocalizations l, LumeTaxAuthority a) => switch (a) {
    LumeTaxAuthority.fbrSalaried => l.taxAuthorityFbrSalaried,
    LumeTaxAuthority.hmrcEngland => l.taxAuthorityHmrcEngland,
    LumeTaxAuthority.irsSingleFiler => l.taxAuthorityIrsSingleFiler,
    LumeTaxAuthority.indiaNewRegime => l.taxAuthorityIndiaNewRegime,
    LumeTaxAuthority.noPersonalIncomeTax => l.taxAuthorityNone,
  };

  static String levyName(AppLocalizations l, LumeLevy levy) => switch (levy) {
    LumeLevy.vat => l.levyVat,
    LumeLevy.pension => l.levyPension,
    LumeLevy.corporate => l.levyCorporate,
    LumeLevy.gosi => l.levyGosi,
    LumeLevy.zakatRate => l.levyZakatRate,
    LumeLevy.ni => l.levyNi,
    LumeLevy.socialSecurity => l.levySocialSecurity,
    LumeLevy.medicare => l.levyMedicare,
    LumeLevy.gst => l.levyGst,
    LumeLevy.eobi => l.levyEobi,
    LumeLevy.pf => l.levyPf,
  };

  /// `contextBar([country → personalise, authority, year])`.
  Widget _context(AppLocalizations l, LumeTaxConfig cfg, String country) =>
      LumeToolSection(
        flush: true,
        child: LumeContextBar(
          items: <LumeContextItem>[
            LumeContextItem(
              label: country,
              icon: LumeIcons.globe,
              onTap: () => showLumePersonalise(context),
            ),
            LumeContextItem(label: _authority(l, cfg.authority)),
            LumeContextItem(label: cfg.year),
          ],
        ),
      );

  List<Widget> _taxable(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTaxConfig cfg,
    String country,
  ) {
    final LumeColors lume = context.lume;
    final LumeTaxPeriod period = _period;
    final LumeTaxResult t = LumeTaxRules.compute(
      cfg,
      period: period,
      income: LumeTaxTool.parse(_income.text),
      deductions: LumeTaxTool.parse(_deductions.text),
    );
    String money(double v) => f.money(v, code: cfg.currency);
    final bool monthly = period == LumeTaxPeriod.month;

    return <Widget>[
      _context(l, cfg, country),
      LumeToolSection(
        child: LumeSegmented(
          key: LumeTaxTool.periodKey,
          semanticLabel: l.taxPeriod,
          value: monthly ? 'month' : 'year',
          onChanged: _setPeriod,
          items: <LumeChoice>[
            LumeChoice(value: 'month', label: l.taxMonthly),
            LumeChoice(value: 'year', label: l.taxAnnual),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LumeToolField(
                key: LumeTaxTool.incomeKey,
                label: monthly ? l.taxIncomeMonthly : l.taxIncomeAnnual,
                controller: _income,
                prefix: cfg.currency,
                kind: LumeFieldKind.number,
                wide: true,
                onChanged: (String v) => _edited('income', v),
              ),
              const SizedBox(height: LumeSpace.x3),
              // `.fgrid` — two columns; Deductions takes the first of them.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: LumeToolField(
                      key: LumeTaxTool.deductionsKey,
                      label: l.taxDeductions,
                      controller: _deductions,
                      prefix: cfg.currency,
                      kind: LumeFieldKind.number,
                      onChanged: (String v) => _edited('deductions', v),
                    ),
                  ),
                  const SizedBox(width: LumeSpace.x3),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ],
          ),
        ),
      ),
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeTaxTool.resultKey,
          gradient: context.lumeGradients.accent,
          kicker: monthly ? l.taxDueMonthly : l.taxDueAnnual,
          value: money(t.dueDisplay),
          caption: l.taxEffective(
            '${f.number(t.effective * 100, decimals: 1)}%',
          ),
          stats: <LumeStat>[
            LumeStat(value: money(t.netDisplay), label: l.taxTakeHome),
            LumeStat(value: money(t.taxableAnnual), label: l.taxTaxable),
            LumeStat(
              value: '${f.number(t.marginal * 100, decimals: 0)}%',
              label: l.taxMarginal,
            ),
          ],
        ),
      ),
      LumeToolSection(
        title: l.taxSlabs,
        child: LumeTable(
          key: LumeTaxTool.bandsKey,
          label: l.taxSlabs,
          columns: <LumeColumn>[
            LumeColumn(label: l.taxBand),
            LumeColumn(label: l.taxRate, numeric: true),
            LumeColumn(label: l.taxTaxedHere, numeric: true),
          ],
          rows: <List<String>>[
            for (final LumeTaxBandResult b in t.bands)
              <String>[
                b.isTop
                    ? l.taxAbove(money(b.lower))
                    : '${money(b.lower)} – ${money(b.upper)}',
                '${f.number(b.rate * 100, decimals: 0)}%',
                money(b.tax),
              ],
          ],
        ),
      ),
      LumeToolSection(
        child: LumeCard(
          child: LumeDonut(
            key: LumeTaxTool.splitKey,
            label: l.taxSplit,
            centre: money(t.netDisplay),
            centreSub: l.taxTakeHome,
            slices: <LumeDonutSlice>[
              LumeDonutSlice(
                label: l.taxTakeHome,
                value: t.netAnnual,
                color: lume.accent,
              ),
              LumeDonutSlice(
                label: l.taxTax,
                value: t.dueAnnual,
                color: lume.amber,
              ),
            ],
          ),
        ),
      ),
      LumeToolSection(child: _actions(l)),
    ];
  }

  /// Export first and filled, Share beside it. Inert until F6A-D7 is decided —
  /// see [LumeToolActions].
  Widget _actions(AppLocalizations l) => LumeButtonRow(
    children: <Widget>[
      LumeButton.accent(
        label: l.commonExport,
        icon: LumeIcons.download,
        onPressed: () {},
      ),
      LumeButton(label: l.commonShare, icon: LumeIcons.share, onPressed: () {}),
    ],
  );

  List<Widget> _untaxed(
    BuildContext context,
    AppLocalizations l,
    LumeFormatting f,
    LumeTaxConfig cfg,
    String country,
  ) {
    final LumeColors lume = context.lume;
    final List<LumeLevyRate> levies = lumeLeviesFor(
      widget.request.user.country,
    );
    final double gross = _income.text.trim().isEmpty
        ? LumeTaxRules.openingGross(lumeRatePerUsd(cfg.currency))
        : LumeTaxTool.parse(_income.text);
    String rate(double v) => '${f.number(v, decimals: 2)}%';

    return <Widget>[
      _context(l, cfg, country),
      LumeToolSection(
        child: LumeSummaryCard(
          key: LumeTaxTool.resultKey,
          gradient: context.lumeGradients.accent,
          kicker: l.taxTakeHome,
          value: f.money(gross, code: cfg.currency),
          caption: l.taxNoneCaption,
          stats: <LumeStat>[
            // `c.pct(0, 0)` — no sign for zero, no decimals.
            LumeStat(
              value: '${f.number(0, decimals: 0)}%',
              label: l.taxIncomeTax,
            ),
            LumeStat(
              value: rate(levies.first.rate),
              label: levyName(l, levies.first.levy),
            ),
            LumeStat(value: cfg.year, label: l.taxYear),
          ],
        ),
      ),
      LumeToolSection(
        child: LumeCard(
          child: LumeToolField(
            key: LumeTaxTool.incomeKey,
            label: l.taxIncomeMonthly,
            controller: _income,
            prefix: cfg.currency,
            kind: LumeFieldKind.number,
            wide: true,
            onChanged: (String v) => _edited('income', v),
          ),
        ),
      ),
      LumeToolSection(
        child: LumeNoteCard(
          tone: LumeNoteTone.success,
          icon: LumeIcons.info,
          title: l.taxNoneTitle,
          text: l.taxNoneText(_authority(l, cfg.authority)),
        ),
      ),
      LumeToolSection(
        title: l.taxOtherLevies,
        child: LumeTable(
          key: LumeTaxTool.leviesKey,
          label: l.taxOtherLevies,
          columns: <LumeColumn>[
            LumeColumn(label: l.taxLevy),
            LumeColumn(label: l.taxRate, numeric: true),
          ],
          rows: <List<String>>[
            for (final LumeLevyRate v in levies)
              <String>[levyName(l, v.levy), rate(v.rate)],
          ],
        ),
      ),
      LumeToolSection(
        title: l.taxLeviesNote,
        // `UI.card(…, { tone: 'quiet' })` — `card-2`, no shadow.
        child: LumeCard(
          tone: lume.card2,
          shadow: false,
          child: Text(
            l.taxLeviesNoteText,
            style: LumeType.fit(
              context,
              context.lumeType.body,
            ).copyWith(fontSize: 13, height: 1.55, color: lume.text2),
          ),
        ),
      ),
    ];
  }

  List<Widget> _unsupported(
    BuildContext context,
    AppLocalizations l,
    String country,
  ) => <Widget>[
    LumeToolSection(
      child: LumeCollectionState(
        kind: LumeCollectionStateKind.empty,
        icon: LumeIcons.percent,
        title: l.taxUnsupportedTitle(country),
        text: l.taxUnsupportedText,
        primaryAction: LumeButton.accent(
          label: l.toolChangeCountry,
          icon: LumeIcons.globe,
          onPressed: () => showLumePersonalise(context),
        ),
      ),
    ),
  ];
}
