/// Where every element of every authentication screen actually is, against
/// where the design source puts it.
///
/// The same method as the onboarding comparison: `measure_auth.mjs` drives the
/// running prototype to a named state and writes `getBoundingClientRect` for
/// each element; this pumps the Flutter screen into the same state and asserts
/// the numbers agree.
///
/// **Positions are relative to the panel's own origin.** The prototype draws a
/// 28-point simulated status bar and sits its authentication screen below it
/// (P1); Flutter's flow covers the shell and has no such bar (D18). Comparing
/// absolute page coordinates would therefore compare two different origins, so
/// every `y` below is measured from `.auth`'s own top — which is the number
/// the composition is actually about.
///
/// A failure here is a layout difference, not a rasterisation one: the
/// tolerance is a whole logical pixel.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/features/auth/application/auth_flow_controller.dart';
import 'package:lume/features/auth/domain/auth_model.dart';
import 'package:lume/features/auth/presentation/auth_chrome.dart';
import 'package:lume/features/auth/presentation/auth_parts.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import 'auth_harness.dart';

const String reportPath = 'docs/conversion_archive/AUTH_PARITY.md';

/// One logical pixel — see the onboarding comparison for why not zero.
const double kTolerance = 1.0;

void main() {
  setUpAll(loadLumeFonts);

  Map<String, dynamic>? cell(String state) {
    final File f = File(
      'docs/conversion_archive/measurements/auth_${state}_390x844_light_en.json',
    );
    if (!f.existsSync()) return null;
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }

  final List<String> rows = <String>[];
  final List<String> misses = <String>[];
  int compared = 0;

  tearDown(() {
    final List<String> found = List<String>.of(misses);
    misses.clear();
    expect(found, isEmpty, reason: 'element bounds differ from the prototype');
  });

  /// The prototype's own origin for this screen, so both sides are measured
  /// from the same place.
  double originOf(Map<String, dynamic> bounds) =>
      ((bounds['auth'] as Map<String, dynamic>)['y'] as num).toDouble();

  void compare(
    WidgetTester tester,
    Map<String, dynamic> bounds,
    String name,
    Finder finder, {
    bool checkY = true,
    bool checkX = true,
    bool checkWidth = true,
    bool checkHeight = true,
    bool fromBottom = false,
    double tolerance = kTolerance,
    String note = '',
  }) {
    final Map<String, dynamic>? b = bounds[name] as Map<String, dynamic>?;
    if (b == null) {
      rows.add('| `$name` | — | — | — | not measured |');
      return;
    }
    expect(finder, findsWidgets, reason: '$name is not on screen');
    final Rect r = tester.getRect(finder.first);
    final double origin = originOf(bounds);

    void check(String what, double wanted, double got) {
      compared++;
      if ((got - wanted).abs() > tolerance) {
        misses.add(
          '$name $what — the prototype puts it at '
          '${wanted.toStringAsFixed(2)}, Flutter at ${got.toStringAsFixed(2)} '
          '(${(got - wanted).toStringAsFixed(2)})',
        );
      }
      rows.add(
        '| `$name` | $what | ${wanted.toStringAsFixed(2)} | '
        '${got.toStringAsFixed(2)} | '
        '${(got - wanted).abs() < 0.005 ? "=" : (got - wanted).toStringAsFixed(2)}'
        ' | ${note.isEmpty ? "" : note} |',
      );
    }

    if (checkY && fromBottom) {
      // A status screen pushes its action to the bottom, so the number that
      // means anything is the distance from there. The Flutter panel is 28
      // taller because the flow covers the shell rather than sitting under a
      // simulated status bar (D18), and a top-anchored comparison would be
      // measuring that difference rather than the composition.
      final double webPanel =
          ((bounds['auth'] as Map<String, dynamic>)['height'] as num)
              .toDouble();
      final double surface =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      check(
        'bottom',
        webPanel -
            ((b['y'] as num).toDouble() -
                origin +
                (b['height'] as num).toDouble()),
        surface - r.bottom,
      );
    } else if (checkY) {
      check('y', (b['y'] as num).toDouble() - origin, r.top);
    }
    if (checkX) check('x', (b['x'] as num).toDouble(), r.left);
    if (checkWidth) check('width', (b['width'] as num).toDouble(), r.width);
    if (checkHeight) check('height', (b['height'] as num).toDouble(), r.height);
  }

  /// The heading's own block: `.auth__title` fills the column, and the
  /// balanced `Text` inside it is narrower by design.
  Finder titleBlock() => find.byKey(LumeAuthKeys.title);

  /// The nth field on the screen.
  Finder fieldAt(int index) =>
      find.byType(LumeAuthInput).at(index).hitTestable(at: Alignment.topLeft);

  /// The chrome of a screen the reference has compressed (D19): recorded in
  /// the report, never asserted.
  void chromeNote(WidgetTester tester, Map<String, dynamic> b) {
    for (final (String name, Finder finder) in <(String, Finder)>[
      ('auth.top', find.byKey(LumeAuthKeys.top)),
      ('auth.back', find.byKey(LumeAuthKeys.back)),
      ('auth.brand', find.byKey(LumeAuthKeys.brand)),
      ('auth.hero', find.byKey(LumeAuthKeys.hero)),
      ('auth.title', titleBlock()),
    ]) {
      compare(
        tester,
        b,
        name,
        finder,
        tolerance: 13,
        note: 'the reference compresses this header (D19)',
      );
    }
  }

  /// Chrome shared by every screen.
  void chrome(
    WidgetTester tester,
    Map<String, dynamic> b, {
    bool brand = true,
    bool back = true,
  }) {
    compare(tester, b, 'auth.top', find.byKey(LumeAuthKeys.top));
    if (back) compare(tester, b, 'auth.back', find.byKey(LumeAuthKeys.back));
    if (brand) {
      compare(tester, b, 'auth.brand', find.byKey(LumeAuthKeys.brand));
      compare(tester, b, 'auth.mark', find.byKey(LumeAuthKeys.mark));
    }
    compare(tester, b, 'auth.hero', find.byKey(LumeAuthKeys.hero));
    compare(tester, b, 'auth.title', titleBlock());
  }

  Future<void> pumpAt(
    WidgetTester tester,
    LumeAuthRoute route, {
    int step = 1,
    bool modal = false,
    bool named = true,
  }) => pumpLume(
    tester,
    authAt(route, step: step, modal: modal, named: named),
    surface: const Size(390, 844),
  );

  group('sign in', () {
    testWidgets('the whole composition', (WidgetTester tester) async {
      final Map<String, dynamic>? measured = cell('signin');
      if (measured == null) {
        markTestSkipped('run tool/measure_auth.mjs --route signin first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpAt(tester, LumeAuthRoute.signIn);

      chrome(tester, b);
      compare(tester, b, 'auth.word', find.byKey(LumeAuthKeys.word));
      compare(tester, b, 'auth.text', find.byKey(LumeAuthKeys.text));
      compare(tester, b, 'auth.form', find.byKey(LumeAuthKeys.form));
      compare(tester, b, 'auth.field.first', fieldAt(0));
      compare(tester, b, 'auth.field.second', fieldAt(1));
      compare(tester, b, 'auth.inline', find.byKey(LumeAuthKeys.inline));
      compare(tester, b, 'auth.actions', find.byKey(LumeAuthKeys.actions));
      compare(tester, b, 'auth.submit', find.byType(LumeAuthSubmit));
      compare(tester, b, 'auth.foot', find.byKey(LumeAuthKeys.foot));
      compare(tester, b, 'auth.link.first', find.byType(LumeAuthLink).first);
    });

    testWidgets('a refused submission moves the form down by its message', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic>? measured = cell('signin_error');
      if (measured == null) {
        markTestSkipped('run tool/measure_auth.mjs --route signin_error first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpAt(tester, LumeAuthRoute.signIn);
      await refuse(tester, LumeAuthFailure.credentials);

      compare(tester, b, 'auth.formerr', find.byKey(LumeAuthKeys.formError));
      compare(tester, b, 'auth.form', find.byKey(LumeAuthKeys.form));
      compare(tester, b, 'auth.field.first', fieldAt(0));
      compare(tester, b, 'auth.submit', find.byType(LumeAuthSubmit));
    });

    testWidgets('a held destination adds the notice above the form', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic>? measured = cell('signin_pending');
      if (measured == null) {
        markTestSkipped('run tool/measure_auth.mjs --route signin_pending');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpAt(tester, LumeAuthRoute.signIn, modal: true);

      compare(tester, b, 'auth.close', find.byKey(LumeAuthKeys.close));
      compare(tester, b, 'auth.notice', find.byKey(LumeAuthKeys.notice));
      compare(tester, b, 'auth.form', find.byKey(LumeAuthKeys.form));
      compare(tester, b, 'auth.foot.secondary', find.byType(LumeAuthSecondary));
    });
  });

  group('sign up', () {
    testWidgets('step one', (WidgetTester tester) async {
      final Map<String, dynamic>? measured = cell('signup');
      if (measured == null) {
        markTestSkipped('run tool/measure_auth.mjs --route signup first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpAt(tester, LumeAuthRoute.signUp);

      chrome(tester, b);
      compare(tester, b, 'auth.stepOf', find.byKey(LumeAuthKeys.stepOf));
      compare(tester, b, 'auth.steps', find.byKey(LumeAuthKeys.steps));
      compare(tester, b, 'auth.form', find.byKey(LumeAuthKeys.form));
      compare(tester, b, 'auth.field.first', fieldAt(0));
      compare(tester, b, 'auth.field.second', fieldAt(1));
      compare(tester, b, 'auth.submit', find.byType(LumeAuthSubmit));
    });

    testWidgets('step two, with the meter and the rules', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic>? measured = cell('signup2');
      if (measured == null) {
        markTestSkipped('run tool/measure_auth.mjs --route signup2 first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpAt(tester, LumeAuthRoute.signUp, step: 2);

      chrome(tester, b);
      compare(tester, b, 'auth.steps', find.byKey(LumeAuthKeys.steps));
      compare(tester, b, 'auth.form', find.byKey(LumeAuthKeys.form));
      compare(tester, b, 'auth.field.first', fieldAt(0));
      compare(tester, b, 'auth.pwmeter', find.byType(LumePasswordMeter));
      compare(tester, b, 'auth.pwrules', find.byType(LumePasswordRules));
      compare(tester, b, 'auth.field.second', fieldAt(1));
      compare(tester, b, 'auth.submit', find.byType(LumeAuthSubmit));
      compare(
        tester,
        b,
        'auth.legal',
        find.byKey(LumeAuthKeys.legal),
        // The reference's inline link is a `<button>` with 2 px of padding,
        // which grows the line box it sits in. A Dart `TextSpan` has no such
        // box, so the paragraph is two points shorter.
        checkHeight: false,
        note: 'the inline link has no padded box in Flutter (D20)',
      );
    });
  });

  group('recovery', () {
    testWidgets('forgot', (WidgetTester tester) async {
      final Map<String, dynamic>? measured = cell('forgot');
      if (measured == null) {
        markTestSkipped('run tool/measure_auth.mjs --route forgot first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpAt(tester, LumeAuthRoute.forgot);

      chrome(tester, b);
      compare(tester, b, 'auth.visual', find.byKey(LumeAuthKeys.visual));
      compare(tester, b, 'auth.seal', find.byKey(LumeAuthKeys.seal));
      compare(tester, b, 'auth.form', find.byKey(LumeAuthKeys.form));
      compare(tester, b, 'auth.submit', find.byType(LumeAuthSubmit));
      compare(tester, b, 'auth.foot', find.byKey(LumeAuthKeys.foot));
    });

    testWidgets('the neutral confirmation', (WidgetTester tester) async {
      final Map<String, dynamic>? measured = cell('sent');
      if (measured == null) {
        markTestSkipped('run tool/measure_auth.mjs --route sent first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpAt(tester, LumeAuthRoute.sent);

      chrome(tester, b, brand: false);
      compare(tester, b, 'auth.visual', find.byKey(LumeAuthKeys.visual));
      compare(tester, b, 'auth.text', find.byKey(LumeAuthKeys.text));
      compare(tester, b, 'auth.note', find.byKey(LumeAuthKeys.note));
      compare(
        tester,
        b,
        'auth.submit',
        find.byType(LumeAuthSubmit),
        fromBottom: true,
      );
      compare(
        tester,
        b,
        'auth.foot',
        find.byKey(LumeAuthKeys.foot),
        fromBottom: true,
      );
    });

    testWidgets('reset', (WidgetTester tester) async {
      final Map<String, dynamic>? measured = cell('reset');
      if (measured == null) {
        markTestSkipped('run tool/measure_auth.mjs --route reset first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpAt(tester, LumeAuthRoute.reset);

      // D19 — this screen's content overflows 844, and the reference's panel
      // is a flex column, so the header *shrinks* from 60 to its 48 minimum
      // and the back control slides 6 up inside it. Everything below moves 12
      // with it. Flutter scrolls instead of compressing, so the chrome is
      // compared on the screens where the reference is not shrinking it.
      chromeNote(tester, b);
      const String shifted =
          'shifted 12 by the compressed header above it (D19)';
      compare(
        tester,
        b,
        'auth.visual',
        find.byKey(LumeAuthKeys.visual),
        tolerance: 13,
        note: shifted,
      );
      compare(
        tester,
        b,
        'auth.form',
        find.byKey(LumeAuthKeys.form),
        tolerance: 13,
        note: shifted,
      );
      compare(
        tester,
        b,
        'auth.pwmeter',
        find.byType(LumePasswordMeter),
        tolerance: 13,
        note: shifted,
      );
      compare(
        tester,
        b,
        'auth.pwrules',
        find.byType(LumePasswordRules),
        tolerance: 13,
        note: shifted,
      );
      compare(
        tester,
        b,
        'auth.submit',
        find.byType(LumeAuthSubmit),
        tolerance: 13,
        note: shifted,
      );
    });
  });

  group('the status screens', () {
    for (final (String state, LumeAuthRoute route, String label)
        in <(String, LumeAuthRoute, String)>[
          ('updated', LumeAuthRoute.updated, 'password updated'),
          ('created', LumeAuthRoute.created, 'account created'),
          ('expired', LumeAuthRoute.expired, 'session expired'),
          ('trouble', LumeAuthRoute.trouble, 'that link did not work'),
        ]) {
      testWidgets(label, (WidgetTester tester) async {
        final Map<String, dynamic>? measured = cell(state);
        if (measured == null) {
          markTestSkipped('run tool/measure_auth.mjs --route $state first');
          return;
        }
        final Map<String, dynamic> b =
            measured['bounds'] as Map<String, dynamic>;
        // The expiry screen was measured with no account behind it, which is
        // the state the driver could reach: `pendingUser()` was null, so the
        // masked address line is not in the capture. Comparing the named
        // variant would be comparing one more line of text.
        await pumpAt(tester, route, named: route != LumeAuthRoute.expired);

        final bool hasBack = route == LumeAuthRoute.trouble;
        chrome(tester, b, brand: false, back: hasBack);
        compare(tester, b, 'auth.visual', find.byKey(LumeAuthKeys.visual));
        compare(tester, b, 'auth.seal', find.byKey(LumeAuthKeys.seal));
        compare(
          tester,
          b,
          'auth.actions',
          find.byKey(LumeAuthKeys.actions),
          fromBottom: true,
        );
        compare(
          tester,
          b,
          'auth.submit',
          find.byType(LumeAuthSubmit),
          fromBottom: true,
        );
      });
    }

    testWidgets('verification', (WidgetTester tester) async {
      final Map<String, dynamic>? measured = cell('verify');
      if (measured == null) {
        markTestSkipped('run tool/measure_auth.mjs --route verify first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpAt(tester, LumeAuthRoute.verify);

      chrome(tester, b, brand: false);
      compare(tester, b, 'auth.visual', find.byKey(LumeAuthKeys.visual));
      compare(tester, b, 'auth.form', find.byKey(LumeAuthKeys.form));
      compare(tester, b, 'auth.field.first', fieldAt(0));
      compare(tester, b, 'auth.submit', find.byType(LumeAuthSubmit));
    });
  });

  tearDownAll(() {
    final StringBuffer out = StringBuffer()
      ..writeln('# Authentication bounds, measured against the design source')
      ..writeln()
      ..writeln(
        'Written by `test/features/auth/auth_bounds_test.dart`. Every row is '
        '`getBoundingClientRect` from the running prototype beside '
        '`tester.getRect` from the Flutter screen in the same state, at '
        '390 × 844, light, English.',
      )
      ..writeln()
      ..writeln(
        '`y` is measured from the panel\'s own origin on both sides: the '
        'prototype draws a 28-point simulated status bar and sits its screen '
        'below it (P1), and the Flutter flow covers the shell and has no such '
        'bar (D18). Comparing page coordinates would compare two origins.',
      )
      ..writeln()
      ..writeln('**$compared values compared**, tolerance $kTolerance px.')
      ..writeln()
      ..writeln('| element | axis | prototype | Flutter | Δ | note |')
      ..writeln('|---|---|---|---|---|---|');
    for (final String row in rows) {
      out.writeln(row);
    }
    File(reportPath).writeAsStringSync(out.toString());
  });
}
