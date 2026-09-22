/// World Clock against the running reference, element by element.
///
/// `ToolParity` reads `getBoundingClientRect` from the browser capture and the
/// same rectangle from Flutter, both relative to the tool bar's top-left, and
/// writes every compared value into
/// `docs/conversion_archive/parity/tool_worldclock.md`.
///
/// The reference's four sections are held to: the summary, the search field,
/// the list and "Convert a time", then the source bar and the related rail.
/// Three differences are *recorded* rather than tolerated, and each is a
/// decision in `WORLD_CLOCK_PROPOSAL.md`:
///
/// * `field1` and `field2` are four points taller — a Lume field box is 42
///   where the reference's `<select>` is 38;
/// * `fgrid` is 77 points taller and `kard` 111, because the converter that
///   the reference ships as dead markup is real here (D-W7): it carries the
///   instant as a third field and prints the answer under the grid;
/// * everything below the card — the source bar and the related rail — sits
///   111 points lower for the same reason.
///
/// The Urdu and Arabic cells are not compared here: their difference is the
/// line height of the script's web font against Flutter's, which is a font
/// metric and not a layout decision. What those cells say, and which way round
/// they say it, is held in `worldclock_screen_test.dart`.
///
/// Two more differences are in the text rather than the geometry, so they are
/// declared as content-width rather than compared: the section reads "Clocks",
/// not "Cities", because the list holds time zones and the reader's own clock
/// leads it; and each row's title is the zone's CLDR label rather than a
/// hard-coded city name (defect 3).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/widgets/lume/lume_field_grid.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_surface.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/onboarding/domain/onboarding_state.dart';
import 'package:lume/features/worldclock/presentation/worldclock_tool.dart';

import '../../helpers/load_fonts.dart';
import '../tools/tool_parity.dart';
import 'worldclock_screen_harness.dart';

/// One measured cell.
typedef _Cell = (
  String name,
  Size surface,
  Locale locale,
  ThemeMode theme,
  LumeProfileRecord? profile,
);

/// The head of the nth section — the title Text, whatever language it is in.
Finder _sectionTitle(int index) => find.descendant(
  of: find.byType(LumeToolSection).at(index),
  matching: find.byType(Text),
);

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('worldclock');
  tearDownAll(parity.write);

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    'summary': find.byKey(LumeWorldClockTool.summaryKey),
    'tsearch': find.byKey(LumeWorldClockTool.searchKey),
    'sect3.title': _sectionTitle(2),
    'sect.title': _sectionTitle(2),
    'rows': find.byKey(LumeWorldClockTool.clocksKey),
    'rrow1': inKey(
      LumeWorldClockTool.clocksKey,
      find.byType(LumeRichRow),
    ).at(0),
    'rrow2': inKey(
      LumeWorldClockTool.clocksKey,
      find.byType(LumeRichRow),
    ).at(1),
    'rrow.title': inKey(LumeWorldClockTool.clocksKey, find.byType(Text)).at(0),
    'rrow.sub': inKey(LumeWorldClockTool.clocksKey, find.byType(Text)).at(1),
    'kard': find.byType(LumeCard),
    'fgrid': find.byType(LumeFieldGrid),
    'field1': find.byKey(LumeWorldClockTool.convertFromKey),
    'field2': find.byKey(LumeWorldClockTool.convertToKey),
    'field.label': inKey(
      LumeWorldClockTool.convertFromKey,
      find.byType(Text),
    ).first,
    'srcbar': find.byType(LumeSourceBar),
    'related': find.byType(LumeRelatedTools),
  };

  /// Widths set by the words themselves rather than by the layout: "Clocks"
  /// is not "Cities", and a zone's label is not a hard-coded city name.
  const Set<String> contentWidth = <String>{
    'sect3.title',
    'sect.title',
    'rrow.title',
    'rrow.sub',
    'field.label',
  };

  for (final _Cell cell in <_Cell>[
    (
      'default_pk_390x844_light_en',
      const Size(390, 5000),
      const Locale('en'),
      ThemeMode.light,
      null,
    ),
    (
      'default_pk_390x844_dark_en',
      const Size(390, 5000),
      const Locale('en'),
      ThemeMode.dark,
      null,
    ),
    (
      'default_us_390x844_light_en',
      const Size(390, 5000),
      const Locale('en'),
      ThemeMode.light,
      worldClockReader(country: 'US', region: 'New York', city: 'New York'),
    ),
    (
      'default_jp_390x844_light_en',
      const Size(390, 5000),
      const Locale('en'),
      ThemeMode.light,
      worldClockReader(country: 'JP', region: 'Tokyo', city: 'Tokyo'),
    ),
    // The two width classes above the phone. The reference's own column
    // is narrower than its window by the shell's rail, so the surface is
    // reduced to match — the same subtraction qr_test and learning_test
    // make. 852x393 is left out: it is the height-constrained landscape
    // cell, and its column comes from the rail against a 393-point
    // height, which a tall test surface cannot reproduce.
    (
      'default_pk_700x900_light_en',
      const Size(650, 5000),
      const Locale('en'),
      ThemeMode.light,
      null,
    ),
    (
      'default_pk_1100x900_light_en',
      const Size(1050, 5000),
      const Locale('en'),
      ThemeMode.light,
      null,
    ),
  ]) {
    testWidgets(cell.$1, (WidgetTester tester) async {
      await pumpWorldClock(
        tester,
        surface: cell.$2,
        locale: cell.$3,
        theme: cell.$4,
        profile: cell.$5,
      );
      final List<String> misses = parity.bounds(
        tester,
        'tool_worldclock_${cell.$1}',
        elements(),
        drifting: const <String>{'rrow.title', 'rrow.sub'},
        noWidth: contentWidth,
        grown: const <String, double>{
          // A Lume field box is 42 where a `<select>` is 38.
          'field1': 4,
          'field2': 4,
          // The instant, as a third field (D-W7).
          'fgrid': 77,
          // …and the answer, printed under the grid.
          'kard': 111,
        },
        shifted: const <String, double>{'srcbar': 111, 'related': 111},
      );
      expect(misses, isEmpty, reason: misses.join('\n'));
    });
  }
}
