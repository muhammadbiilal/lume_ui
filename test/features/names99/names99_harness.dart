/// 99 Names, opened directly for a reader ([pumpLume]), not through the real
/// router.
///
/// Names99's wave lands in parallel with other tools, and the shared
/// `tool_registry.dart` this repository routes through is out of scope for
/// this change — it is wired up in the integration pass that follows (the
/// same approach Qibla's own harness takes, `qibla_tool_test.dart`). The
/// screen itself is exercised exactly as the router would host it, with the
/// same provider overrides and the same clock, and the shared tool frame
/// enforces the faith gate on its own (`tool_screen.dart`'s
/// `eligibility.isVisible`) whether or not a route ever pointed here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/names99/presentation/names99_tool.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature names99Feature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeNames99Tool.id,
);

Future<LumeToolSession> pumpNames99(
  WidgetTester tester, {
  // Faith-gated (`feature_catalogue.dart`, `faith: true`): every state here
  // that expects to see the gallery needs a Muslim context.
  LumeUserContext user = const LumeUserContext(islamic: true),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 5000),
  double textScale = 1,
  LumeToolSession? session,
  List<Override> overrides = const <Override>[],
}) async {
  final LumeToolSession store = session ?? LumeToolSession();
  await pumpLume(
    tester,
    LumeNames99Tool(
      request: LumeToolRequest(
        feature: names99Feature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    overrides: <Override>[
      toolSessionProvider.overrideWithValue(store),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
  return store;
}
