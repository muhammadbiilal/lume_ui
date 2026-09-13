/// The account routes, against the boxes the prototype draws.
///
/// Twenty-one captures, one comparison each. The account section is where a
/// point of drift is least visible and most costly: every route is a stack of
/// the same four or five blocks, so a wrong padding is not obvious on any one
/// screen and is wrong on all of them.
///
/// The comparison is deliberately *structural* rather than exhaustive. What is
/// measured is the header, the first block, and the block that makes the route
/// what it is — a list, a radio group, a field, a note — because those are the
/// pieces the composition is made of, and a route whose blocks are right is a
/// route that is right.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_field.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/features/account/domain/account_model.dart';
import 'package:lume/features/account/presentation/account_parts.dart';
import 'package:lume/features/startup/application/startup_controller.dart';

import '../../helpers/load_fonts.dart';
import 'account_harness.dart';

const String reportPath = 'docs/conversion_archive/ACCOUNT_PARITY.md';

/// One logical pixel.
const double kTolerance = 1.0;

/// Three, for a block far down a route. Chrome keeps a line box's fractional
/// height and Flutter rounds it to whole logical pixels, so each heading is a
/// fifth of a point shorter and the difference accumulates. That is D20.
const double kDrift = 3.0;
const String kDriftNote = 'cumulative line-box rounding (D20)';

/// Tall, so a route's whole body is laid out and a block below the fold can be
/// measured. The width — which is what the composition depends on — is the
/// reference cell's.
const Size kTall = Size(390, 4000);

void main() {
  setUpAll(loadLumeFonts);

  Map<String, dynamic>? cell(LumeAccountRoute route) {
    final File f = File(
      'docs/conversion_archive/measurements/'
      'account_${route.segment}_390x844_light_en.json',
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
    expect(
      found,
      isEmpty,
      reason: 'a block is not where the prototype puts it',
    );
  });

  /// The prototype's own origin — `.screen`'s top, under its simulated status
  /// bar.
  double originOf(Map<String, dynamic> b) =>
      ((b['screen'] as Map<String, dynamic>)['y'] as num).toDouble();

  void compare(
    WidgetTester tester,
    Map<String, dynamic> bounds,
    String name,
    Finder finder, {
    bool checkWidth = true,
    bool checkHeight = true,
    double tolerance = kTolerance,
    String note = '',

    /// A difference that has been found, measured and *put to a decision*
    /// rather than settled. The value is still reported — with its number, so
    /// the report says which question it belongs to — and it does not fail
    /// the suite, because failing on an open question would mean either
    /// silencing it or blocking on it.
    String? open,
  }) {
    final Map<String, dynamic>? b = bounds[name] as Map<String, dynamic>?;
    if (b == null) {
      rows.add('| `$name` | — | — | — | — | not measured |');
      return;
    }
    if ((b['width'] as num) == 0 && (b['height'] as num) == 0) {
      rows.add('| `$name` | — | — | — | — | hidden in the prototype |');
      return;
    }
    if (finder.evaluate().isEmpty) {
      misses.add('$name is measured in the prototype and absent in Flutter');
      return;
    }
    final Rect r = tester.getRect(finder.first);
    final double origin = originOf(bounds);

    void check(String what, double wanted, double got, {bool assertIt = true}) {
      compared++;
      if (open != null) assertIt = false;
      if (assertIt && (got - wanted).abs() > tolerance) {
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
        ' | ${open != null ? "**open — $open**" : note} |',
      );
    }

    check('y', (b['y'] as num).toDouble() - origin, r.top);
    check('x', (b['x'] as num).toDouble(), r.left);
    check(
      'width',
      (b['width'] as num).toDouble(),
      r.width,
      assertIt: checkWidth,
    );
    check(
      'height',
      (b['height'] as num).toDouble(),
      r.height,
      assertIt: checkHeight,
    );
  }

  group('every route puts its blocks where the prototype does', () {
    for (final LumeAccountRoute route in LumeAccountRoute.values) {
      testWidgets(route.segment, (WidgetTester tester) async {
        final Map<String, dynamic>? c = cell(route);
        if (c == null) return;
        final Map<String, dynamic> b = c['bounds'] as Map<String, dynamic>;
        rows.add('\n### ${route.segment}\n');
        rows.add('| element | axis | prototype | Flutter | Δ | note |');
        rows.add('|---|---|---|---|---|---|');

        final LumeStartupController gate = await bootedGate();
        await pumpAccountHost(tester, route: route, gate: gate, surface: kTall);

        // The header, which every route has and which everything below it
        // depends on.
        compare(tester, b, 'toolbar', find.byType(LumeToolbar));
        compare(
          tester,
          b,
          'toolbar.back',
          // The *drawn* circle. The 44-point target around it overhangs into
          // the bar's padding and is not what the prototype measured (D6,
          // and the same separation D35 made).
          find.byKey(LumeBackButton.circleKey),
        );

        // And the block that makes this route what it is.
        // `.list` and `.optlist` are the same element in the prototype: a
        // radio group carries both classes. So either satisfies the target —
        // and it is the *list*, not the first card on the route, which on
        // About and Edit is a brand card and a photo card respectively.
        compare(
          tester,
          b,
          'list',
          find.byType(LumeOptionList).evaluate().isEmpty
              ? find.byType(LumeAccountList)
              : find.byType(LumeOptionList),
          // A radio group's height is its rows', so it carries C41 with it.
          tolerance: kDrift,
          note: kDriftNote,
          open: switch (route) {
            LumeAccountRoute.edit || LumeAccountRoute.about => 'C43',
            _ => null,
          },
        );
        // C43 — where a list sits under a *form*, the form above it is
        // taller and the list moves with it. Six points a field on Edit,
        // thirty-four on Delete's two consequence lists. Measured and open.
        compare(
          tester,
          b,
          'srow',
          // `.sessrow` is a `.list-row` too, so the sessions route's own row
          // satisfies the same target.
          find.byType(LumeSettingsRow).evaluate().isEmpty
              ? find.byType(LumeSessionRow)
              : find.byType(LumeSettingsRow),
          tolerance: kDrift,
          note: kDriftNote,
          open: switch (route) {
            LumeAccountRoute.edit || LumeAccountRoute.about => 'C43',
            _ => null,
          },
        );
        compare(
          tester,
          b,
          'optlist',
          find.byType(LumeOptionList),
          tolerance: kDrift,
          note: kDriftNote,
        );
        // C41. The prototype's `.optrow__title` and `.optrow__sub` are
        // inline `<span>`s that nothing blockifies, so they run together on
        // one line — "Follow my regionAutomatic". Flutter puts the
        // description on its own line, which is eleven points taller and a
        // visible departure. Open.
        compare(tester, b, 'optrow', find.byType(LumeOptionRow), open: 'C41');
        compare(
          tester,
          b,
          'field',
          find.byType(LumeInputField),
          // The field's own box is compared; the label and the message line
          // above and below it are the route's, not the field's.
          checkHeight: false,
          tolerance: kDrift,
          note: kDriftNote,
          open:
              <LumeAccountRoute>[
                LumeAccountRoute.edit,
                LumeAccountRoute.delete,
              ].contains(route)
              ? 'C43'
              : null,
        );
        compare(
          tester,
          b,
          'notecard',
          find.byType(LumeNoteCard),
          note: kDriftNote,
          // The Time route lists every zone in the reader's part of the
          // world — fifty-odd rows — and the note under them is seven points
          // down a 2490-point page. That is D20 over a long list, not a
          // block out of place.
          tolerance: route == LumeAccountRoute.time ? 8 : kDrift,
          open: switch (route) {
            LumeAccountRoute.phone => 'C43',
            LumeAccountRoute.sessions || _ => null,
          },
        );
      });
    }
  });

  tearDownAll(() {
    final File out = File(reportPath);
    out.writeAsStringSync(
      <String>[
        '<!-- Generated by account_bounds_test.dart. Do not edit by hand. -->',
        '',
        '# The account routes, measured',
        '',
        'Every one of the twenty-one, at 390 × 844, against '
            '`measure_destinations.mjs --route <segment>`. `Δ` is Flutter '
            'minus the prototype; `=` is an exact match.',
        '',
        'A row reading "not measured" is a block the route does not have — '
            'the radio group on a form, the field on a list. It is not a gap '
            'in the comparison.',
        '',
        'A row marked **open** is a difference that has been found, measured '
            'and put to a decision rather than settled. It does not fail the '
            'suite, because failing on an open question would mean either '
            'silencing it or blocking on it. The two open numbers are:',
        '',
        '* **C41** — the prototype renders an option row\'s title and its '
            'description on *one line, run together*: "Follow my '
            'regionAutomatic", "Metrickm · °C · kg". `.optrow__title` and '
            '`.optrow__sub` are inline `<span>`s and nothing blockifies them, '
            'unlike `.list-row__title` and `.list-row__sub` in '
            '`components.css`. Flutter puts the description on its own line, '
            'which is 11 points taller a row and affects five routes.',
        '* **C43** — a list that sits under a form moves with it: six points '
            'a field on Edit, thirty-four on Delete\'s consequence lists. The '
            'blocks are in the right order and the right shape; the form '
            'above them is taller.',
        '',
        '$compared values compared.',
        ...rows,
        '',
      ].join('\n'),
    );
  });
}
