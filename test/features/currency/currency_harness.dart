/// Currency, opened directly for a reader ([pumpLume]), not through the real
/// router — the shared `tool_registry.dart` this repository routes through is
/// out of scope for this change; it is wired up in the integration pass that
/// follows, the same approach `markets_tool_test.dart` and
/// `qibla_tool_test.dart` take for their own waves.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/currency/presentation/currency_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature kCurrencyFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeCurrencyTool.id,
);

/// Pump the tool for a reader in [user]'s country, over [session] so a test
/// can seed what a returning reader would have and read back what the screen
/// wrote.
Future<void> pumpCurrency(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(),
  LumeToolSession? session,
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  Size surface = const Size(390, 5000),
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeCurrencyTool(
      request: LumeToolRequest(
        feature: kCurrencyFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    theme: theme,
    textScale: textScale,
    surface: surface,
    overrides: <Override>[
      startupControllerProvider.overrideWithValue(gate),
      toolSessionProvider.overrideWithValue(session ?? LumeToolSession()),
    ],
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

/// Every string drawn under [of], in paint order.
List<String> textsIn(WidgetTester tester, Finder of) => tester
    .widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))
    .map((Text t) => (t.data ?? t.textSpan?.toPlainText() ?? '').trim())
    .where((String s) => s.isNotEmpty)
    .toList();

/// The figure in the answer, as a reader sees it.
String currencyResult(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(LumeCurrencyTool.resultKey)).data!;

/// The code shown on one side of the card.
String currencyCode(WidgetTester tester, Key sideKey) =>
    textsIn(tester, find.byKey(sideKey)).first;

/// Type [amount] into the amount field, replacing what is there.
Future<void> typeAmount(WidgetTester tester, String amount) async {
  await tester.enterText(find.byKey(LumeCurrencyTool.amountKey), amount);
  await tester.pumpAndSettle();
}

/// Open one side's currency sheet and choose [code].
Future<void> pickCurrency(
  WidgetTester tester,
  Key sideKey,
  String code,
) async {
  await tester.tap(find.byKey(sideKey));
  await tester.pumpAndSettle();
  final Finder option = find.byKey(LumeCurrencyTool.optionKey(code));
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}
