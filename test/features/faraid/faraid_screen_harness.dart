/// Faraid, opened directly for a reader ([pumpLume]), not through the real
/// router.
///
/// Faraid's wave lands with `tool_registry.dart` out of scope for this
/// change — it is wired up in the integration pass that follows, the same
/// approach Qibla's own harness took (`qibla_tool_test.dart`) and Zakat's
/// took before its own integration pass landed `'zakat'` in the registry.
/// The screen itself is exercised exactly as the router would host it, with
/// the same provider overrides and the same clock.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/faraid/presentation/faraid_tool.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

final LumeFeature faraidFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeFaraidTool.id,
);

/// Faraid's own screen, over the real shell, for a Muslim reader by default
/// (Faraid is faith-gated — `faith: true` in the catalogue — the same as
/// Zakat and Qibla).
Future<void> pumpFaraid(
  WidgetTester tester, {
  LumeUserContext user = const LumeUserContext(islamic: true),
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 5000),
  double textScale = 1,
}) async {
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: LumeMemoryProfileRepository(),
  );
  await gate.boot();
  addTearDown(gate.dispose);

  await pumpLume(
    tester,
    LumeFaraidTool(
      request: LumeToolRequest(
        feature: faraidFeature,
        user: user,
        branch: 'tools',
      ),
    ),
    locale: locale,
    surface: surface,
    textScale: textScale,
    overrides: <Override>[startupControllerProvider.overrideWithValue(gate)],
  );
  await tester.pumpAndSettle();
}
