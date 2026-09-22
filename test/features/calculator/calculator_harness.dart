/// Calculator, in the shell it is drawn in, for a reader in a given market.
///
/// **Why the tool is built here rather than reached through a route.** The
/// route builds a converted tool out of `kLumeToolRegistry`, and this wave's
/// tools are registered in one edit that no single tool owns. So the harness
/// does exactly what `app_router.dart`'s `_tool` does — asks the *same*
/// [LumeEligibility] the same question, with the *same* profile, and builds
/// the tool only if the gate says yes — and hands the result to the real
/// [LumeToolScreen]. Everything the frame draws (the tool bar, the source
/// bar, the related rail) is therefore the real thing, which is what the
/// parity bounds are read against. [calculatorIsRegistered] is asserted
/// separately, so the missing line is a failing test and not a silence.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/app/providers/personalisation.dart';
import 'package:lume/app/providers/shell_provider.dart';
import 'package:lume/core/routing/lume_routes.dart';
import 'package:lume/features/auth/data/fake_auth_repository.dart';
import 'package:lume/features/auth/domain/auth_repository.dart';
import 'package:lume/features/calculator/presentation/calculator_tool.dart';
import 'package:lume/features/catalogue/domain/eligibility.dart';
import 'package:lume/features/catalogue/domain/lume_feature.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/startup/application/startup_controller.dart';
import 'package:lume/features/tools/application/tool_registry.dart';
import 'package:lume/features/tools/application/tool_request.dart';

import '../../helpers/lume_harness.dart';
import '../tax/tax_harness.dart';

/// Whether the route can reach the tool. Asserted by a test of its own.
bool get calculatorIsRegistered =>
    kLumeToolRegistry.containsKey(LumeCalculatorTool.id);

/// The surface each captured cell is reproduced on.
///
/// The reference draws the app inside a stage: a 25-point margin either side
/// and, above compact width, its own navigation (84 at medium, 244 at
/// expanded). So a 700-point viewport gives the *screen* 566 points, 852
/// gives 718 and 1100 gives 806 — and those, not the viewport widths, are
/// what the tool is pumped at, because the harness hosts the screen without
/// the shell's chrome around it.
const Map<String, Size> kCalculatorCells = <String, Size>{
  'tool_calculator_default_pk_390x844_light_en': Size(390, 5000),
  'tool_calculator_default_pk_390x844_dark_en': Size(390, 5000),
  'tool_calculator_default_pk_390x844_light_ur': Size(390, 5000),
  'tool_calculator_default_pk_390x844_light_ar': Size(390, 5000),
  'tool_calculator_default_pk_700x900_light_en': Size(566, 5000),
  'tool_calculator_default_pk_852x393_light_en': Size(718, 5000),
  'tool_calculator_default_pk_1100x900_light_en': Size(806, 5000),
};

Future<void> pumpCalculator(
  WidgetTester tester, {
  String state = 'default_pk',
  Size surface = const Size(390, 5000),
  Locale locale = const Locale('en'),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  List<Override> overrides = const <Override>[],
}) async {
  final LumeProfileRepository profiles = taxProfile(state);
  final LumeAuthRepository auth = LumeFakeAuthRepository.withAccount();
  final LumeStartupController gate = LumeStartupController(
    authRepository: auth,
    profileRepository: profiles,
  );
  addTearDown(gate.dispose);
  await gate.boot();

  await pumpLume(
    tester,
    const _CalculatorRoute(),
    surface: surface,
    locale: locale,
    textScale: textScale,
    theme: theme,
    overrides: <Override>[
      startupControllerProvider.overrideWithValue(gate),
      profileRepositoryProvider.overrideWithValue(profiles),
      authRepositoryProvider.overrideWithValue(auth),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

/// `app_router.dart`'s `_tool`, minus the registry lookup.
class _CalculatorRoute extends ConsumerWidget {
  const _CalculatorRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LumeEligibility eligibility = ref.watch(eligibilityProvider);
    return LumeProfileScope(
      builder: (BuildContext context, LumeUserContext user) {
        final LumeFeature? feature = eligibility.visibleById(
          LumeCalculatorTool.id,
          user,
        );
        if (feature == null) return const SizedBox.shrink();
        return LumeCalculatorTool.open(
          LumeToolRequest(
            feature: feature,
            user: user,
            branch: LumeRoutes.tools,
          ),
        );
      },
    );
  }
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
