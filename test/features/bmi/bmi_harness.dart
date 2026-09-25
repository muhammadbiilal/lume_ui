/// BMI Calculator, pumped directly.
///
/// `tool_registry.dart` names every converted tool's route, and this one is
/// not in it yet — it is being built alongside nine other tools in the same
/// working tree, and the registry is merged centrally once all ten land. So
/// this harness does not go through the router the way `converter_harness.dart`
/// or `tax_harness.dart` do: it builds the [LumeToolRequest] the route would
/// have handed the screen, from the catalogue's own feature record, and pumps
/// [LumeBmiTool] with [pumpLume]. Once the registry carries `bmi`, a test that
/// wants the router besides can add it without anything here changing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/bmi/presentation/bmi_tool.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/lume_harness.dart';

/// The catalogue's own entry — not a stand-in, so the screen draws the real
/// name, the real source claim and the real related rail.
final LumeFeature kBmiFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeBmiTool.id,
);

/// Pump the tool for a reader in [country].
Future<void> pumpBmi(
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
    LumeBmiTool.open(
      LumeToolRequest(
        feature: kBmiFeature,
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

/// The typed `EditableText` a [LumeToolField] wraps — `enterText` needs this,
/// not the field's own key, exactly as the Tax Calculator's own tests reach
/// theirs.
Finder bmiInput(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

/// What is currently typed into [key]'s field.
String bmiTyped(WidgetTester tester, Key key) =>
    tester.widget<EditableText>(bmiInput(key)).controller.text;

/// Every string drawn under [of], in paint order.
List<String> textsIn(WidgetTester tester, Finder of) => tester
    .widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))
    .map((Text t) => plainText(t.data ?? t.textSpan?.toPlainText() ?? ''))
    .where((String s) => s.isNotEmpty)
    .toList();

/// The bidi isolate marks [LumeLtr]/[LumeNumerals] wrap a figure in, and the
/// narrow no-break space `intl` sometimes puts before an am/pm marker — named
/// by code point ([String.fromCharCode]) rather than as a literal escape in
/// the source, so the file holds plain ASCII and never the invisible mark
/// itself.
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

/// A string as it reads, without the bidi marks or the narrow spaces a
/// formatter puts in.
String plainText(String s) {
  String out = s;
  for (final int mark in _bidiMarks) {
    out = out.replaceAll(String.fromCharCode(mark), '');
  }
  out = out.replaceAll(String.fromCharCode(_nbsp), ' ');
  out = out.replaceAll(String.fromCharCode(_narrowNbsp), ' ');
  return out.trim();
}
