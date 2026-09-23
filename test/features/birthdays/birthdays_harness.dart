/// Birthdays, pumped straight into the app's environment.
///
/// The other record tools reach their screen through the router, which reads
/// `kLumeToolRegistry`; Birthdays is not in it yet — the integrator adds it —
/// so the route would answer with the fixture screen instead. The tool is
/// therefore built here from a hand-made [LumeToolRequest], inside the same
/// `ProviderScope`, clock, theme, locale and breakpoint scope
/// [pumpLume] gives every other widget test. Everything below the request is
/// the real thing: the real host, the real record store, the real formats.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/records_provider.dart';
import 'package:lume/core/fixtures/lume_clock.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/birthdays/presentation/birthdays_tool.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/records/data/memory_record_repository.dart';
import 'package:lume/features/records/data/record_seeds.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';

/// The catalogue's own entry, so the screen is drawn for the feature the
/// route would hand it rather than an invented one.
final LumeFeature kBirthdaysFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeBirthdaysTool.id,
);

/// A store on the fixture day that reads at once.
///
/// `birthdays` is in [kLumeParityOnlySeeds]: only a build that reproduces
/// the reference is seeded, and every other build — a development or release
/// one, and any reader who has added nothing — opens the collection empty.
/// Both are real states, so both are pumped.
LumeMemoryRecordRepository birthdaysStore({bool parity = true}) =>
    LumeMemoryRecordRepository(
      seeds: (String collection, DateTime now) =>
          lumeRecordSeeds(collection, now, reproducesReference: parity),
      now: () => kFixtureInstant,
      hydrateDelay: null,
    );

Future<void> pumpBirthdays(
  WidgetTester tester, {
  LumeMemoryRecordRepository? store,
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  DateTime? now,
  LumeUserContext user = const LumeUserContext(),
  List<Override> overrides = const <Override>[],
}) async {
  final LumeMemoryRecordRepository records = store ?? birthdaysStore();
  addTearDown(records.dispose);
  await pumpLume(
    tester,
    LumeBirthdaysTool.open(
      LumeToolRequest(
        feature: kBirthdaysFeature,
        user: user,
        branch: LumeRoutes.tools,
      ),
    ),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
    now: now,
    overrides: <Override>[
      recordRepositoryProvider.overrideWithValue(records),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

Finder inKey(Key key, Finder matching) =>
    find.descendant(of: find.byKey(key), matching: matching);

/// Every piece of text under [of], in paint order.
List<String> textsIn(WidgetTester tester, Finder of) => <String>[
  for (final Text t in tester.widgetList<Text>(
    find.descendant(of: of, matching: find.byType(Text)),
  ))
    t.data ?? t.textSpan?.toPlainText() ?? '',
];

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
