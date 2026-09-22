/// Tasbih, on the real router, for a Muslim reader.
///
/// The tool is faith-gated (`feature_catalogue.dart:629`, `faith: true`), so
/// every state here has the Islamic experience on — `muslim_pk` and
/// `muslim_gb` are the two the capture was taken in. A default profile does
/// not reach the tool at all, which is its own test.
///
/// `tool_registry.dart` names `tasbih`, so [pumpTasbih] opens the route and
/// the tool is built by `app_router.dart` `_tool` itself — the same
/// eligibility, read from the same profile, refusing in the same place.
/// [pumpTasbihRoute] is the same route pumped for its own sake, when what is
/// being asked about is the refusal rather than the screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/tasbih/presentation/tasbih_tool.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// `/tools/tool/tasbih`.
final String kTasbih = LumeRoutes.tool(LumeRoutes.tools, LumeTasbihTool.id);

/// Pump the tool for a reader in [state].
///
/// [session] is the in-memory store the count lives in. Pass one to seed a
/// count, or to pump twice over the same store and see what survives.
Future<LumeToolSession> pumpTasbih(
  WidgetTester tester, {
  String state = 'muslim_pk',
  Size surface = LumeViewport.tall,
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1,
  bool animate = false,
  LumeToolSession? session,
  List<Override> overrides = const <Override>[],
}) async {
  final LumeToolSession store = session ?? LumeToolSession();

  await pumpLumeRouter(
    tester,
    initialLocation: kTasbih,
    profile: taxProfile(state),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
    animate: animate,
    overrides: <Override>[
      toolSessionProvider.overrideWithValue(store),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
  return store;
}

/// Open `/tools/tool/tasbih` through the router — for asking what a reader
/// who types the route is given.
Future<GoRouter> pumpTasbihRoute(
  WidgetTester tester, {
  String state = 'muslim_pk',
  Size surface = LumeViewport.tall,
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: kTasbih,
    profile: taxProfile(state),
    surface: surface,
  );
  await tester.pumpAndSettle();
  return router;
}

/// A finder for [matching] inside [key].
Finder inTasbih(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);
