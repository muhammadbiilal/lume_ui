/// WhatsApp Status Saver, pumped directly.
///
/// `tool_registry.dart` names every converted tool's route, and this one is
/// not in it yet — it is being built alongside other tools in the same
/// working tree, and the registry is merged centrally once they land. So this
/// harness does not go through the router: it builds the [LumeToolRequest]
/// the route would have handed the screen, from the catalogue's own feature
/// record, and pumps [LumeWastatusTool] with [pumpLume] — the same approach
/// `aqi_harness.dart` takes for the same reason.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/wastatus/presentation/wastatus_tool.dart';

import '../../helpers/lume_harness.dart';

/// The catalogue's own entry — not a stand-in, so the screen draws the real
/// name and can build the real related rail.
final LumeFeature kWastatusFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeWastatusTool.id,
);

/// Pump the tool for a reader in [country] / [city].
Future<void> pumpWastatus(
  WidgetTester tester, {
  Size surface = LumeViewport.phone,
  Locale locale = const Locale('en'),
  double textScale = 1,
  String country = 'PK',
  String city = 'Islamabad',
  VoidCallback? onBack,
  ValueChanged<String>? onOpenRelated,
}) async {
  await pumpLume(
    tester,
    LumeWastatusTool.open(
      LumeToolRequest(
        feature: kWastatusFeature,
        user: LumeUserContext(country: country, city: city),
        branch: 'tools',
        onBack: onBack,
        onOpenRelated: onOpenRelated,
      ),
    ),
    surface: surface,
    locale: locale,
    textScale: textScale,
  );
  await tester.pumpAndSettle();
}
