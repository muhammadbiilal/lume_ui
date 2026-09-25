/// Markets — the reference's world board: `tools/money/markets.tool.js` over
/// `GLOBAL_INDICES`, `CRYPTO` and `ETFS` in `tool-data.js`. Six national
/// benchmarks, four coins, three funds, each a frozen quote with the
/// sparkline `context.js` draws for it (`assetRow`, the inline `world`
/// section).
///
/// The reference's fuller board is a *much* larger surface than these three
/// sections: a class-nav of stocks/forex/commodities per local exchange
/// (`assetClasses`, `assetsFor`), a per-asset detail screen with its own
/// range chips and a currency converter (`assetDetail`, `marketDetail`), and
/// search/filter/sort chrome over all of it. Every one of those reads a
/// *country's own* listings (`D.EXCHANGES[code].stocks`, `D.forexFor(...)`,
/// `D.COMMODITIES`) rather than a fixed set of named instruments, which is a
/// different job from porting "the world board's own instruments, exactly as
/// authored" — this tool is that world board, kept to the three sections
/// every reader sees regardless of country, and to the reference's frozen
/// figures for them. Nothing here invents a ticker or a live price.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/lume_icons.dart';
import '../../../core/localization/lume_format.dart';
import '../../../core/widgets/lume/lume_badge.dart';
import '../../../core/widgets/lume/lume_header.dart';
import '../../../core/widgets/lume/lume_row.dart';
import '../../../core/widgets/lume/lume_spark.dart';
import '../../../core/widgets/lume/lume_tool.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/personalise_sheet.dart';
import '../../tools/application/tool_request.dart';
import '../../tools/presentation/tool_screen.dart';
import '../data/markets_fixtures.dart';
import '../domain/markets_model.dart';
import 'markets_text.dart';

class LumeMarketsTool extends ConsumerWidget {
  const LumeMarketsTool({super.key, required this.request});

  final LumeToolRequest request;

  static Widget open(LumeToolRequest request) =>
      LumeMarketsTool(request: request);

  static const String id = 'markets';

  static const Key indicesKey = ValueKey<String>('markets.indices');
  static const Key cryptoKey = ValueKey<String>('markets.crypto');
  static const Key etfsKey = ValueKey<String>('markets.etfs');

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = request.user;
    final AppLocalizations l = AppLocalizations.of(context);
    final LumeFormatting f = LumeFormatting.of(
      context,
      countryCode: user.country,
    );

    // The `world` section in `markets.tool.js`: `title: ix.name, sub:
    // ix.full`, a percent-only delta (`text: c.pct(ix.pct)`, no absolute
    // move), and a logo that is the symbol's own first three letters.
    Widget indexRow(LumeWorldIndex ix) => LumeRichRow(
      logo: ix.symbol.length > 3 ? ix.symbol.substring(0, 3) : ix.symbol,
      title: ix.name,
      subtitle: ix.country,
      trailing: LumeSparkline(
        values: ix.sparkline,
        trend: LumeMarketsTool.trendOf(ix.percent),
      ),
      value: f.number(ix.value, decimals: 2),
      delta: LumeDelta(
        text: f.signedPercent(ix.percent),
        direction: LumeMarketsTool.directionOf(ix.percent),
        // A dense row (logo + title/subtitle + sparkline + value + delta) —
        // caps only this row's own delta so it can never be the thing that
        // tips a crowded row over at 200%/RTL (wave 9).
        maxWidth: 90,
      ),
    );

    // `assetRow` in `markets.tool.js`: `title: a.sym, sub: a.name`, both
    // priced in dollars (`ccy: 'USD'` for every entry `assetsFor` shapes from
    // `CRYPTO`/`ETFS`), and a delta of the absolute move and the percent.
    Widget assetRow(LumeQuotedAsset a, {required String venue}) => LumeRichRow(
      logo: a.logo,
      title: a.symbol,
      subtitle: a.name,
      meta: LumeMarketsStrings.meta(l, venue: venue, asset: a),
      trailing: LumeSparkline(
        values: a.sparkline,
        trend: LumeMarketsTool.trendOf(a.percent),
      ),
      value: f.money(a.price, code: 'USD', decimals: 2),
      // A five-figure price at 200 % pushed this row 1.5 px past its card
      // with the title already squeezed to nothing; capped as the delta is.
      valueMaxWidth: 120,
      valueSub: 'USD',
      delta: LumeDelta(
        text:
            '${f.signed(a.change, decimals: 2)}  '
            '${f.signedPercent(a.percent)}',
        direction: LumeMarketsTool.directionOf(a.percent),
        // Combines the absolute move and the percent — long enough to
        // overflow a dense row at 200%/RTL without a cap (wave 9).
        maxWidth: 90,
      ),
    );

    return LumeToolScreen(
      feature: request.feature,
      user: user,
      onBack: request.onBack,
      onOpenRelated: request.onOpenRelated,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LumeToolSection(
            flush: true,
            child: LumeContextBar(
              items: <LumeContextItem>[
                LumeContextItem(
                  label: LumeToolScreen.countryName(context, ref, user.country),
                  icon: LumeIcons.globe,
                  onTap: () => showLumePersonalise(context),
                ),
                LumeContextItem(label: l.marketsGlobal),
              ],
            ),
          ),
          LumeToolSection(
            title: l.marketsGlobal,
            child: LumeRows(
              key: LumeMarketsTool.indicesKey,
              children: <Widget>[
                for (final LumeWorldIndex ix in LumeMarkets.worldIndices)
                  indexRow(ix),
              ],
            ),
          ),
          LumeToolSection(
            title: l.marketsTopCrypto,
            child: LumeRows(
              key: LumeMarketsTool.cryptoKey,
              children: <Widget>[
                for (final LumeQuotedAsset a in LumeMarkets.crypto)
                  assetRow(a, venue: l.marketsGlobal),
              ],
            ),
          ),
          LumeToolSection(
            title: l.marketsTopEtfs,
            child: LumeRows(
              key: LumeMarketsTool.etfsKey,
              children: <Widget>[
                for (final LumeQuotedAsset a in LumeMarkets.etfs)
                  assetRow(a, venue: LumeMarkets.etfVenue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
