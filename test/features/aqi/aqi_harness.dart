/// Air Quality, pumped directly.
///
/// `tool_registry.dart` names every converted tool's route, and this one is
/// not in it yet — it is being built alongside other tools in the same
/// working tree, and the registry is merged centrally once they land. So this
/// harness does not go through the router: it builds the [LumeToolRequest]
/// the route would have handed the screen, from the catalogue's own feature
/// record, and pumps [LumeAqiTool] with [pumpLume] — the same approach
/// `bmi_harness.dart` takes for the same reason.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/aqi/presentation/aqi_tool.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

/// The catalogue's own entry — not a stand-in, so the screen draws the real
/// name and the real related rail.
final LumeFeature kAqiFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeAqiTool.id,
);

/// Pump the tool for a reader in [country] / [city].
Future<void> pumpAqi(
  WidgetTester tester, {
  Size surface = LumeViewport.phone,
  Locale locale = const Locale('en'),
  double textScale = 1,
  String country = 'PK',
  String city = 'Islamabad',
}) async {
  await pumpLume(
    tester,
    LumeAqiTool.open(
      LumeToolRequest(
        feature: kAqiFeature,
        user: LumeUserContext(country: country, city: city),
        branch: 'tools',
      ),
    ),
    surface: surface,
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}
