/// Fuel Prices and Fuel Cost, pumped directly.
///
/// `tool_registry.dart` does not carry `fuel`/`fuelcost` yet — both are being
/// built alongside other tools in the same working tree, and the registry is
/// merged centrally once they land (`bmi_harness.dart` documents the same
/// situation for an earlier wave). So this harness does not go through the
/// router: it builds the [LumeToolRequest] the route would have handed each
/// screen, from the catalogue's own feature record, and pumps the tool
/// directly with [pumpLume].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/fuel/presentation/fuel_tool.dart';
import 'package:lume/features/fuel/presentation/fuelcost_tool.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/lume_harness.dart';

/// The catalogue's own entries — not stand-ins, so each screen draws the
/// real name, the real source claim and the real related rail.
final LumeFeature kFuelFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeFuelTool.id,
);
final LumeFeature kFuelcostFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeFuelcostTool.id,
);

/// Pump Fuel Prices for a reader in [country].
Future<void> pumpFuel(
  WidgetTester tester, {
  LumeToolSession? session,
  Size surface = LumeViewport.phone,
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  String country = 'PK',
  String city = 'Islamabad',
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    LumeFuelTool.open(
      LumeToolRequest(
        feature: kFuelFeature,
        user: LumeUserContext(country: country, city: city),
        branch: 'tools',
      ),
    ),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
    overrides: <Override>[
      toolSessionProvider.overrideWithValue(session ?? LumeToolSession()),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

/// Pump Fuel Cost for a reader in [country].
Future<void> pumpFuelcost(
  WidgetTester tester, {
  LumeToolSession? session,
  Size surface = LumeViewport.phone,
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  String country = 'PK',
  String city = 'Islamabad',
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    LumeFuelcostTool.open(
      LumeToolRequest(
        feature: kFuelcostFeature,
        user: LumeUserContext(country: country, city: city),
        branch: 'tools',
      ),
    ),
    surface: surface,
    locale: locale,
    theme: theme,
    textScale: textScale,
    overrides: <Override>[
      toolSessionProvider.overrideWithValue(session ?? LumeToolSession()),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

/// The typed `EditableText` a [LumeToolField] wraps.
Finder fuelInput(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

/// What is currently typed into [key]'s field.
String fuelTyped(WidgetTester tester, Key key) =>
    tester.widget<EditableText>(fuelInput(key)).controller.text;

/// Every string drawn under [of], in paint order.
List<String> textsIn(WidgetTester tester, Finder of) => tester
    .widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))
    .map((Text t) => plainText(t.data ?? t.textSpan?.toPlainText() ?? ''))
    .where((String s) => s.isNotEmpty)
    .toList();

/// The bidi isolate marks and narrow no-break spaces a formatter may put in,
/// stripped so a test compares what a reader actually sees.
const List<int> _bidiMarks = <int>[
  0x2066,
  0x2067,
  0x2068,
  0x2069,
  0x200e,
  0x200f,
];
const int _nbsp = 0x00a0;
const int _narrowNbsp = 0x202f;

String plainText(String s) {
  String out = s;
  for (final int mark in _bidiMarks) {
    out = out.replaceAll(String.fromCharCode(mark), '');
  }
  out = out.replaceAll(String.fromCharCode(_nbsp), ' ');
  out = out.replaceAll(String.fromCharCode(_narrowNbsp), ' ');
  return out.trim();
}
