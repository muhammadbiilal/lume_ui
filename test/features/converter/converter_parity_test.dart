/// Unit Converter against the running reference, element by element.
///
/// The committed cells were measured in a browser with
/// `measure_destinations.mjs --tool converter`, and [ToolParity] compares each
/// recorded `getBoundingClientRect` against the finder for the same element,
/// relative to the tool bar's top-left on both sides — the reference has a
/// simulated status bar and a tablet stage, Flutter has neither. Every
/// compared value is written to
/// `docs/conversion_archive/parity/tool_converter.md`, so the count of
/// mechanically compared values is a file rather than a claim.
///
/// **The one structural difference, measured rather than hidden.** The
/// reference draws six sections: the category chips, the convert card, "All
/// units", **"Recent"**, the source bar and "Related tools". This screen draws
/// five: "Recent" is two literals — `10 km → mi = 6.21` and `1 kg → lb = 2.20`
/// — presented as conversions the reader made, which nothing records and so
/// nothing can list back (`ROLLOUT_WAVE_4.md` §2 and §7). So the reference's
/// `sect4` is Recent and this screen's fourth section is the source bar, and
/// `sect4`/`sect5`/`sect6` are deliberately *not* mapped across. Everything
/// below "All units" is declared with [_kRecent] instead — a subtraction read
/// off the capture itself, asserted in "the section the reference draws and
/// this does not", and written into the report beside every value.
///
/// **The one width the reference sets and this comparison cannot.** The `to`
/// side of the convert card is not compared. The swap's drawn circle is the
/// reference's 34 and its target is §9's 44 (D6), and the ten extra points
/// come out of the two flexible sides: each side is 126 where the reference
/// measures 131, and the `to` side therefore begins at 227 where the
/// reference begins at 222. It is an exclusion rather than an allowance
/// because [ToolParity] records a difference in `y` or `height`, which is
/// where honest ones land, and a difference in `x` or `width` has nowhere to
/// be written down. So the arithmetic is asserted instead, in "the ten points
/// the swap target takes", and the numbers are on the record.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lume/core/theme/lume/lume_space.dart';
import 'package:lume/core/widgets/lume/lume_badge.dart';
import 'package:lume/core/widgets/lume/lume_button.dart';
import 'package:lume/core/widgets/lume/lume_header.dart';
import 'package:lume/core/widgets/lume/lume_pressable.dart';
import 'package:lume/core/widgets/lume/lume_row.dart';
import 'package:lume/core/widgets/lume/lume_table.dart';
import 'package:lume/core/widgets/lume/lume_tool.dart';
import 'package:lume/features/converter/domain/unit_table.dart';
import 'package:lume/features/converter/presentation/converter_tool.dart';

import '../../helpers/load_fonts.dart';
import '../tools/tool_parity.dart';
import 'converter_harness.dart';

/// What the dropped "Recent" section costs everything under it, in points.
///
/// Read off the capture and not guessed at: the section is 116 tall and the
/// sections are 24 apart, so where this screen's source bar sits at
/// `sect3.y + sect3.height + 24` the reference's sits at
/// `sect3.y + sect3.height + 24 + 116 + 24`. The difference — the section
/// plus the gap that followed it — is 140, and it is the same 140 in every
/// English cell.
const double _kRecent = -140;

/// A `LumeToolSection` carries the 24-point gap above it **inside** its own
/// box; the reference's `<section>` has it as a margin, **outside** its box.
/// The same allowance Focus records, and for the same reason.
const double _kSectionGap = 24;

/// `.convert { gap: 10px }`, on both sides of the swap.
const double _kConvertGap = LumeConverterTool.gap;

/// The `composition` block of a measured cell.
Map<String, dynamic> _composition(String cell) =>
    webToolCell(cell)!['composition'] as Map<String, dynamic>;

/// One recorded box of a measured cell.
Map<String, dynamic> _bounds(String cell, String element) =>
    (webToolCell(cell)!['bounds'] as Map<String, dynamic>)[element]
        as Map<String, dynamic>;

/// One recorded number of a measured cell.
double _measured(String cell, String element, String property) =>
    (_bounds(cell, element)[property] as num).toDouble();

/// The nth `.sect` on the screen, in paint order.
Finder _section(int index) => find.byType(LumeToolSection).at(index);

/// The whole `.convert__side` — the nearest `Column` above that side's own
/// unit control, which is `_ConvertSide`'s own and is private to the screen.
Finder _side(Key unitKey) =>
    find.ancestor(of: find.byKey(unitKey), matching: find.byType(Column)).first;

/// `.convert` — the row the two sides and the swap sit in.
Finder _convertRow() => find
    .ancestor(
      of: find.byKey(LumeConverterTool.swapKey),
      matching: find.byType(Row),
    )
    .first;

/// `.convert__swap` — the drawn 34-point circle, not the 44-point target
/// around it. The reference measures the circle, and the two are deliberately
/// different sizes (D6), so the measurement is taken on the same thing.
Finder _swapCircle() => find.descendant(
  of: find.byKey(LumeConverterTool.swapKey),
  matching: find.byWidgetPredicate(
    (Widget w) =>
        w is Container && w.constraints?.maxWidth == LumeConverterTool.swapSize,
  ),
);

/// The drawn box of one category chip, so its fill can be read.
Finder _chipBox(LumeUnitKind kind) => find.descendant(
  of: find.byKey(LumeConverterTool.categoryKey(kind)),
  matching: find.byType(AnimatedContainer),
);

/// The colour a category chip is actually filled with.
Color? _chipFill(WidgetTester tester, LumeUnitKind kind) =>
    (tester.widget<AnimatedContainer>(_chipBox(kind)).decoration
            as BoxDecoration)
        .color;

void main() {
  setUpAll(loadLumeFonts);

  final ToolParity parity = ToolParity('converter');
  tearDownAll(parity.write);

  Map<String, Finder> elements() => <String, Finder>{
    'toolbar': find.byType(LumeToolbar),
    // The drawn 38-point circle, not the 44-point target around it — the
    // reference measures the circle, and `LumeBackButton` keys it apart from
    // its target for exactly this (D6).
    'toolbar.back': find.byKey(LumeBackButton.circleKey),
    // "Calculator" is also the first related tool and "Unit Converter" is on
    // the Tools hub behind this route, so both are taken from inside the bar
    // rather than by their words alone.
    'toolbar.title': find.descendant(
      of: find.byType(LumeToolbar),
      matching: find.text('Unit Converter'),
    ),
    'toolbar.sub': find.descendant(
      of: find.byType(LumeToolbar),
      matching: find.text('Calculator'),
    ),
    'toolbar.actions': find
        .ancestor(
          of: find.descendant(
            of: find.byType(LumeToolbar),
            matching: find.byType(LumeIconButton),
          ),
          matching: find.byType(Row),
        )
        .first,

    // The chip strip and three of its six chips.
    'chips': find.byKey(LumeConverterTool.categoriesKey),
    'chip1': find.byKey(LumeConverterTool.categoryKey(LumeUnitKind.length)),
    'chip2': find.byKey(LumeConverterTool.categoryKey(LumeUnitKind.mass)),
    'chip4': find.byKey(LumeConverterTool.categoryKey(LumeUnitKind.area)),

    // The three sections this screen and the reference both draw.
    'sect1': _section(0),
    'sect2': _section(1),
    'sect3': _section(2),
    'sect3.title': find.text('All units'),

    // `.convert` — the card, the row inside it, and the side the reader
    // types into.
    'kard': find.byKey(LumeConverterTool.cardKey),
    'convert': _convertRow(),
    'convert.side1': _side(LumeConverterTool.fromKey),
    'convert.code1': find.byKey(LumeConverterTool.fromKey),
    'convert.input': find.byKey(LumeConverterTool.amountKey),
    'convert.name1': find.descendant(
      of: _side(LumeConverterTool.fromKey),
      matching: find.text('Metre'),
    ),
    'convert.swap': _swapCircle(),

    // "All units" — the card and its first two rows.
    'rows': find.byKey(LumeConverterTool.allUnitsKey),
    'crow1': find.byKey(LumeConverterTool.rowKey('m')),
    'crow2': find.byKey(LumeConverterTool.rowKey('km')),
    'crow.value': find
        .descendant(
          of: find.byKey(LumeConverterTool.rowKey('m')),
          matching: find.byType(Text),
        )
        .last,

    // Below "All units" — everything the dropped section lifts.
    'srcbar': find.byType(LumeSourceBar),
    'fresh': find.byType(LumeFreshness),
    'srcline': find.byType(LumeSourceLine),
    'related.sect': find.byType(LumeToolSection).last,
    'related.title': find.text('Related tools'),
    'related': find.byType(LumeRelatedTools),
    'related.item1': find
        .descendant(
          of: find.byType(LumeRelatedTools),
          matching: find.byType(LumePressable),
        )
        .at(0),
    'related.item2': find
        .descendant(
          of: find.byType(LumeRelatedTools),
          matching: find.byType(LumePressable),
        )
        .at(1),
  };

  /// The widths the words or the flex set rather than the layout. Every one
  /// of these is compared on `x`, `y` and `height` exactly; only the width is
  /// left out, for the reason written beside it.
  const Set<String> contentWidth = <String>{
    // A `.convert__side` and the three boxes it stretches: the width the flex
    // hands them is 126 against the reference's 131, which is the swap
    // target's ten points, asserted by name below.
    'convert.side1',
    'convert.code1',
    'convert.input',
    'convert.name1',
    // The bar's title and sub-line are measured on their box in the capture —
    // the 254 points of column between the back control and the actions — and
    // on their string in Flutter, so only the position is comparable.
    'toolbar.title',
    'toolbar.sub',
  };

  // Only the English cells are compared point for point. The Urdu and Arabic
  // cells were measured in Chrome with its own Noto faces; Flutter loads
  // different ones, so their line boxes differ by a few points everywhere and
  // a bounds comparison would be measuring the font, not the layout. What
  // those cells are for — the words, the direction and the numerals — is
  // asserted in `converter_screen_test.dart`.
  group('where everything is', () {
    for (final (String cell, Size size) in <(String, Size)>[
      ('tool_converter_default_pk_390x844_light_en', const Size(390, 5000)),
      ('tool_converter_default_pk_390x844_dark_en', const Size(390, 5000)),
      // Above a phone the reference puts the app on a stage beside a rail or
      // a sidebar, and the tool's column is the window less both: 566 in a
      // 700 window, 806 in an 1100 one. The harness pumps the route, so the
      // shell draws the rail and the surface is reduced by it — the same
      // subtraction Focus and World Clock make.
      ('tool_converter_default_pk_700x900_light_en', const Size(650, 5000)),
      ('tool_converter_default_pk_1100x900_light_en', const Size(1050, 5000)),
      // 852x393 is the height-constrained landscape cell. Its column comes
      // from the rail against a 393-point height, which a tall test surface
      // cannot reproduce; comparing it would measure the stage, not the tool.
      // The three width classes above cover what the layout decides.
    ]) {
      testWidgets(cell, (WidgetTester tester) async {
        await pumpConverter(
          tester,
          surface: size,
          theme: cell.contains('_dark_') ? ThemeMode.dark : ThemeMode.light,
        );
        final List<String> misses = parity.bounds(
          tester,
          cell,
          elements(),
          noWidth: contentWidth,
          shifted: const <String, double>{
            // The section's own 24-point gap, inside its box here and outside
            // it there.
            'sect1': -_kSectionGap,
            'sect2': -_kSectionGap,
            'sect3': -_kSectionGap,
            // The dropped "Recent" section, and the gap that followed it.
            'srcbar': _kRecent,
            'fresh': _kRecent,
            'srcline': _kRecent,
            'related.title': _kRecent,
            'related': _kRecent,
            'related.item1': _kRecent,
            'related.item2': _kRecent,
            // The related rail's own section box carries both: it is lifted
            // by the dropped section, and it starts 24 higher than the
            // reference's `<section>` because it owns the gap above it.
            'related.sect': _kRecent - _kSectionGap,
          },
          grown: const <String, double>{
            'sect1': _kSectionGap,
            'sect2': _kSectionGap,
            'sect3': _kSectionGap,
            'related.sect': _kSectionGap,
          },
        );
        expect(misses, isEmpty, reason: misses.join('\n'));
      });
    }
  });

  group('what it says, in the state the reference was captured in', () {
    const String cell = 'tool_converter_default_pk_390x844_light_en';

    testWidgets('the chips, the card and every unit', (
      WidgetTester tester,
    ) async {
      await pumpConverter(tester, surface: const Size(390, 5000));
      final Map<String, dynamic> k = _composition(cell);
      final Map<String, dynamic> convert = k['convert'] as Map<String, dynamic>;

      // The six categories, in the reference's own order.
      expect(
        textsIn(tester, find.byKey(LumeConverterTool.categoriesKey)),
        convert['chips'],
      );

      // The side the reader types into: `m`, `Metre`, and the 1 the
      // reference's own field opens on.
      final Map<String, dynamic> from = convert['from'] as Map<String, dynamic>;
      expect(textsIn(tester, _side(LumeConverterTool.fromKey)), <String>[
        from['code'],
        from['name'],
      ]);
      expect(
        tester
            .widget<TextField>(find.byKey(LumeConverterTool.amountKey))
            .controller!
            .text,
        from['value'],
      );

      // The side the answer is on: `km`, `Kilometre`, `0.001`.
      final Map<String, dynamic> to = convert['to'] as Map<String, dynamic>;
      expect(textsIn(tester, _side(LumeConverterTool.toKey)), <String>[
        to['code'],
        to['value'],
        to['name'],
      ]);
      expect(converterResult(tester), to['value']);

      // "All units" — the reference's first six entries, label, symbol and
      // figure, against the rows this screen draws.
      final List<dynamic> units = convert['units'] as List<dynamic>;
      final List<LumeCompactRow> rows = tester
          .widgetList<LumeCompactRow>(
            find.descendant(
              of: find.byKey(LumeConverterTool.allUnitsKey),
              matching: find.byType(LumeCompactRow),
            ),
          )
          .toList();
      expect(rows, hasLength(6));
      for (int i = 0; i < 6; i++) {
        final Map<String, dynamic> unit = units[i] as Map<String, dynamic>;
        expect(rows[i].label, unit['label'], reason: 'row $i label');
        expect(rows[i].subtitle, unit['sub'], reason: 'row $i symbol');
        expect(plainText(rows[i].value!), unit['value'], reason: 'row $i');
      }

      // The seventh and eighth entries are not units at all: they are the two
      // "Recent" literals, and this screen draws neither.
      expect(units, hasLength(8));
      expect(units[6]['label'], '10 km → mi');
      expect(units[6]['sub'], isNull);
      expect(units[6]['value'], '6.21');
      expect(units[7]['label'], '1 kg → lb');
      expect(units[7]['sub'], isNull);
      expect(units[7]['value'], '2.20');
      expect(find.text('6.21'), findsNothing);
      expect(find.text('2.20'), findsNothing);
      expect(find.text('Recent'), findsNothing);

      // Two numbers with nothing between them is not a conversion, so the
      // swap says what it does — in the reference's own word.
      expect(
        tester
            .widget<LumePressable>(find.byKey(LumeConverterTool.swapKey))
            .semanticLabel,
        convert['swap'],
      );

      final Map<String, dynamic> source = k['source'] as Map<String, dynamic>;
      expect(find.text(source['fresh'] as String), findsOneWidget);
      expect(referenceSourceLine(tester), source['line']);
      expect(textsIn(tester, find.byType(LumeRelatedTools)), k['related']);
    });

    testWidgets('the section the reference draws and this does not', (
      WidgetTester tester,
    ) async {
      // The capture's fourth section, in the reference's own words: a heading
      // and two conversions no store ever held.
      expect(
        _bounds(cell, 'sect4')['text'],
        'Recent10 km → mi6.211 kg → lb2.20',
      );
      // …and it is 116 tall, 24 below "All units" and 24 above the source
      // bar, which is the whole of the 140 in [_kRecent].
      expect(_measured(cell, 'sect4', 'height'), 116);
      final double sect3Bottom =
          _measured(cell, 'sect3', 'y') + _measured(cell, 'sect3', 'height');
      final double sect4Bottom =
          _measured(cell, 'sect4', 'y') + _measured(cell, 'sect4', 'height');
      expect(_measured(cell, 'sect4', 'y') - sect3Bottom, _kSectionGap);
      expect(_measured(cell, 'sect5', 'y') - sect4Bottom, _kSectionGap);
      expect(
        _measured(cell, 'sect5', 'y') - (sect3Bottom + _kSectionGap),
        -_kRecent,
      );

      await pumpConverter(tester, surface: const Size(390, 5000));
      // This screen's fourth section is the source bar and its fifth is the
      // related rail: nothing stands where "Recent" stood.
      expect(find.byType(LumeToolSection), findsNWidgets(5));
      expect(
        find.descendant(of: _section(3), matching: find.byType(LumeSourceBar)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _section(4),
          matching: find.byType(LumeRelatedTools),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the ten points the swap target takes', (
      WidgetTester tester,
    ) async {
      // The reference lays the card out as 131 + 10 + 34 + 10 + 131 = 316.
      final double refRow = _measured(cell, 'convert', 'width');
      final double refSide = _measured(cell, 'convert.side1', 'width');
      final double refSwap = _measured(cell, 'convert.swap', 'width');
      expect(refSide, 131);
      expect(refSwap, LumeConverterTool.swapSize);
      expect(refSide * 2 + _kConvertGap * 2 + refSwap, refRow);

      await pumpConverter(tester, surface: const Size(390, 5000));
      final Rect row = tester.getRect(_convertRow());
      final Rect side1 = tester.getRect(_side(LumeConverterTool.fromKey));
      final Rect side2 = tester.getRect(_side(LumeConverterTool.toKey));
      final Rect target = tester.getRect(find.byKey(LumeConverterTool.swapKey));
      final Rect circle = tester.getRect(_swapCircle());

      // The row is the reference's width to the point, and the circle inside
      // it is the reference's circle.
      expect(row.width, refRow);
      expect(circle.width, refSwap);
      expect(circle.height, refSwap);
      // The target around it is §9's 44, and the ten points it takes come out
      // of the two flexible sides — five each — rather than off the end of
      // the card.
      expect(target.width, LumeSpace.tap);
      expect(target.width - circle.width, 10);
      expect(side1.width, side2.width);
      expect(refSide - side1.width, 5);
      expect(
        side2.left - row.left,
        _measured(cell, 'convert.side2', 'x') -
            _measured(cell, 'convert', 'x') +
            5,
      );
      // …and nothing is lost: the row still adds up to the reference's.
      expect(
        side1.width + _kConvertGap * 2 + target.width + side2.width,
        refRow,
      );
    });
  });

  group('the chip the reference does not draw', () {
    testWidgets('the capture proves it, and this screen does not repeat it', (
      WidgetTester tester,
    ) async {
      const String cell = 'tool_converter_default_pk_390x844_light_en';
      // `converter.tool.js:19` emits `class="chip is-on"` for the selected
      // category and `components.css:463` defines `.chip.is-active`, so
      // nothing styles it. The capture is the proof, and it is re-derived
      // here rather than restated: `chip.on` and `chip1` are recorded as the
      // same box, and that box is drawn in exactly the colours of `chip2`,
      // which is an unselected chip.
      final Map<String, dynamic> on = _bounds(cell, 'chip.on');
      final Map<String, dynamic> first = _bounds(cell, 'chip1');
      final Map<String, dynamic> second = _bounds(cell, 'chip2');
      expect(
        <dynamic>[on['x'], on['y'], on['width']],
        <dynamic>[first['x'], first['y'], first['width']],
      );
      expect(on['color'], first['color']);
      expect(on['background'], first['background']);
      expect(on['color'], second['color']);
      expect(on['background'], second['background']);

      // Correction 6: here the category the reader is in is drawn as such.
      await pumpConverter(tester, surface: const Size(390, 5000));
      final Color? selected = _chipFill(tester, LumeUnitKind.length);
      expect(selected, isNotNull);
      for (final LumeUnitKind other in LumeUnitKind.values) {
        if (other == LumeUnitKind.length) continue;
        expect(
          _chipFill(tester, other),
          isNot(selected),
          reason: '${other.name} is drawn like the selected chip',
        );
      }
    });
  });
}
