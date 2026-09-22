/// World Clock on the real router, over a profile the test chooses, a zone
/// service the test can detach, and a clock the test can step.
///
/// The tool is opened through `/tools/tool/worldclock` as a reader would open
/// it: `tool_registry.dart` names it, so the route builds the tool itself,
/// inside the shell, over the profile and the clock the test hands the router.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/time_zone_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/time/lume_iana_zones.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/tools/application/tool_session.dart';
import 'package:lume/features/worldclock/presentation/worldclock_tool.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// `/tools/tool/worldclock`.
final String kWorldClockLocation = LumeRoutes.tool(
  LumeRoutes.tools,
  LumeWorldClockTool.id,
);

/// A clock a test moves by hand. Nothing here reads the wall clock.
class SteppingClock extends LumeClock {
  SteppingClock(this.instant);

  DateTime instant;

  @override
  DateTime now() => instant;

  void advance(Duration by) => instant = instant.add(by);
}

/// A profile with the zone preferences Account › Time writes.
LumeProfileRecord worldClockReader({
  String country = 'PK',
  String region = 'Islamabad Capital Territory',
  String city = 'Islamabad',
  String? timeZone,
  LumeZoneFollow follow = LumeZoneFollow.region,
  String clock = LumePreference.auto,
}) => taxReader(
  country: country,
  region: region,
  city: city,
).copyWith(timeZone: timeZone, zoneFollow: follow, clock: clock);

/// The tool, in the full environment, at [now].
///
/// [session] is handed in so a test can seed the list the reader would have
/// built up, or read back what the tool wrote — which is the only thing it
/// ever writes anywhere.
Future<GoRouter> pumpWorldClock(
  WidgetTester tester, {
  LumeProfileRecord? profile,
  LumeToolSession? session,
  LumeTimeZoneService? service,
  LumeDeviceZone device = const LumeDeviceZone.unknown(),
  LumeClock? clock,
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  List<Override> extra = const <Override>[],
}) async {
  // A pending minute tick would outlive the test; the tree is taken down
  // first so `dispose` cancels it.
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));

  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: kWorldClockLocation,
    profile: LumeMemoryProfileRepository(
      initial: profile ?? worldClockReader(),
    ),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    overrides: <Override>[
      toolSessionProvider.overrideWithValue(session ?? LumeToolSession()),
      if (service != null) timeZoneServiceProvider.overrideWithValue(service),
      deviceZoneProvider.overrideWithValue(device),
      ...extra,
    ],
    // The test's own instant: a clock tool that read the wall clock would be
    // untestable.
    clock: clock,
  );
  await tester.pumpAndSettle();
  return router;
}

/// Everything drawn under [of], trimmed, with the isolation marks the screen
/// puts around figures removed — a test asserts what a reader sees.
List<String> clockTexts(WidgetTester tester, Finder of) => tester
    .widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))
    .map((Text t) => plain(t.data ?? t.textSpan?.toPlainText() ?? ''))
    .where((String s) => s.isNotEmpty)
    .toList();

/// A string as it reads, without the bidi isolates or the narrow spaces.
String plain(String s) => s
    .replaceAll(RegExp('[\u2066-\u2069\u200e\u200f]'), '')
    .replaceAll('\u00a0', ' ')
    .replaceAll('\u202f', ' ')
    .trim();

/// The semantics label of one clock row.
String rowSemantics(WidgetTester tester, String zone) => plain(
  tester
      .widget<Semantics>(find.byKey(LumeWorldClockTool.rowKey(zone)).first)
      .properties
      .label!,
);

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);
