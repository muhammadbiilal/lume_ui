/// Where every element sits, compared with where the prototype puts it.
///
/// `onboarding_screen_test.dart` asserts a component's own box; this asserts
/// its **position on the screen**, against
/// `measurements/onboarding_step*_390x844_light_en.json` — bounds read from the
/// running flow with `getBoundingClientRect`.
///
/// This is the test that catches the differences a box measurement cannot: a
/// missing ten points of lead padding, a paragraph that wraps to four lines
/// instead of three, a footer that sits eighteen above its button in one engine
/// and twenty-two in the other.
///
/// It also writes `docs/conversion_archive/ONBOARDING_PARITY.md`, so the
/// comparison is reviewable rather than only green.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/features/onboarding/data/country_fixture.dart';
import 'package:lume/features/onboarding/data/interests_fixture.dart';
import 'package:lume/features/onboarding/presentation/country_screen.dart';
import 'package:lume/features/onboarding/presentation/interests_screen.dart';
import 'package:lume/features/onboarding/presentation/onboarding_chrome.dart';
import 'package:lume/features/onboarding/presentation/onboarding_steps.dart';

import '../../helpers/capture.dart';
import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

const String reportPath = 'docs/conversion_archive/ONBOARDING_PARITY.md';

/// How far a position may differ before it is a difference rather than
/// rasterisation. One logical pixel: Skia and Blink round a half-pixel the
/// other way often enough that zero would be noise, and two would hide a real
/// one-pixel shift compounding down a column.
const double kTolerance = 1.0;

void main() {
  setUpAll(loadLumeFonts);

  final LumeCountryFixture countries = LumeCountryFixture.parse(
    File('assets/data/countries.json').readAsStringSync(),
  );
  final LumeInterestsFixture interests = LumeInterestsFixture.parse(
    File('assets/data/interests.json').readAsStringSync(),
  );

  Map<String, dynamic>? web(int step) {
    final File f = File(
      'docs/conversion_archive/measurements/'
      'onboarding_step${step}_390x844_light_en.json',
    );
    if (!f.existsSync()) return null;
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  }

  final List<String> rows = <String>[];

  /// Compares one element's geometry and records the row.
  void compare(
    WidgetTester tester,
    Map<String, dynamic> bounds,
    String name,
    Finder finder, {
    bool checkY = true,
    bool checkX = true,
    bool checkWidth = true,
    bool checkHeight = true,
    String note = '',
  }) {
    final Map<String, dynamic>? b = bounds[name] as Map<String, dynamic>?;
    if (b == null) {
      rows.add('| $name | — | — | not measured |');
      return;
    }
    expect(finder, findsWidgets, reason: '$name is not on screen');
    final Rect r = tester.getRect(finder.first);

    void check(String what, double wanted, double got) {
      expect(
        got,
        closeTo(wanted, kTolerance),
        reason:
            '$name $what — the prototype puts it at $wanted, Flutter at $got',
      );
      rows.add(
        '| `$name` | $what | '
        '${wanted.toStringAsFixed(2)} | ${got.toStringAsFixed(2)} | '
        '${(got - wanted).abs() < 0.005 ? "=" : (got - wanted).toStringAsFixed(2)} '
        '| ${note.isEmpty ? "" : note} |',
      );
    }

    if (checkY) check('y', (b['y'] as num).toDouble(), r.top);
    if (checkX) check('x', (b['x'] as num).toDouble(), r.left);
    if (checkWidth) check('width', (b['width'] as num).toDouble(), r.width);
    if (checkHeight) check('height', (b['height'] as num).toDouble(), r.height);
  }

  group('the country step sits where the prototype puts it', () {
    final Map<String, dynamic>? measured = web(3);

    testWidgets('chrome, lead and list', (WidgetTester tester) async {
      if (measured == null) {
        markTestSkipped('run tool/measure_onboarding.mjs --step 3 first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;

      await pumpLume(
        tester,
        CountryStep(
          countries: countries,
          onBack: () {},
          onSkip: () {},
          onContinue: (_) {},
        ),
        surface: const Size(390, 844),
      );

      // The visible circle, not its 44 px target — the two differ on purpose.
      compare(tester, b, 'onb.nav', find.byKey(LumeOnboardingKeys.backCircle));
      compare(tester, b, 'onb.skip', find.byKey(LumeOnboardingKeys.skipLabel));
      compare(tester, b, 'onb.progress', find.byType(LumeOnboardingProgress));
      compare(tester, b, 'onb.kicker', find.text('MAKE IT LOCAL'));
      compare(tester, b, 'onb.title', find.text('Where are you based?'));
      compare(
        tester,
        b,
        'onb.text',
        find.textContaining('It says nothing about who you are'),
        note: 'the 30ch measure',
      );
      compare(
        tester,
        b,
        'locsearch',
        find.byType(LumeSearchField),
        note: '`.search--sm`',
      );
      compare(tester, b, 'locgroup.first', find.text('POPULAR'));
      compare(
        tester,
        b,
        'locrow.first',
        find.byType(LumeCountryRow),
        // The web list is one element with a 1 px border the rows sit inside;
        // Flutter clips the rows to the same rounded box, so the first row
        // starts one pixel higher and one narrower. Compared as a height.
        checkY: false,
        checkX: false,
        checkWidth: false,
        note: 'the list border rounds the other way',
      );
      compare(tester, b, 'onb.continue', find.byType(LumeOnboardingContinue));
    });

    testWidgets('the supporting text wraps to the same three lines', (
      WidgetTester tester,
    ) async {
      if (measured == null) return;
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpLume(
        tester,
        CountryStep(countries: countries, onBack: () {}, onSkip: () {}),
        surface: const Size(390, 844),
      );
      final int webLines =
          (b['onb.text'] as Map<String, dynamic>)['lines'] as int;
      expect(webLines, 3, reason: 'the prototype wraps it to three');

      final int lines = lineCountOf(
        tester,
        find.textContaining('It says nothing about who you are'),
      );
      expect(lines, webLines, reason: 'the same wrap, not merely the same cap');
      rows.add('| `onb.text` | lines | $webLines | $lines | = | wrapping |');
    });
  });

  group('the interests step sits where the prototype puts it', () {
    final Map<String, dynamic>? measured = web(5);

    testWidgets('chrome, lead, bar and chips', (WidgetTester tester) async {
      if (measured == null) {
        markTestSkipped('run tool/measure_onboarding.mjs --step 5 first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;

      await pumpLume(
        tester,
        InterestsStep(
          catalogue: interests,
          onBack: () {},
          onSkip: () {},
          onContinue: (Set<String> s, bool i) {},
        ),
        surface: const Size(390, 844),
      );

      compare(tester, b, 'onb.nav', find.byKey(LumeOnboardingKeys.backCircle));
      compare(tester, b, 'onb.kicker', find.text('MAKE IT YOURS'));
      compare(tester, b, 'onb.title', find.text('What are you here for?'));
      compare(tester, b, 'onb.text', find.textContaining('Pick 5 to 10'));
      compare(tester, b, 'picker.count', find.text('0 of 5 minimum'));
      compare(tester, b, 'pickgroup.label.first', find.text('EVERYDAY LIFE'));
      compare(
        tester,
        b,
        'pick.first',
        find.byType(LumeInterestChip),
        note: 'the chip’s own width follows its label’s metrics',
        checkWidth: false,
      );
      compare(tester, b, 'onb.continue', find.byType(LumeOnboardingContinue));
    });

    testWidgets('the progress bar is six of nine here, four on country', (
      WidgetTester tester,
    ) async {
      if (measured == null) return;
      final Map<String, dynamic> p =
          measured['progress'] as Map<String, dynamic>;
      expect(p['total'], 9);
      expect(
        p['done'],
        LumeOnboardingStep.interests + 1,
        reason: 'segments up to and including the current one',
      );
      final Map<String, dynamic>? country = web(3);
      if (country != null) {
        expect(
          (country['progress'] as Map<String, dynamic>)['done'],
          LumeOnboardingStep.country + 1,
        );
      }
    });
  });

  tearDownAll(() {
    if (rows.isEmpty) return;
    final StringBuffer out = StringBuffer()
      ..writeln('# Onboarding parity, element by element')
      ..writeln()
      ..writeln(
        '> **Temporary conversion evidence. Not part of the final Flutter '
        'maintenance\n> specification.** This document describes the browser '
        'prototype that Lume is\n> being converted *from*, and is removed or '
        'relabelled as historical at Phase F9.\n> The authoritative documents '
        'for the Flutter application are `claude.md`, `README.md`\n> and the '
        'rewritten `LUME_*` specifications.',
      )
      ..writeln()
      ..writeln(
        'Generated by `test/features/onboarding/onboarding_bounds_test.dart`. '
        'The **web**\ncolumn is `getBoundingClientRect` read from the running '
        'first-run flow at\n390 × 844, light, English — driven to the step by '
        'pressing its own Continue,\nnot by setting classes. The **Flutter** '
        'column is the rendered widget measured\nin the same units. Tolerance '
        'is ${kTolerance.toStringAsFixed(0)} logical pixel.',
      )
      ..writeln()
      ..writeln('| Element | Property | Web | Flutter | Δ | Note |')
      ..writeln('|---|---|---|---|---|---|');
    for (final String r in rows) {
      out.writeln(r);
    }
    out
      ..writeln()
      ..writeln('${rows.length} values compared.')
      ..writeln()
      ..writeln(
        'Not compared: the simulated status bar, the stage and the device '
        'frame — see\n[KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md) P1, P5 and '
        'D11.',
      );
    File(reportPath).writeAsStringSync(out.toString());
  });
}
