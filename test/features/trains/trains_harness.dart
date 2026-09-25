/// The Trains tool, pumped directly.
///
/// `tool_registry.dart` names every converted tool's route, and `trains` is
/// not in it yet: this tool is built alongside others in the same working
/// tree, and the registry is merged centrally once they land (the same
/// approach `bmi_harness.dart`, `holidays_tool_test.dart` and others take).
/// So this harness does not go through the router: it builds the
/// [LumeToolRequest] the route would have handed the screen, from the
/// catalogue's own feature record, and pumps [LumeTrainsTool] with
/// [pumpLume]. Once the registry carries `trains`, a test that wants the
/// router besides can add it without anything here changing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/trains/presentation/trains_tool.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/lume_harness.dart';

/// The catalogue's own entry — not a stand-in, so the screen draws the real
/// name, the real source claim and the real related rail.
final LumeFeature kTrainsFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeTrainsTool.id,
);

/// Pump the tool for a reader in [country]/[city].
Future<void> pumpTrains(
  WidgetTester tester, {
  LumeToolSession? session,
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  String country = 'PK',
  String city = 'Islamabad',
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    LumeTrainsTool.open(
      LumeToolRequest(
        feature: kTrainsFeature,
        user: LumeUserContext(country: country, city: city),
        branch: 'tools',
      ),
    ),
    surface: surface,
    locale: locale,
    textScale: textScale,
    overrides: <Override>[
      toolSessionProvider.overrideWithValue(session ?? LumeToolSession()),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Finder labelled(String label) => find.byWidgetPredicate(
  (Widget w) => w is Semantics && w.properties.label == label,
);
