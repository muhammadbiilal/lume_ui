/// The words Markets draws that its fixtures do not carry.
library;

import '../../../l10n/app_localizations.dart';
import '../domain/markets_model.dart';

abstract final class LumeMarketsStrings {
  /// `assetRow` in `markets.tool.js`:
  ///
  /// ```js
  /// var meta = [a.exchange];
  /// if (a.vol) meta.push(c.t('markets.vol') + ' ' + a.vol);
  /// if (a.cap) meta.push(c.t('markets.cap') + ' ' + a.cap);
  /// ```
  ///
  /// [venue] is the reference's own `a.exchange` — `t('markets.cryptoVenue')`
  /// for a coin, the literal `'NYSE Arca'` ([LumeMarkets.etfVenue]) for a
  /// fund, never invented here.
  static List<String> meta(
    AppLocalizations l, {
    required String venue,
    required LumeQuotedAsset asset,
  }) => <String>[venue, '${l.marketsVol} ${asset.volume}', '${l.marketsCap} ${asset.cap}'];
}
