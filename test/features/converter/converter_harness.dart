/// Unit Converter, in the full environment, over a session the test holds.
///
/// The tool is pumped directly rather than through `/tools/tool/converter`:
/// `tool_registry.dart` does not name it yet, and that file belongs to the
/// rollout rather than to this screen. Everything else is the real thing —
/// the catalogue's own feature record, the real [LumeToolScreen] frame with
/// its source bar and related rail, and the same [LumeToolSession] the app
/// keeps a tool's state in, handed in so a test can seed what a returning
/// reader would have and read back what the screen wrote.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/catalogue/data/feature_catalogue.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/converter/domain/unit_table.dart';
import 'package:lume/features/converter/presentation/converter_tool.dart';
import 'package:lume/features/tools/application/tool_request.dart';
import 'package:lume/features/tools/application/tool_session.dart';

import '../../helpers/lume_harness.dart';

/// The catalogue's own entry — not a stand-in, so the frame draws the real
/// name, the real source claim and the real related rail.
final LumeFeature kConverterFeature = kLumeFeatures.firstWhere(
  (LumeFeature f) => f.id == LumeConverterTool.id,
);

/// Pump the tool for a reader in [country].
Future<void> pumpConverter(
  WidgetTester tester, {
  LumeToolSession? session,
  Size surface = LumeViewport.tall,
  Locale locale = const Locale('en'),
  ThemeMode theme = ThemeMode.light,
  double textScale = 1,
  String country = 'PK',
  String city = 'Islamabad',
  List<Override> overrides = const <Override>[],
}) async {
  await pumpLume(
    tester,
    LumeConverterTool(
      request: LumeToolRequest(
        feature: kConverterFeature,
        user: LumeUserContext(country: country, city: city),
        branch: LumeRoutes.tools,
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

/// The figure in the answer, as a reader sees it.
String converterResult(WidgetTester tester) => plainText(
  tester.widget<Text>(find.byKey(LumeConverterTool.resultKey)).data!,
);

/// What the answer is announced as.
String converterResultSpoken(WidgetTester tester) => plainText(
  tester.widget<Text>(find.byKey(LumeConverterTool.resultKey)).semanticsLabel!,
);

/// The value on one All-units row.
String converterRow(WidgetTester tester, String unitId) => plainText(
  textsIn(tester, find.byKey(LumeConverterTool.rowKey(unitId))).last,
);

/// Every string drawn under [of], in paint order.
List<String> textsIn(WidgetTester tester, Finder of) => tester
    .widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))
    .map((Text t) => (t.data ?? t.textSpan?.toPlainText() ?? '').trim())
    .where((String s) => s.isNotEmpty)
    .toList();

/// A string as it reads, without the bidi marks or the narrow spaces a
/// formatter puts in.
String plainText(String s) => s
    .replaceAll(RegExp('[\u2066-\u2069\u200e\u200f]'), '')
    .replaceAll('\u00a0', ' ')
    .replaceAll('\u202f', ' ')
    .trim();

/// Tap one category chip and settle.
Future<void> tapCategory(WidgetTester tester, LumeUnitKind kind) async {
  await tester.ensureVisible(find.byKey(LumeConverterTool.categoryKey(kind)));
  await tester.tap(find.byKey(LumeConverterTool.categoryKey(kind)));
  await tester.pumpAndSettle();
}

/// Open one side's picker and choose [unitId].
Future<void> pickUnit(WidgetTester tester, Key side, String unitId) async {
  await tester.tap(find.byKey(side));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(LumeConverterTool.optionKey(unitId)));
  await tester.tap(find.byKey(LumeConverterTool.optionKey(unitId)));
  await tester.pumpAndSettle();
}

/// Type [amount] into the field, replacing what is there.
Future<void> typeAmount(WidgetTester tester, String amount) async {
  await tester.enterText(find.byKey(LumeConverterTool.amountKey), amount);
  await tester.pumpAndSettle();
}

/// Every framework error raised while [body] runs.
///
/// A layout overflow is reported through `FlutterError.onError` and then
/// stored for `tester.takeException()`, which hands back one error and
/// nothing about where it came from. A test that has to say *which* widget
/// overflowed needs the details, so they are collected here and the store is
/// drained afterwards.
Future<List<FlutterErrorDetails>> converterErrors(
  Future<void> Function() body,
) async {
  final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
  final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return errors;
}

/// The shared components that overflow at 200 % text, and why.
///
/// Neither is this screen's, neither is only this screen's, and both are
/// named rather than absorbed into a looser assertion:
///
/// * `lume_badge.dart:426` — `LumeFreshnessDot` lays its dot and its label
///   out in a `Row` with `mainAxisSize.min` and nowhere to wrap, and
///   "Stored on this device" at 22 points is wider than the bar. Every tool
///   screen draws it.
/// * `lume_row.dart:468` — `LumeCompactRow` gives its label the flex and its
///   value none, so a wide figure at 22 points runs past the row. A number
///   that ellipsised would be a *wrong* number, so the component does not,
///   and any list of long figures reaches this.
const List<String> kSharedOverflowSources = <String>[
  'lume_badge.dart',
  'lume_row.dart',
];

/// Whether an error came from one of those rather than from anything the
/// converter itself draws.
bool fromSharedComponent(FlutterErrorDetails details) {
  final String text = details.toString();
  return kSharedOverflowSources.any(text.contains);
}

/// Whether anything focused while tabbing sits under [key].
///
/// A focus node's own context is inside the control — inside
/// `FocusableActionDetector`, inside the `TextField` — so the key the screen
/// hung on the control is an ancestor of it.
bool reachedKey(Iterable<BuildContext> focused, Key key) =>
    focused.any((BuildContext c) {
      bool found = false;
      c.visitAncestorElements((Element e) {
        if (e.widget.key == key) {
          found = true;
          return false;
        }
        return true;
      });
      return found;
    });

/// Tab [times] and collect what took focus.
Future<List<BuildContext>> tabThrough(
  WidgetTester tester, {
  int times = 24,
}) async {
  final List<BuildContext> focused = <BuildContext>[];
  for (int i = 0; i < times; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final BuildContext? c = FocusManager.instance.primaryFocus?.context;
    if (c != null) focused.add(c);
  }
  return focused;
}
