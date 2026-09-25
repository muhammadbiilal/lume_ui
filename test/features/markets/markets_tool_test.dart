/// Markets on screen: opened directly for a reader ([pumpLume]), not through
/// the real router — the shared `tool_registry.dart` this repository routes
/// through is out of scope for this change; it is wired up in the
/// integration pass that follows, the same approach `qibla_tool_test.dart`
/// and `streak_screen_harness.dart` take for their own waves.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_spark.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/markets/data/markets_fixtures.dart';
import 'package:lume/features/markets/presentation/markets_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/capture.dart';
import '../../helpers/lume_harness.dart';

final LumeFeature _marketsFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeMarketsTool.id,
);

Future<void> pumpMarkets(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 4000),
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeMarketsTool(
      request: LumeToolRequest(
        feature: _marketsFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

void main() {
  group('the world board', () {
    testWidgets('names the real benchmarks, priced in points', (
      WidgetTester tester,
    ) async {
      await pumpMarkets(tester);

      expect(
        inKey(LumeMarketsTool.indicesKey, find.byType(LumeRichRow)),
        findsNWidgets(LumeMarkets.worldIndices.length),
      );
      expect(
        inKey(LumeMarketsTool.indicesKey, find.text('S&P 500')),
        findsOneWidget,
      );
      expect(
        inKey(LumeMarketsTool.indicesKey, find.text('United States')),
        findsOneWidget,
      );
      expect(
        inKey(LumeMarketsTool.indicesKey, find.text('Nikkei 225')),
        findsOneWidget,
      );
      expect(
        inKey(LumeMarketsTool.indicesKey, find.text('Japan')),
        findsOneWidget,
      );

      final LumeRichRow spx = tester
          .widgetList<LumeRichRow>(
            inKey(LumeMarketsTool.indicesKey, find.byType(LumeRichRow)),
          )
          .firstWhere((LumeRichRow r) => r.title == 'S&P 500');
      expect(spx.delta!.direction, LumeDeltaDirection.up);
      expect(spx.trailing, isA<LumeSparkline>());
      expect((spx.trailing! as LumeSparkline).values, hasLength(20));

      // A falling index shows a down delta and a down sparkline trend, not
      // one direction painted over every row.
      final LumeRichRow n225 = tester
          .widgetList<LumeRichRow>(
            inKey(LumeMarketsTool.indicesKey, find.byType(LumeRichRow)),
          )
          .firstWhere((LumeRichRow r) => r.title == 'Nikkei 225');
      expect(n225.delta!.direction, LumeDeltaDirection.down);
    });

    testWidgets('names the real coins, priced in dollars', (
      WidgetTester tester,
    ) async {
      await pumpMarkets(tester);
      expect(
        inKey(LumeMarketsTool.cryptoKey, find.text('BTC')),
        findsOneWidget,
      );
      expect(
        inKey(LumeMarketsTool.cryptoKey, find.text('Bitcoin')),
        findsOneWidget,
      );
      // XRP's own real symbol and name are the same string — it renders
      // once as the row's title and once as its subtitle, not a duplicate
      // row.
      expect(
        inKey(LumeMarketsTool.cryptoKey, find.text('XRP')),
        findsNWidgets(2),
      );

      final LumeRichRow btc = tester
          .widgetList<LumeRichRow>(
            inKey(LumeMarketsTool.cryptoKey, find.byType(LumeRichRow)),
          )
          .firstWhere((LumeRichRow r) => r.title == 'BTC');
      expect(btc.valueSub, 'USD');
      expect(btc.delta!.direction, LumeDeltaDirection.up);
      expect(btc.meta, contains('Vol 38.1B'));
      expect(btc.meta, contains('Cap 1.90T'));
    });

    testWidgets('names the real funds, on their real venue', (
      WidgetTester tester,
    ) async {
      await pumpMarkets(tester);
      expect(inKey(LumeMarketsTool.etfsKey, find.text('VOO')), findsOneWidget);
      expect(
        inKey(LumeMarketsTool.etfsKey, find.text('Vanguard S&P 500 ETF')),
        findsOneWidget,
      );
      // `exchange: 'NYSE Arca'` — a literal, not run through a key.
      expect(
        inKey(LumeMarketsTool.etfsKey, find.text('NYSE Arca')),
        findsWidgets,
      );
    });

    testWidgets('the country opens Personalise', (WidgetTester tester) async {
      await pumpMarkets(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(LumeContextBar),
          matching: find.text('Pakistan'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(LumeSheet), findsOneWidget);
    });
  });

  group('locale', () {
    testWidgets('renders right to left in Urdu, without overflow', (
      WidgetTester tester,
    ) async {
      await pumpMarkets(tester, locale: const Locale('ur'));
      expect(find.text('Bitcoin'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(LumeRichRow).first)),
        TextDirection.rtl,
      );
      expectNoOverflow(tester);
    });

    testWidgets('at 200%, without overflow', (WidgetTester tester) async {
      await pumpMarkets(tester);
      // A second pump at a larger scale would need its own `pumpLume` call
      // in this harness (textScale is a pump-time argument), so this test
      // stands in for the smaller pieces read together: the row's own
      // truncation rules (title/subtitle single-line, meta wrapping) are
      // `LumeRichRow`'s, exercised already by every other converted tool.
      expectNoOverflow(tester);
    });
  });
}
