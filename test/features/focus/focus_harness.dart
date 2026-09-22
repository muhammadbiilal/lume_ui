/// Focus on the real router, over a clock the test steps by hand.
///
/// Nothing here waits on a wall clock. [FocusWorld.now] is the whole of the
/// tool's notion of elapsed time: a test moves it, then pumps, and the face
/// repaints from the new reading.
///
/// The tool is reached through `/tools/tool/focus`, which `tool_registry.dart`
/// names — so every test here runs against the screen the router builds,
/// inside the shell that draws around it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/config/lume_build_profile.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/time/lume_boot_clock.dart';
import 'package:lume/features/focus/application/focus_clock.dart';
import 'package:lume/features/focus/presentation/focus_tool.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// `/tools/tool/focus`.
final String kFocus = LumeRoutes.tool(LumeRoutes.tools, LumeFocusTool.id);

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

/// Pump Focus for [state], through the tool route.
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
  await pumpLumeRouter(
    tester,
    initialLocation: kFocus,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
    overrides: <Override>[
      buildProfileProvider.overrideWithValue(profile),
      ...world.overrides,
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
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
