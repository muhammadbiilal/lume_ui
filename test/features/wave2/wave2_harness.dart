/// Rollout wave 2's shared test harness: a tool opened for a reader, with a
/// record store the test holds.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// A store on the fixture day that reads at once.
LumeMemoryRecordRepository wave2Store() => LumeMemoryRecordRepository(
  seeds: lumeRecordSeeds,
  now: () => kFixtureInstant,
  hydrateDelay: null,
);

Future<GoRouter> pumpWave2(
  WidgetTester tester,
  String id, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  LumeMemoryRecordRepository? store,
  ThemeMode theme = ThemeMode.light,
  LumeProfileRepository? profile,
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: LumeRoutes.tool(LumeRoutes.tools, id),
    profile: profile ?? taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    overrides: <Override>[
      if (store != null) recordRepositoryProvider.overrideWithValue(store),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
  return router;
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

Finder toolbarAction(String label) => find.descendant(
  of: find.byType(LumeToolbar),
  matching: find.byWidgetPredicate(
    (Widget w) =>
        (w is LumeIconButton && w.label == label) ||
        (w is LumeTextButton && w.label == label),
  ),
);

Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

/// Let a save's deliberate delay run, and the toast that follows go.
Future<void> settleSave(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Future<void> dismissToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

String textOf(WidgetTester tester, Finder f) {
  final Widget w = tester.widget(f);
  if (w is Text) return w.data ?? w.textSpan?.toPlainText() ?? '';
  return '';
}

/// Every piece of text under [f], in paint order.
List<String> textsIn(WidgetTester tester, Finder f) => <String>[
  for (final Text t in tester.widgetList<Text>(
    find.descendant(of: f, matching: find.byType(Text)),
  ))
    t.data ?? t.textSpan?.toPlainText() ?? '',
];
