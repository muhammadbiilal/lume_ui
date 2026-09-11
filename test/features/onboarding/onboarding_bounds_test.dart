/// Where every element sits, compared with where the prototype puts it.
///
/// `onboarding_screen_test.dart` asserts a component's own box; this asserts
/// its **position on the screen**, against
/// `measurements/onboarding_step*_390x844_light_en.json` — bounds read from the
/// running flow with `getBoundingClientRect`.
///
/// All nine steps, each driven through `LumeOnboardingFlow` so the thing
/// measured is the composition the application shows rather than a step widget
/// mounted on its own.
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
import 'package:lume/core/widgets/lume/lume_text.dart';
import 'package:lume/features/onboarding/data/country_fixture.dart';
import 'package:lume/features/onboarding/data/interests_fixture.dart';
import 'package:lume/features/onboarding/presentation/country_screen.dart';
import 'package:lume/features/onboarding/presentation/interests_screen.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/presentation/onboarding_art.dart';
import 'package:lume/features/onboarding/presentation/onboarding_chrome.dart';
import 'package:lume/features/onboarding/presentation/onboarding_flow.dart';
import 'package:lume/features/onboarding/presentation/onboarding_parts.dart';

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

  /// Differences found in the test that is running, emptied after each one.
  final List<String> misses = <String>[];

  tearDown(() {
    final List<String> found = List<String>.of(misses);
    misses.clear();
    expect(found, isEmpty, reason: 'element bounds differ from the prototype');
  });

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
    double tolerance = kTolerance,
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
      // Collected rather than thrown, so one run reports every difference
      // instead of stopping at the first. `tearDown` turns the list into the
      // failure.
      if ((got - wanted).abs() > tolerance) {
        misses.add(
          '$name $what — the prototype puts it at '
          '${wanted.toStringAsFixed(2)}, Flutter at ${got.toStringAsFixed(2)} '
          '(${(got - wanted).toStringAsFixed(2)})',
        );
      }
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

  /// The flow at one step, on the primary cell.
  Future<void> pumpStep(
    WidgetTester tester,
    int step, {
    bool islamic = false,
    String name = '',
  }) => pumpLume(
    tester,
    LumeOnboardingFlow(
      countries: countries,
      catalogue: interests,
      store: LumeMemoryOnboardingStore(
        LumeProfileRecord(islamic: islamic, displayName: name),
      ),
      initialStep: step,
    ),
    surface: const Size(390, 844),
  );

  /// The heading's own block. `.onb__title` fills the 350-wide column; the
  /// balanced `Text` inside it is narrower by design, so the block is what the
  /// prototype's element corresponds to.
  Finder titled(String text) => find.ancestor(
    of: find.text(text),
    matching: find.byType(LumeBalancedText),
  );

  /// The chrome every step shares. Skip is compared even on the last step:
  /// `.onb__skip[disabled]` is `opacity: 0`, so the prototype still reserves
  /// its width and the progress bar is the same 257.11 throughout.
  void chrome(WidgetTester tester, Map<String, dynamic> b) {
    compare(tester, b, 'onb.nav', find.byKey(LumeOnboardingKeys.backCircle));
    compare(tester, b, 'onb.skip', find.byKey(LumeOnboardingKeys.skipLabel));
    compare(tester, b, 'onb.progress', find.byType(LumeOnboardingProgress));
  }

  group('step 0 — welcome', () {
    final Map<String, dynamic>? measured = web(0);

    testWidgets('brand, stage, copy and the two actions', (
      WidgetTester tester,
    ) async {
      if (measured == null) {
        markTestSkipped('run tool/measure_onboarding.mjs --step 0 first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpStep(tester, LumeOnboardingStep.welcome);

      chrome(tester, b);
      compare(tester, b, 'onb.art', find.byType(LumeOnboardingArt));
      compare(
        tester,
        b,
        'onb.brand',
        find.byType(LumeOnboardingBrand),
        // The 20 below the brand is `margin-bottom` in CSS and padding inside
        // the widget, so the widget's box is 20 taller for the same layout.
        checkHeight: false,
        note: '`.onb__brand`, whose 20 margin is inside the widget',
      );
      compare(
        tester,
        b,
        'onb.title',
        titled('Everything your day needs, quietly organised.'),
        note: '`text-wrap: balance`',
      );
      compare(
        tester,
        b,
        'onb.text',
        find.textContaining('without the clutter'),
      );
      compare(tester, b, 'onb.continue', find.byType(LumeOnboardingContinue));
      compare(
        tester,
        b,
        'onb.link',
        find.byType(LumeOnboardingLink),
        // 36 drawn, 44 targeted: the box is 8 taller and starts 4 higher, and
        // the text inside it is exactly where the prototype puts it. D16.
        checkY: false,
        checkHeight: false,
        note: 'the sign-in link — D16',
      );
    });

    testWidgets('the balanced title wraps to the prototype two lines', (
      WidgetTester tester,
    ) async {
      if (measured == null) return;
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpStep(tester, LumeOnboardingStep.welcome);
      final int webLines =
          (b['onb.title'] as Map<String, dynamic>)['lines'] as int;
      final int lines = lineCountOf(
        tester,
        find.text('Everything your day needs, quietly organised.'),
      );
      expect(lines, webLines);
      rows.add('| `onb.title` | lines | $webLines | $lines | = | balanced |');
    });
  });

  group('steps 1 and 2 — the two value slides', () {
    for (final (int step, String title, String tail) in <(int, String, String)>[
      (
        LumeOnboardingStep.plan,
        'Your day, laid out before it starts',
        'already in the right place',
      ),
      (
        LumeOnboardingStep.tools,
        '85-odd tools, one or two taps away',
        'so you never hunt for them',
      ),
    ]) {
      testWidgets('step $step — stage, kicker, title, text', (
        WidgetTester tester,
      ) async {
        final Map<String, dynamic>? measured = web(step);
        if (measured == null) {
          markTestSkipped('run tool/measure_onboarding.mjs --step $step first');
          return;
        }
        final Map<String, dynamic> b =
            measured['bounds'] as Map<String, dynamic>;
        await pumpStep(tester, step);

        chrome(tester, b);
        compare(tester, b, 'onb.art', find.byType(LumeOnboardingArt));
        compare(tester, b, 'onb.title', titled(title));
        compare(tester, b, 'onb.text', find.textContaining(tail));
        compare(tester, b, 'onb.continue', find.byType(LumeOnboardingContinue));
      });
    }
  });

  group('step 3 — the country step sits where the prototype puts it', () {
    final Map<String, dynamic>? measured = web(3);

    testWidgets('chrome, lead and list', (WidgetTester tester) async {
      if (measured == null) {
        markTestSkipped('run tool/measure_onboarding.mjs --step 3 first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpStep(tester, LumeOnboardingStep.country);

      chrome(tester, b);
      compare(tester, b, 'onb.kicker', find.text('MAKE IT LOCAL'));
      compare(tester, b, 'onb.title', titled('Where are you based?'));
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
      await pumpStep(tester, LumeOnboardingStep.country);
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

  group('step 4 — the city step', () {
    final Map<String, dynamic>? measured = web(4);

    testWidgets('chrome, lead, search and list', (WidgetTester tester) async {
      if (measured == null) {
        markTestSkipped('run tool/measure_onboarding.mjs --step 4 first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpStep(tester, LumeOnboardingStep.city);

      chrome(tester, b);
      compare(
        tester,
        b,
        'onb.kicker',
        find.text('PAKISTAN'),
        note: 'the country name, not a fixed word',
      );
      compare(tester, b, 'onb.title', titled('Which city are you in?'));
      compare(tester, b, 'onb.text', find.textContaining('anything local'));
      compare(tester, b, 'locsearch', find.byType(LumeSearchField));
      compare(tester, b, 'onb.continue', find.byType(LumeOnboardingContinue));
    });
  });

  group('step 5 — the interests step sits where the prototype puts it', () {
    final Map<String, dynamic>? measured = web(5);

    testWidgets('chrome, lead, bar and chips', (WidgetTester tester) async {
      if (measured == null) {
        markTestSkipped('run tool/measure_onboarding.mjs --step 5 first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpStep(tester, LumeOnboardingStep.interests);

      chrome(tester, b);
      compare(tester, b, 'onb.kicker', find.text('MAKE IT YOURS'));
      compare(tester, b, 'onb.title', titled('What are you here for?'));
      compare(tester, b, 'onb.text', find.textContaining('Pick 5 to 10'));
      compare(tester, b, 'picker.count', find.text('0 of 5 minimum'));
      compare(tester, b, 'pickgroup.label.first', find.text('EVERYDAY LIFE'));
      compare(
        tester,
        b,
        'pick.first',
        find.byType(LumeInterestChip),
        note: 'the chip width follows its label metrics',
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

  group('step 6 — set it up once', () {
    testWidgets('stage, copy, permission rows and the note', (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic>? measured = web(6);
      if (measured == null) {
        markTestSkipped('run tool/measure_onboarding.mjs --step 6 first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpStep(tester, LumeOnboardingStep.setUp);

      chrome(tester, b);
      compare(tester, b, 'onb.art', find.byType(LumeOnboardingArt));
      compare(tester, b, 'onb.title', titled('Set it up once'));
      compare(tester, b, 'onb.text', find.textContaining('Two permissions'));
      compare(
        tester,
        b,
        'onb.rows',
        find.byKey(LumeOnboardingKeys.rows),
        // Two rows of two-line subtitles. Skia rounds a line box to whole
        // pixels where Blink keeps 1/64ths, so 15.390625 becomes 15 and the
        // pair is 1.56 short. P7, compounded — not a spacing difference.
        tolerance: 2,
        note: 'two rounded line boxes — P7',
      );
      compare(
        tester,
        b,
        'onb.row.first',
        find.byType(LumeOnboardingToggleRow).first,
      );
      compare(
        tester,
        b,
        'onb.row.title',
        find.text('Use your location'),
        // `.onb-row__title` is `display: block` and fills the row's body; a
        // `Text` shrinks to its glyphs. Same origin, different width.
        checkWidth: false,
      );
      compare(
        tester,
        b,
        'onb.row.sub',
        find.textContaining('local services and nearby places'),
      );
      compare(tester, b, 'onb.continue', find.byType(LumeOnboardingContinue));
      compare(tester, b, 'onb.note', find.byType(LumeOnboardingNote));
    });

    testWidgets('the method block, once the experience is on', (
      WidgetTester tester,
    ) async {
      final File f = File(
        'docs/conversion_archive/measurements/'
        'onboarding_step6_390x844_light_en_faith.json',
      );
      if (!f.existsSync()) {
        markTestSkipped('run measure_onboarding.mjs --step 6 --faith 1 first');
        return;
      }
      final Map<String, dynamic> b =
          (jsonDecode(f.readAsStringSync()) as Map<String, dynamic>)['bounds']
              as Map<String, dynamic>;
      await pumpStep(tester, LumeOnboardingStep.setUp, islamic: true);

      compare(
        tester,
        b,
        'onb.row.sub',
        find.textContaining('For prayer times, Qibla'),
        note: 'the subtitle changes with the preference',
      );
      compare(
        tester,
        b,
        'onb.methodLabel',
        find.text('PRAYER CALCULATION METHOD'),
        // Sits below the same two rounded subtitles — see `onb.rows`.
        tolerance: 2,
        note: '`.group-label`, uppercased in CSS; P7 above it',
      );
      compare(
        tester,
        b,
        'onb.choice',
        find.descendant(
          of: find.byType(LumeOnboardingChoice),
          matching: find.byType(Wrap),
        ),
        // 34-point pills in 44-point targets: the runs sit 10 apart rather
        // than 7, so the block is taller. See D15. Its position carries the
        // same P7 rounding as the rows above it.
        checkHeight: false,
        tolerance: 2,
        note: 'D15 — 44 px targets widen the run gap',
      );
    });
  });

  group('step 7 — what should we call you', () {
    final Map<String, dynamic>? measured = web(7);

    testWidgets('stage, copy, field and the two actions', (
      WidgetTester tester,
    ) async {
      if (measured == null) {
        markTestSkipped('run tool/measure_onboarding.mjs --step 7 first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpStep(tester, LumeOnboardingStep.name);

      chrome(tester, b);
      compare(tester, b, 'onb.art', find.byType(LumeOnboardingArt));
      compare(tester, b, 'onb.kicker', find.text('ONE LAST THING'));
      compare(tester, b, 'onb.title', titled('What should we call you?'));
      compare(tester, b, 'onb.text', find.textContaining('skip it entirely'));
      compare(tester, b, 'onb.field', find.byType(LumeToolField));
      compare(tester, b, 'onb.continue', find.byType(LumeOnboardingContinue));
      compare(
        tester,
        b,
        'onb.skipStep',
        find.byType(LumeOnboardingLink),
        checkY: false,
        checkHeight: false,
        note: 'Skip for now — D16',
      );
      compare(tester, b, 'onb.note', find.byType(LumeOnboardingNote));
    });
  });

  group('step 8 — done', () {
    final Map<String, dynamic>? measured = web(8);

    testWidgets('the seal, the copy and the finish', (
      WidgetTester tester,
    ) async {
      if (measured == null) {
        markTestSkipped('run tool/measure_onboarding.mjs --step 8 first');
        return;
      }
      final Map<String, dynamic> b = measured['bounds'] as Map<String, dynamic>;
      await pumpStep(tester, LumeOnboardingStep.done);

      chrome(tester, b);
      compare(tester, b, 'onb.art', find.byType(LumeOnboardingArt));
      compare(tester, b, 'onb.kicker', find.text('ALL SET'));
      compare(tester, b, 'onb.continue', find.byType(LumeOnboardingContinue));
      compare(tester, b, 'onb.note', find.byType(LumeOnboardingNote));
    });

    testWidgets('Skip keeps its width even where it cannot be pressed', (
      WidgetTester tester,
    ) async {
      if (measured == null) return;
      await pumpStep(tester, LumeOnboardingStep.done);
      // `.onb__skip[disabled] { opacity: 0 }` — the control is invisible and
      // inert, and still holds the top row's shape, which is why the progress
      // bar is 257.11 on every step rather than growing on the last.
      expect(
        tester.getSize(find.byKey(LumeOnboardingKeys.skipLabel)).width,
        closeTo(
          ((measured['bounds'] as Map<String, dynamic>)['onb.skip']
                  as Map<String, dynamic>)['width']
              as num,
          kTolerance,
        ),
      );
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
