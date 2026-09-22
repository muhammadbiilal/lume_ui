/// Play on the real router where the registry knows it, and on the real tool
/// host where it does not yet.
///
/// `tool_registry.dart` is not this feature's file to edit, so at the time of
/// writing `/tools/tool/play` still resolves to the fixture screen. Rather
/// than test something other than the shipped widget, [pumpPlay] asks the
/// registry which world it is in: once `'play': LumePlayTool.open` lands, the
/// same tests run through the router with no edit here. Either way the screen
/// under test is the real [LumeToolScreen] with the real header, source bar
/// and related tools, and the geometry the parity harness reads is the
/// geometry the app draws.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/play/presentation/play_tool.dart';
import 'package:lume/features/tools/application/tool_registry.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// `/tools/tool/play`.
final String kPlayLocation = LumeRoutes.tool(LumeRoutes.tools, LumePlayTool.id);

/// Whether the route can build Play yet.
bool get playIsRegistered => kLumeToolRegistry.containsKey(LumePlayTool.id);

/// Play's catalogue entry — the same object the route would hand the tool.
final LumeFeature kPlayFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumePlayTool.id,
);

/// What a press of a related tool asked for, if anything did.
final List<String> playOpened = <String>[];

/// Whether Back was pressed.
final List<int> playBacks = <int>[];

/// Pump Play for [state].
Future<void> pumpPlay(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  bool animate = false,
  List<Override> overrides = const <Override>[],
}) async {
  playOpened.clear();
  playBacks.clear();

  if (playIsRegistered) {
    await pumpLumeRouter(
      tester,
      initialLocation: kPlayLocation,
      profile: taxProfile(state),
      surface: surface,
      locale: locale,
      theme: theme,
      textScale: textScale,
      animate: animate,
      overrides: overrides,
    );
    return;
  }

  final LumeProfileRecord record = kTaxStates[state]!;
  await pumpLume(
    tester,
    LumePlayTool(
      request: LumeToolRequest(
        feature: kPlayFeature,
        user: LumeUserContext.from(record),
        branch: LumeRoutes.tools,
        onBack: () => playBacks.add(1),
        onOpenRelated: playOpened.add,
      ),
    ),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
    animate: animate,
    overrides: overrides,
  );
  await tester.pumpAndSettle();
}
