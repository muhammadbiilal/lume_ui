/// Fuel Prices — the reference tool for a global, per-market data explorer.
///
/// `tools/money/fuel.tool.js` over `D.fuelFor(c.profile.country)`: the
/// reader's own market's leading grade in a summary card, every grade in a
/// table with its previous price and its change, and a trend chart over the
/// leading grade. [LumeFuel] carries the fixture; [LumeFuelStrings] carries
/// the words it does not.
///
/// **One addition, not a correction.** `fuel.tool.js` itself never draws
/// `f.source`/`f.sourceKey` — only the effective-date line reaches the
/// screen. The task that ported this tool asked explicitly for "the
/// source/effective-date flavor text where the reference has it", so the
/// context bar carries a third chip for it here: the regulator or retail
/// label next to the country and the date, exactly the way Zakat's screen
/// already adds a country chip GoldRates alone used to carry. Nothing about
/// the reference's own figures changes — only what is shown of data the
/// fixture already had.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fixtures/lume_reference_walk.dart';
import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/platform/lume_share.dart';
import '../../../core/theme/lume/lume_theme.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_spark.dart';
import '../../../core/widgets/lume/lume_summary.dart';
import '../../../core/widgets/lume/lume_surface.dart';
import '../../../core/widgets/lume/lume_table.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/fuel_fixtures.dart';
import 'fuel_text.dart';

class LumeFuelTool extends ConsumerWidget {
  const LumeFuelTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) => LumeFuelTool(request: request);

  static const String id = 'fuel';

  static const Key summaryKey = ValueKey<String>('fuel.summary');
  static const Key gradesKey = ValueKey<String>('fuel.grades');
  static const Key chartKey = ValueKey<String>('fuel.chart');

  /// `dirOf(n)`.
  static LumeDeltaDirection directionOf(num n) => n > 0
      ? LumeDeltaDirection.up
      : n < 0
      ? LumeDeltaDirection.down
      : LumeDeltaDirection.flat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LumeToolRequest r = request;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: r.user.country,
    );
    final LumeFuelMarket market = LumeFuel.forCountry(r.user.country);
    String money(double v) => f.money(v, code: market.currency, decimals: 2);

    final LumeFuelItem main = market.main;
    final LumeDeltaDirection mainDir = directionOf(main.change);
    final String sourceLabel = LumeFuelStrings.source(l, market);
    final String effectiveLabel = LumeFuelStrings.effective(l, market);
    final String unitLabel = LumeFuelStrings.unit(l, market.unit);

    return LumeToolScreen(
      feature: r.feature,
      user: r.user,
      onBack: r.onBack,
      onOpenRelated: r.onOpenRelated,
      // `fuel.tool.js` shares nothing of its own; the price the summary
      // leads with is the honest artifact, exactly as GoldRates' own card
      // stands in for its own unrelated reference share text (C68).
      shareCard: () => LumeShareCard.forFeature(
        sensitive: r.feature.sensitive,
        kind: LumeShareKind.quote,
        text: l.ratesShareText(
          LumeFuelStrings.grade(l, main.grade),
          money(main.price),
          unitLabel,
        ),
        source: '$sourceLabel · $effectiveLabel',
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
                LumeContextItem(label: sourceLabel),
                LumeContextItem(label: l.fuelEffective(effectiveLabel)),
              ],
            ),
          ),
          LumeToolSection(
            child: LumeSummaryCard(
              key: summaryKey,
              gradient: context.lumeGradients.accent,
              kicker: '${LumeFuelStrings.grade(l, main.grade)} · ${main.code}',
              value: money(main.price),
              unit: l.ratesPerUnit(unitLabel),
              captionDelta: LumeDelta(
                text: '${f.signed(main.change)} ${l.fuelSinceLast}',
                direction: mainDir,
              ),
              stats: <LumeStat>[
                for (final LumeFuelItem item in market.items.skip(1).take(3))
                  LumeStat(
                    value: money(item.price),
                    label: LumeFuelStrings.grade(l, item.grade),
                  ),
              ],
            ),
          ),
          LumeToolSection(
            title: l.fuelAllGrades,
            child: LumeTable(
              key: gradesKey,
              label: l.fuelAllGrades,
              columns: <LumeColumn>[
                LumeColumn(label: l.fuelGrade),
                LumeColumn(label: l.fuelPrevious, numeric: true),
                LumeColumn(label: l.fuelCurrent, numeric: true),
                LumeColumn(label: l.commonChange, numeric: true),
              ],
              rows: <List<String>>[
                for (final LumeFuelItem item in market.items)
                  <String>[
                    '${LumeFuelStrings.grade(l, item.grade)} (${item.code})',
                    money(item.previous),
                    money(item.price),
                    '${LumeDelta.glyphFor(directionOf(item.change))}'
                        '${f.signed(item.change)}',
                  ],
              ],
              cellWidth: (BuildContext context, int row, int column) =>
                  column == 3
                  ? LumeDelta.widthOf(
                      context,
                      f.signed(market.items[row].change),
                      directionOf(market.items[row].change),
                    )
                  : null,
              cell: (int row, int column) => column == 3
                  ? LumeDelta(
                      text: f.signed(market.items[row].change),
                      direction: directionOf(market.items[row].change),
                    )
                  : null,
            ),
          ),
          LumeToolSection(
            title: l.fuelTrend,
            child: LumeCard(
              child: LumeLineChart(
                key: chartKey,
                // `D.walk(731, 24, main.v, 0.01)`.
                values: lumeWalk(731, 24, main.price, 0.01),
                label: l.fuelTrend,
                labels: const <String>['6m', '3m'],
                caption: l.fuelTrendCap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
