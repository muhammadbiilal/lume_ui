/// Focus on the real router, over a clock the test steps by hand.
///
/// Nothing here waits on a wall clock. [FocusWorld.now] is the whole of the
/// tool's notion of elapsed time: a test moves it, then pumps, and the face
/// repaints from the new reading.
///
/// The route serves the tool only once `tool_registry.dart` names it —
/// [kFocusRouted]. Until then the same screen is hosted directly, inside the
/// same environment, so every test but the bounds comparison runs either way.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/time/lume_boot_clock.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/focus/application/focus_clock.dart';
import 'package:lume/features/focus/presentation/focus_tool.dart';
import 'package:lume/features/tools/application/tool_registry.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// `/tools/tool/focus`.
final String kFocus = LumeRoutes.tool(LumeRoutes.tools, LumeFocusTool.id);

/// Whether the tool route builds Focus. `tool_registry.dart` owns the entry
/// and is not this feature's to edit.
final bool kFocusRouted = kLumeToolRegistry.containsKey(LumeFocusTool.id);

/// Why a cell that needs the shell around the tool cannot be compared yet.
const String kFocusUnrouted =
    'the rail and sidebar come from the shell, which only the tool route is '
    'inside: tool_registry.dart has no focus entry yet';

/// `focus` as the catalogue holds it.
final LumeFeature kFocusFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeFocusTool.id,
);

/// The elapsed-time source the tool reads, under the test's hand.
class FocusWorld {
  /// Any instant; the tool only ever reads differences.
  Duration now = const Duration(hours: 5);

  LumeElapsed get elapsed =>
      () => now;

  void advance(Duration d) => now += d;

  /// Move [total] in [steps] equal pieces, so a test can show that many small
  /// readings add up to exactly one large one.
  void advanceInSteps(Duration total, int steps) {
    for (int i = 0; i < steps; i++) {
      now += Duration(microseconds: total.inMicroseconds ~/ steps);
    }
  }

  List<Override> get overrides => <Override>[
    focusClockProvider.overrideWithValue(elapsed),
  ];
}

/// Pump Focus for [state], on the router where it is routed and directly
/// where it is not.
Future<void> pumpFocus(
  WidgetTester tester,
  FocusWorld world, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  LumeBuildProfile profile = LumeBuildProfile.parity,
  List<Override> overrides = const <Override>[],
}) async {
  final List<Override> all = <Override>[
    buildProfileProvider.overrideWithValue(profile),
    ...world.overrides,
    ...overrides,
  ];
  if (kFocusRouted) {
    await pumpLumeRouter(
      tester,
      initialLocation: kFocus,
      profile: taxProfile(state),
      surface: surface,
      locale: locale,
      theme: theme,
      textScale: textScale,
      overrides: all,
    );
    await tester.pumpAndSettle();
    return;
  }
  await pumpLume(
    tester,
    _FocusHost(state: state),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
    overrides: all,
  );
  await tester.pumpAndSettle();
}

/// The tool as the route would build it: the catalogue's feature, the
/// state's reader, and the Tools branch under it.
class _FocusHost extends StatelessWidget {
  const _FocusHost({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) => LumeFocusTool(
    request: LumeToolRequest(
      feature: kFocusFeature,
      user: LumeUserContext.from(kTaxStates[state]!),
      branch: LumeRoutes.tools,
    ),
  );
}

/// The time on the face.
String focusTime(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(LumeFocusTool.timeKey),
        matching: find.byType(Text),
      ),
    )
    .data!;

/// Every string rendered under [of].
List<String> focusTexts(WidgetTester tester, Finder of) => <String>[
  for (final Text t in tester.widgetList<Text>(
    find.descendant(of: of, matching: find.byType(Text)),
  ))
    if (t.data != null) t.data!,
];
