/// Calculator, on the real router, for a reader in a given market.
///
/// `tool_registry.dart` names `calculator`, so `/tools/tool/calculator`
/// builds the tool itself: the same [LumeEligibility] asked the same
/// question, with the same profile, inside the shell the app draws. So the
/// tool bar, the source bar and the related rail the parity bounds are read
/// against are the real ones, and so is the navigation beside them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/calculator/presentation/calculator_tool.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// `/tools/tool/calculator`.
final String kCalculatorLocation = LumeRoutes.tool(
  LumeRoutes.tools,
  LumeCalculatorTool.id,
);

/// The surface each captured cell is reproduced on.
///
/// The reference draws the app inside a stage with a 25-point margin either
/// side, and its own navigation beside the screen above compact width. The
/// margins are not a surface Lume ever has, so they come off; the navigation
/// stays, because the tool route is inside the shell and the shell draws the
/// same rail (84) and sidebar (244) at the same widths. So a 700-point
/// reference viewport is pumped at 650, 852 at 802 and 1100 at 1050, and the
/// screen inside each is the reference's own 566, 718 and 806.
const Map<String, Size> kCalculatorCells = <String, Size>{
  'tool_calculator_default_pk_390x844_light_en': Size(390, 5000),
  'tool_calculator_default_pk_390x844_dark_en': Size(390, 5000),
  'tool_calculator_default_pk_390x844_light_ur': Size(390, 5000),
  'tool_calculator_default_pk_390x844_light_ar': Size(390, 5000),
  'tool_calculator_default_pk_700x900_light_en': Size(650, 5000),
  'tool_calculator_default_pk_852x393_light_en': Size(802, 5000),
  'tool_calculator_default_pk_1100x900_light_en': Size(1050, 5000),
};

Future<GoRouter> pumpCalculator(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  List<Override> overrides = const <Override>[],
}) async {
  final GoRouter router = await pumpLumeRouter(
    tester,
    initialLocation: kCalculatorLocation,
    profile: taxProfile(state),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    overrides: overrides,
  );
  await tester.pumpAndSettle();
  return router;
}

/// Every string drawn under [of], trimmed, in paint order.
List<String> calcTextsIn(WidgetTester tester, Finder of) => tester
    .widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))
    .map(
      (Text t) => (t.data ?? t.textSpan!.toPlainText())
          .replaceAll(String.fromCharCode(0x2066), '')
          .replaceAll(String.fromCharCode(0x2069), '')
          .trim(),
    )
    .where((String s) => s.isNotEmpty)
    .toList();

/// What the readout says, with the bidi isolates stripped. The key is on the
/// number, or - when a key was refused - on the message in its place.
String calcReadout(WidgetTester tester) =>
    _textAt(tester, LumeCalculatorTool.readoutKey);

String calcExpression(WidgetTester tester) =>
    _textAt(tester, LumeCalculatorTool.expressionKey);

String _textAt(WidgetTester tester, Key key) {
  final Finder self = find.byKey(key);
  final Finder inside = find.descendant(of: self, matching: find.byType(Text));
  final Text t = inside.evaluate().isEmpty
      ? tester.widget<Text>(self)
      : tester.widget<Text>(inside.first);
  return (t.data ?? t.textSpan!.toPlainText())
      .replaceAll(String.fromCharCode(0x2066), '')
      .replaceAll(String.fromCharCode(0x2069), '');
}

/// Press a key by its widget key, letting the press settle.
Future<void> calcTap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}
