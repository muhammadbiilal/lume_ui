/// Play on the real router.
///
/// `/tools/tool/play` resolves to the tool itself — `tool_registry.dart`
/// names it — so every test here reaches the screen the way a reader does.
/// The screen under test is the real [LumeToolScreen] with the real header,
/// source bar and related tools, and the geometry the parity harness reads is
/// the geometry the app draws.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/play/presentation/play_tool.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// `/tools/tool/play`.
final String kPlayLocation = LumeRoutes.tool(LumeRoutes.tools, LumePlayTool.id);

/// Pump Play for [state].
///
/// The router is returned so a test can ask where the reader ended up — the
/// only record of a tile having opened something, or of Back having been
/// pressed, now that the route supplies both callbacks itself.
Future<GoRouter> pumpPlay(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  bool animate = false,
  List<Override> overrides = const <Override>[],
}) => pumpLumeRouter(
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
