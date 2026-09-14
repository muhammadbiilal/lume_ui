/// Currency & Gold — the reference tool for the data-explorer archetype.
///
/// `tools/money/goldrates.tool.js` over `context.js` `metals()`: where the
/// reader is and which market, gold's price per tola with its change and the
/// figures under it, the metals table, a search over the currencies, each
/// currency's rate with its trend, gold over 30 days, and what an amount of
/// gold is worth. The query and the weight live in the tool session.
///
/// Kept as the reference has it (C72): one market, figures that are fixture
/// data, and an ounce priced in dollars whatever the reader's currency.
/// Corrected: the converter converts — the reference writes the worth of ten
/// grams once and never again, whatever weight is typed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/shell_provider.dart';
import '../../../core/fixtures/lume_clock.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/layout/lume_breakpoint.dart';
import '../../../core/layout/lume_measure.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_field.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_spark.dart';
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
import '../data/goldrates_fixtures.dart';
import 'goldrates_strings.dart';

class LumeGoldratesTool extends ConsumerStatefulWidget {
  const LumeGoldratesTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeGoldratesTool(request: request);

  static const String id = 'goldrates';

  static const Key summaryKey = ValueKey<String>('goldrates.summary');
  static const Key metalsKey = ValueKey<String>('goldrates.metals');
  static const Key searchKey = ValueKey<String>('goldrates.search');
  static const Key listKey = ValueKey<String>('goldrates.currencies');
  static const Key emptyKey = ValueKey<String>('goldrates.empty');
  static const Key chartKey = ValueKey<String>('goldrates.chart');
  static const Key weightKey = ValueKey<String>('goldrates.weight');
  static const Key worthKey = ValueKey<String>('goldrates.worth');

  /// `g_weight`'s value when the reader has typed nothing.
  static const String defaultWeight = '10';

  /// `dirOf(n)`.
  static LumeDeltaDirection directionOf(num n) => n > 0
      ? LumeDeltaDirection.up
      : n < 0
      ? LumeDeltaDirection.down
      : LumeDeltaDirection.flat;

  static LumeTrend trendOf(num n) => switch (directionOf(n)) {
    LumeDeltaDirection.up => LumeTrend.up,
    LumeDeltaDirection.down => LumeTrend.down,
    LumeDeltaDirection.flat => LumeTrend.flat,
  };

  /// What a query leaves, in the reference's order.
  ///
  /// `(p.code + ' ' + p.name).toLowerCase().indexOf(query)`, matched in the
  /// reader's language and in English (§47).
  static List<LumeFxPair> filter(
    List<LumeFxPair> pairs, {
    required String query,
    required List<AppLocalizations> languages,
  }) {
    final String q = query.trim().toLowerCase();
    return <LumeFxPair>[
      for (final LumeFxPair p in pairs)
        if (q.isEmpty ||
            languages.any(
              (AppLocalizations l) =>
                  '${p.code} ${LumeGoldratesStrings.currency(l, p.code)}'
                      .toLowerCase()
                      .contains(q),
            ))
          p,
    ];
  }

  /// The worth of [weight] grams of 24-carat gold, or `null` when the weight
  /// is not a number of grams — nothing is priced from a guess.
  static double? worth(LumeMetals metals, String weight) {
    final double? grams = double.tryParse(weight.trim().replaceAll(',', '.'));
    if (grams == null || grams < 0 || !grams.isFinite) return null;
    return metals.goldPerGram * grams;
  }

  @override
  ConsumerState<LumeGoldratesTool> createState() => _LumeGoldratesToolState();
}

class _LumeGoldratesToolState extends ConsumerState<LumeGoldratesTool> {
  final GlobalKey<LumeToolScreenState> _host = GlobalKey<LumeToolScreenState>();
  late final LumeToolSession _session = ref.read(toolSessionProvider);
  late final TextEditingController _query = TextEditingController(
    text: _session.read(LumeGoldratesTool.id, 'q') ?? '',
  );
  late final TextEditingController _weight = TextEditingController(
    text:
        _session.read(LumeGoldratesTool.id, 'weight') ??
        LumeGoldratesTool.defaultWeight,
  );
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _query.dispose();
    _weight.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _search(String q) =>
      setState(() => _session.write(LumeGoldratesTool.id, 'q', q));

  void _setWeight(String w) =>
      setState(() => _session.write(LumeGoldratesTool.id, 'weight', w));

  @override
  Widget build(BuildContext context) {
    final LumeToolRequest r = widget.request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final DateTime now = LumeClockScope.of(context).now();
    final double gutter = LumeLayout.pageGutter(context.measureClass);
    // `L.currencyCode()` — the country's currency.
    final String ccy =
        ref
            .watch(startupControllerProvider)
            .state
            .countries
            ?.currencyOf(r.user.country) ??
        f.currency;
    final LumeMetals m = LumeMetals.forCurrency(ccy);
    String money(double v) => f.money(v, code: ccy);

    final List<LumeFxPair> pairs = LumeGoldratesTool.filter(
      m.pairs,
      query: _query.text,
      languages: <AppLocalizations>{
        l,
        lookupAppLocalizations(const Locale('en')),
      }.toList(),
    );
    final double? worth = LumeGoldratesTool.worth(m, _weight.text);
    final List<double> history = m.history;

    final LumeDeltaDirection goldDir = LumeGoldratesTool.directionOf(
      LumeMetals.goldPct,
    );
    final LumeDeltaDirection silverDir = LumeGoldratesTool.directionOf(
      LumeMetals.silverPct,
    );
    final List<(String, double, double, double, LumeDeltaDirection)> metals =
        <(String, double, double, double, LumeDeltaDirection)>[
          (
            l.ratesGold24,
            m.goldPerGram,
            m.goldPerTola,
            LumeMetals.goldPct,
            goldDir,
          ),
          (
            l.ratesGold22,
            m.goldPerGram * LumeMetals.purity22,
            m.goldPerTola * LumeMetals.purity22,
            LumeMetals.goldPct,
            goldDir,
          ),
          (
            l.ratesSilver,
            m.silverPerGram,
            m.silverPerTola,
            LumeMetals.silverPct,
            silverDir,
          ),
        ];

    return LumeToolScreen(
      key: _host,
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      actions: LumeToolActions(onSearch: _searchFocus.requestFocus),
      // The reference shares an unrelated quote (C68); this is the price the
      // screen leads with, and where and when it was quoted.
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.quote,
        text: l.ratesShareText(
          l.ratesGold24,
          money(m.goldPerTola),
          l.ratesPerUnit(l.unitTola),
        ),
        source: '${l.ratesOpenMarket} · ${f.dateLong(now)}',
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
                  onTap: () => showLumePersonalise(context),
                ),
                LumeContextItem(label: l.ratesOpenMarket),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: LumeGoldratesTool.summaryKey,
              gradient: context.lumeGradients.gold,
              kicker: l.ratesGold24,
              value: money(m.goldPerTola),
              unit: l.ratesPerUnit(l.unitTola),
              captionDelta: LumeDelta(
                text:
                    '${f.signed(m.goldChange, decimals: 0)}  '
                    '${f.signedPercent(LumeMetals.goldPct)}',
                direction: goldDir,
              ),
              stats: <LumeStat>[
                LumeStat(value: money(m.goldPerGram), label: l.unitGram),
                LumeStat(
                  value: f.money(LumeMetals.goldPerOunceUsd, code: 'USD'),
                  label: l.unitOunce,
                ),
                LumeStat(
                  value: money(m.silverPerTola),
                  label: l.ratesSilverTola,
                ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.ratesMetals,
            child: LumeTable(
              key: LumeGoldratesTool.metalsKey,
              label: l.ratesMetals,
              columns: <LumeColumn>[
                LumeColumn(label: l.ratesMetal),
                LumeColumn(label: l.unitGram, numeric: true),
                LumeColumn(label: l.unitTola, numeric: true),
                LumeColumn(label: l.commonChange, numeric: true),
              ],
              rows: <List<String>>[
                for (final (
                      String name,
                      double gram,
                      double tola,
                      double pct,
                      LumeDeltaDirection dir,
                    )
                    in metals)
                  <String>[
                    name,
                    money(gram),
                    money(tola),
                    '${LumeDelta.glyphFor(dir)}${f.signedPercent(pct)}',
                  ],
              ],
              cellWidth: (BuildContext context, int row, int column) =>
                  column == 3
                  ? LumeDelta.widthOf(
                      context,
                      f.signedPercent(metals[row].$4),
                      metals[row].$5,
                    )
                  : null,
              cell: (int row, int column) => column == 3
                  ? LumeDelta(
                      text: f.signedPercent(metals[row].$4),
                      direction: metals[row].$5,
                    )
                  : null,
            ),
          ),
          // The same second gutter as Recipes' and News' fields (C69).
          LumeToolSection(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: LumeSearchField(
                key: LumeGoldratesTool.searchKey,
                controller: _query,
                focusNode: _searchFocus,
                placeholder: l.ratesSearch,
                onChanged: _search,
              ),
            ),
          ),
          LumeToolSection(
            title: l.ratesCurrencies,
            child: pairs.isEmpty
                ? LumeToolState(
                    key: LumeGoldratesTool.emptyKey,
                    icon: LumeIcons.currency,
                    title: l.ratesNoMatch,
                    text: l.ratesNoMatchText,
                  )
                : LumeRows(
                    key: LumeGoldratesTool.listKey,
                    children: <Widget>[
                      for (final LumeFxPair p in pairs)
                        LumeRichRow(
                          logo: p.flag,
                          title: p.code,
                          subtitle: LumeGoldratesStrings.currency(l, p.code),
                          meta: <String>[
                            l.ratesBuyValue(f.number(p.buy, decimals: 2)),
                            l.ratesSellValue(f.number(p.sell, decimals: 2)),
                          ],
                          trailing: LumeSparkline(
                            values: p.spark,
                            trend: LumeGoldratesTool.trendOf(p.pct),
                          ),
                          value: f.number(p.sell, decimals: 2),
                          delta: LumeDelta(
                            text: f.signedPercent(p.pct),
                            direction: LumeGoldratesTool.directionOf(p.pct),
                          ),
                        ),
                    ],
                  ),
          ),
          LumeToolSection(
            title: l.ratesHistory,
            child: LumeCard(
              child: LumeLineChart(
                key: LumeGoldratesTool.chartKey,
                values: history,
                label: l.ratesGoldHistory,
                labels: <String>[
                  l.ratesDaysAgo(30),
                  l.ratesDaysAgo(15),
                  l.commonToday,
                ],
                caption: l.ratesGoldHistoryCap,
                summary: l.ratesHistoryRange(
                  money(history.first),
                  money(history.last),
                ),
              ),
            ),
          ),
          LumeToolSection(
            title: l.ratesConverter,
            child: LumeCard(
              // `.fgrid` — two columns, 12 apart.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: LumeToolField(
                      key: LumeGoldratesTool.weightKey,
                      label: l.ratesWeight,
                      controller: _weight,
                      suffix: l.unitGram,
                      kind: LumeFieldKind.money,
                      onChanged: _setWeight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LumeToolField(
                      key: LumeGoldratesTool.worthKey,
                      label: l.ratesWorth,
                      value: worth == null ? '—' : money(worth),
                      enabled: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
