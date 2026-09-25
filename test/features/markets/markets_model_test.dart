/// Markets' fixtures against the reference's own frozen figures
/// (`GLOBAL_INDICES`, `CRYPTO`, `ETFS` in `tool-data.js`), and the
/// determinism of the sparkline each one draws with.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/fixtures/lume_reference_walk.dart';
import 'package:lume/features/markets/data/markets_fixtures.dart';
import 'package:lume/features/markets/domain/markets_model.dart';

void main() {
  group('GLOBAL_INDICES, ported unchanged', () {
    test("is the reference's six benchmarks, in its own order", () {
      expect(
        LumeMarkets.worldIndices.map((LumeWorldIndex i) => i.symbol).toList(),
        <String>['SPX', 'UKX', 'N225', 'DAX', 'HSI', 'TASI'],
      );
    });

    test("carries the reference's frozen figures", () {
      final LumeWorldIndex spx = LumeMarkets.worldIndices[0];
      expect(spx.name, 'S&P 500');
      expect(spx.country, 'United States');
      expect(spx.value, 5812.44);
      expect(spx.change, 24.18);
      expect(spx.percent, 0.42);
      expect(spx.isUp, isTrue);

      final LumeWorldIndex n225 = LumeMarkets.worldIndices[2];
      expect(n225.name, 'Nikkei 225');
      expect(n225.country, 'Japan');
      expect(n225.percent, lessThan(0));
      expect(n225.isUp, isFalse);

      final LumeWorldIndex tasi = LumeMarkets.worldIndices[5];
      expect(tasi.name, 'TASI');
      expect(tasi.country, 'Saudi Arabia');
      expect(tasi.value, 11844.20);
    });

    test('each sparkline is 20 points, deterministic under its own seed', () {
      for (final LumeWorldIndex ix in LumeMarkets.worldIndices) {
        expect(ix.sparkline, hasLength(20));
        // Same seed (the index's fixed value and position) — same series.
        expect(ix.sparkline, ix.sparkline);
      }
    });

    test('the seed matches D.walk(ix.value + i, ...), rounded to an int', () {
      final LumeWorldIndex spx = LumeMarkets.worldIndices[0];
      expect(
        spx.sparkline,
        lumeWalk((spx.value + spx.index + 0.5).floor(), 20, spx.value, 0.005),
      );
    });

    test('two indices do not share a seed — each sparkline is its own', () {
      final List<double> spx = LumeMarkets.worldIndices[0].sparkline;
      final List<double> ukx = LumeMarkets.worldIndices[1].sparkline;
      expect(spx, isNot(equals(ukx)));
    });
  });

  group('CRYPTO, ported unchanged', () {
    test("is the reference's four coins", () {
      expect(
        LumeMarkets.crypto.map((LumeQuotedAsset a) => a.symbol).toList(),
        <String>['BTC', 'ETH', 'SOL', 'XRP'],
      );
    });

    test("carries the reference's frozen figures", () {
      final LumeQuotedAsset btc = LumeMarkets.crypto[0];
      expect(btc.name, 'Bitcoin');
      expect(btc.logo, '₿');
      expect(btc.price, 96420.00);
      expect(btc.change, 1840.00);
      expect(btc.percent, 1.95);
      expect(btc.volume, '38.1B');
      expect(btc.cap, '1.90T');
      expect(btc.isUp, isTrue);

      final LumeQuotedAsset eth = LumeMarkets.crypto[1];
      expect(eth.name, 'Ethereum');
      expect(eth.percent, lessThan(0));
      expect(eth.isUp, isFalse);

      final LumeQuotedAsset xrp = LumeMarkets.crypto[3];
      expect(xrp.name, 'XRP');
      expect(xrp.price, 2.31);
    });

    test('the sparkline is 20 points, deterministic, and matches seriesFor', () {
      for (final LumeQuotedAsset a in LumeMarkets.crypto) {
        expect(a.sparkline, hasLength(20));
        expect(a.sparkline, a.sparkline);
      }
      final LumeQuotedAsset btc = LumeMarkets.crypto[0];
      final int seed = (btc.price * 1000 + 0.5).floor() + 1533;
      expect(
        btc.sparkline,
        lumeWalk(seed, 44, btc.price, 0.004).take(20).toList(),
      );
    });
  });

  group('ETFS, ported unchanged', () {
    test("is the reference's three funds", () {
      expect(
        LumeMarkets.etfs.map((LumeQuotedAsset a) => a.symbol).toList(),
        <String>['VOO', 'QQQ', 'GLD'],
      );
    });

    test("carries the reference's frozen figures", () {
      final LumeQuotedAsset voo = LumeMarkets.etfs[0];
      expect(voo.name, 'Vanguard S&P 500 ETF');
      expect(voo.price, 534.20);
      expect(voo.volume, '4.1M');
      expect(voo.cap, '520B');

      final LumeQuotedAsset gld = LumeMarkets.etfs[2];
      expect(gld.name, 'SPDR Gold Shares');
      expect(gld.price, 244.10);
    });

    test("NYSE Arca is the reference's own literal, not translated", () {
      expect(LumeMarkets.etfVenue, 'NYSE Arca');
    });
  });
}
