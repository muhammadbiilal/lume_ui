/// Tasbih, on the real router, for a Muslim reader.
///
/// The tool is faith-gated (`feature_catalogue.dart:629`, `faith: true`), so
/// every state here has the Islamic experience on — `muslim_pk` and
/// `muslim_gb` are the two the capture was taken in. A default profile does
/// not reach the tool at all, which is its own test.
///
/// **While the registry has no entry for `tasbih`**, the route resolves to the
/// fixture screen, so [pumpTasbih] hosts the tool the way `app_router.dart`
/// `_tool` hosts one — the same eligibility, read from the same profile,
/// refusing in the same place — and switches to the route itself the moment
/// the id is registered. [pumpTasbihRoute] always goes through the router,
/// because what it is testing is the route's own refusal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tasbih/presentation/tasbih_tool.dart';
import 'package:lume/features/tools/application/tool_registry.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// `/tools/tool/tasbih`.
final String kTasbih = LumeRoutes.tool(LumeRoutes.tools, LumeTasbihTool.id);

/// Whether the route can draw the converted tool yet.
bool get tasbihIsRegistered => kLumeToolRegistry.containsKey(LumeTasbihTool.id);

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
  final List<Override> all = <Override>[
    toolSessionProvider.overrideWithValue(store),
    ...overrides,
  ];

  if (tasbihIsRegistered) {
    await pumpLumeRouter(
      tester,
      initialLocation: kTasbih,
      profile: taxProfile(state),
      surface: surface,
      theme: theme,
      locale: locale,
      textScale: textScale,
      animate: animate,
      overrides: all,
    );
    await tester.pumpAndSettle();
    return store;
  }

  final LumeProfileRepository profiles = taxProfile(state);
  final LumeStartupController gate = LumeStartupController(
    authRepository: LumeFakeAuthRepository.withAccount(),
    profileRepository: profiles,
  );
  addTearDown(gate.dispose);
  await gate.boot();

  await pumpLume(
    tester,
    const _TasbihRoute(),
    surface: surface,
    theme: theme,
    locale: locale,
    textScale: textScale,
    animate: animate,
    overrides: <Override>[
      profileRepositoryProvider.overrideWithValue(profiles),
      startupControllerProvider.overrideWithValue(gate),
      ...all,
    ],
  );
  await tester.pumpAndSettle();
  return store;
}

/// Open `/tools/tool/tasbih` through the router itself, whatever the registry
/// holds — for asking what a reader who types the route is given.
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

/// What `app_router.dart` `_tool` does: ask the catalogue, then build.
class _TasbihRoute extends ConsumerWidget {
  const _TasbihRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LumeEligibility eligibility = ref.watch(eligibilityProvider);
    return LumeProfileScope(
      builder: (BuildContext context, LumeUserContext user) {
        final LumeFeature? feature = eligibility.byId(LumeTasbihTool.id);
        if (feature == null || !eligibility.isVisible(feature, user)) {
          return const SizedBox.shrink();
        }
        return LumeTasbihTool(
          request: LumeToolRequest(
            feature: feature,
            user: user,
            branch: LumeRoutes.tools,
            // The route always supplies both, and the frame draws its Back
            // arrow and its related rail from whether it has them — so a
            // harness without them would be measuring a different header.
            onBack: () => Navigator.of(context).maybePop(),
            onOpenRelated: (String _) {},
          ),
        );
      },
    );
  }
}

/// A finder for [matching] inside [key].
Finder inTasbih(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);
