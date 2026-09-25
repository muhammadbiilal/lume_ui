/// Speed Test, pumped directly.
///
/// `tool_registry.dart` names every converted tool's route, and this one is
/// not in it yet — it is being built alongside other tools in the same
/// working tree, and the registry is merged centrally once the wave lands
/// (the same situation `bmi_harness.dart` documents for itself). So this
/// harness does not go through the router: it builds the [LumeToolRequest]
/// the route would have handed the screen, from the catalogue's own feature
/// record, and pumps [LumeSpeedtestTool] with [pumpLume].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/speedtest/presentation/speedtest_tool.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

/// The catalogue's own entry — not a stand-in, so the screen draws the real
/// name and the real source claim.
final LumeFeature kSpeedtestFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeSpeedtestTool.id,
);

/// Pump the tool for a reader in [country].
Future<void> pumpSpeedtest(
  WidgetTester tester, {
  Size surface = LumeViewport.phone,
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  String country = 'PK',
  String city = 'Islamabad',
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    LumeSpeedtestTool.open(
      LumeToolRequest(
        feature: kSpeedtestFeature,
        user: LumeUserContext(country: country, city: city),
        branch: 'tools',
      ),
    ),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
    overrides: overrides,
  );
  await tester.pumpAndSettle();
}

/// Every string drawn under [of], in paint order.
List<String> textsIn(WidgetTester tester, Finder of) => tester
    .widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))
    .map((Text t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((String s) => s.isNotEmpty)
    .toList();
