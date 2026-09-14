/// Tax, through the real router, for a reader in a given market.
///
/// The measurement tool's states, as saved profiles: the same country, city
/// and faith setting the web capture was taken with, so a Flutter cell and a
/// web cell describe the same reader.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';

import '../../helpers/lume_harness.dart';

/// `/tools/tool/tax` — Tax opened from the Tools hub.
final String kTaxLocation = LumeRoutes.tool(LumeRoutes.tools, 'tax');

/// A saved, onboarded profile.
LumeProfileRecord taxReader({
  String country = 'PK',
  String region = 'Islamabad Capital Territory',
  String city = 'Islamabad',
  bool islamic = false,
}) => LumeProfileRecord(
  country: country,
  region: region,
  city: city,
  islamic: islamic,
  interests: LumeOnboardingState.defaultInterests,
  onboarded: true,
);

/// `measure_destinations.mjs`'s states.
final Map<String, LumeProfileRecord> kTaxStates = <String, LumeProfileRecord>{
  'default_pk': taxReader(),
  'muslim_pk': taxReader(islamic: true),
  'default_us': taxReader(country: 'US', region: 'New York', city: 'New York'),
  'muslim_gb': taxReader(
    country: 'GB',
    region: 'England',
    city: 'London',
    islamic: true,
  ),
  'default_ae': taxReader(country: 'AE', region: 'Dubai', city: 'Dubai'),
  'default_jp': taxReader(country: 'JP', region: 'Tokyo', city: 'Tokyo'),
};

/// A repository holding [state]'s profile.
LumeProfileRepository taxProfile(String state) =>
    LumeMemoryProfileRepository(initial: kTaxStates[state]);

/// Pump Tax for [state].
Future<GoRouter> pumpTax(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 844),
  ThemeMode theme = ThemeMode.light,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  String? location,
}) => pumpLumeRouter(
  tester,
  initialLocation: location ?? kTaxLocation,
  profile: taxProfile(state),
  surface: surface,
  theme: theme,
  locale: locale,
  textScale: textScale,
);

/// A committed web measurement, or `null` where the cell was never taken.
Map<String, dynamic>? webCell(String cell) {
  final File f = File('docs/conversion_archive/measurements/$cell.json');
  if (!f.existsSync()) return null;
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}
