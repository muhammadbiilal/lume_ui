/// Zakat, through the real router — `tool_registry.dart` now carries
/// `'zakat'`, so this pumps it exactly the way `mealplan_screen_harness.dart`
/// and `reminders_screen_harness.dart` do, rather than the hand-built
/// `Navigator.push` this file used before the integration pass landed the
/// registry entry.
///
/// **Zakat is faith-gated** (`faith: true` in the catalogue) — the real
/// router hides it from a non-Muslim profile, which the old direct-push
/// harness never exercised (it bypassed the gate entirely, silently). Every
/// state here is Muslim by default; a test wanting a specific country still
/// gets one, by building its own profile with [zakatReader] rather than
/// reaching for `tax_harness.dart`'s `kTaxStates`, none of which pairs a
/// non-Pakistan/non-GB country with `islamic: true`.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';

import '../../helpers/lume_harness.dart';

/// A saved, onboarded, Muslim profile — every zakat test needs one to reach
/// a faith-gated tool through the real router at all.
LumeProfileRecord zakatReader({
  String country = 'PK',
  String region = 'Islamabad Capital Territory',
  String city = 'Islamabad',
}) => LumeProfileRecord(
  country: country,
  region: region,
  city: city,
  islamic: true,
  interests: LumeOnboardingState.defaultInterests,
  onboarded: true,
);

/// Zakat's own screen, over the real shell, for a Muslim reader in
/// [country]/[city] (Pakistan/Islamabad unless told otherwise).
Future<GoRouter> pumpZakatTool(
  WidgetTester tester, {
  String country = 'PK',
  String region = 'Islamabad Capital Territory',
  String city = 'Islamabad',
  LumeProfileRepository? profile,
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: LumeRoutes.tool(LumeRoutes.tools, 'zakat'),
    profile:
        profile ??
        LumeMemoryProfileRepository(
          initial: zakatReader(country: country, region: region, city: city),
        ),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
  );
  await tester.pumpAndSettle();
  return router;
}
