/// Where global search's parts are, against where the running reference puts
/// them.
///
/// `measure_destinations.mjs --screen home --state default_pk --after
/// search_*` raises `#sheet-search` over Home the way a reader does — the app
/// bar's own control — and writes `getBoundingClientRect` for each part. This
/// raises the same sheet over the same Home through `/home/search` and asserts
/// the numbers agree.
///
/// **Positions are the page's own.** The sheet is anchored to the bottom of
/// the viewport on both sides, so the reference's 28-point simulated status
/// bar (P1) does not move it: `y` is compared as measured, not from `.screen`.
///
/// A failure is a layout difference, not a rasterisation one: the tolerance is
/// a whole logical pixel. Every difference is collected before failing, so one
/// run reports them all.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_destination_cards.dart';
import 'package:lume/core/widgets/lume/lume_overlay.dart';
import 'package:lume/core/widgets/lume/lume_settings.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/onboarding/domain/profile_repository.dart';
import 'package:lume/features/search/presentation/search_sheet.dart';

import '../../helpers/load_fonts.dart';
import '../../helpers/lume_harness.dart';

/// One logical pixel.
const double kTolerance = 1.0;

/// The reference cell.
const Size kPhone = Size(390, 844);

void main() {
  setUpAll(loadLumeFonts);

  Map<String, dynamic> measured(String cell) {
    final File f = File(
      'docs/conversion_archive/measurements/${cell}_390x844_light_en.json',
    );
    final Map<String, dynamic> j =
        jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    return j['bounds'] as Map<String, dynamic>;
  }

  Future<void> open(WidgetTester tester, {String query = ''}) async {
    // `default_pk` — the cell the reference was measured in.
    final LumeMemoryProfileRepository profiles = LumeMemoryProfileRepository();
    await profiles.writeProfile(
      const LumeProfileRecord(country: 'PK', city: 'Islamabad', islamic: false),
    );
    await pumpLumeRouter(
      tester,
      initialLocation: '/home/search',
      profile: profiles,
      surface: kPhone,
    );
    await tester.pumpAndSettle();
    if (query.isNotEmpty) {
      await tester.enterText(
        find.descendant(
          of: find.byKey(LumeSearchSheet.fieldKey),
          matching: find.byType(EditableText),
        ),
        query,
      );
      await tester.pumpAndSettle();
    }
  }

  /// Compares [finder]'s rect with the reference's [name], and returns every
  /// disagreement as a sentence.
  List<String> compare(
    WidgetTester tester,
    Map<String, dynamic> bounds,
    String name,
    Finder finder, {
    bool checkWidth = true,
  }) {
    final Map<String, dynamic>? b = bounds[name] as Map<String, dynamic>?;
    if (b == null) return <String>['$name was not measured'];
    if (finder.evaluate().isEmpty) return <String>['$name is not on screen'];
    final Rect r = tester.getRect(finder.first);
    final List<String> out = <String>[];
    void check(String what, num wanted, double got) {
      if ((got - wanted).abs() > kTolerance) {
        out.add(
          '$name $what — reference ${wanted.toStringAsFixed(2)}, '
          'Flutter ${got.toStringAsFixed(2)}',
        );
      }
    }

    check('x', b['x'] as num, r.left);
    check('y', b['y'] as num, r.top);
    if (checkWidth) check('width', b['width'] as num, r.width);
    check('height', b['height'] as num, r.height);
    return out;
  }

  Finder label(String startsWith) => find.byWidgetPredicate(
    (Widget w) =>
        w is Text &&
        (w.data ?? '').toLowerCase().startsWith(startsWith.toLowerCase()),
  );

  Finder cardOf(Finder row) =>
      find.ancestor(of: row, matching: find.byType(LumeCard));

  testWidgets('idle: the field, the suggestions and the recents', (
    WidgetTester tester,
  ) async {
    await open(tester);
    final Map<String, dynamic> b = measured('search_idle');
    final Finder firstRow = find.byType(LumeSettingsRow).first;

    final List<String> misses = <String>[
      ...compare(tester, b, 'sheet', find.byType(LumeSheet)),
      ...compare(tester, b, 'search', find.byKey(LumeSearchSheet.fieldKey)),
      ...compare(tester, b, 'idle.try', label('try searching')),
      ...compare(tester, b, 'chip', find.byType(LumeChoiceChip)),
      ...compare(tester, b, 'idle.jump', label('jump back')),
      ...compare(tester, b, 'recents', cardOf(firstRow)),
      ...compare(tester, b, 'recent', firstRow),
    ];
    expect(misses, isEmpty, reason: misses.join('\n'));
  });

  testWidgets('typed: the sheet rises and the hits are the same rows', (
    WidgetTester tester,
  ) async {
    await open(tester, query: 'ca');
    final Map<String, dynamic> b = measured('search_results');
    final Finder firstRow = find.byType(LumeSettingsRow).first;

    final List<String> misses = <String>[
      ...compare(tester, b, 'sheet', find.byType(LumeSheet)),
      ...compare(tester, b, 'search', find.byKey(LumeSearchSheet.fieldKey)),
      ...compare(tester, b, 'result', firstRow),
    ];
    expect(misses, isEmpty, reason: misses.join('\n'));
  });

  testWidgets('nothing found: the reference’s own empty drawing', (
    WidgetTester tester,
  ) async {
    await open(tester, query: 'zzzz nothing');
    final Map<String, dynamic> b = measured('search_empty');

    final List<String> misses = <String>[
      ...compare(tester, b, 'sheet', find.byType(LumeSheet)),
      ...compare(tester, b, 'empty', find.byType(LumeEmptyState)),
      ...compare(tester, b, 'empty.title', find.text('Nothing found')),
    ];
    expect(misses, isEmpty, reason: misses.join('\n'));
  });
}
