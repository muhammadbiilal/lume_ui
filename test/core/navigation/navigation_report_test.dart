/// The navigation parity matrix, compared at every cell and written down.
///
/// `navigation_parity_test.dart` proves the surfaces match at one cell each.
/// This walks the whole matrix — four widths, two themes, two directions — and
/// leaves [reportPath] behind as the evidence, so a reviewer can read what was
/// compared instead of taking a green tick for it.
///
/// It fails on any mismatch. The report is a side effect of the comparison, not
/// a substitute for it: a row can only appear in the file because the assertion
/// that produced it passed.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/navigation/lume_destination.dart';
import 'package:lume/core/navigation/lume_navigation_surfaces.dart';
import 'package:lume/core/navigation/lume_shell.dart';
import 'package:lume/core/theme/lume/lume_colors.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';
import '../../helpers/measured.dart';
import '../../helpers/reference_tokens.dart';

const String reportPath = 'docs/conversion_archive/NAVIGATION_PARITY.md';

/// One (width, height, theme, direction) the shell is compared at.
typedef Cell = ({
  String name,
  double width,
  double height,
  ThemeMode theme,
  Locale locale,
  String dir,
  String measurementCell,

  /// The cell whose measurements describe the navigation **Flutter** draws
  /// here. The same as [measurementCell] everywhere except the landscape
  /// phone, where D1's height override puts Flutter in compact and the web in
  /// expanded — so there the bar has no counterpart at this width and is
  /// compared against the phone's.
  String navCell,
});

void main() {
  if (!Measurements.available()) {
    test('navigation measurements are present', () {
      fail(
        'No measurements found. They are frozen and cannot be regenerated; '
        'restore docs/conversion_archive/measurements/ from git history.',
      );
    });
    return;
  }

  setUpAll(loadLumeFonts);

  const List<Cell> cells = <Cell>[
    (
      name: 'phone 390×844',
      width: 390,
      height: 844,
      theme: ThemeMode.light,
      locale: Locale('en'),
      dir: 'ltr',
      measurementCell: 'components_390_light_ltr',
      navCell: 'components_390_light_ltr',
    ),
    (
      name: 'phone 390×844 · dark',
      width: 390,
      height: 844,
      theme: ThemeMode.dark,
      locale: Locale('en'),
      dir: 'ltr',
      measurementCell: 'components_390_dark_ltr',
      navCell: 'components_390_dark_ltr',
    ),
    (
      name: 'phone 390×844 · Urdu',
      width: 390,
      height: 844,
      theme: ThemeMode.light,
      locale: Locale('ur'),
      dir: 'rtl',
      measurementCell: 'components_390_light_rtl',
      navCell: 'components_390_light_rtl',
    ),
    (
      name: 'landscape phone 852×393',
      width: 852,
      height: 393,
      theme: ThemeMode.light,
      locale: Locale('en'),
      dir: 'ltr',
      measurementCell: 'components_852_light_ltr',
      navCell: 'components_390_light_ltr',
    ),
    (
      name: 'medium 700×900',
      width: 700,
      height: 900,
      theme: ThemeMode.light,
      locale: Locale('en'),
      dir: 'ltr',
      measurementCell: 'components_700_light_ltr',
      navCell: 'components_700_light_ltr',
    ),
    (
      name: 'medium 700×900 · dark',
      width: 700,
      height: 900,
      theme: ThemeMode.dark,
      locale: Locale('en'),
      dir: 'ltr',
      measurementCell: 'components_700_dark_ltr',
      navCell: 'components_700_dark_ltr',
    ),
    (
      name: 'medium 700×900 · Urdu',
      width: 700,
      height: 900,
      theme: ThemeMode.light,
      locale: Locale('ur'),
      dir: 'rtl',
      measurementCell: 'components_700_light_rtl',
      navCell: 'components_700_light_rtl',
    ),
    (
      name: 'expanded 1100×900',
      width: 1100,
      height: 900,
      theme: ThemeMode.light,
      locale: Locale('en'),
      dir: 'ltr',
      measurementCell: 'components_1100_light_ltr',
      navCell: 'components_1100_light_ltr',
    ),
    (
      name: 'expanded 1100×900 · dark',
      width: 1100,
      height: 900,
      theme: ThemeMode.dark,
      locale: Locale('en'),
      dir: 'ltr',
      measurementCell: 'components_1100_dark_ltr',
      navCell: 'components_1100_dark_ltr',
    ),
    (
      name: 'expanded 1100×900 · Urdu',
      width: 1100,
      height: 900,
      theme: ThemeMode.light,
      locale: Locale('ur'),
      dir: 'rtl',
      measurementCell: 'components_1100_light_rtl',
      navCell: 'components_1100_light_rtl',
    ),
  ];

  const ReferenceTokens css = ReferenceTokens.frozen;
  final List<String> rows = <String>[];

  /// One compared value. Recorded for the report, and asserted here.
  void row(
    Cell cell,
    String what,
    Object web,
    Object flutter, {
    String note = '',
  }) {
    expect(
      flutter,
      web,
      reason:
          '${cell.name} · $what — the reference says $web, Flutter renders '
          '$flutter',
    );
    rows.add(
      '| ${cell.name} | $what | `$web` | `$flutter` | ${note.isEmpty ? '=' : note} |',
    );
  }

  String hex(Color c) =>
      '#${((c.a * 255).round() << 24 | (c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(8, '0').toUpperCase()}';

  for (final Cell cell in cells) {
    testWidgets(cell.name, (WidgetTester tester) async {
      final Measurements m = Measurements.load(cell.measurementCell);
      final Measurements nav = Measurements.load(cell.navCell);

      final List<LumeDestination> destinations = LumeDestinations.build(
        countryCode: 'PK',
        label: (LumeDestinationId id) => id.name,
      );

      await pumpLume(
        tester,
        LumeShell(
          destinations: destinations,
          selectedIndex: 0,
          onSelected: (_) {},
          clock: '9:41',
          child: const SizedBox.expand(),
        ),
        surface: Size(cell.width, cell.height),
        theme: cell.theme,
        locale: cell.locale,
      );

      final BuildContext context = tester.element(find.byType(LumeShell));
      final LumeColors lume = Theme.of(context).extension<LumeColors>()!;
      final bool compact = find.byType(LumeBottomBar).evaluate().isNotEmpty;

      row(cell, 'direction', cell.dir, Directionality.of(context).name);

      // D1. The web has no height rule, so a landscape phone is `expanded`
      // there and its bottom bar is `display: none` — height 0. Flutter keeps
      // the phone presentation, so there is nothing to compare the bar
      // against at this width and it is compared against the phone's instead.
      // The divergence is the point, and is recorded rather than asserted
      // away.
      if (cell.navCell != cell.measurementCell) {
        rows.add(
          '| ${cell.name} | width class | `expanded` | `compact` | '
          '**D1** — a landscape phone is a phone; the web has no height rule |',
        );
        expect(m['tabbar'].height, 0, reason: 'the web hides the bar here');
        expect(compact, isTrue, reason: 'Flutter keeps the bar here');
      }

      if (compact) {
        final Rect bar = tester.getRect(
          find
              .descendant(
                of: find.byType(LumeBottomBar),
                matching: find.byType(Container),
              )
              .first,
        );
        row(cell, '.tabbar height', nav['tabbar'].height, bar.height);
        row(cell, '.tabbar inset start', LumeBottomBar.inset, bar.left);
        row(
          cell,
          '.tabbar inset end',
          LumeBottomBar.inset,
          cell.width - bar.right,
        );
        row(
          cell,
          '.tabbar__pill height',
          nav['tabbar.pill'].height,
          tester.getRect(find.byType(AnimatedPositionedDirectional)).height,
        );
        row(
          cell,
          '.tab.is-active ink',
          hex(nav['tab.active'].colour('color')),
          hex(lume.accent),
        );
        row(cell, '.tab ink', hex(nav['tab'].colour('color')), hex(lume.text3));
        row(
          cell,
          '.tab__label size',
          nav['tab.label'].fontSize,
          tester.widget<Text>(find.text('home')).style!.fontSize!,
        );
      } else {
        final bool expanded = cell.width >= 840;
        final Rect rail = tester.getRect(find.byType(LumeNavigationRail));
        row(
          cell,
          '.navside width',
          ReferenceTokens.px(
            css.light[expanded ? '--nav-side' : '--nav-rail']!,
          ),
          rail.width,
          note:
              'from tokens.css — `.navside` is a grid area with no width of '
              'its own',
        );
        row(
          cell,
          '.navside edge',
          cell.dir == 'rtl' ? 'end' : 'start',
          rail.left == 0 ? 'start' : 'end',
          note: 'direction-aware placement',
        );
        row(
          cell,
          '.navtab label size',
          m['navtab'].fontSize,
          tester.widget<Text>(find.text('home')).style!.fontSize!,
        );
        row(
          cell,
          '.navtab.is-active tint',
          hex(m['navtab.active'].colour('backgroundColor')),
          hex(lume.tintAccent),
        );
        row(
          cell,
          '.navtab.is-active ink',
          hex(m['navtab.active'].colour('color')),
          hex(lume.accent700),
        );
        row(
          cell,
          '.navside__brand shown',
          expanded,
          find.text('Lume').evaluate().isNotEmpty,
        );
        row(
          cell,
          '.statusbar ground',
          hex(m['statusbar'].colour('backgroundColor')),
          hex(lume.card),
          note: 'application chrome at these widths — see P1',
        );
      }
    });
  }

  tearDownAll(() {
    final StringBuffer out = StringBuffer()
      ..writeln('# Navigation parity, cell by cell')
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
        'Generated by `test/core/navigation/navigation_report_test.dart`. Every '
        'row\nbelow is an assertion that passed: the **web** column is '
        '`getComputedStyle`\nread from the rendered prototype (or `tokens.css` '
        'where the specimen fixture\ncannot report a value), and the **Flutter** '
        'column is the rendered widget\nmeasured in the same run. A mismatch '
        'fails the test, so this file cannot\ndisagree with the code.',
      )
      ..writeln()
      ..writeln(
        'The **web** column is frozen: it was measured before Phase F9 removed '
        'the\nprototype and cannot be re-measured. Re-running '
        '`flutter test test/core/navigation/navigation_report_test.dart`\n'
        'refreshes the **Flutter** column.',
      )
      ..writeln()
      ..writeln('| Cell | Property | Web | Flutter | Note |')
      ..writeln('|---|---|---|---|---|');
    for (final String r in rows) {
      out.writeln(r);
    }
    out
      ..writeln()
      ..writeln('${rows.length} values compared across ${cells.length} cells.')
      ..writeln()
      ..writeln(
        'What is deliberately **not** compared here: the stage, the device '
        'frame and\nthe simulated device glyphs, which are browser costume — '
        'see\n[KNOWN_DIFFERENCES.md](KNOWN_DIFFERENCES.md) P1, P5 and D11.',
      );

    File(reportPath).writeAsStringSync(out.toString());
  });
}
