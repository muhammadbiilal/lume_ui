/// Every authentication screen and state, rendered and frozen.
///
/// Two jobs, as in F4A and F4B:
///
/// * **Goldens** are committed, and are the visual evidence for the phase.
/// * **Captures** write `.flutter.png` beside the `.web.png` that
///   `measure_auth.mjs --shot 1` produces, so `compare.mjs` can pair them.
///   Working artefacts, gitignored.
///
/// The cells are the ones F4C asks for: 390 × 844 in English light, dark, Urdu
/// and Arabic; 359 × 844 for the narrowest supported phone; 700 × 900 and
/// 1100 × 900 for the two larger classes; 852 × 393 for a phone held sideways;
/// and 1400 × 900, which is where the composition becomes two regions and the
/// only cell that draws the aside. 200 per cent text, an open keyboard and the
/// four feedback states have their own goldens at the end.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/auth/application/auth_flow_controller.dart';
import 'package:lume/features/auth/domain/auth_model.dart';
import 'package:lume/features/auth/presentation/auth_flow.dart';
import 'package:lume/features/startup/presentation/splash_screen.dart';

import '../features/auth/auth_harness.dart';
import '../helpers/capture.dart';
import '../helpers/load_fonts.dart';
import '../helpers/lume_harness.dart';
import 'onboarding_golden_test.dart' show Cell;

/// The nine cells the phase asks to see.
const List<Cell> kAuthCells = <Cell>[
  (
    name: '390 light en',
    surface: Size(390, 844),
    theme: ThemeMode.light,
    locale: Locale('en'),
  ),
  (
    name: '390 dark en',
    surface: Size(390, 844),
    theme: ThemeMode.dark,
    locale: Locale('en'),
  ),
  (
    name: '390 light ur',
    surface: Size(390, 844),
    theme: ThemeMode.light,
    locale: Locale('ur'),
  ),
  (
    name: '390 light ar',
    surface: Size(390, 844),
    theme: ThemeMode.light,
    locale: Locale('ar'),
  ),
  (
    name: '359 light en',
    surface: Size(359, 844),
    theme: ThemeMode.light,
    locale: Locale('en'),
  ),
  (
    name: '700 light en',
    surface: Size(700, 900),
    theme: ThemeMode.light,
    locale: Locale('en'),
  ),
  (
    name: '1100 light en',
    surface: Size(1100, 900),
    theme: ThemeMode.light,
    locale: Locale('en'),
  ),
  (
    name: '1400 light en',
    surface: Size(1400, 900),
    theme: ThemeMode.light,
    locale: Locale('en'),
  ),
  (
    name: '852 light en',
    surface: Size(852, 393),
    theme: ThemeMode.light,
    locale: Locale('en'),
  ),
];

void main() {
  setUpAll(loadLumeFonts);

  String slug(Cell c) =>
      '${c.surface.width.round()}_${c.theme == ThemeMode.dark ? 'dark' : 'light'}'
      '_${c.locale.languageCode}';

  group('every screen, everywhere', () {
    for (final (LumeAuthRoute route, String label, int step) in kAuthStates) {
      for (final Cell cell in kAuthCells) {
        testWidgets('$label · ${cell.name}', (WidgetTester tester) async {
          await pumpLume(
            tester,
            authAt(route, step: step),
            surface: cell.surface,
            theme: cell.theme,
            locale: cell.locale,
          );
          await expectLater(
            find.byType(LumeAuthFlow),
            matchesGoldenFile('images/auth_${label}_${slug(cell)}.png'),
          );
        });
      }
    }
  });

  group('the states the phase asks for', () {
    testWidgets('sign in · a refused submission', (WidgetTester t) async {
      await pumpLume(t, authAt(LumeAuthRoute.signIn));
      await refuse(t, LumeAuthFailure.credentials);
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_signin_formerror.png'),
      );
    });

    testWidgets('sign in · a field that failed on blur', (
      WidgetTester t,
    ) async {
      await pumpLume(t, authAt(LumeAuthRoute.signIn));
      await typeAndLeave(t, LumeAuthField.email, 'not-an-address');
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_signin_fielderror.png'),
      );
    });

    testWidgets('sign in · working', (WidgetTester t) async {
      await pumpLume(t, authAt(LumeAuthRoute.signIn));
      await startSubmit(t, email: 'a@b.com', password: 'Whatever1');
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_signin_busy.png'),
      );
      await t.pumpAndSettle();
    });

    testWidgets('sign in · interrupting something', (WidgetTester t) async {
      await pumpLume(t, authAt(LumeAuthRoute.signIn, modal: true));
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_signin_modal.png'),
      );
    });

    testWidgets('sign in · offline', (WidgetTester t) async {
      await pumpLume(t, authAt(LumeAuthRoute.signIn));
      await refuse(t, LumeAuthFailure.network);
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_signin_offline.png'),
      );
    });

    testWidgets('sign up · a password part-way to acceptable', (
      WidgetTester t,
    ) async {
      await pumpLume(t, authAt(LumeAuthRoute.signUp, step: 2));
      await type(t, LumeAuthField.password, 'abcd1234');
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_signup2_typed.png'),
      );
    });

    testWidgets('sign up · a password that meets every rule', (
      WidgetTester t,
    ) async {
      await pumpLume(t, authAt(LumeAuthRoute.signUp, step: 2));
      await type(t, LumeAuthField.password, 'Passw0rdy!');
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_signup2_strong.png'),
      );
    });

    testWidgets('sign up · with the keyboard up', (WidgetTester t) async {
      await pumpLume(
        t,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: const EdgeInsets.only(bottom: 320)),
            child: authAt(LumeAuthRoute.signUp, step: 2),
          ),
        ),
      );
      // Scrolled to the end, which is where the reservation shows: the action
      // sits above the keyboard rather than behind it.
      await t.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await t.pumpAndSettle();
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_signup2_keyboard.png'),
      );
    });

    testWidgets('verify · once the window has opened', (WidgetTester t) async {
      await pumpLume(t, authAt(LumeAuthRoute.verify, resendOpen: true));
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_verify_resendable.png'),
      );
    });

    testWidgets('created · without a name', (WidgetTester t) async {
      await pumpLume(t, authAt(LumeAuthRoute.created, named: false));
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_created_unnamed.png'),
      );
    });

    testWidgets('trouble · an expired link', (WidgetTester t) async {
      await pumpLume(
        t,
        authAt(LumeAuthRoute.trouble, trouble: LumeTroubleReason.linkExpired),
      );
      await expectLater(
        find.byType(LumeAuthFlow),
        matchesGoldenFile('images/auth_trouble_expired.png'),
      );
    });

    testWidgets('the splash', (WidgetTester t) async {
      await pumpLume(t, const LumeSplashScreen());
      await expectLater(
        find.byType(LumeSplashScreen),
        matchesGoldenFile('images/auth_splash.png'),
      );
    });

    for (final (LumeAuthRoute route, String label, int step)
        in <(LumeAuthRoute, String, int)>[
          (LumeAuthRoute.signIn, 'signin', 1),
          (LumeAuthRoute.signUp, 'signup2', 2),
          (LumeAuthRoute.sent, 'sent', 1),
          (LumeAuthRoute.verify, 'verify', 1),
        ]) {
      testWidgets('$label · 200 per cent text', (WidgetTester t) async {
        await pumpLume(t, authAt(route, step: step), textScale: 2.0);
        await expectLater(
          find.byType(LumeAuthFlow),
          matchesGoldenFile('images/auth_${label}_text200.png'),
        );
      });
    }
  });

  // Paired with the web captures by `compare.mjs`. Gitignored — see Q7.
  group('captures for the comparison', () {
    for (final (LumeAuthRoute route, String label, int step) in kAuthStates) {
      for (final Cell cell in kAuthCells) {
        testWidgets('$label · ${cell.name}', (WidgetTester tester) async {
          await captureLume(
            tester,
            authAt(route, step: step),
            name: 'auth_$label',
            surface: cell.surface,
            theme: cell.theme,
            locale: cell.locale,
            outDir: 'docs/conversion_archive/shots/auth',
          );
        });
      }
    }
  });
}
